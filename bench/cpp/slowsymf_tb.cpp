////////////////////////////////////////////////////////////////////////////////
//
// Filename:	slowsymf_tb.cpp
//
// Project:	DSP Filtering Example Project
//
// Purpose:	A generic filter testing module to test a symmetric filter
//		that takes many clock cycles per CE.  It's used for testing
//	the slowsymf.v filter.  Tests include making certain that impulses
//	do what they should, that a block filter has the proper impulse response
//	and unit response.  The final test verifies whether a nice high quality
//	lowpass filter works as intended.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2018, Gisselquist Technology, LLC
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
#include <signal.h>
#include <time.h>
#include <ctype.h>
#include <string.h>
#include <stdint.h>
#include <assert.h>

#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vslowsymf.h"
#include "testb.h"

// #define	FILTER_HAS_O_CE
#include "filtertb.h"
#include "filtertb.cpp"
#include "twelvebfltr.h"

const	unsigned IW = 16,
		TW = 12,
		OW = IW+TW+7,
		NTAPS = 107,
		DELAY = 2,
		CKPCE = (NTAPS-1)/2+3;
const	unsigned	MIDP = (NTAPS-1)/2;

static	int     nextlg(int vl) {
	int     r;

	for(r=1; r<vl; r<<=1)
		;
	return r;
}

class	SLOWSYMF_TB : public FILTERTB<Vslowsymf> {
public:
	bool		m_done;

	SLOWSYMF_TB(void) {
		IW(::IW);
		TW(::TW);
		OW(::OW);
		NTAPS(::NTAPS);
		DELAY(::DELAY);
		CKPCE(::CKPCE);
		// NTAPS(odd(::NTAPS));
	}

	int	odd(int v) {
		int ov = v;
		ov = ((v-1)&(-2))+1;
printf("ODD of %d is %d\n", v, ov);
		return ov;
	}
	void	test(int nlen, int64_t *data) {
		clear_filter();
		FILTERTB<Vslowsymf>::test(nlen, data);
	}

	void	load(int nlen, int64_t *data) {
		reset();
		FILTERTB<Vslowsymf>::load(nlen, data);
	}

	void	clear_filter(void) {
		m_core->i_tap_wr = 0;

		// This filter requires running NTAPS worth of data through
		// it to fully clear it.  The reset isn't sufficient.
		m_core->i_ce     = 1;
		m_core->i_sample = 0;
		for(int k=0; k<nextlg(NTAPS()); k++)
			tick();

		m_core->i_ce = 0;
		for(int k=0; k<CKPCE(); k++)
			tick();
	}

        void    testload(int nlen, int64_t *data) {
		load(nlen, data);


		for(int k=0; k<2*NTAPS(); k++) {
			int	m = (*this)[k];

			if ((unsigned)k < MIDP)
				assert(data[k] == m);
			else if (k == MIDP)
				assert(m == (1<<(TW()-1))-1);
			else if (k < NTAPS())
				assert(m == data[NTAPS()-1-k]);
			else
				assert(m == 0);
		}
        }

};

SLOWSYMF_TB	*tb;

int	main(int argc, char **argv) {
	Verilated::commandArgs(argc, argv);
	tb = new SLOWSYMF_TB();

	const int64_t	TAPVALUE =  (1<<(TW-1))-1;
	const int64_t	IMPULSE  =  (1<<(IW-1))-1;

	int64_t	tapvec[NTAPS];
	int64_t	ivec[2*NTAPS];

	// tb->opentrace("trace.vcd");
	tb->reset();

	printf("Impulse tests\n");
	for(unsigned k=0; k<NTAPS/2+1; k++) {
		//
		// Create a new coefficient vector
		//
		// Initialize it with all zeros
		for(unsigned i=0; i<MIDP; i++)
			tapvec[i] = 0;
		// Then set one value to non-zero
		tapvec[k] = TAPVALUE;

		// Test whether or not this coefficient vector
		// loads properly into the filter
		tb->testload(MIDP, tapvec);

		// Then test whether or not the filter overflows
		tb->test_overflow();
	}

	printf("Block Fil, Impulse input\n");

	//
	// Block filter, impulse input
	//
	for(unsigned i=0; i<MIDP; i++)
		tapvec[i] = TAPVALUE;

	tb->testload(MIDP, tapvec);

	for(unsigned i=0; i<2*NTAPS; i++)
		ivec[i] = 0;
	ivec[0] = IMPULSE;

	tb->test(2*NTAPS, ivec);

	for(unsigned i=0; i<NTAPS; i++)
		assert(ivec[i] == IMPULSE * TAPVALUE);
	for(unsigned i=NTAPS; i<2*NTAPS; i++)
		assert(0 == ivec[i]);

	//
	//
	// Block filter, block input
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

#ifdef	SYMMETRIC
	assert(NCOEFFS <= NTAPS);
	for(int i=0; i<SYMCOEF; i++)
		tapvec[i] = symcoeffs[i];

	// In case the filter is longer than the number of taps we have,
	// we'll load zero any taps beyond the filters length.
	for(int i=SYMCOEF; i<(int)NTAPS; i++)
		tapvec[i] = 0;

	printf("Low-pass filter test\n");
	tb->testload(MIDP, tapvec);

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

