////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	histogram.v
//
// Project:	DSP Filtering Example Project
//
// Purpose:	Generate a bus readable histogram from the data given to us
//
//	So, here's how this works: We keep track of two memory areas, ping
//	and pong.  On a reset, ...
//
//	1. On a reset, we clear the current memory area.
//		- A reset can be triggered externally by writing to the memory
//			in question.
//	2. Once cleared, we count the number of times each sample has been
//		received.
//	3. Once NAVGS samples have been counted into the histogram, we ...
//		A. Trigger an interrupt
//		B. Swap memory areas, making the first area available to be
//			read over the WB bus
//		C. Start clearing the new memory as part of (2) above and
//	4. Repeat from (2) above
//
//	As currently built, the number of averages is not configurable.
//	Neither is there a way to clear both buffers--only the current buffer.
//
// Usage:	A core might use this histogram by waiting for the interrupt,
//		and then copying the histogram from the memory.  If you want
//	to sync to the core, then write (any value) to the core and wait for
//	the interrupt--at which point you can read the values from the core.
//
// Performance:	This core is designed around a block-RAM implementation, and
//		a block histogram count.  This means that the histogram is not
//	valid until the full NAVGS count of values have been received.  Even
//	better, the core can handle a data rate up to and including the system
//	clock rate.
//
// Resource usage: For 12-bit samples, and averaging 64kB samples, this
//		core will use (Xilinx baseline):
//
//	100	Flip-Flops
//	228	LUTs maximum (Yosys estimate: 191 with packing)
//	  8	RAMB36E1's	(i.e. 4k RAM words, each of 17 bits)
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2017-2019, Gisselquist Technology, LLC
//
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
//
// License:	LGPL, v3, as defined and found on www.gnu.org,
//		http://www.gnu.org/licenses/lgpl.html
//
////////////////////////////////////////////////////////////////////////////////
//
//
module	histogram #(
	parameter	NAVGS = 65536,
	localparam	ACCW = $clog2(NAVGS+1),
	localparam	DW = 32,
	parameter	AW = 12,
	localparam	MEMSZ = (1<<(AW+1))
	) (
	input	wire	i_clk,
	input	wire	i_reset,
	//
	input	wire	i_wb_cyc, i_wb_stb, i_wb_we,
	input	wire [AW-1:0]	i_wb_addr,
	input	wire [DW-1:0]	i_wb_data,
	input	wire [DW/8-1:0]	i_wb_sel,
	output	reg		o_wb_stall,
	output	reg		o_wb_ack,
	output	reg [DW-1:0]	o_wb_data,
	//
	input	wire		i_ce,
	input	wire [AW-1:0]	i_sample,
	//
	output	reg		o_int
	);

	reg	[ACCW-1:0]		count;
	reg	[ACCW-1:0]		mem	[0:MEMSZ-1];
	reg				start_reset, resetpipe, activemem,
					wb_restart, last_resetpipe,
					bypass_resetpipe;
	reg	[2:0]			cepipe;
	reg	[ACCW-1:0]		memavg, memnew, bypass_data;
	reg	[AW-1:0]		r_sample, memaddr, bypass_addr;

	//
	// Zero out our memory initially
	integer	ik;
	initial	begin
		for(ik=0; ik<MEMSZ; ik=ik+1)
			mem[ik] = 0;
	end

	//
	// Count how many samples we've used in our block average
	//
	initial	count = 0;
	always @(posedge i_clk)
	if (i_reset || start_reset)
	begin
		count <= 0;
	end else if (i_ce)
	begin
		if (count == NAVGS[ACCW-1:0])
			count <= 0;
		else if (!start_reset && !resetpipe)
			count <= count + 1;
	end

	//
	// Control when we start our reset cycle.  There are three possible
	// causes: 1) Based upon an external reset, i_reset, 2) Based upon
	// writing the last sample in our average set, and 3) User commanded.
	//
	// On the second cause only we switch memories.
	//
	initial	start_reset = 1;
	initial	wb_restart = 1;
	always @(posedge i_clk)
	begin
		start_reset <= 0;
		wb_restart    <= 0;

		if (i_reset)
		begin
			start_reset <= 1;
			wb_restart  <= 1;
		end else if (i_ce && !start_reset && !resetpipe)
		begin
			if (count == NAVGS[ACCW-1:0])
				start_reset <= 1;
		end

		if (i_wb_stb && i_wb_we)
		begin
			start_reset <= 1;
			wb_restart  <= 1;
		end
	end

	initial	resetpipe = 0;
	always @(posedge i_clk)
	begin
		if (i_reset || start_reset)
			resetpipe <= 1;
		else if (&memaddr)
			resetpipe <= 0;
	end

	initial	{ bypass_resetpipe, last_resetpipe } = 0;
	always @(posedge i_clk)
		{ bypass_resetpipe, last_resetpipe }
			<= { last_resetpipe, resetpipe };

	initial	activemem = 0;
	initial	o_int = 0;
	always @(posedge i_clk)
	begin
		o_int <= 0;
		if (i_reset)
			activemem <= 0;
		else if (start_reset && !wb_restart)
		begin
			activemem <= !activemem;
			o_int <= 1;
		end
	end

	initial	cepipe = 0;
	always @(posedge i_clk)
	if (i_reset || start_reset || resetpipe)
		cepipe <= 3'b010;
	else
		cepipe <= { cepipe[1:0], (!resetpipe && i_ce) };

	always @(posedge i_clk)
	if (i_ce)
	begin
		memavg <= mem[{ activemem, i_sample }];
		r_sample <= i_sample;
	end

	always @(posedge i_clk)
	if (i_reset || start_reset)
	begin
		memnew  <= 0;
		memaddr <= 0;
	end else if (resetpipe)
	begin
		memnew  <= 0;
		memaddr <= memaddr + 1;
	end else if (cepipe[0])
	begin
		memaddr <= r_sample;
		if (cepipe[1] && r_sample == memaddr && !last_resetpipe)
			memnew  <= memnew + 1;
		else if (cepipe[2] && r_sample == bypass_addr && !bypass_resetpipe)
			memnew  <= bypass_data + 1;
		else
			memnew  <= memavg + 1;
	end

	//
	// Write to memory
	//
	always @(posedge i_clk)
	if (cepipe[1])
		mem[{ activemem, memaddr }] <= memnew;

	always @(posedge i_clk)
	if (cepipe[1])
	begin
		bypass_data <= memnew;
		bypass_addr <= memaddr; 
	end

	//
	// Handle the bus
	//
	always @(posedge i_clk)
	begin
		o_wb_data <= 0;
		o_wb_data[ACCW-1:0] <= mem[{ !activemem, i_wb_addr }];
	end

	always @(posedge i_clk)
		o_wb_ack <= !i_reset && i_wb_stb;

	always @(*)
		o_wb_stall = 1'b0;

	//
	// Keep Verilator happy
	//
	// Verilator lint_off UNUSED
	wire	unused;
	assign	unused = &{ 1'b0, i_wb_data, i_wb_cyc, i_wb_sel };
	// Verilator lint_on UNUSED

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
// Formal properties used to verify the histogram
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
`ifdef	FORMAL
	(* anyconst *)	reg [AW:0]	f_addr;
			reg [ACCW-1:0]	f_data;
	reg	[2:0]	f_this_pipe;

	reg	f_past_valid;
	initial	f_past_valid = 0;
	always @(posedge i_clk)
		f_past_valid <= 1;

	////////////////////////////////////////////////////////////////////////
	//
	// External assumptions
	//
	////////////////////////////////////////////////////////////////////////
	//
	always @(*)
	if (!f_past_valid)
		assume(i_reset);

	always @(*)
	if (!i_wb_cyc)
		assume(!i_wb_stb);

	////////////////////////////////////////////////////////////////////////
	//
	// The counter is not allowed to overflow
	//
	always @(*)
		assert(count <= NAVGS);

	////////////////////////////////////////////////////////////////////////
	//
	// Contract proofs
	//
	// Pick a particular value to average and consider.  Now we'll prove
	// that this special data, f_data, will always be less then NAVGS,
	// and in particular always less than the counter's value of how
	// many items we've averaged so far in a run.
	//
	////////////////////////////////////////////////////////////////////////
	//
	//

	//
	// Update our copy of memory on every memory write
	//
	initial	f_data = 0;
	always @(posedge i_clk)
	if (cepipe[1] && { activemem, memaddr } == f_addr)
		f_data <= memnew;

	//
	// For tracking bypass issues, keep track of when our special
	// value is written to
	//
	initial	f_this_pipe = 3'b000;
	always @(posedge i_clk)
	if (i_reset || start_reset || resetpipe)
		f_this_pipe <= 3'b000;
	else
		f_this_pipe <= { f_this_pipe[1:0], (!resetpipe && i_ce
				&& activemem == f_addr[AW]
				&& i_sample == f_addr[AW-1:0]) };

	//
	// Induction check: Make certain that if f_this_pipe is ever true, then
	// cepipe is also true for that same bit.
	//
	always @(*)
		assert((f_this_pipe & cepipe) == f_this_pipe);

	always @(*)
	if (!last_resetpipe && f_this_pipe[0])
		assert(activemem == f_addr[AW] && r_sample == f_addr[AW-1:0]);

	always @(posedge i_clk)
	if (cepipe[1] && { activemem, memaddr } == f_addr)
		f_data <= memnew;

	always @(*)
	begin
		assert(mem[f_addr] == f_data);
		assert(f_data <= NAVGS);
		if (!start_reset && !resetpipe)
		begin
			if (activemem == f_addr[AW])
				assert(f_data <= count);
		end
		if (!start_reset && f_this_pipe[2])
			assert(bypass_data <= count + f_this_pipe[1] + f_this_pipe[0]);
	end

	always @(posedge i_clk)
		if (!start_reset && !resetpipe
			&&(activemem == f_addr[AW])
			&&(f_addr[AW-1:0] == memaddr))
			assert(memnew <= $past(count));

	////////////////////////////////////////////////////////////////////////
	//
	// Reset sequence checks
	//
	always @(*)
	if (resetpipe && activemem == f_addr[AW] && count > f_addr[AW-1:0])
		assert(f_data == 0);

	always @(*)
	if (resetpipe)
		assert(count == 0);


`ifdef	VERIFIC
	assert property (@(posedge i_clk)
		disable iff (i_reset || start_reset || resetpipe)
		i_ce && (i_sample == { activemem, f_addr})
		|=> ##2 f_data == $past(f_data + 1));

	assert property (@(posedge i_clk)
		$fell(resetpipe) && activemem == f_addr[AW]
		|=> f_data == 0);

	assert property (@(posedge i_clk)
		i_wb_stb && !i_reset |=> o_wb_ack);

`endif
	////////////////////////////////////////////////////////////////////////
	//
	// Cover checks
	//
	////////////////////////////////////////////////////////////////////////
	//
	//

	//
	// Cover being able to reach 16 -- a good round test number
	generate if (NAVGS >= 16 && NAVGS <= 32)
	begin

		always @(*)
			cover(f_data == 16);
	end endgenerate

	generate if (NAVGS <= 16)
	begin
		always @(*)
			cover(start_reset && !wb_restart && f_data == 0);

		always @(*)
			cover(f_data == NAVGS);

`ifdef	VERIFIC
		cover property (@(posedge i_clk)
			i_wb_stb && (i_wb_addr == f_addr[AW-1:0]) && activemem
				&& f_addr[AW] == !activemem
			##1 o_wb_ack && o_wb_data[ACCW-1:0] == f_data
				&& f_data == 0);

		cover property (@(posedge i_clk)
			i_wb_stb && (i_wb_addr == f_addr[AW-1:0]) && activemem
				&& f_addr[AW] == !activemem
			##1 o_wb_ack && o_wb_data[ACCW-1:0] == f_data
				&& f_data == NAVGS);
`endif
	end endgenerate
`endif
endmodule
