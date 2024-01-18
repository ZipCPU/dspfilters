////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	cheapspectral_tb.cpp
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
// Copyright (C) 2020-2024, Gisselquist Technology, LLC
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
#include "Vcheapspectral.h"

#define	BASEFILE	"cheapspectral"

// reset_core(TESTB<Vcheapspectral> *tb)
// {{{
void	reset_core(TESTB<Vcheapspectral> *tb) {
	// reset our core before cycling it
	tb->m_core->i_data_ce= 0;
	tb->m_core->i_data   = 0;
	tb->m_core->i_wb_cyc = 0;
	tb->m_core->i_wb_stb = 0;
	tb->reset();
}
// }}}

// clear_mem
// {{{
void	clear_mem(TESTB<Vcheapspectral> *tb, int lglags) {
	// Clear all the memory, then reset again
	for(int k=0; k<1+(1<<lglags); k++) {
		tb->m_core->i_data_ce = 1;
		tb->m_core->i_data    = 0;
		tb->tick();
	}
	tb->m_core->i_data_ce = 0;
}
// }}}

// request_start
// {{{
void	request_start(TESTB<Vcheapspectral> *tb) {
	// Send a start request to the core
	tb->m_core->i_wb_cyc  = 1;
	tb->m_core->i_wb_stb  = 1;
	tb->m_core->i_wb_we   = 1;
	tb->m_core->i_wb_addr = 0;
	tb->m_core->i_wb_data = 0;
	tb->m_core->i_wb_sel  = 15;
	tb->m_core->i_data_ce = 0;
	assert(!tb->m_core->o_wb_stall);
	tb->tick();
	assert(tb->m_core->o_wb_ack);
	tb->m_core->i_wb_cyc  = 0;
	tb->m_core->i_wb_stb  = 0;
}
// }}}

// wb_read
// {{{
int	wb_read(TESTB<Vcheapspectral> *tb, unsigned addr) {
	tb->m_core->i_wb_cyc = 1;
	tb->m_core->i_wb_stb = 1;
	tb->m_core->i_wb_we  = 0;
	tb->m_core->i_wb_addr= addr;

	assert(!tb->m_core->o_wb_stall);

	tb->tick();

	assert(tb->m_core->o_wb_ack);

	tb->m_core->i_wb_cyc = 0;
	tb->m_core->i_wb_stb = 0;
	tb->m_core->i_wb_we  = 0;
	return tb->m_core->o_wb_data;
}
// }}}

