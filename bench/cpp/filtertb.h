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
#ifndef	FILTERTB_H
#define	FILTERTB_H

#ifndef	COMPLEX_H
#include <complex>
#define	COMPLEX_H
typedef	std::complex<double>	COMPLEX;
#endif

#define	FILTERTB_TEMPLATE template <class VA>
#define	FILTERTB_CLS	FILTERTB<VA>

// template <class VA, const int DELAY, const int IW, const int OW, const int TW, const int NTAPS>
FILTERTB_TEMPLATE class FILTERTB : public TESTB<VA> {
	int	*m_hk;
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
	int	IW(void) const    { return m_iw; }
	int	OW(void) const    { return m_ow; }
	int	TW(void) const    { return m_tw; }
	int	DELAY(void) const { return m_delay; }
	int	NTAPS(void) const { return m_ntaps; }
	int	CKPCE(void) const { return m_nclks; }

	int	IW(int k)    { m_iw = k;    return m_iw; }
	int	OW(int k)    { m_ow = k;    return m_ow; }
	int	TW(int k)    { m_tw = k;    return m_tw; }
	int	DELAY(int k) { m_delay = k; return m_delay; }
	int	NTAPS(int k) {
		m_ntaps = k;
		clear_cache();
		return m_ntaps;
	}
	int	CKPCE(int k) {
		m_nclks = k;
		if (m_nclks <= 1)
			m_nclks=1;
		return m_nclks;
	}

	void	clear_cache(void) {
		if (m_hk)
			delete[] m_hk;
		m_hk = NULL;
	}

	virtual	void	tick(void);
	virtual	void	reset(void);
	virtual	int	delay(void) const { return m_delay; };
	virtual	void	apply(int nlen, int *data);
	virtual	void	load(int  ntaps,  int *data);
	// load(const char *fname);
	virtual	void	test(int  nlen, int *data);
	virtual	void	testload(int  nlen, int *data);
	virtual	void	response(int nfreq, COMPLEX *response, double mag= 1.0);

	// Some tests we can apply
	bool	test_bibo(void);
	void	measure_lowpass(double &fp, double &fs, double &depth, double &ripple);
	// void	check_linearity

	int	operator[](const int tap);

	void	record_results(const char *fname) {
		result_fp = fopen(fname, "w");
	}
};

#endif
