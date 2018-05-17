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
## Copyright (C) 2017-2018, Gisselquist Technology, LLC
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
TESTS := lfsr lfsr_equiv fastfir
.PHONY: $(TESTS)
all: $(TESTS)
RTL := ../../rtl

LFSR=lfsr
EQUIV=lfsr_equiv
DELAY=delayw
FFIR=fastfir

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

clean:
	rm -f  $(LFSR).smt2   $(LFSR)*.vcd  $(LFSR).yslog
	rm -f  $(EQUIV).smt2  $(EQUIV)*.vcd $(EQUIV).yslog
	rm -f  $(DELAY).smt2  $(DELAY)*.vcd $(DELAY).yslog
	rm -rf $(FFIR)/
	rm -f  *.check
