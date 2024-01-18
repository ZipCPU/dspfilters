////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	ratfil.v
// {{{
// Project:	DSP Filtering Example Project
//
// Purpose:	A basic rational downsampling filter, with an AXI stream
//		interface.  Due to its construction, this can *only* be a
//	downsampling resampler.  Hence, the amount to upsample by (prior
//	to downsampling) must be less than the downsample factor.
//
// Implementation notes:
//	Unfortunately, the verification of the *LAST* output based upon
//	*LAST* inputs got rather complex.  Judging from the various traces
//	I've examined, this *should* work--I'm just not confident in the
//	verification of this routine (yet).  Adding to the problem are the
//	amount of differences in how this filter behaves for various upsample
//	and downsample factors.  I've been checking a small number of these,
//	potentially leaving many missing parts and pieces.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
// }}}
// Copyright (C) 2021-2024, Gisselquist Technology, LLC
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
`default_nettype none
// }}}
module ratfil #(
		// {{{
		parameter		IW = 12, // Input bit width
		parameter		TW = 12, // Coefficient width
		parameter		OW = 12, // Output bit width
		parameter		NS = 2, // Num parallel input streams
		parameter		NUP = 2, // Must be >= 1
		parameter		NDOWN = 5, // Must be > NUP
		parameter		LGGAIN = 0, // Bit shift at output
		parameter		NCOEFFS = 19, // Will be 96
		localparam		LGNCOEFFS = $clog2(NCOEFFS),
		parameter	[0:0]	OPT_SKIDBUFFER = 1'b0,
		parameter	[0:0]	OPT_FIXED_TAPS = 1'b0,
		parameter		INITIAL_COEFFS = ""
		// }}}
	) (
		// {{{
`ifdef	VERILATORTB
		input	wire			i_clk,
		input	wire			i_reset,
		output	wire	[31:0]		o_IW,
		output	wire	[31:0]		o_TW,
		output	wire	[31:0]		o_OW,
		output	wire	[31:0]		o_NCOEFFS,
		output	wire	[31:0]		o_NUP,
		output	wire	[31:0]		o_NDOWN,
		output	wire	[31:0]		o_LGGAIN,
`else
		input	wire			S_AXI_ACLK,
		input	wire			S_AXI_ARESETN,
`endif
		// Filter adjustment
		// {{{
		input	wire			i_tap_wr,
		input	wire	[TW-1:0]	i_tap,
		// }}}
		// Incoming data stream, at the faster clock rate
		// {{{
		input	wire			S_AXI_TVALID,
		output	wire			S_AXI_TREADY,
		input	wire	[IW-1:0]	S_AXI_TDATA,
		input	wire			S_AXI_TLAST,
		// }}}
		// Outgoing data stream, at the slower/lower clock rate
		// {{{
		output	reg			M_AXI_TVALID,
		input	wire			M_AXI_TREADY,
		output	reg	[IW-1:0]	M_AXI_TDATA,
		output	reg			M_AXI_TLAST
		// }}}
		// }}}
	);

	// Local declarations
	// {{{
	localparam	MINMEMSZ = NS * (NCOEFFS + NUP - 1) / NUP;
	localparam	LGMEM = $clog2(MINMEMSZ);
	localparam	AW = IW + TW + LGNCOEFFS;	// Accumulator width
	localparam	PW = IW + TW;			// Product width
	localparam	CBITS = $clog2(NCOEFFS+2*NUP)+1;
	localparam	SKIPW = $clog2(NDOWN / NUP + 1);

	wire			skd_valid, skd_ready, skd_last;
	wire	[IW-1:0]	skd_data;

	reg	[IW-1:0]		dmem	[0:(1<<LGMEM)-1];
	reg	[TW-1:0]		cmem	[0:(1<<LGNCOEFFS)-1];

	reg	[CBITS-1:0]		coefficient_index, starting_coefficient_index, next_firstc;
	reg	[LGMEM-1:0]		data_index, data_write_address;
	reg	[SKIPW-1:0]		next_skip, skip_count;
	reg				skip_run, next_skip_run;

	reg	signed	[IW-1:0]	dval;
	reg	signed	[TW-1:0]	cval;

	// If read_enable,	data_index, coefficient_index, idx_load, idx_last are valid
	//				f_idxstream + 1 = f_istream
	// If p_enable,		dmem, cmem, mem_load, mem_last are valid
	// If acc_enable,	product, product_load, product_last are valid
	// If output_load,	acc, acc_last are valid
	// 
	reg	signed	[PW-1:0]	product;
	reg	signed	[AW-1:0]	wide_product;
	reg	signed	[AW-1:0]	acc;
	reg	signed	[AW-1:0]	rounded_acc;
	reg				read_enable, p_enable;
	reg				idx_load, mem_load,
					product_load, output_load;
	reg				acc_enable;
	reg				idx_last, mem_last,
					product_last, acc_last;

	wire	mem_stalled, product_stalled, acc_stalled;

