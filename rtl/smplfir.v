////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	smplfir.v
//
// Project:	DSP Filtering Example Project
//
// Purpose:	To demonstrate an exceptionally simple FIR filter.
//
//	Filter taps:	[1, 1] (fixed)
//	Filter Speed:	Full clock rate
//	
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
module	smplfir(i_clk, i_ce, i_val, o_val);
	parameter	IW=15;
	localparam	OW=IW+1;
	input	wire		i_clk, i_ce;
	input	wire	[(IW-1):0]	i_val;
	output	wire	[(OW-1):0]	o_val;

	reg	[(IW-1):0]	delayed;

	always @(posedge i_clk)
		if (i_ce)
			delayed <= i_val;

	always @(posedge i_clk)
		if (i_ce)
			o_val <= i_val + delayed;

endmodule
