////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	cheapspectral.v
// {{{
// Project:	DSP Filtering Example Project
//
// Purpose:	To create a cheap autocorrelation estimate of an incoming
//		signal.  Such an estimate could then be Fourier transformed
//	to yield a basic spectral estimate of the incoming data.
//
// Usage:	To use this core, connect it to a (real) data stream: set
//		i_data_ce for every new value of the data stream, and i_data
//	to the actual value.  For those who like AXI stream interfaces,
//
//		TVALID = i_data_ce
//		TREADY = 1 (as written, but will skip correlations to keep up)
//			The core could be rewritten to create a TREADY output
//			== !running (internal signal)
//		TDATA = i_data
//		T(anything else) would be ignored.
//
//	As written, this core cannot handle complex data streams.  Creating an
//	upgrade to handle complex values wouldn't be that hard, this core just
//	doesn't handle them.
//
//	Set the LGLAGS parameter to the log (based two) of the number of
//	autocorrelation lags you'd like to estimate.  This will determine your
//	ultimate frequency resolution in the end.  It also determines the
//	address width (in words) of the core.
//
//	Set the LGNAVG parameter to the log (based two) of the number of
//	averages you want to make of each lag.  This will help determine the
//	variance in your autocorrelation estimate, larger values producing
//	lower variances.  (The core doesn't divide by the number of averages,
//	so if scale is important you'll still need to do that yourself.
//	Depending on the input data width and the number of averages, you might
//	also need to adjust for the scale associated with any dropped bits at
//	the end.  See bench/test/cheapspectral_tb.cpp and
//	bench/test/cheapspectral.m for examples of this.)
//
//	Set IW to the width (i.e. number of bits) of the incoming data.
//	Incoming data is assumed to be signed two's complement.
//
//	When you want to create a spectral estimate, write to the core.  Any
//	address will work.  Once the core has completed its estimate, it will
//	set o_int high for one cycle.  At that point, you can read the
//	correlations back out of  the core.  They'll be read in the order of
//	R[-N+1 : 0].  From this, you can create a new vector, 2^N long, of
//	{ R[0 : N-1], (zero padding), R[N-1:1] } / (1<<LGNAVG).  An FFT of
//	this vector will yield the spectrum estimate of the incoming data
//	provided to the core.
//
//	An alternate interface uses double buffers.  To use this, set the
//	OPT_DBLBUFFER parameter.  When using this alternate interface, the
//	core can estimate one FFT while reporting the results from another.
//	Once the interrupt wire goes high, the buffers swap and there's new
//	information to be read.
//
//	If you are using the double buffering interface, you can also set the
//	OPT_AUTO_RESTART parameter.  If set, the core will always and
//	automatically restart correlation calculations immediately upon the
//	conclusion of the last calculation.  It makes sense with the double
//	buffer option, and guarantees that the core always has valid data
//	containing the most recent autocorrelation result.  What it doesn't
//	do, however, is guarantee that reads from the core will return
//	results from the same autocorrelation.  As a result, reads might return
//	results that ... don't maintain the properties of autocorrelations
//	when using this option.
//
// Algorithm: Given a piece of data,
//
//	Clock 1:
//		- Multiply that data value by 1) itself then 2) every other
//		  previous data value given to the core, up to the number of
//		  lags 2^LGLAGS the core is configured for, one clock at time
//		  (Any new data that enters the core during this time will be
//		  recorded as "previous data", but otherwise ignored for
//		  spectral purposes.)
//		- Read the last average value, that is the last estimate of
//		  R[k], for the current lag
//	Clock 2:
//		- Add the new product to the last average to create a block
//		  average.  If this is the first average in the set, then skip
//		  the addition and just sign extend the product.
//	Clock 3:
//		- Write the updated autocorrelation estimate back to memory
//
//	In order to support high speed data on non-stationary signals, it might
//	make sense to support a special pseudorandom signal to indicate
//	whether or not to examine a given piece of data or not.  Such random
//	data selection is not (currently) a part of this implementation.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
// }}}
// Copyright (C) 2020-2024, Gisselquist Technology, LLC
// {{{
// This file is part of the DSP filtering set of designs.
//
// The DSP filtering designs are free RTL designs: you can redistribute them
// and/or modify any of them under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation, either version 3 of
// the License, or (at your option) any later version.
//
// The DSP filtering designs are distributed in the hope that they will be
// useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTIBILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
// General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with these designs.  (It's in the $(ROOT)/doc directory.  Run make
// with no target there if the PDF file isn't present.)  If not, see
// <http://www.gnu.org/licenses/> for a copy.
// }}}
// License:	LGPL, v3, as defined and found on www.gnu.org,
// {{{
//		http://www.gnu.org/licenses/lgpl.html
//
////////////////////////////////////////////////////////////////////////////////
//
//
`default_nettype	none
// }}}
module	cheapspectral #(
		// {{{
		parameter [0:0]	OPT_DBLBUFFER = 1'b0,
		parameter [0:0]	OPT_AUTO_RESTART = OPT_DBLBUFFER,
		parameter [0:0]	OPT_LOWPOWER = 1'b0,
		parameter	LGLAGS = 6,
		parameter	IW = 10,	// Input data Width
		parameter	LGNAVG = 15,
		localparam	AW = LGLAGS+((OPT_DBLBUFFER) ? 1:0),
		localparam	DW = 32	// Bus data width
		// }}}
	) (
		// {{{
		input	wire			i_clk, i_reset,
		// Incoming data
		// {{{
		input	wire			i_data_ce,
		input	wire	[IW-1:0]	i_data,
		// }}}
		// Wishbone interface
		// {{{
		input	wire			i_wb_cyc, i_wb_stb, i_wb_we,
		input	wire	[LGLAGS-1:0]	i_wb_addr,
		input	wire	[DW-1:0]	i_wb_data,
		input	wire	[DW/8-1:0]	i_wb_sel,
		output	wire			o_wb_stall,
		output	reg			o_wb_ack,
		output	reg	[DW-1:0]	o_wb_data,
		// }}}
		output	reg			o_int
`ifdef	VERILATOR
		// Communicate the details of our setup with our Verilator
		// test bench
		// {{{
		, output reg	[0:0]		o_dblbuffer, o_restart,
		output	reg	[4:0]		o_width,
		output	reg	[9:0]		o_lglags, o_lgnavg
		// }}}
