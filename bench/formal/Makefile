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
## Copyright (C) 2017, Gisselquist Technology, LLC
##
## This program is free software (firmware): you can redistribute it and/or
## modify it under the terms of  the GNU General Public License as published
## by the Free Software Foundation, either version 3 of the License, or (at
## your option) any later version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
## FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
## for more details.
##
## You should have received a copy of the GNU General Public License along
## with this program.  (It's in the $(ROOT)/doc directory.  Run make with no
## target there if the PDF file isn't present.)  If not, see
## <http://www.gnu.org/licenses/> for a copy.
##
## License:	GPL, v3, as defined and found on www.gnu.org,
##		http://www.gnu.org/licenses/gpl.html
##
################################################################################
##
##
TESTS := lfsr
.PHONY: $(TESTS)
all: $(TESTS)
RTL := ../../rtl

LFSR=lfsr
LFSRBMC=$(LFSR)_bmc
LFSRIND=$(LFSR)_ind
SMTBMC  := yosys-smtbmc
# SOLVER  := -s z3
SOLVER  := -s yices
# BMCARGS := --presat $(SOLVER)
BMCARGS := $(SOLVER)
INDARGS := $(SOLVER) -i

$(LFSR).smt2: $(RTL)/$(LFSR).v
	yosys -ql $(LFSR).yslog -s $(LFSR).ys

$(LFSR) : $(LFSR).check
$(LFSR).check: $(LFSR).smt2
	@rm -f $(LFSR).check
	$(SMTBMC) --presat $(BMCARGS) -t 520 --dump-vcd $(LFSRBMC).vcd $(LFSR).smt2
	$(SMTBMC) -g       $(BMCARGS) -t 520 --dump-vcd $(LFSRBMC).vcd $(LFSR).smt2
	$(SMTBMC)          $(INDARGS) -t 516 --dump-vcd $(LFSRIND).vcd $(LFSR).smt2
	touch $@


clean:
	rm -f   $(LFSR).smt2   $(LFSRBMC).smt2   $(LFSRIND).smt2   $(LFSR)*.vcd
	rm -f *.check
