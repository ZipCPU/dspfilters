////////////////////////////////////////////////////////////////////////////////
//
// Filename:	boxcar_fir.cpp
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
// Copyright (C) 2017-2018, Gisselquist Technology, LLC
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
#include "Vboxwrapper.h"
#include "testb.h"
#include "filtertb.h"
#include "filtertb.cpp"

const	unsigned	LGMEM = 6;
const	unsigned	NTAPS = (1ul<<LGMEM);
const	unsigned	IW    = 16;
const	unsigned	TW    = 2;
const	unsigned	OW    = IW+LGMEM;
const	unsigned	DELAY = 3; // NTAPS-1; // bits

#define	BASECLASS	Vboxwrapper
#define	PARENTTB	FILTERTB<BASECLASS>
class	BOXCAR_TB : public PARENTTB {
public:
	BOXCAR_TB(void) {
		IW(::IW);
		TW(::TW);
		OW(::OW);
		NTAPS(::NTAPS);
		DELAY(::DELAY);
	}

	void	reset(void) {
		PARENTTB::reset();
	}

	void	feed_rand(int nlen) {

		PARENTTB::m_core->i_reset  = 0;
		PARENTTB::m_core->i_tap_wr = 0;
		PARENTTB::m_core->i_ce     = 1;

		for(int k=0; k<nlen; k++) {
			int	s;

			s = rand() & ((1<<IW())-1);
			PARENTTB::m_core->i_sample = s;
			tick();
		}
	}

	void	feed_zeros(int nlen) {

		PARENTTB::m_core->i_reset  = 0;
		PARENTTB::m_core->i_tap_wr = 0;
		PARENTTB::m_core->i_ce     = 1;

		for(int k=0; k<nlen; k++) {
			PARENTTB::m_core->i_sample = 0;
			tick();
		}
	}

	void	apply(int nlen, int64_t *data) {
		PARENTTB::apply(nlen, data);
	}

	void	load(int nlen, int64_t *data) {
		PARENTTB::m_core->i_reset = 0;
		PARENTTB::m_core->i_ce    = 0;
		PARENTTB::m_core->i_tap_wr= 1;
		PARENTTB::m_core->i_sample= nlen;
		tick();
		PARENTTB::m_core->i_tap_wr= 0;

		PARENTTB::clear_cache();
	}

	void	testload(int nlen, int64_t *data) {
		load(nlen, data);

		for(int k=0; k<nlen; k++) {
			printf("[%3d] = %04x = %d\n", k, 
				(*this)[k], (*this)[k]);
			assert(1 == (*this)[k]);
		} printf("---\n");
		for(int k=nlen; k<2*DELAY(); k++) {
			printf("[%3d] = %04x = %d\n", k, 
				(*this)[k], (*this)[k]);
			assert(0 == (*this)[k]);
		}
	}

	bool	test_overflow(void) {
		return PARENTTB::test_overflow();
	}

	void	trace(const char *vcd_trace_file_name) {
		fprintf(stderr, "Opening TRACE(%s)\n", vcd_trace_file_name);
		opentrace(vcd_trace_file_name);
	}

	// void	record(const char *record_file_name);
};

BOXCAR_TB	*tb;

int	main(int argc, char **argv) {
	Verilated::commandArgs(argc, argv);
	tb = new BOXCAR_TB();
	// FILE	*dsp = fopen("dsp.64t", "w");

	tb->trace("boxcar.vcd");
	tb->reset();

	//
	// Block filter, impulse input
	//
	printf("Test #%3d /%3d\n", NTAPS+1, NTAPS+2);
	for(unsigned i=1; i<NTAPS; i++) {
		tb->testload(i, NULL);
		tb->test_overflow();
	}

	{
		// tb->testload(NTAPS-1, NULL);		//
		tb->testload(NTAPS/2, NULL);		//
		// tb->testload(4, NULL);		//

		// tb->record_results("boxcar.32t");

		double	fp, fs, depth, ripple;
		tb->measure_lowpass(fp, fs, depth, ripple);
		printf("FP     = %f\n", fp);
		printf("FS     = %f\n", fs);
		printf("DEPTH  = %6.2f dB\n", depth);
		printf("RIPPLE = %.2g\n", depth);
	}

	printf("TW     =%3d\n", tb->TW());
	printf("IW     =%3d\n", tb->IW());
	printf("OW     =%3d\n", tb->OW());
	printf("NTAPS  =%3d\n", tb->NTAPS());
	printf("DELAY  =%3d\n", tb->DELAY());

	printf("SUCCESS\n");

	// tb->close();
	exit(0);
}