`ifdef	VERILATORTB
	wire	S_AXI_ACLK, S_AXI_ARESETN;

	assign	S_AXI_ACLK = i_clk;
	assign	S_AXI_ARESETN = !i_reset;

	assign	o_IW      = IW;
	assign	o_TW      = TW;
	assign	o_OW      = OW;
	assign	o_NCOEFFS = NCOEFFS;
	assign	o_NUP     = NUP;
	assign	o_NDOWN   = NDOWN;
	assign	o_LGGAIN  = LGGAIN;
`endif
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Filter coefficient loading and/or adjustment
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	generate if (OPT_FIXED_TAPS || (INITIAL_COEFFS != 0 && INITIAL_COEFFS != ""))
	begin : LOAD_INITIAL_COEFFS

		initial $readmemh(INITIAL_COEFFS, cmem);
	end endgenerate

	generate if (OPT_FIXED_TAPS)
	begin : UNUSED_LOADING_PORTS
		// {{{
		// Verilator lint_off UNUSED
		wire	ignored_inputs;
		assign	ignored_inputs = &{ 1'b0, i_tap_wr, i_tap };
		// Verilator lint_on  UNUSED
		// }}}
	end else begin : LOAD_COEFFICIENTS
		// {{{
		reg	[LGNCOEFFS-1:0]	wr_coeff_index;

		initial	wr_coeff_index = 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
			wr_coeff_index <= 0;
		else if (i_tap_wr)
			wr_coeff_index <= wr_coeff_index + 1;

		always @(posedge S_AXI_ACLK)
		if (i_tap_wr)
			cmem[wr_coeff_index] <= i_tap;
		// }}}
	end endgenerate
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Skid buffer
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	generate if (OPT_SKIDBUFFER)
	begin : SKIDBUFFER

		wire	w_last;

		skidbuffer #(
			.DW(IW + 1)
		) skd (
			// {{{
			.i_clk(S_AXI_ACLK), .i_reset(!S_AXI_ARESETN),
			.i_valid(S_AXI_TVALID), .o_ready(S_AXI_TREADY),
				.i_data({ S_AXI_TDATA, S_AXI_TLAST }),
			.o_valid(skd_valid), .i_ready(skd_ready),
				.o_data({ skd_data, w_last })
			// }}}
		);

		assign	skd_last = (NS <= 1) ? 1'b1 : w_last;
	end else begin : NO_SKIDBUFFER
		// {{{
		assign	skd_valid = S_AXI_TVALID;
		assign	S_AXI_TREADY = skd_ready;
		assign	skd_data  = S_AXI_TDATA;
		assign	skd_last  = (NS <= 1) ? 1'b1 : S_AXI_TLAST;
		// }}}
	end endgenerate

	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Write data to memory logic
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	initial	data_write_address = 0;
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		data_write_address <= 0;
	else if (skd_valid && skd_ready)
		data_write_address <= data_write_address + 1;

	always @(posedge S_AXI_ACLK)
	if (skd_valid && skd_ready)
		dmem[data_write_address] <= skd_data;

	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Pointer logic
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	// top_stream
	/*
	// {{{
	wire	top_stream;
	generate if (NS > 1)
	begin
		reg	r_top_stream;

		always @(posedge S_AXI_ACLK)
		if (skd_valid && skd_ready)
			r_top_stream <= skd_last;

		assign	top_stream = r_top_stream;
	end else begin
		assign	top_stream = 1;
	end endgenerate
	// }}}
	*/

	// starting_coefficient_index, skip_run
	// {{{
	always @(*)
	begin
		next_skip_run = (NDOWN >= 2*NUP);
		next_firstc = starting_coefficient_index + (NDOWN % NUP);
		// Verilator lint_off WIDTH
		next_skip = (NDOWN / NUP)-1;
		// Verilator lint_on  WIDTH
		if (next_firstc >= NUP)
		begin
			next_skip_run = 1;
			next_firstc = next_firstc - NUP;
			next_skip   = next_skip + 1;
		end
	end

	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
	begin
		starting_coefficient_index <= 0;
		skip_run    <= 0;
		skip_count  <= 0;
	end else if (skd_valid && skd_ready && skd_last)
	begin
		if (skip_run)
		begin
			skip_count <=  skip_count - 1;
			// Verilator lint_off CMPCONST
			skip_run   <= (skip_count > 1);
			// Verilator lint_on  CMPCONST
		end else begin
			// Here is where we require NDOWN > NUP, else the
			// following math will fail.
			starting_coefficient_index <= next_firstc;
			skip_run    <= next_skip_run;
			skip_count  <= next_skip;
		end
	end
