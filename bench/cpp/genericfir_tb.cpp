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
#include <complex>
#include <assert.h>

#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vgenericfir.h"
#include "testb.h"
#include "filtertb.h"
#include "filtertb.cpp"

const	unsigned	NTAPS = 128;
const	unsigned	IW = 12;
const	unsigned	TW = IW;
const	unsigned	OW = IW+TW+7;
const	unsigned	DELAY= NTAPS; // bits

#define	BASECLASS	Vgenericfir
class	GENERICFIR_TB : public FILTERTB<BASECLASS> {
public:
	GENERICFIR_TB(void) {
		IW(::IW);
		OW(::OW);
		TW(::TW);
		NTAPS(::NTAPS);
		DELAY(::DELAY);
	}

	void	reset(void) {
		FILTERTB<BASECLASS>::reset();
	}

	void	apply(int nlen, int *data) {
		FILTERTB<BASECLASS>::apply(nlen, data);
	}

	void	testload(int nlen, int *data) {
		FILTERTB<BASECLASS>::testload(nlen, data);
	}

	bool	test_overflow(void) {
		return FILTERTB<BASECLASS>::test_overflow();
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
	// FILE	*dsp = fopen("dsp.64t", "w");

	const int	TAPVALUE = -(1<<(IW-1));
	const int	IMPULSE  = (1<<(IW-1))-1;

	int	tapvec[NTAPS];
	int	ivec[2*NTAPS];

	// tb->trace("trace.vcd");
	tb->reset();

	for(unsigned k=0; k<NTAPS; k++) {
		printf("Test #%3d /%3d\n", k+1, NTAPS);
		//
		// Load a new set of taps
		//
		for(unsigned i=0; i<NTAPS; i++)
			tapvec[i] = 0;
		tapvec[k] = TAPVALUE;

		tb->testload(NTAPS, tapvec);

		tb->test_overflow();
	}

	//
	// Block filter, impulse input
	//
	printf("Test #%3d /%3d\n", NTAPS+1, NTAPS+2);
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
	printf("Test #%3d /%3d\n", NTAPS+2, NTAPS+2);

	for(unsigned i=0; i<2*NTAPS; i++)
		ivec[i] = IMPULSE;

	tb->test(2*NTAPS, ivec);

	for(unsigned i=0; i<NTAPS; i++)
		assert(ivec[i] == ((int)i+1)*IMPULSE*TAPVALUE);

	assert(tb->test_overflow());

	{
		double fp, fs, depth, ripple;
		tb->measure_lowpass(fp, fs, depth, ripple);
		printf("FP     = %f\n", fp);
		printf("FS     = %f\n", fs);
		printf("DEPTH  = %6.2f dB\n", depth);
		printf("RIPPLE = %.2g\n", ripple);
	}

	printf("%d tests accomplished\nSUCCESS\n", NTAPS+3);

	// tb->close();
	exit(0);
}

