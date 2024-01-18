////////////////////////////////////////////////////////////////////////////////
//
// Filename:	abs_mpy.v
// {{{
// Project:	DSP Filtering Example Project
//
// Purpose:	This code has been modified from the mpyop.v file so as to
//		abstract the multiply that formal methods struggle so hard to
//	deal with.  It also simplifies the interface so that (if enabled)
//	the multiply will return in 1-6 clocks, rather than the specified
//	number for the given architecture.
//
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
// }}}
// Copyright (C) 2015-2024, Gisselquist Technology, LLC
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
module	abs_mpy #(
		// {{{
		parameter	AW = 32, BW=32,
		parameter [0:0]	OPT_SIGNED = 1'b1
		// }}}
	) (
		// {{{
		input	wire			i_clk, i_reset,
		input	wire	[(AW-1):0]	i_a,
		input	wire	[(BW-1):0]	i_b,
		output	wire	[(AW+BW-1):0]	o_result
		// }}}
	);

	// Local declarations
	// {{{
	wire	[(AW+BW-1):0]	any_result;
	assign	any_result = $anyseq;

	reg	[AW-1:0]	u_a;
	reg	[BW-1:0]	u_b;
	reg	[(AW+BW-1):0]	u_result;
	// }}}

	// u_a, u_b : unsigned copies of the input values
	// {{{
	always @(*)
	begin
		u_a = ((i_a[AW-1])&&(OPT_SIGNED)) ? -i_a : i_a;
		u_b = ((i_b[BW-1])&&(OPT_SIGNED)) ? -i_b : i_b;
	end
	// }}}

	always @(*)
	if ((OPT_SIGNED)&&(any_result[AW+BW-1]))
		u_result = - { 1'b1, any_result };
	else
		u_result =  { 1'b0, any_result };

	always @(*)
	if (i_reset)
		assume(any_result == 0);
	else begin
		// Constrain our result among many possibilities
		if ((i_a == 0)||(i_b == 0))
			assume(any_result == 0);
		if (OPT_SIGNED)
			assume(any_result[AW+BW-1]
				== (i_a[AW-1] ^ i_b[BW-1]));

		assume(u_result[AW+BW-1:BW] <= u_a);
		assume(u_result[AW+BW-1:AW] <= u_b);
	end

	genvar	k;
	generate
	begin
		for(k=1; k<AW-1; k=k+1)
		begin
			always @(*)
			if (u_a == (1<<k))
				assume(u_result == (u_b << k));
		end

		for(k=0; k<BW; k=k+1)
		begin
			always @(*)
			if (u_b == (1<<k))
				assume(u_result== (u_a << k));
		end

	end endgenerate

	assign	o_result = any_result;

endmodule
