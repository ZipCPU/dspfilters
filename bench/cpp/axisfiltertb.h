////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	axisfiltertb.h
// {{{
// Project:	DSP Filtering Example Project
//
// Purpose:	A generic downsampling/filter testbench class, based upon the
//		assumption that the filter follows the AXI stream specification
//	for data input and output.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
// }}}
// Copyright (C) 2021, Gisselquist Technology, LLC
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
#ifndef	AXISTREAMTB_H
#define	AXISTREAMTB_H

// #include "filtertb.h"

#ifndef	COMPLEX_H
#include <complex>
#define	COMPLEX_H
typedef	std::complex<double>	COMPLEX;
#endif

template <class VFLTR> class AXISTREAMTB : public TESTB<VFLTR> {
protected:
	int64_t	*m_hk;
	int	m_iw, m_ow, m_tw, m_ntaps;
	FILE	*result_fp;
public:
	int	IW(int k)	{ m_iw = k; return m_iw; }
	int	IW(void) const	{ return m_iw; }
	int	OW(int k)	{ m_ow = k; return m_ow; }
	int	OW(void) const	{ return m_ow; }
	int	TW(int k)	{ m_tw = k; return m_tw; }
	int	TW(void) const	{ return m_tw; }
	int	NTAPS(int k)	{ m_ntaps = k; return m_ntaps; }
	int  NTAPS(void) const	{ return m_ntaps; }
	void	tick(void);

	// reset() calls tick() with S_AXI_ARESETN low in order to reset the
	// filter
	void	reset(void);

	void	sync(void);

	// Apply a given test vector to the filter (no reset applied)
	bool	apply(int64_t input, int64_t &result);
	void	apply(int &nlen, int64_t *data);

	// Load values from the taps into the filter
	void	load(int  ntaps, int64_t *data);

	// Reset the filter, and apply a given test vector to the filter
	void	test(int  &nlen, int64_t *data);

	// The [] operator is used to "read-back" from the filter what it's
	// actual impulse is.  [0] should return the first value in that impulse
	// response--if all is set up well.  This will only work, however, for
	// an even input -> output rate filter.
	// int	operator[](const int tap);
	// void	testload(int nlen, int64_t *data);

	// Measure the filter's frequency response, across nfreq from 0 to the
	// Nyquist frequency.
	void	response(int nfreq,
		COMPLEX *rvec, double mag, const char *fname);

	// Some canned tests we can apply
	bool	test_overflow(void);

	void	measure_lowpass(double &fp, double &fs,
			double &depth, double &ripple);
};

#endif
