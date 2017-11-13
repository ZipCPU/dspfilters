////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	boxwrapper.v
//
// Project:	DSP Filtering Example Project
//
// Purpose:	To wrap the boxcar.v filter so that it looks like a more generic
//		filter.  This is necessary because we want to use our
//	generic filtering test bench to also test the boxcar filter.  It isn't
//	necessary to use the boxcar filter, however.
//
//	There are a couple of differences from the generic filter spec:
//
//	1. The i_tap value is completely ignored.  In the boxcar filter,
//		all taps are defined as '1'.  Instead, i_sample is used
//		to set the number of averages--presumably because IW >= LGMEM.
//
//	2. The boxcar filter requires that i_reset be set any time the number
//		of averages changes.  Hence, i_reset gets applied to boxcar.v
//		more often that it gets applied to other general filters.
//
//	3. The boxcar filter is very dependent upon the LGMEM parameter.
//		It can only average between 1 and (1<<LGMEM)-1 values together.
//		This also means that there will be an accumulation of (up to)
//		LGMEM extra bits from IW, hence OW=IW+LGMEM.  You may find this
//		number of taps to be too conservative.
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
module	boxwrapper(i_clk, i_reset, i_tap_wr, i_tap, i_ce, i_sample, o_result);
	parameter	IW=16, OW=(IW+LGMEM), NTAPS=(1<<LGMEM), TW=LGMEM, LGMEM=6;
	input	wire	i_clk, i_reset;
	//
	input	wire			i_tap_wr;
	input	wire	[(TW-1):0]	i_tap;
	//
	input	wire			i_ce;
	input	wire	[(IW-1):0]	i_sample;
	output	wire	[(OW-1):0]	o_result;

	reg	[(LGMEM-1):0]	r_navg;
	wire	[(LGMEM-1):0]	navg;
	initial	r_navg = -4;
	always @(posedge i_clk)
		if (i_tap_wr)
			r_navg <= i_sample[(LGMEM-1):0];

	assign	navg = (i_tap_wr)?i_sample[(LGMEM-1):0] : r_navg;

	boxcar	#(.IW(IW), .OW(OW), .LGMEM(LGMEM))
		 boxfilter(i_clk, (i_reset)||(i_tap_wr),
			navg, i_ce, i_sample, o_result);

	// Make verilator happy
	// verilator lint_off UNUSED
	wire	[(TW-1):0]	unused;
	assign	unused = i_tap;
	// verilator lint_on  UNUSED
endmodule
