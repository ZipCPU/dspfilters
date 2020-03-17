################################################################################
##
## Filename:	Makefile
##
## Project:	DSP Filtering Example Project
##
## Purpose:	To direct the formal verification of the some of the
##		rtl (not all).
##
## Targets:	The default target, all, tests all of the components with
##		formal validation statements.
##
## Creator:	Dan Gisselquist, Ph.D.
##		Gisselquist Technology, LLC
##
################################################################################
##
## Copyright (C) 2017-2019, Gisselquist Technology, LLC
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
TESTS := lfsr lfsr_equiv fastfir histogram cheapspectral # boxcar
.PHONY: $(TESTS)
all: $(TESTS)
RTL := ../../rtl

LFSR=lfsr
EQUIV=lfsr_equiv
DELAY=delayw
FFIR=fastfir
HIST=histogram
BCAR=boxcar
SPECTRAL=cheapspectral

SMTBMC  := yosys-smtbmc
# SOLVER  := -s z3
SOLVER  := -s yices
# BMCARGS := --presat $(SOLVER)
BMCARGS := $(SOLVER)
INDARGS := $(SOLVER) -i

$(EQUIV).smt2: $(EQUIV).v $(RTL)/lfsr_fib.v $(RTL)/lfsr_gal.v
	yosys -ql $(EQUIV).yslog -s $(EQUIV).ys

.PHONY: $(LFSR)
$(LFSR): $(LFSR)_prf/PASS
$(LFSR)_prf/PASS: ../../rtl/$(LFSR).v $(LFSR).sby
	sby -f $(LFSR).sby prf

.PHONY: $(EQUIV)
$(EQUIV) : $(EQUIV)_prf/PASS
$(EQUIV)_prf/PASS: $(EQUIV).sby $(EQUIV).v ../../rtl/lfsr_fib.v ../../rtl/lfsr_gal.v
	sby -f $(EQUIV).sby prf

$(DELAY) : $(DELAY)_prf/PASS
$(DELAY)_prf/PASS: ../../rtl/$(DELAY).v $(DELAY).sby
	sby -f $(DELAY).sby prf

$(BCAR) : $(BCAR)_prf/PASS
$(BCAR)_prf/PASS: $(BCAR).sby ../../rtl/boxcar.v
	sby -f $(BCAR).sby prf

.PHONY: $(FFIR)
$(FFIR) : $(FFIR)_prf/PASS
$(FFIR)_prf/PASS: ../../rtl/$(FFIR).v $(FFIR).sby
	sby -f $(FFIR).sby prf

.PHONY: $(HIST)
$(HIST) : $(HIST)_prf/PASS $(HIST)_cvr/PASS
$(HIST)_prf/PASS: ../../rtl/$(HIST).v $(HIST).sby
	sby -f $(HIST).sby prf
$(HIST)_cvr/PASS: ../../rtl/$(HIST).v $(HIST).sby
	sby -f $(HIST).sby cvr

.PHONY: $(SPECTRAL)
$(SPECTRAL): $(SPECTRAL)_prf/PASS $(SPECTRAL)_cvr/PASS
$(SPECTRAL): $(SPECTRAL)_prfz/PASS $(SPECTRAL)_prfdbl/PASS
$(SPECTRAL)_prf/PASS: ../../rtl/$(SPECTRAL).v fwb_slave.v $(SPECTRAL).sby
	sby -f $(SPECTRAL).sby prf
$(SPECTRAL)_prfz/PASS: ../../rtl/$(SPECTRAL).v fwb_slave.v $(SPECTRAL).sby
	sby -f $(SPECTRAL).sby prfz
$(SPECTRAL)_prfdbl/PASS: ../../rtl/$(SPECTRAL).v fwb_slave.v $(SPECTRAL).sby
	sby -f $(SPECTRAL).sby prfdbl
$(SPECTRAL)_cvr/PASS: ../../rtl/$(SPECTRAL).v fwb_slave.v $(SPECTRAL).sby
	sby -f $(SPECTRAL).sby cvr

clean:
	rm -rf  $(LFSR)_*/
	rm -rf $(EQUIV)_*/
	rm -rf $(DELAY)_*/
	rm -rf $(BCAR)_*/
	rm -rf $(FFIR)/ $(FFIR)_first/ $(FFIR)_second/
	rm -f  *.check
