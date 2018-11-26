###############################################################################
##
## Filename:	Makefile
##
## Project:	DSP Filtering Example Project
##
## Purpose:	This is the master project makefile, building simulation
##		components for all of the cores that exist in bench/cpp.
##
## Targets:	The default target, all, builds all subdirectory targets.
##
## Creator:	Dan Gisselquist, Ph.D.
##		Gisselquist Technology, LLC
##
################################################################################
##
## Copyright (C) 2018, Gisselquist Technology, LLC
##
## This file is part of the DSP filtering set of designs.
##
## The DSP filtering designs are free RTL designs: you can redistribute them
## and/or modify any of them under the terms of the GNU Lesser General Public
## License as published by the Free Software Foundation, either version 3 of
## the License, or (at your option) any later version.
##
## The DSP filtering designs are distributed in the hope that they will be
## useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTIBILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
## General Public License for more details.
##
## You should have received a copy of the GNU Lesser General Public License
## along with these designs.  (It's in the $(ROOT)/doc directory.  Run make
## with no target there if the PDF file isn't present.)  If not, see
## <http://www.gnu.org/licenses/> for a copy.
##
## License:	LGPL, v3, as defined and found on www.gnu.org,
##		http://www.gnu.org/licenses/lgpl.html
##
################################################################################
##
##
all: benchcpp
SUBMAKE := make --no-print-directory -C

rtld:
	$(SUBMAKE) rtl

benchrtl: rtld
	$(SUBMAKE) bench/rtl

benchcpp: benchrtl rtl
	$(SUBMAKE) bench/cpp

formal: rtld
	$(SUBMAKE) formal

clean:
	$(SUBMAKE) rtl       clean
	$(SUBMAKE) bench/rtl clean
	$(SUBMAKE) bench/cpp clean
