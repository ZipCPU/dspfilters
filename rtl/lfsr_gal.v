////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	lfsr_gal.v
//
// Project:	DSP Filtering Example Project
//
// Purpose:	
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2017, Gisselquist Technology, LLC
//
// This program is free software (firmware): you can redistribute it and/or
// modify it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program.  (It's in the $(ROOT)/doc directory.  Run make with no
// target there if the PDF file isn't present.)  If not, see
// <http://www.gnu.org/licenses/> for a copy.
//
// License:	GPL, v3, as defined and found on www.gnu.org,
//		http://www.gnu.org/licenses/gpl.html
//
//
////////////////////////////////////////////////////////////////////////////////
//
//
`default_nettype	none
//
module	lfsr_gal(i_clk, i_reset, i_ce, i_in, o_bit);
	parameter		LN=8;	// LFSR Register length/polynomial deg
	parameter [(LN-1):0]	TAPS = 8'hb4,
				INITIAL_FILL = { { (LN-1){1'b0}}, 1'b1 };
	//
	input	wire		i_clk, i_reset, i_ce, i_in;
	output	wire		o_bit;

	reg	[(LN-1):0]	sreg;

	initial	sreg = INITIAL_FILL;
	always @(posedge i_clk)
		if (i_reset)
			sreg <= INITIAL_FILL;
		else if (i_ce)
		begin
			if (sreg[0])
				sreg <= { i_in, sreg[(LN-1):1] } ^ TAPS;
			else
				sreg <= { i_in, sreg[(LN-1):1] };
		end

	assign	o_bit = sreg[0];

endmodule
