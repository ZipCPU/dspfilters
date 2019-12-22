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
// Resource usage: For 12-bit samples, and averaging 64k samples, this
//		core will use (Xilinx baseline):
//
//	102	Flip-Flops
//	167	LUTs
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
`default_nettype none
//
module	histogram #(
	parameter	NAVGS = 65536,
	localparam	ACCW = $clog2(NAVGS+1),
	localparam	DW = 32,
	parameter	AW = 12,
	localparam	MEMSZ = (1<<(AW+1))
	) (
`ifdef	AXIDOUBLE
	input	wire		S_AXI_ACLK,
	input	wire		S_AXI_ARESETN,
	//
	input	wire		S_AXI_AWVALID,
	input	wire		S_AXI_WDATA,
	input	wire		S_AXI_WSTRB,
	output	wire	[1:0]	S_AXI_BRESP,
	//
	input	wire 		S_AXI_ARVALID,
	input	wire [AW+ADDRLSB-1:0]	S_AXI_ARADDR,
	output	wire [DW-1:0]	S_AXI_RDATA,
	output	wire	[1:0]	S_AXI_RRESP,
`else
	input	wire		i_clk,
	input	wire		i_reset,
	//
	input	wire		i_wb_cyc, i_wb_stb, i_wb_we,
	input	wire [AW-1:0]	i_wb_addr,
	input	wire [DW-1:0]	i_wb_data,
	input	wire [DW/8-1:0]	i_wb_sel,
	output	reg		o_wb_stall,
	output	reg		o_wb_ack,
	output	reg [DW-1:0]	o_wb_data,
`endif
	//
	input	wire		i_ce,
	input	wire [AW-1:0]	i_sample,
	//
	output	reg		o_int
	);

`ifdef	AXIDOUBLE
	wire	clk   = S_AXI_ACLK;
	wire	reset = !S_AXI_ARESETN;
	wire	bus_write = S_AXI_AWVALID && S_AXI_WSTRB != 0;
	// Under the AXIDOUBLE protocol, S_AXI_AWVALID = S_AXI_WVALID
	//   S_AXI_AWREADY = S_AXI_WREADY = 1, S_AXI_BREADY = 1,
	//   S_AXI_ARREADY = 1, and S_AXI_RREADY = 1
`else
	wire	clk   = i_clk;
	wire	reset = i_reset;
	wire	bus_write = i_wb_cyc && i_wb_we;
`endif

	reg	[ACCW-1:0]		count;
	reg	[ACCW-1:0]		mem	[0:MEMSZ-1];
	reg				start_reset, resetpipe, activemem,
					first_reset_clock;
	reg	[2:0]			cepipe;
	reg	[ACCW-1:0]		memval, memnew, bypass_data;
	reg	[AW:0]			r_sample, memaddr, bypass_addr;

	//
	// Zero out our memory initially
`ifndef	FORMAL
	integer	ik;
	initial	begin
		for(ik=0; ik<MEMSZ; ik=ik+1)
			mem[ik] = 0;
	end
