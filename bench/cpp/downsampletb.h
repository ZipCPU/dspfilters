////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	downsampletb.h
// {{{
// Project:	DSP Filtering Example Project
//
// Purpose:	A generic downsampling/filter testbench class
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
#ifndef	DOWNSAMPLETB_H
#define	DOWNSAMPLETB_H

#include "filtertb.h"

template <class VFLTR> class DOWNSAMPLETB : public FILTERTB<VFLTR> {
	int	m_ndown;
public:
	int	IW(int k)	{ return FILTERTB<VFLTR>::IW(k); }
	int	IW(void) const	{ return FILTERTB<VFLTR>::IW(); }
	int	OW(int k)	{ return FILTERTB<VFLTR>::OW(k); }
	int	OW(void) const	{ return FILTERTB<VFLTR>::OW(); }
	int	TW(int k)	{ return FILTERTB<VFLTR>::TW(k); }
	int	TW(void) const	{ return FILTERTB<VFLTR>::TW(); }
	int	NTAPS(int k)	{ return FILTERTB<VFLTR>::NTAPS(k); }
	int  NTAPS(void) const	{ return FILTERTB<VFLTR>::NTAPS(); }
	int	NDOWN(int k)	{ return m_ndown = k; }
	int  NDOWN(void) const	{ return m_ndown; }
	void	tick(void);
	void	reset(void);
	void	sync(void);
	void	apply(int &nlen, int64_t *data);
	void	load(int  ntaps, int64_t *data);
	void	test(int  &nlen, int64_t *data);
	int	operator[](const int tap);
	void	testload(int nlen, int64_t *data);
	bool	test_overflow(void);
	void	response(int nfreq,
		COMPLEX *rvec, double mag, const char *fname);

	void	measure_lowpass(double &fp, double &fs,
			double &depth, double &ripple);
};

#endif