int	main(int argc, char **argv) {
	Verilated::commandArgs(argc, argv);
	TESTB<Vcheapspectral>	tb;
	bool		failed = false;
	FILE		*fdata;

	fdata = fopen(BASEFILE ".bin", "w");
	if (NULL == fdata) {
		fprintf(stderr, "ERR: Could not open output data file, %s\n",
			BASEFILE ".bin");
		perror("O/S Err:");
		exit(EXIT_FAILURE);
	}

	// Open a .VCD trace file, cheapspectral.vcd
	// tb.opentrace(BASEFILE ".vcd");

	reset_core(&tb);

	// bool	dblbuffer, autorestart;
	int	iw, lglags, lgnavg, dmask, *mem, lags, navg, shift;
	double	scale;

	// dblbuffer   = tb.m_core->o_dblbuffer;
	// autorestart = tb.m_core->o_restart;
	iw     = tb.m_core->o_width;
	lglags = tb.m_core->o_lglags; lags = (1<<lglags);
	lgnavg = tb.m_core->o_lgnavg; navg = (1<<lgnavg);
	dmask  = (1<<iw)-1;
	mem = new int[lags];
	scale = (1<<iw)/2.0-1;
	shift = 0;
	if (2*iw + lgnavg > 32)
		shift = (2*iw+lgnavg - 32);

	fwrite(&lglags, sizeof(int), 1, fdata);

	////////////////////////////////////////////////////////////////////////
	//
	// Test #1: Uniform (not Gaussian) noise
	// {{{
	// Expected result: A peak at ADDR[&], much lower values everywhere else
	//

	clear_mem(&tb, lglags);
	request_start(&tb);

	// Set us up with completely random data, see what happens
	printf("Random data test\n");
	tb.m_core->i_data_ce = 1;
	for(int k=0; k<(lags+1) * (navg); k++) {
		tb.m_core->i_data    = rand() & dmask;
		tb.tick();

		if ((k & 0x3ffff) == 0)
			printf("  k = %7d\n", k);
	}
	tb.m_core->i_data_ce = 0;
	while(!tb.m_core->o_int)
		tb.tick();

	for(int k=0; k<lags; k++)
		mem[k] = wb_read(&tb, k);

	fwrite(mem, sizeof(int), lags, fdata);
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Test #2: All zeros
	// {{{
	// Expected result: All zeros
	//

	clear_mem(&tb, lglags);
	request_start(&tb);

	// Set us up with completely zero data
	printf("Zero data test\n");
	tb.m_core->i_data_ce = 1;
	tb.m_core->i_data    = 0;
	for(int k=0; k<(lags+1) * (navg); k++) {
		tb.tick();

		if ((k & 0x3ffff) == 0)
			printf("  k = %7d\n", k);
	}
	tb.m_core->i_data_ce = 0;
	while(!tb.m_core->o_int)
		tb.tick();

	for(int k=0; k<lags; k++)
		mem[k] = wb_read(&tb, k);

	fwrite(mem, sizeof(int), lags, fdata);

	for(int k=0; k<lags; k++)
		if (!failed && mem[k] != 0) {
			printf("Test #2 All zeros test: R[%d] = %d, when it should be 0\n",
				lags-1-k, mem[k]);
			failed = true;
		}
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Test #3: All ones
	// {{{
	// Expected result: All values == LGNAVGS
	//

	clear_mem(&tb, lglags);
	request_start(&tb);

	// Set us up with completely zero data
	printf("One data test\n");
	tb.m_core->i_data_ce = 1;
	tb.m_core->i_data    = 1;
	for(int k=0; k<(lags+1) * (navg); k++) {
		tb.tick();

		if ((k & 0x3ffff) == 0)
			printf("  k = %7d\n", k);
	}
	tb.m_core->i_data_ce = 0;
	while(!tb.m_core->o_int)
		tb.tick();

	for(int k=0; k<lags; k++)
		mem[k] = wb_read(&tb, k);

	fwrite(mem, sizeof(int), lags, fdata);

	for(int k=0; k<lags; k++)
		if (!failed && (mem[k] != (navg)/(1<<shift))
				&& (mem[k] != (navg-1)/(1<<shift))) {
			printf("Test #3 All ones test: R[%d] = %d, when it should be %d\n",
				lags-1-k, mem[k], (navg)/(1<<shift));
			failed = true;
		}
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Test #4: Alternating +/- 1
	// {{{
	// Expected result: All values are alternating +/- LGNAVGS
	//
	clear_mem(&tb, lglags);
	request_start(&tb);

	// Set us up with completely zero data
	printf("Alternating data test\n");
	tb.m_core->i_data_ce = 1;
	tb.m_core->i_data    = -1;
	for(int k=0; k<(lags+1) * (navg); k++) {
		tb.m_core->i_data    = -tb.m_core->i_data;
		tb.tick();

		if ((k & 0x3ffff) == 0)
			printf("  k = %7d\n", k);
	} tb.m_core->i_data_ce = 0;
	while(!tb.m_core->o_int)
		tb.tick();

	for(int k=0; k<lags; k++)
		mem[k] = wb_read(&tb, k);

	fwrite(mem, sizeof(int), lags, fdata);

	for(int k=0; k<lags; k++) {
		int expected = navg * ((k&1) ? 1:-1);
		expected = expected / (1<<shift);
	//	printf("Test #4: R[%d] = %5d, when it should be %5d\n",
	//		lags-1-k, mem[k], expected);

		if (!failed && (mem[k] != expected)
			&& (mem[k] != expected-1)) {
			printf("Test #4 Alternating data test: R[%d] = %d, when it should be %d\n",
				lags-1-k, mem[k], expected);
			// failed = true;
		}
	}
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Test #5: Alternating +/- 1, only slower--once per lag
	// {{{
	// Expected result: A square wave output, one waveform, having the
	//	sign of a cosine
	//
	clear_mem(&tb, lglags);
	request_start(&tb);

	// Set us up with completely zero data
	printf("Slower Alternating data test\n");
	tb.m_core->i_data_ce = 1;
	tb.m_core->i_data    = -1;
	for(int k=0; k<(lags+1) * (navg); k++) {
		if ((k & (lags/2-1))==0)
			tb.m_core->i_data    = -tb.m_core->i_data;
		tb.tick();

		if ((k & 0x3ffff) == 0)
			printf("  k = %7d\n", k);
	} tb.m_core->i_data_ce = 0;
	while(!tb.m_core->o_int)
		tb.tick();

	for(int k=0; k<lags; k++)
		mem[k] = wb_read(&tb, k);

	fwrite(mem, sizeof(int), lags, fdata);
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Test #6: a sinewave
	// {{{
	// Expected result: A cosine wave, with a peak at ADDR[&] (i.e. posn 0)
	//

	// Clear our test memory
	clear_mem(&tb, lglags);
	request_start(&tb);

	//
	// Set us up with a strong sine wave, see what happens
	printf("Sinewave test\n");
	double	TEST_FREQUENCY = 7.0 / (double)lags;
	tb.m_core->i_data_ce = 1;
	for(int k=0; k<(lags+1) * (navg); k++) {
		tb.m_core->i_data    = (int)scale * sin(2.0 * M_PI * TEST_FREQUENCY * k);
		tb.m_core->i_data   &= dmask;
		tb.tick();

		if ((k & 0x3ffff) == 0)
			printf("  k = %7d\n", k);
	} tb.m_core->i_data_ce = 0;
	while(!tb.m_core->o_int)
		tb.tick();

	for(int k=0; k<lags; k++)
		mem[k] = wb_read(&tb, k);

	fwrite(mem, sizeof(int), lags, fdata);

	for(int k=0; k<lags; k++) {
		double	expected, dif, memv;

		expected = 0.5 * cos(2.0 * M_PI * TEST_FREQUENCY * (lags-1-k));

		memv = (mem[k]* (double)(1<<shift) / (double)navg);
		memv = memv / (scale * scale);

		dif = memv - expected;
		dif = fabs(dif);

		if (!failed && dif > 2.0 / sqrt(navg)) {
			printf("Test #5 Sinewave test: R[%d]=%8.2f, when it should be %f, dif = %f\n",
				lags-1-k, memv,
				expected, dif);
			// failed = true;
		}
	}
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Test #7: a random binary waveform
	// {{{
	// Expected result: A ramp, ramping up from zero to a peak at ADDR[&]
	//	and starting BAUD_CYCLES from the end
	//

	// Clear our test memory
	clear_mem(&tb, lglags);
	request_start(&tb);

	printf("Random binary waveform test\n");

	const int	BAUD_CYCLES = 7;
	int	bc = BAUD_CYCLES; // Position in current baud cycle
	tb.m_core->i_data_ce = 1;
	for(int k=0; k<(lags+1) * (navg); k++) {
		if (++bc >= BAUD_CYCLES) {
			// Generate a new data value
			bc = 0;
			if (rand() & 1)
				tb.m_core->i_data = - (dmask >> 1);
			else
				tb.m_core->i_data = (dmask >> 1);
		} tb.tick();

		if ((k & 0x3ffff) == 0)
			printf("  k = %7d\n", k);
	} tb.m_core->i_data_ce = 0;
	while(!tb.m_core->o_int)
		tb.tick();

	for(int k=0; k<lags; k++)
		mem[k] = wb_read(&tb, k);

	fwrite(mem, sizeof(int), lags, fdata);

	for(int k=0; k<lags; k++) {
		double	expected = (dmask >> 1), dif, tau, memv, s;

		s = (dmask >> 1);

		tau = lags-1-k;
		if (fabs(tau) > BAUD_CYCLES)
			expected = 0.0;
		else
			expected = 1-(tau / BAUD_CYCLES);

		memv = mem[k] * (double)(1<<shift) /(double)navg;
		memv = memv / (s * s);

		dif = memv - expected;
		dif = fabs(dif);

		if (!failed && dif > 4.0 / sqrt(navg)) {
			printf("Test #7 RBW test: R[%d] = %8.3f, when it should be %f, %.0f, %f\n",
				lags-1-k, memv, expected, tau, dif);
			failed = true;
		}
	}
	// }}}


	if (failed)
		printf("TEST FAILURE!\n");
	else {	
		printf("\n\nSimulation complete: %ld clocks\n", tb.m_tickcount);
		printf("SUCCESS!!\n");
	}
}