`endif

	//
	// Count how many samples we've used in our block average
	//
	initial	count = 0;
	always @(posedge clk)
	if (start_reset || resetpipe)
		count <= 0;
	else if (i_ce)
	begin
		if (count == NAVGS[ACCW-1:0]-1)
			count <= 0;
		else
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
	always @(posedge clk)
	begin
		start_reset <= 0;

		if (i_ce && (count == NAVGS[ACCW-1:0]-1))
			start_reset <= 1;

		if (bus_write)
			start_reset <= 1;

		if (resetpipe)
			start_reset <= 0;
		if (reset)
			start_reset <= 1;
	end

	always @(posedge clk)
		first_reset_clock <= start_reset;

	initial	resetpipe = 0;
	always @(posedge clk)
	if (start_reset || first_reset_clock)
		resetpipe <= 1;
	else if (&memaddr[AW-1:0])
		resetpipe <= 0;

	initial	activemem = 0;
	initial	o_int = 0;
	always @(posedge clk)
	begin
		o_int <= 0;
		if (i_ce && !start_reset && count == NAVGS[ACCW-1:0] -1)
		begin
			activemem <= !activemem;
			o_int <= 1;
		end

		if (reset)
			o_int <= 0;
	end

	//
	// Track i_ce through our three clocks of operations.  We'll then use
	// cepipe[1] as our flag to write to memory.  cepipe[2:1] also serve
	// as flags for operand forwarding without needing to read from memory.
	//
	initial	cepipe = 0;
	always @(posedge clk)
	if (resetpipe)
		cepipe <= 3'b010;
	else
		cepipe <= { cepipe[1:0], i_ce };

	//
	// Cycle one: Read from memory, keep track of the address
	//
	always @(posedge clk)
		memval <= mem[{ activemem, i_sample }];

	always @(posedge clk)
		r_sample <= { activemem, i_sample };

	//
	// Cycle two:
	//	Add to our memory value, forward the address into memaddr
	//    UNLESS: we are in reset.  If resetting, set ourselves up to
	//	write zeros to an ever increasing address.
	//
	initial	memaddr = 0;
	initial	memnew  = 0;
	always @(posedge clk)
	if (resetpipe)
	begin
		memnew  <= 0;
		//
		memaddr <= memaddr + 1;
		if (first_reset_clock)
			memaddr <= 0;
		memaddr[AW] <= activemem;
	end else begin
		memaddr <= r_sample;

		//
		// Add one to the histogram bin of our incoming sample value
		//
		memnew  <= memval + 1;

		// Unless ... we just calculated this value and it hasn't been
		// written to memory yet
		if (cepipe[1] && r_sample == memaddr)
			memnew  <= memnew + 1;
		// OR ... we're writing it to memory now, and it'll still take
		// another clock cycle to read it back out.
		else if (cepipe[2] && r_sample == bypass_addr)
			memnew  <= bypass_data + 1;
	end

	//
	// Clock three: Write to memory
	//
	always @(posedge clk)
	if (cepipe[1])
		mem[memaddr] <= memnew;

	//
	// Keep track of data necessary to bypass the memory
	//
	always @(posedge clk)
	begin
		bypass_data <= memnew;
		bypass_addr <= memaddr; 
	end

	////////////////////////////////////////////////////////////////////////
	//
	// Handle the bus interactions
	//
	////////////////////////////////////////////////////////////////////////
	//
`ifdef	AXIDOUBLE
	always @(posedge clk)
	begin
		S_AXI_RDATA <= 0;
		S_AXI_RDATA[ACCW-1:0] <= mem[{ !activemem, i_wb_addr }];
	end
	
	always @(*)
		S_AXI_BRESP = 2'b00;
	always @(*)
		S_AXI_RRESP = 2'b00;
`else
	always @(posedge clk)
	begin
		o_wb_data <= 0;
		o_wb_data[ACCW-1:0] <= mem[{ !activemem, i_wb_addr }];
	end

	always @(posedge clk)
		o_wb_ack <= !reset && i_wb_stb;

	always @(*)
		o_wb_stall = 1'b0;
`endif

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
			reg [ACCW-1:0]	f_mem_data, f_this_counts;
	reg	[2:0]	f_this_pipe;

	reg	f_past_valid;
	initial	f_past_valid = 0;
	always @(posedge clk)
		f_past_valid <= 1;

	always @(*)
		f_mem_data = mem[f_addr];

	always @(*)
	if (!f_past_valid)
		assume(mem[f_addr] == 0);

	////////////////////////////////////////////////////////////////////////
	//
	// External assumptions
	//
	////////////////////////////////////////////////////////////////////////
	//
`ifdef	AXIDOUBLE
`else
	always @(*)
	if (!i_wb_cyc)
		assume(!i_wb_stb);
