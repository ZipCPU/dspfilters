////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	lfsr_gal_tb.cpp
// {{{
// Project:	DSP Filtering Example Project
//
// Purpose:	To test a Verilog Linear Feedback Shift Register pseudorandom
//		noise generator module called lfsr_gal.v.  This module is
//	nearly identical to lfsr_fib_tb.cpp, save only for the module under test.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
// }}}
// Copyright (C) 2017-2022, Gisselquist Technology, LLC
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
// }}}
#include <verilatedos.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <time.h>
#include <sys/types.h>
#include <signal.h>
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vlfsr_gal.h"

#ifdef	OLD_VERILATOR
#define	VVAR(A)	v__DOT_ ## A
#else
#define	VVAR(A)	lfsr_gal__DOT_ ## A
#endif

#define	sreg	VVAR(_sreg)

int	main(int argc, char **argv) {
	Verilated::commandArgs(argc, argv);
	Vlfsr_gal	tb;
	int		nout = 0;
	unsigned	clocks = 0, ones = 0;

#define	VCDTRACE
#ifdef	VCDTRACE
	Verilated::traceEverOn(true);
	VerilatedVcdC* tfp = new VerilatedVcdC;
	tb.trace(tfp, 99);
	tfp->open("lfsr_gal.vcd");
#define	TRACE_POSEDGE	tfp->dump(10*clocks)
#define	TRACE_NEGEDGE	tfp->dump(10*clocks+5)
#define	TRACE_CLOSE	tfp->close()
#else
#define	TRACE_POSEDGE
#define	TRACE_NEGEDGE
#define	TRACE_CLOSE
#endif

	// reset our core before cycling it
	tb.i_clk   = 1;
	tb.i_reset = 1;
	tb.i_ce    = 1;
	tb.eval();
	TRACE_POSEDGE;
	tb.i_clk   = 0;
	tb.i_reset = 0;
	tb.eval();
	TRACE_NEGEDGE;

	assert(tb.sreg == 1);

	while(clocks < 16*32*32) {
		int	ch;

		tb.i_clk = 1;
		tb.i_ce  = 1;
		tb.eval();
		TRACE_POSEDGE;
		tb.i_clk = 0;
		tb.eval();
		TRACE_NEGEDGE;

		ch = (tb.o_bit) ? '1' : '0';
		ones += (tb.o_bit&1);
		putchar(ch);
		nout++;
		if ((nout & 0x07)==0) {
			if (nout == 56) {
				nout = 0;
				putchar('\n');
			} else
				putchar(' ');
		}
		clocks++;

		if (tb.sreg == 1)
			break;
	}
	TRACE_CLOSE;

	while(tb.sreg != 1) {
		tb.i_clk = 1;
		tb.eval();
		tb.i_clk = 0;
		tb.eval();

		ones += (tb.o_bit&1);
		clocks++;
	}
	printf("\n\nSimulation complete: %d clocks (%08x), %d ones\n", clocks, clocks, ones);

	const int LN = 8;
	if ((clocks == (1<<LN)-1)&&(ones == (1<<(LN-1))))
		printf("SUCCESS!\n");
	else
		printf("FAILURE!\n");
}
