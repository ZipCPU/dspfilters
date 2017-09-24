////////////////////////////////////////////////////////////////////////////////
//
// Filename:	genericfir_tb.cpp
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
#include <signal.h>
#include <time.h>
#include <ctype.h>
#include <string.h>
#include <stdint.h>
#include <assert.h>

#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vgenericfir.h"
#include "testb.h"

class	GENERICFIR_TB : public TESTB<Vgenericfir> {
public:
	bool		m_done;

	GENERICFIR_TB(void) {
	}

	void	trace(const char *vcd_trace_file_name) {
		fprintf(stderr, "Opening TRACE(%s)\n", vcd_trace_file_name);
		opentrace(vcd_trace_file_name);
	}

	void	close(void) {
		TESTB<Vgenericfir>::closetrace();
	}

	void	tick(void) {
		if (m_done)
			return;

		TESTB<Vgenericfir>::tick();
	}

	bool	done(void) {
		if (m_done)
			return true;
		else if (Verilated::gotFinish())
			m_done = true;
		return m_done;
	}

	void	clear_filter(void) {
		m_core->i_tap_wr = 0;
		m_core->i_reset  = 1;
		tick();
		m_core->i_reset = 0;
	}
			
	void	load_taps(const unsigned NTAPS, const int *taps) {
		m_core->i_tap_wr = 1;
		m_core->i_ce     = 0;

		for(unsigned k=0; k<NTAPS; k++) {
			m_core->i_tap = taps[k];
			tick();
		}

		m_core->i_tap_wr = 0;
	}

	void	apply_filter(const unsigned NLEN, long int *signal) {
		const	int	IW = 16, OW = 2*IW+8;
		m_core->i_tap_wr = 0;
		m_core->i_reset  = 0;
		m_core->i_ce     = 1;

		for(unsigned k=0; k<NLEN; k++) {
			long	v;
			m_core->i_sample = signal[k] & ((1l<<IW)-1);
			tick();
			v = m_core->o_result;
			v <<= (8*sizeof(long)-OW);
			v >>= (8*sizeof(long)-OW);
			signal[k] = v;
		}
	}
};

GENERICFIR_TB	*tb;

int	main(int argc, char **argv) {
	Verilated::commandArgs(argc, argv);
	tb = new GENERICFIR_TB();
	FILE	*dsp = fopen("dsp.64t", "w");
	const	unsigned	NTAPS = 128;
	const	unsigned	TAPW = 16; // bits
	const	unsigned	IW   = 16; // bits
	// const	unsigned	OW   = IW+TAPW+8; // bits

	const int	TAPVALUE = -0x7f;
	const int	IMPULSE  = (1<<(IW-1))-1;

	int	tapvec[NTAPS], ntests = 0;
	long	ivec[2*NTAPS];

	tb->trace("trace.vcd");
	tb->reset();

	for(unsigned k=0; k<NTAPS; k++) {
		//
		// Load a new set of taps
		//
		for(unsigned i=0; i<NTAPS; i++)
			tapvec[i] = 0;
		tapvec[k] = TAPVALUE & ((1<<TAPW)-1);

		tb->load_taps(NTAPS, tapvec);

		// Clear any memory within the filter
		tb->clear_filter();

		for(unsigned i=0; i<2*NTAPS; i++)
			ivec[i] = 0;
		ivec[0] = IMPULSE & ((1<<IW)-1);

		// Apply the filter to a test vector
		tb->apply_filter(2*NTAPS, ivec); ntests++;

		for(unsigned i=0; i<NTAPS; i++)
			assert(ivec[i] == 0);

		for(unsigned i=0; i<NTAPS; i++) {
			if (NTAPS+i != 2*NTAPS-1-k)
				assert(ivec[NTAPS+i] == 0);
			else
				assert(ivec[NTAPS+i] = IMPULSE * TAPVALUE);
		}


		// Write the results out
		fwrite(ivec, sizeof(ivec[0]), 2*NTAPS, dsp);
	}

	//
	// Block filter, impulse input
	//
	tb->clear_filter();
	for(unsigned i=0; i<NTAPS; i++)
		tapvec[i] = TAPVALUE & ((1<<TAPW)-1);

	tb->load_taps(NTAPS, tapvec);

	for(unsigned i=0; i<2*NTAPS; i++)
		ivec[i] = 0;
	ivec[0] = IMPULSE;

	tb->apply_filter(2*NTAPS, ivec); ntests++;
	fwrite(ivec, sizeof(ivec[0]), 2*NTAPS, dsp);

	for(unsigned i=0; i<NTAPS; i++)
		assert(ivec[i] == 0);

	for(unsigned i=0; i<NTAPS; i++)
		assert(ivec[NTAPS+i] == IMPULSE * TAPVALUE);

	//
	//
	// Block filter, block input
	tb->clear_filter();

	for(unsigned i=0; i<2*NTAPS; i++)
		ivec[i] = IMPULSE;

	tb->apply_filter(2*NTAPS, ivec); ntests++;
	fwrite(ivec, sizeof(ivec[0]), 2*NTAPS, dsp);

	for(unsigned i=0; i<NTAPS; i++)
		assert(ivec[i] == 0);

	for(unsigned i=0; i<NTAPS; i++)
		assert(ivec[NTAPS+i] == (i+1)*IMPULSE*TAPVALUE);

	printf("%d tests accomplished\n", ntests);

	tb->close();
	fclose(dsp);
	exit(0);
}

