////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	iiravg.v
//
// Project:	DSP Filtering Example Project
//
// Purpose:	Implements a simple recursive filter.
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
module	iiravg(i_clk, i_ce, i_data, o_data);
	parameter	IW=15, OW=16, LGALPHA=4;
	localparam	AW=OW;
	//
	input	wire	i_clk, i_ce;
	input	wire	[(IW-1):0]	i_data;
	output	wire	[(OW-1):0]	o_data;

	wire	signed	[(AW-1):0]	difference, adjustment;
	reg	signed	[(AW-1):0]	r_average;

	assign	difference = { i_data, {(AW-IW){1'b0}} } - r_average;
	assign	adjustment = { {(LGALPHA){difference[(AW-1)]}},
				difference[(AW-1):LGALPHA] };

	always @(posedge i_clk)
		if (i_ce)
			r_average <= r_average + adjustment;

	assign	o_data = r_average;

endmodule
