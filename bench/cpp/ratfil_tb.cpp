////////////////////////////////////////////////////////////////////////////////
//
// Filename:	ratfil.cpp
// {{{
// Project:	DSP Filtering Example Project
//
// Purpose:	Run the rational resampler through its paces.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
// }}}
// Copyright (C) 2019-2024, Gisselquist Technology, LLC
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
#include <signal.h>
#include <time.h>
#include <ctype.h>
#include <string.h>
#include <stdint.h>
#include <assert.h>

#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vratfil.h"
#include "testb.h"
#include "filtertb.h"
#include "filtertb.cpp"

#include "downsampletb.h"
#include "downsampletb.cpp"
#include "twelvebfltr.h"

const	unsigned IW = 16,
		TW = 12,
		OW = 24, // IW+TW+7,
		NTAPS = 103,
		NUP = 4,
		NDOWN = 5,
		CKPCE = 1;

// nextlg
// {{{
static	int     nextlg(int vl) {
	int     r;

	for(r=1; r<vl; r<<=1)
		;
	return r;
}
// }}}

class	RATFIL_TB : public AXISFILTERTB<Vratfil> {
public:
	bool		m_done;

	// RATFIL_TB
	// {{{
	RATFIL_TB(void) {
		IW(::IW);
		TW(::TW);
		OW(::OW);
		NTAPS(::NTAPS);
		NDOWN(::NDOWN);
		// DELAY(::DELAY);
		CKPCE(::CKPCE);
	}
	// }}}

	// test
	// {{{
	void	test(int nlen, int64_t *data) {
		clear_filter();
		AXISFILTERTB<Vratfil>::test(nlen, data);
	}
	// }}}

	// load
	// {{{
	void	load(int nlen, int64_t *data) {
		reset();
		AXISFILTERTB<Vratfil>::load(nlen, data);
	}
	// }}}

	// clear_filter
	// {{{
	void	clear_filter(void) {
		m_core->i_tap_wr = 0;

		// This filter requires running NTAPS worth of data through
		// it to fully clear it.  The reset isn't sufficient.
		m_core->i_ce     = 1;
		m_core->i_sample = 0;
		for(int k=0; k<nextlg(NTAPS()); k++)
			tick();

		m_core->i_ce = 0;
		for(int k=0; k<NTAPS(); k++)
			tick();
	}
	// }}}
};

RATFIL_TB	*tb;

int	main(int argc, char **argv) {
	Verilated::commandArgs(argc, argv);
	tb = new RATFIL_TB();

	const int64_t	TAPVALUE = -(1<<(TW-1));
	const int64_t	IMPULSE  =  (1<<(IW-1))-1;

	int64_t	tapvec[NTAPS];
	int64_t	ivec[2*NTAPS];

	tb->record_results("ratfil.bin");
	tb->opentrace("trace.vcd");
	tb->reset();

	printf("Impulse tests\n");
	// {{{
	for(unsigned k=0; k<NTAPS; k++) {
		//
		// Create a new coefficient vector
		//
		// Initialize it with all zeros
		for(unsigned i=0; i<NTAPS; i++)
			tapvec[i] = 0;
		// Then set one value to non-zero
		tapvec[k] = TAPVALUE;

		// Test whether or not this coefficient vector
		// loads properly into the filter
		tb->testload(NTAPS, tapvec);

		// Then test whether or not the filter overflows
		// tb->test_overflow();
	}

#ifdef	NOT_YET_ADAPTED_FOR_THE_SUBFILTER
	printf("Block Fil, Impulse input\n");

	//
	// Block filter, impulse input
	// {{{
	printf("Block Fil, Impulse input\n");

	for(unsigned i=0; i<NTAPS; i++)
		tapvec[i] = TAPVALUE;

	tb->testload(NTAPS, tapvec);

	for(unsigned i=0; i<2*NTAPS; i++)
		ivec[i] = 0;
	ivec[0] = IMPULSE;

	tb->test(2*NTAPS, ivec);

	for(unsigned i=0; i<NTAPS; i++) {
		if (ivec[i] != IMPULSE * TAPVALUE) {
			printf("IVEC[%3d] = %d\n"
			"IMPULSE = %d\n"
			"TAPVALUE = %d\n", i, ivec[i], IMPULSE, TAPVALUE);
			assert(ivec[i] == IMPULSE * TAPVALUE);
		}
	}
	for(unsigned i=NTAPS; i<2*NTAPS; i++)
		assert(0 == ivec[i]);
	// }}}
	//
	//
	// Block filter, block input
	// {{{
	// Set every element of an array to the same value
	printf("Block Fil, block input\n");
	for(unsigned i=0; i<2*NTAPS; i++)
		ivec[i] = IMPULSE;

	// Now apply this vector to the filter
	tb->test(2*NTAPS, ivec);

	for(unsigned i=0; i<NTAPS; i++) {
		int64_t	expected = (int64_t)(i+1l)*IMPULSE * TAPVALUE;
		if (ivec[i] != expected) {
			printf("OUT[%3d] = %12ld != (i+1)*IMPULSE*TAPVALUE = %12ld\n",
				i, ivec[i], expected);
			assert(ivec[i] == expected);
		}
	}
	for(unsigned i=0; i<NTAPS; i++) {
		int64_t	expected = NTAPS*IMPULSE * TAPVALUE;
		if (ivec[NTAPS+i] != expected) {
			printf("OUT[%3d] = %12ld != NTAPS*IMPULSE*TAPVALUE = %12ld\n",
				i+NTAPS, ivec[i+NTAPS], expected);
			assert(ivec[NTAPS+i] == expected);
		}
	}

	assert(tb->test_overflow());

	{
		double fp,      // Passband frequency cutoff
			fs,     // Stopband frequency cutoff,
			depth,  // Depth of the stopband
			ripple; // Maximum deviation within the passband

		tb->measure_lowpass(fp, fs, depth, ripple);
		printf("FP     = %f\n", fp);
		printf("FS     = %f\n", fs);
		printf("DEPTH  = %6.2f dB\n", depth);
		printf("RIPPLE = %.2g\n", ripple);

		// The depth of the filter should be between -14 and -13.
		// assert() that here.
		assert(depth < -13);
		assert(depth > -14);
	}
	// }}}

	assert(NCOEFFS < NTAPS);
	for(int i=0; i<NCOEFFS; i++)
		tapvec[i] = icoeffs[i];

	// In case the filter is longer than the number of taps we have,
	// we'll load zero any taps beyond the filters length.
	for(int i=NCOEFFS; i<(int)NTAPS; i++)
		tapvec[i] = 0;

	printf("Low-pass filter test\n");
	tb->testload(NTAPS, tapvec);

	{
		double fp,      // Passband frequency cutoff
			fs,     // Stopband frequency cutoff,
			depth,  // Depth of the stopband
			ripple; // Maximum deviation within the passband

		tb->measure_lowpass(fp, fs, depth, ripple);
		printf("FP     = %f\n", fp);
		printf("FS     = %f\n", fs);
		printf("DEPTH  = %6.2f dB\n", depth);
		printf("RIPPLE = %.2g\n", ripple);

		// The depth of this stopband should be between -55 and -54 dB
		assert(depth < -54);
		assert(depth > -55);
	}
#endif
	printf("SUCCESS\n");

	exit(0);
}

