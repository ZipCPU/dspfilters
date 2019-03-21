////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	twelvebfltr.h
//
// Project:	DSP Filtering Example Project
//
// Purpose:	Describe the coefficients of a half-band filter in terms that
//		are easily understandable within C/C++.  It is named a
//	twelve-bit filter since the coefficients are all sized to fit
//	within a twelve bit integer.
//
//	The filter started out with a stop-band of nearly 80dB.  That was
//	reduced due to truncation effects down to 50dB.  Sadly, I'm still
//	reviewing the literature to discover if an 80dB filter can even
//	be made of 12'bit integers.
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
#ifndef	TWELVEBFLTR_H
#define	TWELVEBFLTR_H

const int NDCOEF = 127;
const double	dcoeffs[NDCOEF] = {
	  -4.565423e-05,   0.000000e+00,   5.807274e-05,   0.000000e+00,
	  -9.387644e-05,   0.000000e+00,   1.431971e-04,   0.000000e+00,
	  -2.092803e-04,   0.000000e+00,   2.958316e-04,   0.000000e+00,
	  -4.070250e-04,   0.000000e+00,   5.475428e-04,   0.000000e+00,
	  -7.225928e-04,   0.000000e+00,   9.379540e-04,   0.000000e+00,
	  -1.200030e-03,   0.000000e+00,   1.515914e-03,   0.000000e+00,
	  -1.893517e-03,   0.000000e+00,   2.341714e-03,   0.000000e+00,
	  -2.870587e-03,   0.000000e+00,   3.491778e-03,   0.000000e+00,
	  -4.218988e-03,   0.000000e+00,   5.068737e-03,   0.000000e+00,
	  -6.061476e-03,   0.000000e+00,   7.223278e-03,   0.000000e+00,
	  -8.588452e-03,   0.000000e+00,   1.020368e-02,   0.000000e+00,
	  -1.213477e-02,   0.000000e+00,   1.447830e-02,   0.000000e+00,
	  -1.738249e-02,   0.000000e+00,   2.108737e-02,   0.000000e+00,
	  -2.600886e-02,   0.000000e+00,   3.293482e-02,   0.000000e+00,
	  -4.355716e-02,   0.000000e+00,   6.228094e-02,   0.000000e+00,
	  -1.052696e-01,   0.000000e+00,   3.180311e-01,   5.000000e-01,
	   3.180311e-01,   0.000000e+00,  -1.052696e-01,   0.000000e+00,
	   6.228094e-02,   0.000000e+00,  -4.355716e-02,   0.000000e+00,
	   3.293482e-02,   0.000000e+00,  -2.600886e-02,   0.000000e+00,
	   2.108737e-02,   0.000000e+00,  -1.738249e-02,   0.000000e+00,
	   1.447830e-02,   0.000000e+00,  -1.213477e-02,   0.000000e+00,
	   1.020368e-02,   0.000000e+00,  -8.588452e-03,   0.000000e+00,
	   7.223278e-03,   0.000000e+00,  -6.061476e-03,   0.000000e+00,
	   5.068737e-03,   0.000000e+00,  -4.218988e-03,   0.000000e+00,
	   3.491778e-03,   0.000000e+00,  -2.870587e-03,   0.000000e+00,
	   2.341714e-03,   0.000000e+00,  -1.893517e-03,   0.000000e+00,
	   1.515914e-03,   0.000000e+00,  -1.200030e-03,   0.000000e+00,
	   9.379540e-04,   0.000000e+00,  -7.225928e-04,   0.000000e+00,
	   5.475428e-04,   0.000000e+00,  -4.070250e-04,   0.000000e+00,
	   2.958316e-04,   0.000000e+00,  -2.092803e-04,   0.000000e+00,
	   1.431971e-04,   0.000000e+00,  -9.387644e-05,   0.000000e+00,
	   5.807274e-05,   0.000000e+00,  -4.565423e-05
};
const int NCOEFFS = 107; // 127
const	int	icoeffs[NCOEFFS] = {
	     1,     0,    -1,     0,     2,     0,    -2,     0,
	     3,     0,    -4,     0,     6,     0,    -7,     0,
	     9,     0,   -11,     0,    14,     0,   -17,     0,
	    20,     0,   -24,     0,    29,     0,   -35,     0,
	    41,     0,   -49,     0,    59,     0,   -71,     0,
	    86,     0,  -106,     0,   134,     0,  -178,     0,
	   254,     0,  -430,     0,  1302,  2047,  1302,     0,
	  -430,     0,   254,     0,  -178,     0,   134,     0,
	  -106,     0,    86,     0,   -71,     0,    59,     0,
	   -49,     0,    41,     0,   -35,     0,    29,     0,
	   -24,     0,    20,     0,   -17,     0,    14,     0,
	   -11,     0,     9,     0,    -7,     0,     6,     0,
	    -4,     0,     3,     0,    -2,     0,     2,     0,
	    -1,     0,     1
};


#define SYMMETRIC

const int SYMCOEF = 53;
const	int	symcoeffs[SYMCOEF] = {
	     1,     0,    -1,     0,     2,     0,    -2,     0,
	     3,     0,    -4,     0,     6,     0,    -7,     0,
	     9,     0,   -11,     0,    14,     0,   -17,     0,
	    20,     0,   -24,     0,    29,     0,   -35,     0,
	    41,     0,   -49,     0,    59,     0,   -71,     0,
	    86,     0,  -106,     0,   134,     0,  -178,     0,
	   254,     0,  -430,     0,  1302 //,  2047
};


#define	HALFBAND
#define	MBAND	2

const int HALFCOEF = 27;
const	int	halfcoef[HALFCOEF] = {
	     1,    -1,     2,    -2,     3,    -4,     6,    -7,
	     9,   -11,    14,   -17,    20,   -24,    29,   -35,
	    41,   -49,    59,   -71,    86,  -106,   134,  -178,
	   254,  -430,  1302 //,   2047
};
// 127: 10 - 116
#endif	// TWELVEBFLTR_H
