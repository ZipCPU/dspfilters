###############################################################################
##
## Filename:	Makefile
## {{{
## Project:	DSP Filtering Example Project
##
## Purpose:	To direct the Verilator build of the SoC sources.  The result
##		is C++ code (built by Verilator), that is then built (herein)
##	into a library.
##
## Targets:	The default target, all, builds the target test, which includes
##		the libraries necessary for Verilator testing.
##
## Creator:	Dan Gisselquist, Ph.D.
##		Gisselquist Technology, LLC
##
################################################################################
## }}}
## Copyright (C) 2015-2024, Gisselquist Technology, LLC
## {{{
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
## }}}
## License:	LGPL, v3, as defined and found on www.gnu.org,
## {{{
##		http://www.gnu.org/licenses/lgpl.html
##
################################################################################
##
## }}}
all:
FBDIR := .
VDIRFB:= $(FBDIR)/obj_dir
VERILATOR := verilator
VFLAGS := -O3 -Wall -MMD -DVERILATORTB -trace -cc
SUBMAKE := make --no-print-directory -C
CORES := smplfir iiravg genericfir fastfir boxcar lfsr_gal lfsr_fib delayw lfsr slowfil slowsymf shalfband slowfil_srl subfildown histogram cheapspectral ratfil
.PHONY: all $(CORES)
all: $(CORES) # symfil
.DELETE_ON_ERROR:

## Abbreviations
## {{{
genericfir:	$(VDIRFB)/Vgenericfir__ALL.a
fastfir:	$(VDIRFB)/Vfastfir__ALL.a
symfil:		$(VDIRFB)/Vsymfil__ALL.a
slowfil:	$(VDIRFB)/Vslowfil__ALL.a
slowfil_srl:	$(VDIRFB)/Vslowfil_srl__ALL.a
slowsymf:	$(VDIRFB)/Vslowsymf__ALL.a
shalfband:	$(VDIRFB)/Vshalfband__ALL.a
smplfir:	$(VDIRFB)/Vsmplfir__ALL.a
iiravg:		$(VDIRFB)/Viiravg__ALL.a
boxcar:		$(VDIRFB)/Vboxcar__ALL.a
lfsr_gal:	$(VDIRFB)/Vlfsr_gal__ALL.a
lfsr_fib:	$(VDIRFB)/Vlfsr_fib__ALL.a
lfsr:		$(VDIRFB)/Vlfsr__ALL.a
delayw:		$(VDIRFB)/Vdelayw__ALL.a
histogram:	$(VDIRFB)/Vhistogram__ALL.a
subfildown:	$(VDIRFB)/Vsubfildown__ALL.a
cheapspectral:	$(VDIRFB)/Vcheapspectral__ALL.a
ratfil:		$(VDIRFB)/Vratfil__ALL.a
## }}}

$(VDIRFB)/V%.cpp $(VDIRFB)/V%.h $(VDIRFB)/V%.mk: $(FBDIR)/%.v
	$(VERILATOR) $(VFLAGS) $*.v
$(VDIRFB)/V%.mk: $(FBDIR)/%.v
	$(VERILATOR) $(VFLAGS) $^

$(VDIRFB)/V%__ALL.a: $(VDIRFB)/V%.mk
	$(SUBMAKE) $(VDIRFB)/ -f V$*.mk V$*__ALL.a

.PHONY: clean
clean:
	rm -rf $(VDIRFB)/

DEPS=$(wildcard $(VDIRFB)/*.d)
ifneq ($(MAKECMDGOALS),clean)
ifneq ($(DEPS),)
include $(DEPS)
endif
endif
