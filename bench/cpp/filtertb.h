////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	filtertb.h
//
// Project:	DSP Filtering Example Project
//
// Purpose:	A generic filter testbench class
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2017-2019, Gisselquist Technology, LLC
//
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
//
// License:	LGPL, v3, as defined and found on www.gnu.org,
//		http://www.gnu.org/licenses/lgpl.html
//
////////////////////////////////////////////////////////////////////////////////
//
//
#ifndef	FILTERTB_H
#define	FILTERTB_H

#include <stdint.h>

#ifndef	COMPLEX_H
#include <complex>
#define	COMPLEX_H
typedef	std::complex<double>	COMPLEX;
#endif

template <class VFLTR> class FILTERTB : public TESTB<VFLTR> {
protected:
	int64_t	*m_hk;
	int	m_delay, m_iw, m_ow, m_tw, m_ntaps, m_nclks;
	FILE	*result_fp;
public:
	FILTERTB(void) {
		m_hk = NULL;
		m_delay = 2;
		m_iw    = 16;
		m_ow    = 16;
		m_tw    = 12;
		m_ntaps = 128;
		m_nclks = 1;
		result_fp = NULL;
	}

	// Handle setting and clearing the various properties concerning
	// our filter.  This doesn't actually change the filter, it just
	// let's the TB code know what those properties are.

	// There's the number of bits allocated to the input sample, IW
	int	IW(int k)    { m_iw = k;    return m_iw; }
	int	IW(void) const    { return m_iw; }

	// The number of bits allocated to output samples, OW
	int	OW(void) const    { return m_ow; }
	int	OW(int k)    { m_ow = k;    return m_ow; }

	// The number of bits allocated to each tap, TW
	int	TW(void) const    { return m_tw; }
	int	TW(int k)    { m_tw = k;    return m_tw; }

	// The number of samples delay between when an impulse enters the
	// filter, and when the first value returns from it.
	int	DELAY(void) const { return m_delay; }
	int	DELAY(int k) { m_delay = k; return m_delay; }

	// Slower filters may require multiple clocks between each global CE,
	// i_ce.  We'll keep track of that in the CKPCE parameter.
	int	CKPCE(void) const { return m_nclks; }
	int	CKPCE(int k) {
		m_nclks = k;
		if (m_nclks <= 1)
			m_nclks=1;
		return m_nclks;
	}

	// The number of taps in this filter.  This is useful to know
	// how many samples following an impulse need to be examined.
	int	NTAPS(void) const { return m_ntaps; }
	// If this ever changes (ex., our moving average filter), then we'll
	// need to clear any estimate we have of what the filter's response is.
	int	NTAPS(int k) {
		m_ntaps = k;
		clear_cache();
		return m_ntaps;
	}

	// tick() steps the clock forward by one step, recording state
	// information to a VCD file (or more) as necessary.
	virtual	void	tick(void);

	// Open a file so that, upon each tick, results can be written to it
	// for later examination.
	void	record_results(const char *fname) {
		result_fp = fopen(fname, "w");
	}

	// reset() calls tick() with i_reset high in order to reset the filter
	virtual	void	reset(void);

	// Load values from taps into the filter.
	virtual	void	load(int  ntaps,  int64_t *data);

	// Apply a given test vector to the filter (no reset applied)
	virtual	void	apply(int nlen, int64_t *data);

	// Reset the filter, and apply a given test vector to the filter
	virtual	void	test(int  nlen, int64_t *data);

	// Load the taps into the filter, and then compare the taps against
	// the impulse response that results.
	virtual	void	testload(int  nlen, int64_t *data);

	// The [] operator is used to "read-back" from the filter what it's
	// actual impulse response is.  [0] should return the first value in
	// that impulse response--if all is set up well.
	int	operator[](const int tap);
	// Since so many things depend upon the filter's impulse response,
	// we'll calculate it once and cache it.  If things ever change,
	// we'll need to come back and reload the cache.  Here, we let the
	// harness know that the cache needs to be rebuilt.
	void	clear_cache(void) {
		if (m_hk)
			delete[] m_hk;
		m_hk = NULL;
	}

	// Measure the filter's frequency response, across nfreq from 0 to
	// the Nyquist frequency.
	virtual	void	response(int nfreq, COMPLEX *response, double mag= 1.0,
				const char *fname = NULL);

	// Some canned tests we can apply
	bool	test_overflow(void);
	void	measure_lowpass(double &fp, double &fs, double &depth, double &ripple);
};

#endif
