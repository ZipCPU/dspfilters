////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	lfsr_tb.cpp
// {{{
// Project:	DSP Filtering Example Project
//
// Purpose:	
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
#include "Vlfsr.h"

#ifdef	ROOT_VERILATOR
#include "Vlfsr___024root.h"

#define	VVAR(A)	rootp->lfsr__DOT_ ## A
#elif	defined(NEW_VERILATOR)
#define	VVAR(A)	lfsr__DOT_ ## A
#else
#define	VVAR(A)	v__DOT_ ## A
#endif
#define	sreg	VVAR(_sreg)


int	main(int argc, char **argv) {
	Verilated::commandArgs(argc, argv);
	Vlfsr		tb;
	int		nout = 0;
	unsigned	clocks = 0, ones = 0, nbits = 0;
	const	int	LN = 8, WS = 24;

#define	VCDTRACE
#ifdef	VCDTRACE
	Verilated::traceEverOn(true);
	VerilatedVcdC* tfp = new VerilatedVcdC;
	tb.trace(tfp, 99);
	tfp->open("lfsr.vcd");
#define	TRACE_POSEDGE	tfp->dump(10*clocks)
#define	TRACE_NEGEDGE	tfp->dump(10*clocks+5); tfp->flush()
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

	assert(((tb.sreg)&((1<<LN)-1)) == 1);
	assert(tb.sreg != 0);

	while(clocks < 16*32*32) {
		int	ch;

		tb.i_clk = 1;
		tb.i_ce  = 1;
		tb.eval();
		TRACE_POSEDGE;
		tb.i_clk = 0;
		tb.eval();
		TRACE_NEGEDGE;

		for(int k=0; k<WS; k++) {
			ch    = ((tb.o_word>>k)&1) ? '1' : '0';
			ones += ((tb.o_word>>k)&1);
			putchar(ch);
			nout++;
			if ((nout & 0x07)==0) {
				if (nout == 56) {
					nout = 0;
					putchar('\n');
				} else
					putchar(' ');
			}
		} nbits += WS;
		clocks++;

		assert(tb.sreg != 0);
		if (((tb.sreg)&((1<<LN)-1)) == 1)
			break;
	}
	TRACE_CLOSE;

	while(((tb.sreg)&((1<<LN)-1)) != 1) {
		tb.i_clk = 1;
		tb.i_ce  = 1;
		tb.eval();
		TRACE_POSEDGE;
		tb.i_clk = 0;
		tb.eval();
		TRACE_NEGEDGE;

		for(int k=0; k<WS; k++) {
			ones += ((tb.o_word>>k)&1);
		} nbits += WS;
		clocks++;
		assert(tb.sreg != 0);
	}
	printf("\n\nSimulation complete: %d clocks (%08x), %d ones, %d bits\n", clocks, clocks, ones, nbits);

	bool	failed = false;
	{
		unsigned	nb = nbits, no = ones, ns=0;

		while(((nb&1)==0)&&((no&1)==0)) {
			ns++;
			nb >>=1;
			no >>= 1;
		}

		if (nb != (1<<LN)-1)
			failed = true;
		else if (no != (1<<(LN-1)))
			failed = true;
	}
	if (!failed)
		printf("SUCCESS!\n");
	else
		printf("FAILURE!\n");
}

/*
00000000 00000000 00000001 00000000 00000000 00000011 00000000
00000000 00000101 00000000 00000000 00001111 00000000 00000000
00010001 00000000 00000000 00110011 00000000 00000000 01010101
00000000 00000000 11111111 00000000 00000001 00000001 00000000
00000011 00000011 00000000 00000101 00000101 00000000 00001111
00001111 00000000 00010001 00010001 00000000 00110011 00110011
00000000 01010101 01010101 00000000 11111111 11111111 00000001
00000000 00000001 00000011 00000000 00000011 00000101 00000000
00000101 00001111 00000000 00001111 00010001 00000000 00010001
00110011 00000000 00110011 01010101 00000000 01010101 11111111
00000000 11111110 00000001 00000001 00000010 00000011 00000011
00000110 00000101 00000101 00001010 00001111 00001111 00011110
00010001 00010001 00100010 00110011 00110011 01100110 01010101
01010101 10101010 11111111 11111110 11111111 00000000 00000011
00000001 00000000 00000101 00000011 00000000 00001111 00000101
00000000 00010001 00001111 00000000 00110011 00010001 00000000
01010101 00110011 00000000 11111111 01010101 00000001 00000001
11111111 00000011 00000010 00000001 00000101 00000110 00000011
00001111 00001010 00000101 00010001 00011110 00001111 00110011
00100010 00010001 01010101 01100110 00110011 11111111 10101010
01010100 00000000 11111110 11111100 00000001 00000011 00000100
00000011 00000101 00001100 00000101 00001111 00010100 00001111
*/
