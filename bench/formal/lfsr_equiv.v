////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	lfsr_equiv
// {{{
// Project:	DSP Filtering Example Project
//
// Purpose:	This is a formal proof that the two types of LRS's, Fibonacci
//		and Galois, are equivalent expressions of the same underlying
//	function.
//
//	The CE line is also a challenge to include, making this a potentially
//	difficult proof.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
// }}}
// Copyright (C) 2017-2024, Gisselquist Technology, LLC
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
`default_nettype	none
// }}}
module	lfsr_equiv(i_clk, i_reset, i_ce, i_in, o_bit);
	parameter			LN=8;
	parameter	[(LN-1):0]	FIB_TAPS = 8'h2d;
	parameter	[(LN-1):0]	INITIAL_FILL = (1<<(LN-1));
	localparam	[(LN-1):0]	GAL_TAPS = 8'hb4;
	input	wire	i_clk, i_reset, i_ce, i_in;
	output	wire	o_bit;

	wire	fib_bit, gal_bit;

	lfsr_fib #(.LN(LN), .TAPS(FIB_TAPS), .INITIAL_FILL(INITIAL_FILL))
		fib(i_clk, i_reset, i_ce, i_in, fib_bit);

	lfsr_gal #(.LN(LN), .TAPS(GAL_TAPS), .INITIAL_FILL(INITIAL_FILL))
		gal(i_clk, i_reset, i_ce, i_in, gal_bit);

	assign	o_bit = fib_bit ^ gal_bit;
`ifdef	FORMAL
	always @(*)
		assert(fib_bit == gal_bit);
	always @(*)
		assume(i_ce);
`endif
endmodule