`endif

	////////////////////////////////////////////////////////////////////////
	//
	// Contract proofs
	//
	// Pick a particular value to average and consider.  Now we'll prove
	// that this special data, f_mem_data, will always be less then NAVGS,
	// and in particular always less than the counter's value of how
	// many items we've averaged so far in a run.
	//
	////////////////////////////////////////////////////////////////////////
	//
	//

	//
	// Count the number of times our incoming value is received
	//
	initial	f_this_counts = 0;
	always @(posedge clk)
	if (start_reset || resetpipe)
	begin
		// Clear our special value on or during any reset
		if (activemem == f_addr[AW])
			f_this_counts <= 0;

	end else if (i_ce && { activemem, i_sample } == f_addr)
		// In all other cases, if we see our special value,
		// accumulate  it
		f_this_counts <= f_this_counts + 1;

	//
	// For tracking bypass issues, keep track of when our special
	// value is written to
	//
	initial	f_this_pipe = 3'b000;
	always @(posedge clk)
	if (resetpipe)
		f_this_pipe <= 3'b000;
	else
		f_this_pipe <= { f_this_pipe[1:0], (!start_reset && i_ce
				&& activemem == f_addr[AW]
				&& i_sample == f_addr[AW-1:0]) };

	//
	//
	//
	always @(*)
	if (resetpipe && activemem == f_addr[AW])
		assert(f_this_counts == 0);
	else if (f_this_pipe == 0)
		assert(f_this_counts == f_mem_data);

	//
	// Check operand forwarding
	//
	always @(posedge clk)
	if (f_this_pipe == 3'b001)
		assert(memval == $past(f_this_counts));

	always @(posedge clk)
	if (f_this_pipe[1])
		assert(memnew <= $past(f_this_counts));

	always @(posedge clk)
	if (f_this_pipe[2])
		assert(bypass_data == $past(f_this_counts,2));

	//
	// Prove that our special memory value matches this count
	//
	always @(posedge clk)
	if (f_past_valid && $past(f_past_valid) && cepipe[1]
			&& { activemem, memaddr } == f_addr
			&& !resetpipe)
		assert(f_mem_data == $past(f_this_counts,2));

	always @(*)
	if (resetpipe && !first_reset_clock
			&& activemem == f_addr[AW]
			&& memaddr[AW-1:0] > f_addr[AW-1:0])
		assert(f_mem_data == 0);

	//
	// Induction check: Make certain that if f_this_pipe is ever true, then
	// cepipe is also true for that same bit.
	//
	always @(*)
	if (!resetpipe)
		assert((f_this_pipe & cepipe) == f_this_pipe);

	////////////////////////////////////////////////////////////////////////
	//
	// The counter is not allowed to overflow
	//
	always @(*)
		assert(count < NAVGS);

	////////////////////////////////////////////////////////////////////////
	//
	// Our counter isn't allowed to generate anything over NAVGS--EVER
	//
	////////////////////////////////////////////////////////////////////////
	//
	//
	always @(*)
		assert(f_mem_data <= NAVGS);

	always @(*)
		assert(f_this_counts <= NAVGS);

	always @(*)
	if (!start_reset && !resetpipe && activemem == f_addr[AW])
		assert(f_this_counts <= count);


	////////////////////////////////////////////////////////////////////////
	//
	// Reset sequence checks
	//
	always @(*)
	if (resetpipe)
		assert(count == 0);

	////////////////////////////////////////////////////////////////////////
	//
	// Interrupt / memory swap check
	//
	always @(posedge i_clk)
	if (f_past_valid && $past(!reset && !start_reset && i_ce && !bus_write)
		&& $past(count == NAVGS-1))
	begin
		assert(o_int);
		assert($changed(activemem));
		assert(start_reset);
		assert(count == 0);
	end

	always @(posedge i_clk)
	if (f_past_valid && !$past(reset) && $changed(activemem))
		assert(o_int);
	else
		assert(!o_int);

`ifdef	VERIFIC
	assert property (@(posedge clk)
		start_reset
		|=> first_reset_clock && resetpipe
		##1 resetpipe && memaddr[AW-1:0] == 0
			&& memaddr[AW] == activemem);

	assert property (@(posedge clk)
		i_ce && (i_sample == { activemem, f_addr})
				&& !start_reset && !resetpipe
		|=> ##2 f_mem_data == $past(f_mem_data + 1));

	assert property (@(posedge clk)
		$fell(resetpipe) && activemem == f_addr[AW]
		|=> f_mem_data == 0);

	assert property (@(posedge clk)
		i_wb_stb && !reset |=> o_wb_ack);

	assert property (@(posedge clk)
		!reset && !start_reset && i_ce && !bus_write
		&& count == NAVGS-1
		|=> o_int && start_reset && count == 0);
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
			cover(f_mem_data == 16);
	end endgenerate

	generate if (NAVGS <= 16)
	begin
		always @(*)
			cover(start_reset && f_mem_data == 0);

		always @(*)
			cover(f_mem_data == NAVGS);

`ifdef	VERIFIC
		cover property (@(posedge clk)
			i_wb_stb && (i_wb_addr == f_addr[AW-1:0]) && activemem
				&& f_addr[AW] == !activemem
			##1 o_wb_ack && o_wb_data[ACCW-1:0] == f_mem_data
				&& f_mem_data == 0);

		cover property (@(posedge clk)
			i_wb_stb && (i_wb_addr == f_addr[AW-1:0]) && activemem
				&& f_addr[AW] == !activemem
			##1 o_wb_ack && o_wb_data[ACCW-1:0] == f_mem_data
				&& f_mem_data == NAVGS);
`endif
	end endgenerate
`endif
endmodule
