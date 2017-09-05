////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	genericfir.v
//
// Project:	DSP Filtering Example Project
//
// Purpose:	Implement a high speed (1-output per clock), adjustable tap FIR
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2017, Gisselquist Technology, LLC
//
// This program is free software (firmware): you can redistribute it and/or
// modify it under the terms of  the GNU General Public License as published
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
module	genericfir(i_clk, i_reset, i_tap_wr, i_tap, i_ce, i_sample, o_result);
	parameter		NTAPS=128, IW=16, TW=IW, OW=2*IW+8;
	parameter [0:0]		FIXED_TAPS=0;
	input	wire			i_clk, i_reset;
	//
	input	wire			i_tap_wr;
	input	wire	[(TW-1):0]	i_tap;
	//
	input	wire			i_ce;
	input	wire	[(IW-1):0]	i_sample;
	output	wire	[(OW-1):0]	o_result;

	wire	[(TW-1):0] tap		[NTAPS:0];
	wire	[(IW-1):0] sample	[NTAPS:0];
	wire	[(OW-1):0] result	[NTAPS:0];

	assign	tap[0]		= i_tap;
	assign	sample[0]	= i_sample;
	assign	result[0]	= 0;

	genvar	k;
	generate
	for(k=0; k<NTAPS; k=k+1)
	begin: FILTER
		firtap tapk(i_clk, i_reset,
				// Tap update circuitry
				i_tap_wr, tap[k], tap[k+1],
				// Sample delay line
				i_ce, sample[k], sample[k+1],
				// The output accumulation line
				result[k], result[k+1]);
	end endgenerate

	assign	o_result = result[NTAPS];

endmodule