`ifdef	FORMAL
	// wire	f_fcoef_plus_ndown;
	always @(*)
	if (S_AXI_ARESETN)
	begin
		assert(starting_coefficient_index < NUP);
		assert(skip_run == (skip_count != 0));
		assert(skip_count <= (NDOWN/NUP));
	end
`endif
	// }}}

	// coefficient_index, read_enable
	// {{{
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
	begin
		coefficient_index <= 0;
		read_enable <= 0;
	end else if (skd_ready && !skip_run)
	begin
		coefficient_index <= starting_coefficient_index;
		read_enable <= skd_valid;
	end else if (!mem_stalled)
	begin
		if (coefficient_index < NCOEFFS)
		begin
			coefficient_index <= coefficient_index + NUP;
			read_enable <= (coefficient_index + NUP < NCOEFFS);
		end else
			read_enable <= 0;
	end
`ifdef	FORMAL
	always @(*)
	if (S_AXI_ARESETN)
	begin
		assert(coefficient_index < NCOEFFS + NUP);
		// assert(read_enable == (coefficient_index < NCOEFFS));
		if (read_enable)
			assert(coefficient_index < NCOEFFS);
		if (coefficient_index >= NUP && coefficient_index < NCOEFFS)
			assert(read_enable);
		else if (coefficient_index >= NCOEFFS)
			assert(!read_enable);

		if (read_enable && coefficient_index >= NUP * 2)
			assert(p_enable);
		if (read_enable && coefficient_index >= NUP * 3)
			assert(acc_enable);
	end
`endif
	// }}}

	// data_index
	// {{{
	always @(posedge S_AXI_ACLK)
	if (skd_ready && !skip_run)
		data_index <= data_write_address;
	else if (read_enable && !mem_stalled)
		data_index <= data_index - NS;
	// }}}

	// idx_load
	// {{{
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		idx_load <= 1'b0;
	else if (!mem_stalled)
		idx_load <= read_enable && (coefficient_index >= NCOEFFS-2*NUP)
				&& (coefficient_index < NCOEFFS - NUP);
