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

static long	sbits(uint64_t val, int b) {
	long	s;

	s = (val << (sizeof(val)*8-b));
	s >>= (sizeof(val)*8-b);
	return	s;
}

static unsigned	long ubits(uint64_t val, int b) {
	return	val &= (1<<b)-1;
}

template<class VFLTR> void	FILTERTB<VFLTR>::tick(void) {
	bool	ce;
	long	vec[2];

	ce = (TESTB<VFLTR>::m_core->i_ce);
	vec[0] = sbits(TESTB<VFLTR>::m_core->i_sample, IW());

	TESTB<VFLTR>::tick();

	vec[1] = sbits(TESTB<VFLTR>::m_core->o_result, OW());

	if ((ce)&&(result_fp))
		fwrite(vec, sizeof(long), 2, result_fp);
}

template<class VFLTR> void	FILTERTB<VFLTR>::reset(void) {
	TESTB<VFLTR>::m_core->i_tap   = 0;
	TESTB<VFLTR>::m_core->i_sample= 0;
	TESTB<VFLTR>::m_core->i_ce    = 0;
	TESTB<VFLTR>::m_core->i_tap_wr= 0;

	TESTB<VFLTR>::reset();

	TESTB<VFLTR>::m_core->i_reset = 0;
}

template<class VFLTR> void	FILTERTB<VFLTR>::apply(int nlen, long *data) {
// printf("FILTERTB::apply(%d, ...)\n", nlen);
	TESTB<VFLTR>::m_core->i_reset  = 0;
	TESTB<VFLTR>::m_core->i_tap_wr = 0;
	TESTB<VFLTR>::m_core->i_ce     = 0;
	tick();
	for(int i=0; i<nlen; i++) {
		// Make sure the CE line is high
		TESTB<VFLTR>::m_core->i_ce     = 1;

		// Strip off any excess bits
		TESTB<VFLTR>::m_core->i_sample= ubits(data[i], IW());

		// Apply the filter
		tick();

		// Sign extend the result
		data[i] = sbits(TESTB<VFLTR>::m_core->o_result, OW());

		if (m_nclks > 1) {
			TESTB<VFLTR>::m_core->i_ce     = 0;
			for(int k=1; k<m_nclks; k++) {
				tick();
#ifdef	FILTER_HAS_O_CE
				if (TESTB<VFLTR>::m_core->o_ce)
					data[i] = sbits(TESTB<VFLTR>::m_core->o_result, OW());
#endif
			}
		}
	}
	TESTB<VFLTR>::m_core->i_ce     = 0;
}

template<class VFLTR> void	FILTERTB<VFLTR>::load(int  ntaps, long *data) {
	TESTB<VFLTR>::m_core->i_reset = 0;
	TESTB<VFLTR>::m_core->i_ce    = 0;
	TESTB<VFLTR>::m_core->i_tap_wr= 1;
	for(int i=0; i<ntaps; i++) {
		// Strip off any excess bits
		TESTB<VFLTR>::m_core->i_tap = ubits(data[i], TW());

		// Apply the filter
		tick();
	}
	TESTB<VFLTR>::m_core->i_tap_wr= 0;

	clear_cache();
}

template<class VFLTR> void	FILTERTB<VFLTR>::test(int  nlen, long *data) {
	const	bool	debug = false;
	assert(nlen > 0);

	reset();

	TESTB<VFLTR>::m_core->i_reset  = 0;
	TESTB<VFLTR>::m_core->i_tap_wr = 0;

	int	tstcounts = nlen+DELAY();
	for(int i=0; i<tstcounts; i++) {
		long	v;

		v = 0;
		TESTB<VFLTR>::m_core->i_ce = 1;

		// Strip off any excess bits
		if (i >= nlen)
			TESTB<VFLTR>::m_core->i_sample = 0;
		else
			TESTB<VFLTR>::m_core->i_sample = ubits(data[i], IW());

		if (debug) {
			printf("%c%3d, %3d, %d : Input :%10ld[%08lx] ", (i >= nlen)?'z':' ', i, DELAY(), nlen, sbits(TESTB<VFLTR>::m_core->i_sample,IW()),ubits(TESTB<VFLTR>::m_core->i_sample,IW()) );
			fflush(stdout);
		}

		// Apply the filter
		tick();

		// Sign extend the result
		v = TESTB<VFLTR>::m_core->o_result;

		// Deal with any filters requiring multiple clocks
		TESTB<VFLTR>::m_core->i_ce = 0;
		for(int k=1; k<m_nclks; k++) {
#ifdef	FILTER_HAS_O_CE
			if (TESTB<VFLTR>::m_core->o_ce)
				v = TESTB<VFLTR>::m_core->o_result;
#endif
			tick();
		}

		if (i >= DELAY()) {
			if (debug) printf("Read    :%12ld[%8lx]\n",
				sbits(v, OW()), v);
			data[i-DELAY()] = sbits(v, OW());
		} else if (debug)
			printf("Discard : %2ld\n", v);

	}
	TESTB<VFLTR>::m_core->i_ce = 0;
}

