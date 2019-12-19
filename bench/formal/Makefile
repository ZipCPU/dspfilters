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
TESTS := lfsr lfsr_equiv fastfir histogram
.PHONY: $(TESTS)
all: $(TESTS)
RTL := ../../rtl

LFSR=lfsr
EQUIV=lfsr_equiv
DELAY=delayw
FFIR=fastfir
HIST=histogram

SMTBMC  := yosys-smtbmc
# SOLVER  := -s z3
SOLVER  := -s yices
# BMCARGS := --presat $(SOLVER)
BMCARGS := $(SOLVER)
INDARGS := $(SOLVER) -i

$(LFSR).smt2: $(RTL)/$(LFSR).v
	yosys -ql $(LFSR).yslog -s $(LFSR).ys

$(EQUIV).smt2: $(EQUIV).v $(RTL)/lfsr_fib.v $(RTL)/lfsr_gal.v
	yosys -ql $(EQUIV).yslog -s $(EQUIV).ys

$(DELAY).smt2: $(RTL)/delayw.v
	yosys -ql $(DELAY).yslog -s $(DELAY).ys

$(LFSR) : $(LFSR).check
$(LFSR).check: $(LFSR).smt2
	@rm -f $(LFSR).check
	$(SMTBMC) --presat $(ARGS) -t  60 --dump-vcd $(LFSR).vcd $(LFSR).smt2
	$(SMTBMC)       -i $(ARGS) -t  60 --dump-vcd $(LFSR).vcd $(LFSR).smt2
	$(SMTBMC) -g       $(ARGS) -t 120 --dump-vcd $(LFSR).vcd $(LFSR).smt2
	touch $@

$(EQUIV) : $(EQUIV).check
$(EQUIV).check: $(EQUIV).smt2
	@rm -f $(EQUIV).check
	$(SMTBMC) --presat $(ARGS) -t  16 --dump-vcd $(EQUIV).vcd $(EQUIV).smt2
	$(SMTBMC)       -i $(ARGS) -t  60 --dump-vcd $(EQUIV).vcd $(EQUIV).smt2
	$(SMTBMC) -g       $(ARGS) -t 120 --dump-vcd $(EQUIV).vcd $(EQUIV).smt2
	touch $@

$(DELAY) : $(DELAY).check
$(DELAY).check: $(DELAY).smt2
	@rm -f $(DELAY).check
	$(SMTBMC) --presat $(ARGS) -t  16 --dump-vcd $(DELAY).vcd $(DELAY).smt2
	$(SMTBMC)       -i $(ARGS) -t  60 --dump-vcd $(DELAY).vcd $(DELAY).smt2
	$(SMTBMC) -g       $(ARGS) -t 120 --dump-vcd $(DELAY).vcd $(DELAY).smt2
	touch $@

$(FFIR) : $(FFIR).check
$(FFIR).check: ../../rtl/$(FFIR).v $(FFIR).sby
	sby -f $(FFIR).sby
	touch $@

.PHONY: $(HIST)
$(HIST) : $(HIST)_prf/PASS $(HIST)_cvr/PASS
$(HIST)_prf/PASS: ../../rtl/$(HIST).v $(HIST).sby
	sby -f $(HIST).sby prf
$(HIST)_cvr/PASS: ../../rtl/$(HIST).v $(HIST).sby
	sby -f $(HIST).sby cvr

clean:
	rm -f  $(LFSR).smt2   $(LFSR)*.vcd  $(LFSR).yslog
	rm -f  $(EQUIV).smt2  $(EQUIV)*.vcd $(EQUIV).yslog
	rm -f  $(DELAY).smt2  $(DELAY)*.vcd $(DELAY).yslog
	rm -rf $(FFIR)/ $(FFIR)_first/ $(FFIR)_second/
	rm -f  *.check
