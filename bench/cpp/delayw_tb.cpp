////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	delayw_tb.cpp
// {{{
// Project:	DSP Filtering Example Project
//
// Purpose:	To test a Verilog signal delay block, delayw.
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
#include "testb.h"
#include "Vdelayw.h"

const int	DW = 12, LGDLY=4, NTESTS=512;

int	main(int argc, char **argv) {
	Verilated::commandArgs(argc, argv);
	TESTB<Vdelayw>	tb;
	unsigned	mask = 0, wptr = 0;;
	unsigned	*mem;
	bool		failed = false;

	// Open a .VCD trace file, delayw.vcd
	tb.opentrace("delayw.vcd");

	// reset our core before cycling it
	tb.m_core->i_ce    = 0;
	tb.m_core->i_delay = 0;
	tb.reset();

	mem = new unsigned[(1<<LGDLY)];
	mask = (1<<LGDLY)-1;

	for(int dly=0; dly<(1<<LGDLY); dly++) {
		tb.m_core->i_delay = dly;
		for(int k=0; k<dly+1; k++) {
			unsigned	v = rand() & ((1<<DW)-1),
				c = rand() & 0x7;

			tb.m_core->i_ce = 1;
			tb.m_core->i_word = v;
			tb.tick();

			mem[wptr] = v;
			wptr += 1; wptr &= mask;

			for(unsigned i=0; i<c; i++) {
				tb.m_core->i_ce = 0;
				tb.m_core->i_word = rand();
				tb.tick();
			}
		}

		if (failed)
			break;

		for(int k=0; k<NTESTS; k++) {
			unsigned	v = rand() & ((1<<DW)-1),
				c = rand() & 0x7;

			mem[wptr] = v;
			wptr += 1; wptr &= mask;
			tb.m_core->i_ce = 1;
			tb.m_core->i_word = v;

			do {
				tb.tick();

				if (tb.m_core->i_ce) {
					assert(tb.m_core->o_word
						== mem[(wptr-1)&mask]);
					assert(tb.m_core->o_delayed
						== mem[(wptr-1-dly)&mask]);
				}

				tb.m_core->i_ce = 0;
			} while(c--);

			if (failed)
				break;
		}

		if (failed)
			break;
	}

	if (failed)
		printf("TEST FAILURE!\n");
	else {	
		printf("\n\nSimulation complete: %ld clocks\n", tb.m_tickcount);
		printf("SUCCESS!!\n");
	}
}