`ifdef	FORMAL
	always @(*)
	if (S_AXI_ARESETN)
		assert(idx_load == ((coefficient_index >= NCOEFFS - NUP)
					&&(coefficient_index < NCOEFFS)));
`endif
	// }}}

	// idx_last
	// {{{
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		idx_last <= 1'b0;
	else if (skd_ready && !skip_run)
		idx_last <= skd_valid && skd_last;
	else if (idx_load && idx_last)
		idx_last <= 1'b0;
	// }}}

	assign	skd_ready = skip_run || !read_enable
			|| (idx_load && !mem_stalled);
`ifdef	FORMAL
	// Stream properties
	// {{{
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN || $past(!S_AXI_ARESETN))
	begin
		if (S_AXI_ARESETN)
		begin
			assert(!read_enable);
			assert(!idx_load);
			assert(!idx_last);
		end
	end else if ($past(read_enable && mem_stalled))
	begin
		assert($stable(coefficient_index));
		assert($stable(data_index));
		assert($stable(read_enable));
		assert($stable(idx_load));
		assert($stable(idx_last));
	end
	// }}}
`endif
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Memory read index logic
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	assign	mem_stalled = read_enable && product_stalled;

	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		mem_load <= 0;
	else if (!mem_stalled)
		mem_load <= idx_load && read_enable;

	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		mem_last <= 0;
	else if (!mem_stalled)
		mem_last <= idx_last && read_enable;

	always @(posedge S_AXI_ACLK)
	if (read_enable && !mem_stalled)
	begin
		dval <= dmem[data_index];
		cval <= cmem[coefficient_index[LGNCOEFFS-1:0]];
	end

`ifdef	FORMAL
	// Stream properties
	// {{{
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN || $past(!S_AXI_ARESETN))
	begin
		if (S_AXI_ARESETN)
		begin
			assert(!mem_load);
			assert(!mem_last);
			assert(!read_enable);
		end
	end else if ($past(p_enable && product_stalled))
	begin
		assert($stable(mem_load));
		assert($stable(mem_last));
		assert($stable(dval));
		assert($stable(cval));
	end
	// If output_load,	acc, acc_last are valid
	// }}}
`endif
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Product stage
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	assign	product_stalled = p_enable && acc_stalled;

	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		product_load <= 0;
	else if (!product_stalled)
		product_load <= mem_load;

	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		product_last <= 0;
	else if (!product_stalled)
		product_last <= mem_last;

	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		p_enable <= 0;
	else if (!product_stalled)
		p_enable <= read_enable;

`ifdef	FORMAL
	(* anyseq *) wire [IW + TW - 1:0]	informal_product;
	always @(*)
	begin
		if (dval == 0)
			assume(informal_product == 0);
		if (cval == 0)
			assume(informal_product == 0);
		assume(informal_product[IW+TW-1] == (dval[IW-1] ^ cval[TW-1]));
	end

	always @(posedge S_AXI_ACLK)
	if (S_AXI_ARESETN && p_enable && !product_stalled)
		product <= informal_product;

	// Stream properties
	// {{{
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN || $past(!S_AXI_ARESETN))
	begin
		if (S_AXI_ARESETN)
		begin
			assert(!product_load);
			assert(!product_last);
			assert(!p_enable);
		end
	end else if ($past(acc_enable && acc_stalled))
	begin
		assert($stable(product_load));
		assert($stable(product_last));
		assert($stable(product));
	end
	// If acc_enable,	product, product_load, product_last are valid
	// If output_load,	acc, acc_last are valid
	// }}}
`else
	always @(posedge S_AXI_ACLK)
	if (S_AXI_ARESETN && p_enable && !product_stalled)
		product <= dval * cval;
