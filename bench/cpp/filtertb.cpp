////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	filtertb.cpp
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
#include "filtertb.h"

FILTERTB_TEMPLATE void	FILTERTB_CLS::tick(void) { TESTB<VA>::tick(); }
FILTERTB_TEMPLATE void	FILTERTB_CLS::reset(void) {
	TESTB<VA>::m_core->i_tap   = 0;
	TESTB<VA>::m_core->i_sample= 0;
	TESTB<VA>::m_core->i_ce    = 0;
	TESTB<VA>::m_core->i_tap_wr= 0;

	TESTB<VA>::reset();

	TESTB<VA>::m_core->i_reset = 0;
}

FILTERTB_TEMPLATE void	FILTERTB_CLS::apply(int nlen, int *data) {
	TESTB<VA>::m_core->i_reset  = 0;
	TESTB<VA>::m_core->i_tap_wr = 0;
	TESTB<VA>::m_core->i_ce     = 1;
	for(int i=0; i<nlen; i++) {
		int	v;

		// Strip off any excess bits
		v = data[i];
		v &= (1<<IW)-1;
		TESTB<VA>::m_core->i_sample= v;

		// Apply the filter
		tick();

		v = TESTB<VA>::m_core->o_result;
		// Sign extend the result
		v <<= (8*sizeof(v)-OW);
		v >>= (8*sizeof(v)-OW);
		data[i] = v;
	}
	TESTB<VA>::m_core->i_ce     = 0;
}

FILTERTB_TEMPLATE void	FILTERTB_CLS::load(int  ntaps,  int *data) {
	TESTB<VA>::m_core->i_reset = 0;
	TESTB<VA>::m_core->i_ce    = 0;
	TESTB<VA>::m_core->i_tap_wr= 1;
	for(int i=0; i<ntaps; i++) {
		int	v;

		// Strip off any excess bits
		v = data[i];
		v &= (1<<TW)-1;
		TESTB<VA>::m_core->i_tap = v;

		// Apply the filter
		tick();
	}
	TESTB<VA>::m_core->i_tap_wr= 0;

	if (m_hk)
		delete[] m_hk;
	m_hk = NULL;
}

FILTERTB_TEMPLATE void	FILTERTB_CLS::test(int  nlen, int *data) {
	const	bool	debug = false;
	assert(nlen > 0);

	reset();

	TESTB<VA>::m_core->i_reset  = 0;
	TESTB<VA>::m_core->i_tap_wr = 0;
	TESTB<VA>::m_core->i_tap    = 0;
	TESTB<VA>::m_core->i_ce = 1;
	
	for(int i=0; i<nlen+DELAY; i++) {
		int	v;

		// Strip off any excess bits
		if (i >= nlen)
			TESTB<VA>::m_core->i_sample = v = 0;
		else {
			v = data[i];
			v &= (1<<IW)-1;
			TESTB<VA>::m_core->i_sample = v;
		}

		if (debug)
			printf("%3d, %3d, %d : Input : %5d[%6x] ", i, DELAY, nlen, v,v );

		// Apply the filter
		tick();

		v = TESTB<VA>::m_core->o_result;
		// Sign extend the result
		v <<= (8*sizeof(v)-OW);
		v >>= (8*sizeof(v)-OW);

		if (i >= DELAY) {
			if (debug) printf("Read    :%8d[%8x]\n", v, v);
			data[i-DELAY] = v;
		} else if (debug)
			printf("Discard : %2d\n", v);
	}
	TESTB<VA>::m_core->i_ce = 0;
}

FILTERTB_TEMPLATE void	FILTERTB_CLS::response(int nfreq,
		COMPLEX *rvec, double mag) {
	int	nlen = NTAPS;
	int	*data = new int[nlen+DELAY+NTAPS];

	mag = mag * ((1<<(IW-1))-1);

	for(int i=0; i<nfreq; i++) {
		double	dtheta = 2.0 * M_PI * i / (double)nfreq / 2.0,
			theta=0.;
		COMPLEX	acc = 0.;

		theta = 0;
		for(int j=NTAPS; j<nlen+DELAY+NTAPS; j++) {
			double	dv = mag * cos(theta);

			theta += dtheta;
			data[j] = dv;
		}

		theta = -dtheta;
		for(int j=NTAPS-1; j>= 0; j--) {
			double	dv = mag * cos(theta);

			theta -= dtheta;
			data[j] = dv;
		}

		apply(nlen+DELAY+NTAPS, data);

		theta = 0.0;
		for(int j=0; j<nlen; j++) {
			double	cs = cos(theta) / mag,
				sn = sin(theta) / mag;

			theta -= dtheta;

			real(acc) += cs * data[j+NTAPS+DELAY];
			imag(acc) += sn * data[j+NTAPS+DELAY];
		}

		// Repeat what should produce the same response, but using
		// a 90 degree phase offset.  Do this for all but the zero
		// frequency
		if (i > 0) {
			theta = 0.0;
			for(int j=NTAPS; j<nlen+DELAY+NTAPS; j++) {
				double	dv = mag * sin(theta);

				theta += dtheta;
				data[j] = dv;
			}

			theta = -dtheta;
			for(int j=NTAPS-1; j>=0; j--) {
				double	dv = mag * sin(theta);

				theta -= dtheta;
				data[j] = dv;
			}

			apply(nlen+DELAY+NTAPS, data);

			theta = 0.0;
			for(int j=0; j<nlen; j++) {
				double	cs = cos(theta) / mag,
					sn = sin(theta) / mag;

				theta -= dtheta;

				real(acc) += sn * data[j+NTAPS+DELAY];
				imag(acc) += cs * data[j+NTAPS+DELAY];
			}

		} rvec[i] = acc * (1./ nlen);

		printf("RSP[%4d / %4d] = %10.1f + %10.1f\n",
			i, nfreq, real(acc), imag(acc));
	}

	delete[] data;

	{
		FILE* fp;
		fp = fopen("filter_tb.dbl","w");
		fwrite(rvec, sizeof(COMPLEX), nfreq, fp);
		fclose(fp);
	}
}

