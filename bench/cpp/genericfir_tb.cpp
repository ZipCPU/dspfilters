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
#include "Vgenericfir.h"
#include "testb.h"
#include "filtertb.h"
#include "filtertb.cpp"
#include "twelvebfltr.h"

const	unsigned	NTAPS = 128;
const	unsigned	IW   = 12; // bits
const	unsigned	TW   = IW; // bits
const	unsigned	OW = IW+TW+7;
const	unsigned	DELAY= NTAPS; // bits

class	GENERICFIR_TB : public FILTERTB<Vgenericfir> {
public:
	GENERICFIR_TB(void) {
		TW(::TW);
		IW(::IW);
		OW(::OW);
		NTAPS(::NTAPS);
		DELAY(::DELAY);
	}


	void	trace(const char *vcd_trace_file_name) {
		fprintf(stderr, "Opening TRACE(%s)\n", vcd_trace_file_name);
		opentrace(vcd_trace_file_name);
	}
};

GENERICFIR_TB	*tb;

int	main(int argc, char **argv) {
	Verilated::commandArgs(argc, argv);
	tb = new GENERICFIR_TB();

	const int	TAPVALUE = -(1<<(TW-1));
	const long	IMPULSE  =  (1<<(IW-1))-1;

	long	tapvec[NTAPS];
	long	ivec[2*NTAPS];

	// tb->trace("trace.vcd");
	tb->reset();

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
		tb->test_overflow();
	}

	//
	// Block filter, impulse input
	//
	for(unsigned i=0; i<NTAPS; i++)
		tapvec[i] = TAPVALUE;

	tb->testload(NTAPS, tapvec);

	for(unsigned i=0; i<2*NTAPS; i++)
		ivec[i] = 0;
	ivec[0] = IMPULSE;

	tb->test(2*NTAPS, ivec);

	for(unsigned i=0; i<NTAPS; i++)
		assert(ivec[i] == IMPULSE * TAPVALUE);

	//
	//
	// Block filter, block input
	// Set every element of an array to the same value
	for(unsigned i=0; i<2*NTAPS; i++)
		ivec[i] = IMPULSE;

	// Now apply this vector to the filter
	tb->test(2*NTAPS, ivec);

	// And check that it has the right response
	for(unsigned i=0; i<NTAPS; i++)
		assert(ivec[i] == (i+1)*IMPULSE*TAPVALUE);

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

	assert(NCOEFFS < NTAPS);
	for(int i=0; i<NCOEFFS; i++)
		tapvec[i] = icoeffs[i];

	// In case the filter is longer than the number of taps we have,
	// we'll load zero any taps beyond the filters length.
	for(int i=NCOEFFS; i<(int)NTAPS; i++)
		tapvec[i] = 0;

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
	printf("SUCCESS\n");

	exit(0);
}