`endif

	assign	wide_product = { {(AW-PW){product[PW-1]}}, product };
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Accumulation stage
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	assign	acc_stalled = output_load && M_AXI_TVALID && !M_AXI_TREADY;

	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		output_load <= 0;
	else if (!acc_stalled)
		output_load <= product_load;

	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		acc_last <= 0;
	else if (!acc_stalled)
		acc_last <= product_last;


	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		acc_enable <= 0;
	else if (!acc_stalled)
		acc_enable <= p_enable;

	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		acc <= 0;
	else if (!acc_stalled)
	begin
		if (output_load && acc_enable)
			acc <= wide_product;
		else if (output_load)
			acc <= 0;
		else if (acc_enable)
			acc <= acc + wide_product;
	end

`ifdef	FORMAL
	// Stream properties
	// {{{
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN || $past(!S_AXI_ARESETN))
	begin
		if (S_AXI_ARESETN)
		begin
			assert(!output_load);
			assert(!acc_last);
		end
	end else if ($past(output_load && M_AXI_TVALID && !M_AXI_TREADY))
	begin
		assert($stable(output_load));
		assert($stable(acc_last));
		assert($stable(acc));
	end
	// If output_load,	acc, acc_last are valid
	// }}}
`endif
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Output stage
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	// rounded_acc
	// {{{
	generate if (OW == AW-LGGAIN)
	begin : GEN_TRUNCATE
		assign	rounded_acc = acc[AW-LGGAIN-1:AW-LGGAIN-OW];
	end else // if (AW-LGGAIN > OW)
	begin : SHIFT_OUTPUT

		wire	[AW-1:0]	shifted;

		assign	shifted = { acc[AW-LGGAIN-1:0], {(LGGAIN){1'b0}} };
		assign	rounded_acc = shifted
				+ { {(OW){1'b0}}, shifted[AW-OW-1],
					{(AW-OW-1){!shifted[AW-OW-1]}} };

	end // else if (AW-LGGAIN < OW) ... not implemented
	endgenerate
	// }}}

	// M_AXI_TVALID
	// {{{
	initial	M_AXI_TVALID = 0;
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		M_AXI_TVALID <= 0;
	else if (output_load)
		M_AXI_TVALID <= 1;
	else if (M_AXI_TREADY)
		M_AXI_TVALID <= 0;
	// }}}

	// M_AXI_TDATA
	// {{{
	always @(posedge S_AXI_ACLK)
	if ((!M_AXI_TVALID || M_AXI_TREADY) && output_load)
		M_AXI_TDATA <= rounded_acc[AW-1:AW-OW];
	// }}}

	// M_AXI_TLAST
	// {{{
	always @(posedge S_AXI_ACLK)
	if (NS <= 1 || !S_AXI_ARESETN)
		M_AXI_TLAST <= 1;
	else if ((!M_AXI_TVALID || M_AXI_TREADY) && output_load)
		M_AXI_TLAST <= acc_last;
	// }}}

	// }}}

	// Keep Verilator happy
	// {{{
	wire	unused;
	assign	unused = &{ 1'b0, rounded_acc[AW-OW-1:0] };
	// }}}
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
// Formal properties
// {{{
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
`ifdef	FORMAL
	// Local (formal only) declarations
	// {{{
	reg	f_past_valid;
	reg	[$clog2(NS):0]	f_istream, f_ostream;
	reg	[2:0]		f_sumlast, f_sumactive;
	reg	[15:0]		f_icount, f_ocount, f_countchk;
	reg	[15:0]		f_ipkt, f_opkt, f_pktchk;

	initial	f_past_valid = 1'b0;
	always @(posedge S_AXI_ACLK)
		f_past_valid <= 1;

	always @(*)
	if (!f_past_valid)
		assume(!S_AXI_ARESETN);
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Stream assumptions & assertions
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	// f_istream, f_icount, f_ipkt
	// {{{
	initial	f_istream = 0;
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
	begin
		f_istream <= 0;
		f_icount <= 0;
		f_ipkt <= 0;
	end else if (skd_valid && skd_ready)
	begin
		if (skd_last)
			f_istream <= 0;
		else
			f_istream <= f_istream + 1;
		if (!skip_run)
		begin
			f_icount <= f_icount + 1;
			f_ipkt <= f_ipkt + (skd_last ? 1:0);
		end else
			assert(f_icount[0] == 1'b0);
	end
	// }}}

	always @(*)
	if (S_AXI_ARESETN && NS == 2)
	begin
		if (skip_run)
			assert(f_icount[0] == 1'b0);
		else
			assert(f_icount[0] == f_istream[0]);
	end

	always @(*)
	if (skd_valid)
		assume(skd_last == (f_istream == NS-1));

	always @(*)
		assert(f_istream < NS);

	always @(posedge S_AXI_ACLK)
	if (!f_past_valid || $past(!S_AXI_ARESETN))
		assume(!S_AXI_TVALID);
	else if ($past(S_AXI_TVALID && !S_AXI_TREADY))
	begin
		assume(S_AXI_TVALID);
		assume($stable(S_AXI_TDATA));
		assume($stable(S_AXI_TLAST));
	end

	always @(posedge S_AXI_ACLK)
	if (!f_past_valid || $past(!S_AXI_ARESETN))
		assert(!M_AXI_TVALID);
	else if ($past(M_AXI_TVALID && !M_AXI_TREADY))
	begin
		assert(M_AXI_TVALID);
		assert($stable(M_AXI_TDATA));
		assert($stable(M_AXI_TLAST));
	end

	// f_ostream, f_ocount, f_opkt
	// {{{
	initial	f_ostream = 0;
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
	begin
		f_ostream <= 0;
		f_ocount <= 0;
		f_opkt <= 0;
	end else if (M_AXI_TVALID && M_AXI_TREADY)
	begin
		if (M_AXI_TLAST)
			f_ostream <= 0;
		else
			f_ostream <= f_ostream + 1;
		f_ocount <= f_ocount + 1;
		f_opkt <= f_opkt + (M_AXI_TLAST ? 1:0);
	end
	// }}}

	generate if (NS == 1)
	begin
	end else if (NS == 2)
	begin

		always @(*)
		if (S_AXI_ARESETN && !M_AXI_TVALID && output_load)
		begin
			// assert(acc_last != M_AXI_TLAST);
			assert(acc_last == f_ostream[0]);
		end

	end else begin

		always @(*)
		if (S_AXI_ARESETN && output_load)
			assert(acc_last == (f_ostream == NS-2));

	end endgenerate

	always @(*)
	if (S_AXI_ARESETN)
	begin
		if (M_AXI_TVALID)
			assert(M_AXI_TLAST == (f_ostream == NS-1));
		else if (f_ostream == 0)
			assert(M_AXI_TLAST);
		else
			assert(!M_AXI_TLAST);
	end

	always @(*)
	if (S_AXI_ARESETN)
		assert(f_ostream < NS);

	always @(*)
	if (S_AXI_ARESETN && NS == 2)
	begin
		assert(data_write_address[0] == f_istream);
	end
	
	always @(*)
	begin
		f_sumlast = ((idx_last && idx_load) ? 1:0)
			+ ((mem_last && mem_load) ? 1:0)
			+ ((product_last && product_load) ? 1:0)
			+ ((acc_last && output_load) ? 1:0);

		f_sumactive = (read_enable ? 1:0)
			+ (mem_load ? 1:0)
			+ (product_load ? 1:0)
			+ (output_load ? 1:0);

		f_countchk = f_ocount + (f_sumactive > 0);
		if ((mem_load || product_load || output_load)&&(read_enable))
			f_countchk = f_countchk + 1;
		if (M_AXI_TVALID)
			f_countchk = f_countchk + 1;

		if (S_AXI_ARESETN)
		begin
			if (idx_last)
				assert(read_enable);
			if (mem_last)
				assert(p_enable);
			if (product_last)
				assert(acc_enable);

			if (acc_last && output_load)
			begin
				assert(!product_last);
				assert(!mem_last);
				assert(!idx_last);
			end else if (product_last && product_load)
			begin
				assert(!mem_last);
				assert(!idx_last);
				assert(acc_last);
			end else if (mem_last && mem_load)
			begin
				assert(!idx_last);
				assert(product_last);
				assert(acc_last);
			end else if (idx_last && idx_load)
			begin
				assert(mem_last);
				assert(product_last);
				assert(acc_last);
			end

			if (f_sumactive == 0)
			begin
				assert(idx_last == mem_last);
				assert(idx_last == product_last);
				assert(idx_last == acc_last);
			end

			casez({idx_last, mem_last, product_last, acc_last, M_AXI_TLAST })
			5'b1000?: begin end
			5'b1100?: begin end
			5'b1110?: begin end
			5'b1111?: begin end
			5'b1111?: begin end
			5'b0111?: begin end
			5'b0011?: begin end
			5'b0001?: begin end
			5'b0000?: begin end
			5'b0000?: begin end
			default: assert(0);
			endcase

			if (output_load)
				assert(!product_load);

			if (!read_enable)
				assert(!idx_last);
			else if (f_icount > 0)
				assert(idx_last != f_icount[0]);

			assert(f_sumlast <= 1);
			assert(f_sumactive <= 2);
			if (output_load)
				assert(!idx_load);

			if (p_enable)
				assert(read_enable || (mem_load && acc_enable));
			if (idx_load)
				assert(read_enable);

			if (NS > 1 && f_sumlast > 0)
				assert(!M_AXI_TLAST);

			if (NS > 1 && f_sumactive > 0)
			begin
				if (output_load)
				begin
					assert(acc_last == (f_ostream == NS-1 - (M_AXI_TVALID ? 1:0)));
					assert(!product_load);
					assert(!acc_last || !product_last);
					assert(!mem_load);
					assert(!acc_last || !mem_last);
					assert(!idx_load);
					// assert(!idx_last);
				end else if (product_load)
				begin
					assert(product_last == (f_ostream == NS-1 - (M_AXI_TVALID ? 1:0)));
					assert(!mem_load);
					assert(!product_last || !mem_last);
					assert(!idx_load);
					// assert(!idx_last);
				end else if (mem_load)
				begin
					assert(mem_last == (f_ostream == NS-1 - (M_AXI_TVALID ? 1:0)));
					assert(!idx_load);
					// assert(!idx_last);
				end else if (read_enable)
				begin
					assert(idx_last == (f_ostream == NS-1 - (M_AXI_TVALID ? 1:0)));
				end
			end

			// if (!f_icount[0] && f_sumactive > 0)
			// assert({idx_last, mem_last, product_last, acc_last } == 0);
			// if (!f_ocount[0] && !f_icount[0] && f_ocount != f_icount)
			//	assert({idx_last, mem_last, product_last, acc_last } != 0);

			// The following is true, but can't be proven via
			// induction (yet)
			assert(f_icount == f_countchk);
		end

		/*
		f_sumstream = f_sumstream + f_ostream;
		if (f_sumstream >= NS)
			f_sumstream = f_sumstream - NS;

		if (S_AXI_ARESETN)
		begin
			assert(f_sumstream == f_istream);
			assert(f_sumstream <= 1);
		end
		*/
	end
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Cover checks
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	reg	[3:0]	cvr_results;


	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		cvr_results <= 0;
	else if (M_AXI_TVALID && M_AXI_TREADY && M_AXI_TLAST && !cvr_results[3])
		cvr_results <= cvr_results + 1;

	always @(posedge S_AXI_ACLK)
	if (S_AXI_ARESETN)
		cover(M_AXI_TVALID && M_AXI_TLAST);

	always @(posedge S_AXI_ACLK)
	if (S_AXI_ARESETN)
		cover(cvr_results[1]);
	always @(posedge S_AXI_ACLK)
	if (S_AXI_ARESETN)
	begin
		cover(cvr_results == 3'd3);
		cover(cvr_results == 3'd4);
		cover(cvr_results == 3'd5);
	end

	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// "Careless" assumptions
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	always @(posedge S_AXI_ACLK)
	begin
		if (f_past_valid && (read_enable || $past(S_AXI_TVALID)))
			assume(!i_tap_wr);
	end
	// }}}
`endif
// }}}
endmodule
