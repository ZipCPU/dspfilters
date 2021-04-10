////////////////////////////////////////////////////////////////////////////////
//
// Filename:	shalfband_tb.cpp
// {{{
// Project:	DSP Filtering Example Project
//
// Purpose:	Slow, half-band (or Hilbert) filter test.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
// }}}
// Copyright (C) 2018-2021, Gisselquist Technology, LLC
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
#include "Vshalfband.h"
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
const	unsigned	MIDP = (NTAPS-1)/2,
		QTRP = MIDP/2+1;
const	bool	OPT_HILBERT = false;

static	int     nextlg(int vl) {
	int     r;

	for(r=1; r<vl; r<<=1)
		;
	return r;
}

class	SHALFBAND_TB : public FILTERTB<Vshalfband> {
public:
	bool		m_done;

	SHALFBAND_TB(void) {
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
		FILTERTB<Vshalfband>::test(nlen, data);
	}

	void	load(int nlen, int64_t *data) {
		reset();
		FILTERTB<Vshalfband>::load(nlen, data);
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
		bool	debug = false;
		load(nlen, data);


		if (debug) {
			for(int k=0; k<2*NTAPS(); k++) {
				int	m = (*this)[k];

				if ((k&1)&&((unsigned)k<MIDP))
					printf("FIR[%3d] = %08x\n", k, m);
				else if ((unsigned)k < MIDP)
					printf("FIR[%3d] = %08x, LOAD[%3d/%d] = %08lx, MIDP=%d\n",
						k, m, (int)(k/2), nlen, data[k/2], MIDP);
				else if ((k<NTAPS())||(m != 0))
				printf("FIR[%3d] = %08x\n", k, m);
			}
		}

		for(int k=0; k<2*NTAPS(); k++) {
			int	m = (*this)[k];

			if ((k&1)&&((unsigned)k<MIDP))
				assert(m == 0);
			else if ((unsigned)k < MIDP)
				assert(data[k/2] == m);
			else if (k == MIDP)
				assert(m == (1<<(TW()-1))-1);
			else if ((k < NTAPS())&&(((k-MIDP)&1)==0))
				assert(m == 0);
			else if (k < NTAPS()) {
				if (OPT_HILBERT)
					assert(m == -data[((NTAPS()-1-k))/2]);
				else
					assert(m ==  data[((NTAPS()-1-k))/2]);
			} else
				assert(m == 0);
		}
        }

};

SHALFBAND_TB	*tb;

int	main(int argc, char **argv) {
	Verilated::commandArgs(argc, argv);
	tb = new SHALFBAND_TB();

	assert((NTAPS & 3)==3);
	const int64_t	TAPVALUE =  (1<<(TW-1))-1;
	// const long	IMPULSE  =  (1<<(IW-1))-1;

	int64_t	tapvec[NTAPS];
	// long	ivec[2*NTAPS];

	tb->opentrace("trace.vcd");
	tb->reset();

	printf("Impulse tests\n");
	for(unsigned k=0; k<NTAPS/4+1; k++) {
		//
		// Create a new coefficient vector
		//
		// Initialize it with all zeros
		for(unsigned i=0; i<QTRP; i++)
			tapvec[i] = 0;
		// Then set one value to non-zero
		tapvec[k] = TAPVALUE;

		// Test whether or not this coefficient vector
		// loads properly into the filter
		tb->testload(QTRP, tapvec);
//		tb->testload(NTAPS, tapvec);

		// Then test whether or not the filter overflows
		tb->test_overflow();
	}

#ifdef	HALFBAND
	if (!OPT_HILBERT) {
		assert(NCOEFFS <= NTAPS);
		for(int i=0; i<HALFCOEF; i++)
			tapvec[i] = halfcoef[i];

		// In case the filter is longer than the number of taps we have,
		// we'll load zero any taps beyond the filters length.
		for(int i=HALFCOEF; i<(int)NTAPS; i++)
			tapvec[i] = 0;

		assert(HALFCOEF == QTRP);

		printf("Low-pass filter test\n");
		tb->testload(QTRP, tapvec);

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
	}
#endif
	printf("SUCCESS\n");

	exit(0);
}