`endif
		// }}}
	);

`ifdef	VERILATOR
	// {{{
	always @(*)
	begin
		o_dblbuffer = OPT_DBLBUFFER;
		o_restart   = OPT_AUTO_RESTART;
		o_width     = IW[4:0];
		o_lglags    = LGLAGS;
		o_lgnavg    = LGNAVG;
	end
	// }}}
`endif

	// Local declarations
	// {{{
	reg	[LGLAGS-1:0]	data_write_address;
	reg	[IW-1:0]	data_mem [0:(1<<LGLAGS)-1];

	reg			check_this, running,clear_memory,
				last_read_address;
	wire			start_request;
	reg	[LGLAGS-1:0]	delayed_addr;
	reg	[AW-1:0]	av_read_addr;
	reg	[LGNAVG-1:0]	avcounts;
	reg	[1:0]		run_pipe;

	localparam	PRODUCT_WIDTH = 2*IW, PW = PRODUCT_WIDTH;
	localparam	AVERAGE_BITS  = PW + LGNAVG, AB = AVERAGE_BITS;
	reg	signed	[IW-1:0]	new_data, delayed_data;
	reg	signed	[PW-1:0]	product;
	reg	signed	[AB-1:0]	last_average, new_average;
	reg				first_round;
	wire				update_memory, calculate_average;

	reg	[AW-1:0]		av_tmp_addr;
	reg	[AW-1:0]		av_write_addr;
	reg	signed	[AB-1:0]	avmem	[0:(1<<AW)-1];

	reg				last_write, last_tmp;

	reg	[AB-1:0]	data_out;
	// }}}

	////////////////////////////////////////////////////////////////////////
	//
	// New data logic
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	// On any incoming data, write it into memory
	//
	// This applies even if we aren't going to process that data, since we
	// need the lag/delayed data to be valid for when we wish to process
	// data later

	//
	// The address ... doesn't matter all that much, as long as it
	// increments.  If anything goes wrong, or our data memory gets
	// corrupted, the corruption will get flushed out over time as the
	// algorithm progresses

	initial	data_write_address = 0;
	always @(posedge i_clk)
	if (i_data_ce)
		data_write_address <= data_write_address + 1;

	always @(posedge i_clk)
	if (i_data_ce)
		data_mem[data_write_address] <= i_data;
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Pipeline control logic
	// {{{
	////////////////////////////////////////////////////////////////////////
	//

	// start_request
	// {{{
	generate if (OPT_AUTO_RESTART)
	begin : ALWAYS_RESTART

		assign start_request = 1'b1;

	end else begin : RESTART_ON_REQUEST
		reg	r_start_request;

		initial	r_start_request = 1;
		always @(posedge i_clk)
		if (i_reset)
			r_start_request <= 1'b1;
		else if (i_wb_stb && i_wb_we)
			r_start_request <= 1'b1;
		else if (!running && i_data_ce && check_this)
			r_start_request <= 1'b0;

		assign	start_request = r_start_request;
	end endgenerate
	// }}}

	// check_this
	// {{{
	initial	check_this = 1;
	always @(posedge i_clk)
	if (i_reset)
		check_this <= 1'b1;
	else if (!running)
		check_this <= (check_this || start_request || !(&avcounts));
	else
		check_this <= !(&avcounts);
	// }}}

	// o_int
	// {{{
	initial	o_int = 0;
	always @(posedge i_clk)
	if (i_reset || start_request)
		o_int <= 1'b0;
	else
		o_int <= update_memory && last_write && (&av_write_addr);
	// }}}

	// avcounts
	// {{{
	initial	avcounts = 0;
	always @(posedge i_clk)
	if (i_reset)
		avcounts <= 0;
	else if (!running)
	begin
		if (start_request)
			avcounts <= 0;
		else if (i_data_ce && check_this)
			avcounts <= avcounts + 1;
	end
	// }}}

	// delayed_addr
	// {{{
	always @(posedge i_clk)
	if (running && !last_read_address)
		delayed_addr <= delayed_addr + 1;
	else
		delayed_addr <= data_write_address + 1
			+ ((i_data_ce && check_this) ? 1:0);
	// }}}

	always @(*)
		last_read_address = (running && (&av_read_addr[LGLAGS-1:0]));
			// && av_read_addr[LGLAGS-1:1] && !av_read_addr[0]);

	// av_read_addr
	// {{{
	generate if (OPT_DBLBUFFER)
	begin : DOUBLE_BUFFER_AVADDR
		// {{{
		reg			src_buffer;
		reg	[LGLAGS-1:0]	read_addr;

		initial	src_buffer = 1'b0;
		always @(posedge i_clk)
		if (i_reset)
			src_buffer <= 1'b0;
		else if (running && last_read_address)
			src_buffer <= !src_buffer;

		always @(posedge i_clk)
		if (running)
			read_addr <= read_addr + 1;
		else // if (i_data_ce)
			read_addr <= 0;

		always @(*)
			av_read_addr = { src_buffer, read_addr };
		// }}}
	end else begin : SINGLE_BUFFER_AVADDR
		// {{{
		always @(posedge i_clk)
		if (running)
			av_read_addr <= av_read_addr + 1;
		else // if (i_data_ce)
			av_read_addr <= 0;
		// }}}
	end endgenerate
	// }}}

	// running, clear_memory
	// {{{
	initial	running = 1'b0;
	initial	clear_memory = 1'b1;
	always @(posedge i_clk)
	if (i_reset)
	begin
		running <= 1'b0;
		clear_memory <= 1'b1;
	end else if (running)
	begin
		if (last_read_address)
		begin
			running <= 0;
			// If we were clearing memory, it's now cleared
			// and doesn't need any more clearing
			clear_memory <= 1'b0;
		end
	end else // if (i_data_ce)
	begin
		running <= i_data_ce && check_this;
		if (start_request)
			clear_memory <= 1'b1;
	end
	// }}}

	// run_pipe: Pipeline valid signaling
	// {{{
	initial	run_pipe = 0;
	always @(posedge i_clk)
	if (i_reset)
		run_pipe <= 0;
	else
		run_pipe <= { run_pipe[0], running };
	// }}}

	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Clock 0 -- !running
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	//	This is the same clock as the data logic taking place above
	// Valid this cycle:
	//	delayed_addr, i_data_ce, i_data
	//

	// new_data
	// {{{
	always @(posedge i_clk)
	if (!running && (!OPT_LOWPOWER || (i_data_ce && check_this)))
		new_data <= i_data;
	// }}}

	// delayed_data
	// {{{
	// We'll need at least one clock where !running in order to get the
	// delayed_adddress right
	always @(posedge i_clk)
	if (!OPT_LOWPOWER || running || (i_data_ce && check_this))
		delayed_data <= data_mem[delayed_addr];
	// }}}
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Clock 1 -- running
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	// Valid this cycle:
	//	new_data, delayed_data, clear_memory, av_read_addr
	//

	// product
	// {{{
`ifdef	FORMAL
	// {{{
	(* anyseq *) wire signed [2*IW-1:0]	formal_product;

	always @(posedge i_clk)
	if (!OPT_LOWPOWER || running)
		product <= formal_product;
	// }}}