FILTERTB_TEMPLATE int	FILTERTB_CLS::operator[](const int tap) {

	if ((tap < 0)||(tap >= 2*NTAPS))
		return 0;
	else if (!m_hk) {
		int	nlen = 2*NTAPS;
		m_hk = new int[nlen];

		for(int i=0; i<nlen; i++)
			m_hk[i] = 0;
		m_hk[0] = -(1<<(IW-2));

		test(nlen, m_hk);

		for(int i=0; i<nlen; i++) {
			int	shift;
			shift = IW-2;
			m_hk[i] >>= shift;
			m_hk[i] = -m_hk[i];
		}
	}

	// if (m_hk[tap] != 0) printf("Hk[%4d] = %8d\n", tap, m_hk[tap]);
	return m_hk[tap];
}

FILTERTB_TEMPLATE void	FILTERTB_CLS::testload(int nlen, int *data) {
	load(nlen, data);
	reset();

	for(int k=0; k<nlen; k++) {
		int	m = (*this)[k];
		if (data[k] != m)
			printf("Data[k] = %d != (*this)[k] = %d\n", data[k], m);
		assert(data[k] == m);
	}
	for(int k=nlen; k<2*DELAY; k++)
		assert(0 == (*this)[k]);
}

FILTERTB_TEMPLATE bool	FILTERTB_CLS::test_bibo(void) {
	int	nlen = 2*NTAPS;
	int	*input  = new int[nlen],
		*output = new int[nlen];
	int	maxv = (1<<(IW-1))-1;
	bool	pass = true, tested = false;

	// maxv = 1;
printf("TESTING-BIBO\n");

	for(int k=0; k<nlen; k++) {
		// input[v] * (*this)[(NTAPS-1)-v]
		if ((*this)[NTAPS-1-k] < 0)
			input[k] = -maxv;
		else
			input[k] =  maxv;
		output[k]= input[k];
	}

	test(nlen, output);

	for(int k=0; k<nlen; k++) {
		long	acc = 0;
		bool	all = true;
		for(int v = 0; v<NTAPS; v++) {
			if (k-v >= 0) {
				acc += input[k-v] * (*this)[v];
				if (acc < 0)
					all = false;
			} else
				all = false;
		}

		if (all)
			tested = true;

		pass = (pass)&&(output[k] == acc);
		assert(output[k] == acc);
	}

	delete[] input;
	delete[] output;
	return (pass)&&(tested);
}

FILTERTB_TEMPLATE void	FILTERTB_CLS::measure_lowpass(double &fp, double &fs,
			double &depth, double &ripple) {
	const	int	NLEN = 16*NTAPS;
	COMPLEX	*data = new COMPLEX[NLEN];
	double	*magv = new double[NLEN];
	double	dc, maxpass, minpass, maxstop;
	int	midcut;
	bool	passband_ripple = false;

	response(NLEN, data);

	for(int k=0; k<NLEN; k++) {
		magv[k]= norm(data[k]);
	}

	midcut = NLEN-1;
	dc = magv[0];
	for(int k=0; k<NLEN; k++)
		if (magv[k] < 0.25 * dc) {
			midcut = k;
			break;
		}
	maxpass = dc;
	minpass = dc;
	for(int k=midcut; k>= 0; k--)
		if (magv[k] > maxpass)
			maxpass = magv[k];
	for(int k=midcut; k>= 0; k--)
		if ((magv[k] < minpass)&&(magv[k+1] > magv[k])) {
			minpass = magv[k];
			passband_ripple = true;
		}
	if (!passband_ripple)
		minpass = maxpass / sqrt(2.0);
	for(int k=midcut; k>= 0; k--)
		if (magv[k] > minpass) {
			fp = k;
			break;
		}

	maxstop = magv[NLEN-1];
	for(int k=midcut; k<NLEN; k++)
		if ((fabs(magv[k]) > fabs(magv[k-1]))&&(fabs(magv[k])> maxstop))
			maxstop = fabs(magv[k]);
	for(int k=midcut; k<NLEN; k++)
		if (magv[k] <= maxstop) {
			fs = k;
			break;
		}

printf("MAXPASS= %f\n", maxpass);
printf("MINPASS= %f\n", minpass);
printf("FP     = %f\n", fp);
printf("FS     = %f\n", fs);
printf("DC     = %f\n", dc);
printf("--------\n");

	ripple = 2.0 * (maxpass - minpass)/(maxpass + minpass);
	depth  = 10.0*log(maxstop/dc)/log(10.0);
	fs = fs / NLEN / 2.;
	fp = fp / NLEN / 2.;
	delete[]	data;
}