template<class VFLTR> int	FILTERTB<VFLTR>::operator[](const int tap) {

	if ((tap < 0)||(tap >= 2*NTAPS()))
		return 0;
	else if (!m_hk) {
		int	nlen = 2*NTAPS();
		m_hk = new long[nlen];

		// Create an input vector with a single impulse in it
		for(int i=0; i<nlen; i++)
			m_hk[i] = 0;
		m_hk[0] = -(1<<(IW()-1));

		// Apply the filter to the impulse vector
		test(nlen, m_hk);

		// Set our m_hk vector based upon the results
		for(int i=0; i<nlen; i++) {
			int	shift;
			shift = IW()-1;
			m_hk[i] >>= shift;
			m_hk[i] = -m_hk[i];
		}
	}

	return m_hk[tap];
}

template<class VFLTR> void	FILTERTB<VFLTR>::testload(int nlen, long *data) {
	bool	mismatch = false;
	load(nlen, data);
	reset();

	for(int k=0; k<nlen; k++) {
		int	m = (*this)[k];
		if (data[k] != m) {
			printf("Err: Data[%d] = %ld != (*this)[%d] = %d\n", k, data[k], k, m);
			mismatch = true;
		}
	}

	if (mismatch) {
		fflush(stdout);
		assert(!mismatch);
	}
	for(int k=nlen; k<2*DELAY(); k++)
		assert(0 == (*this)[k]);
}

template<class VFLTR> bool	FILTERTB<VFLTR>::test_overflow(void) {
	int	nlen = 2*NTAPS();
	long	*input  = new long[nlen],
		*output = new long[nlen];
	long	maxv = (1<<(IW()-1))-1;
	bool	pass = true, tested = false;

	// maxv = 1;

	for(int k=0; k<nlen; k++) {
		// input[v] * (*this)[(NTAPS-1)-v]
		if ((*this)[NTAPS()-1-k] < 0)
			input[k] = -maxv-1;
		else
			input[k] =  maxv;
		output[k]= input[k];
	}

	test(nlen, output);

	for(int k=0; k<nlen; k++) {
		long	acc = 0;
		bool	all = true;
		for(int v = 0; v<NTAPS(); v++) {
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

template<class VFLTR> void	FILTERTB<VFLTR>::response(int nfreq,
		COMPLEX *rvec, double mag, const char *fname) {
	int	nlen = NTAPS();
	long	*data = new long[nlen];
	double	df = 1./nfreq / 2.;
	COMPLEX	hk;
	const bool	debug= false;

	// Nh tap filter
	// Nv length vector
	// Nh+Nv-1 length output
	// But we want our output length to not include any runups
	//
	// Nh runup + Nv + Nh rundown + delay
	mag = mag * ((1<<(IW()-1))-1);

	for(int i=0; i<nfreq; i++) {
		double	dtheta = 2.0 * M_PI * i * df,
			theta=0.;
		hk = 0;

		if (debug)
			theta = 0.;
			for(int j=0; j<nlen; j++) {
				double	dv = cos(theta);
				real(hk) += dv * (*this)[j];
				theta -= dtheta;
			}

		theta = -(NTAPS()-1) * dtheta;
		for(int j=0; j<nlen; j++) {
			double	dv = mag * cos(theta);

			theta += dtheta;
			data[j] = dv;
		}

		test(nlen, data);
		real(rvec[i])  = data[nlen-1] / mag;

		// Repeat what should produce the same response, but using
		// a 90 degree phase offset.  Do this for all but the zero
		// frequency
		if (i > 0) {
			if (debug)
				theta = 0.;
				for(int j=0; j<2*nlen; j++) {
					double	dv = sin(theta);
					imag(hk) += dv * (*this)[j];
					theta -= dtheta;
				}

			theta = -(NTAPS()-1) * dtheta;
			for(int j=0; j<nlen; j++) {
				double	dv = mag * sin(theta);

				theta += dtheta;
				data[j] = dv;
			}

			test(nlen, data);
			imag(rvec[i])  = data[nlen-1] / mag;
		}

		if (debug)
			printf("RSP[%4d / %4d] = %10.2f+%10.2fj  // Expect %10.2f+%10.2fj\n",
				i, nfreq, real(rvec[i]), imag(rvec[i]),
				real(hk), imag(hk));
	}

	delete[] data;

	if (fname) {
		FILE* fp;
		fp = fopen(fname,"w");
		fwrite(rvec, sizeof(COMPLEX), nfreq, fp);
		fclose(fp);
	}
}

template<class VFLTR> void FILTERTB<VFLTR>::measure_lowpass(double &fp, double &fs,
			double &depth, double &ripple) {
	const	int	NLEN = 16*NTAPS();
	COMPLEX	*data = new COMPLEX[NLEN];
	double	*magv = new double[NLEN];
	double	dc, maxpass, minpass, maxstop;
	int	midcut;
	bool	passband_ripple = false;

	response(NLEN, data, 1.0, "filter_tb.dbl");

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