`else
	always @(posedge i_clk)
	if (!OPT_LOWPOWER || running)
		product <= delayed_data * new_data;
`endif
	// }}}

	// first_round
	// {{{
	initial	first_round = 1'b1;
	always @(posedge i_clk)
		first_round <= clear_memory;
	// }}}

	// last_average
	// {{{
	initial	last_average = 0;
	always @(posedge i_clk)
	if (!OPT_LOWPOWER || running)
		last_average <= avmem[av_read_addr];
	// }}}

	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Clock 2 -- $past(running), run_pipe[0], product is now valid
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	// Valid this cycle:
	//	product, first_round, last_average, av_tmp_addr, last_tmp
	//

	assign	calculate_average = run_pipe[0];


	// new_average
	// {{{
	always @(posedge i_clk)
	if (!OPT_LOWPOWER || calculate_average)
	begin
		if (first_round)
			new_average <= { {(LGNAVG){product[2*IW-1]}}, product };
		else
			new_average <= last_average
				+ { {(LGNAVG){product[2*IW-1]}}, product };
	end else
		new_average <= 0;
	// }}}

	// av_write_addr, av_tmp_addr
	// {{{
	initial { av_write_addr, av_tmp_addr } = 0;
	always @(posedge i_clk)
		{ av_write_addr, av_tmp_addr } <= { av_tmp_addr, av_read_addr};
	// }}}

	// last_write, last_tmp
	// {{{
	initial { last_write, last_tmp } = 0;
	always @(posedge i_clk)
	if (i_reset || (i_wb_we && i_wb_stb))
		{ last_write, last_tmp } <= 0;
	else
		{ last_write, last_tmp } <= { last_tmp, (&avcounts) };
	// }}}
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Clock 3 -- run_pipe[1], new_average is now valid
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	// Valid this cycle:
	//	new_average, update_memory, av_write_addr, last_write
	//
	assign	update_memory = run_pipe[1];

	always @(posedge i_clk)
	if (update_memory)
		avmem[av_write_addr] <= new_average;
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Handling the bus interaction
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	assign	o_wb_stall = 1'b0;

	// o_wb_ack
	// {{{
	initial	o_wb_ack = 1'b0;
	always @(posedge i_clk)
		o_wb_ack <= !i_reset && i_wb_stb;
	// }}}

	// data_out
	// {{{
	generate if (OPT_DBLBUFFER)
	begin : GEN_BUFFERED_OUT

		always @(posedge i_clk)
			data_out <= avmem[{!av_write_addr[AW-1], i_wb_addr }];

	end else begin : GEN_OUT

		always @(posedge i_clk)
			data_out <= avmem[i_wb_addr];

	end endgenerate
	// }}}

	// o_wb_data
	// {{{
	generate if (AB == DW)
	begin : PERFECT_BITWIDTH

		always @(*)
			o_wb_data = data_out;

	end else if (AB < DW)
	begin : NOT_ENOUGH_BITS

		always @(*)
			o_wb_data = { {(DW-AB){data_out[AB-1]}}, data_out };

	end else begin : TOO_MANY_BITS

		always @(*)
			o_wb_data = data_out[AB-1:AB-DW];

		wire	unused;
		assign	unused = &{ data_out[AB-DW-1:0] };
	end endgenerate
	// }}}
	// }}}

	// Keep Verilator happy
	// {{{
	// Verilator lint_off UNUSED
	wire	unused;
	assign	unused = &{ 1'b0, i_wb_cyc, i_wb_data, i_wb_sel };
	// Verilator lint_on  UNUSED
	// }}}
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
// Formal property section
// {{{
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
`ifdef	FORMAL
	reg	f_past_valid;
	reg	[LGLAGS:0]	f_phase;
	reg	[LGLAGS-1:0]	f_new_data_addr, f_delayed_addr,
				f_worst_write_diff, f_write_diff;
	(* anyconst *) reg	[AW-1:0]	f_const_addr;
	reg	signed	[AB-1:0]	f_avdata;

	initial	f_past_valid = 0;
	always @(posedge i_clk)
		f_past_valid <= 1;

	////////////////////////////////////////////////////////////////////////
	//
	// Bus properties
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//
	localparam	F_LGDEPTH = 2;
	wire	[F_LGDEPTH-1:0]	f_nreqs, f_nacks, f_outstanding;

	fwb_slave #(
		.AW(AW), .DW(DW), .F_MAX_STALL(1), .F_MAX_ACK_DELAY(1),
		.F_LGDEPTH(F_LGDEPTH)
	) fwb (i_clk, i_reset,
		i_wb_cyc, i_wb_stb, i_wb_we, i_wb_addr, i_wb_data, i_wb_sel,
			o_wb_ack, o_wb_stall, o_wb_data, 1'b0,
		f_nreqs, f_nacks, f_outstanding);

	always @(*)
	if (i_wb_cyc)
		assert(f_outstanding == (o_wb_ack ? 1:0));
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Assumptions
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	// Let's just assume some things regarding the multiplication product,
	// since formal can't handle multiplies very well
	always @(*)
	if ((new_data == 0) || (delayed_data == 0))
		assume(formal_product == 0);
	always @(*)
	if (new_data == 1)
		assume(formal_product == delayed_data);
	always @(*)
	if (delayed_data == 1)
		assume(formal_product == new_data);
	always @(*)
	if (&new_data)
		assume(formal_product == -delayed_data);
	always @(*)
	if (&delayed_data)
		assume(formal_product == -new_data);

	always @(*)
		assume(formal_product[2*IW-1]
				== (new_data[IW-1] ^ delayed_data[IW-1]));

	always @(*)
	if (!formal_product[2*IW-1])
		assume(formal_product <= (1<<(2*IW-2)));
	else
		assume(formal_product >= -(1<<(2*IW-2))+1);


	always @(*)
	if (!f_past_valid)
		assume(f_avdata == 0);

	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	//
	//
	////////////////////////////////////////////////////////////////////////
	//
	//
	reg	[LGNAVG-1:0]	f_avcounts_one, f_avcounts_two;
	reg			f_first_write;

	//
	// We'll start with some basic assertions--just to guarantee that we
	// are running through our states properly.
	//
	always @(posedge i_clk)
	begin
		f_avcounts_one <= avcounts;
		f_avcounts_two <= f_avcounts_one;
		f_first_write <= first_round;
	end

	always @(posedge i_clk)
	if (!running && i_data_ce && check_this)
		f_new_data_addr <= data_write_address;

	always @(*)
		f_delayed_addr = delayed_addr - f_new_data_addr -2;

	always @(*)
	begin
		f_worst_write_diff = delayed_addr - data_write_address;
		f_write_diff = data_write_address - f_new_data_addr;
	end

	always @(*)
	if (running)
		assert(f_write_diff <= f_phase);

	always @(*)
	if (running)
		assert(f_delayed_addr == av_read_addr[LGLAGS-1:0]);

	always @(*)
	if (running && f_phase != (1<<LGLAGS))
		assert(data_write_address != f_new_data_addr);

	always @(*)
	if (running)
		assert(data_mem[f_new_data_addr] == new_data);

	always @(*)
	if (running && f_phase == (1<<LGLAGS))
		assert(delayed_data == new_data);

	initial	f_phase = 0;
	always @(posedge i_clk)
	if (i_reset)
		f_phase <= 0;
	else if (!running && i_data_ce && check_this)
		f_phase <= 1;
	else if (running && !last_read_address)
		f_phase <= f_phase + 1;
	else
		f_phase <= 0;

	always @(*)
		assert(f_phase <= (1<<LGLAGS));
	always @(*)
		assert(running == (f_phase != 0));

	always @(*)
	if (running)
		assert(f_phase-1 == { 1'b0, av_read_addr[LGLAGS-1:0] });

	always @(*)
		f_avdata = avmem[f_const_addr];

	//
	// Prove that we won't overflow in a positive direction
	// (The guarantee of not overflowing in a negative direction is assumed)
	always @(*)
	if (run_pipe[0] && (&av_tmp_addr[LGLAGS-1:0]))
		assert(!product[2*IW-1]);

	always @(*)
	if (!OPT_DBLBUFFER && update_memory
			&& (&f_const_addr) && (&av_write_addr[LGLAGS-1:0]))
		assert(!new_average[AB-1]);

	always @(*)
	if (&f_const_addr)
		assert(!f_avdata[AB-1]);

	//
	// Here's the key assertion: The maximum we can add to our counter on
	// any given pass is 2^(IW-2).  Here we prove that our average *must*
	// be less than 2^(IW-2) * (number_of_passes so far).  Everything else
	// is really just icing on the cake.
	//
	reg	[2:0]	f_check;
	always @(*)
	if (OPT_DBLBUFFER && av_write_addr[AW-1] != f_const_addr[AW-1])
	begin
		// Wrong buffer ...
		// assert(f_avdata[AB-1]|| (f_avdata <=((1<<LGNAVG) << (2*IW-2))));
		f_check = 3'h0;
	end else if (!clear_memory && !first_round && !f_first_write && !run_pipe[1])
	begin
		// We haven't yet been written to
		assert(f_avdata[AB-1] || (f_avdata <= ((avcounts+1) << (2*IW-2))));
		f_check = 3'h1;
	end else if (run_pipe[1]) // && first_round
	begin
		f_check = 3'h4;
		if (f_const_addr[LGLAGS-1:0] < av_write_addr[LGLAGS-1:0])
		begin
			// After writing to this address
			assert(f_avdata[AB-1] || (f_avdata <= (f_avcounts_two+1)<<(2*IW-2)));
			f_check = 3'h2;
		end else if (!f_first_write && !first_round)
		begin
			// Before writing to this address
			assert(f_avdata[AB-1] || (f_avdata <= (f_avcounts_two << (2*IW-2))));
			f_check = 3'h3;
		end
	end else
		f_check = 3'h5;

	always @(*)
	if (clear_memory && !running)
	begin
		assert(avcounts == 0);
		assert(start_request);
	end

	always @(*)
	if (first_round || clear_memory)
		assert(avcounts == 0);
	else if (running)
		assert(avcounts > 0);

	always @(*)
	if (&avcounts && check_this && !running)
		assert(start_request);


	////////////////////////////////////////////////////////////////////////
	//
	// Cover checks
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//
	always @(posedge i_clk)
		cover(!running && i_data_ce && check_this);

	always @(posedge i_clk)
	if (f_past_valid && !$past(i_reset))
		cover($fell(running));

	// Let's verify that a whole round does as we might expect
	always @(*)
		cover(&avcounts);

	always @(*)
		cover(o_int);
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Careless/constraining assumptions
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//
	always @(*)
	if (f_avdata[AB-1])
		assume(&f_avdata[AB-1:AB-2]);
	// }}}
`endif
// }}}
endmodule
