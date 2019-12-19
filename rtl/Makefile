###############################################################################
##
## Filename:	Makefile
##
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
##
## Copyright (C) 2015-2019, Gisselquist Technology, LLC
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
all:
FBDIR := .
VDIRFB:= $(FBDIR)/obj_dir
VERILATOR := verilator
VFLAGS := -O3 -Wall -MMD -trace -cc
SUBMAKE := make --no-print-directory -C
CORES := smplfir iiravg genericfir fastfir boxcar lfsr_gal lfsr_fib delayw lfsr slowfil slowsymf shalfband slowfil_srl subfildown histogram
.PHONY: all $(CORES)
all: $(CORES) # symfil

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

$(VDIRFB)/V%.cpp $(VDIRFB)/V%.h $(VDIRFB)/V%.mk: $(FBDIR)/%.v
	$(VERILATOR) $(VFLAGS) $*.v

#$(VDIRFB)/V%__ALL.a: $(VDIRFB)/V%.mk
#	$(SUBMAKE) $(VDIRFB)/ -f $< $(subst $(VDIRFB)/,,$@)

$(VDIRFB)/Vgenericfir__ALL.a: $(VDIRFB)/Vgenericfir.mk
	$(SUBMAKE) $(VDIRFB)/ -f Vgenericfir.mk Vgenericfir__ALL.a

$(VDIRFB)/Vfastfir__ALL.a: $(VDIRFB)/Vfastfir.mk
	$(SUBMAKE) $(VDIRFB)/ -f Vfastfir.mk Vfastfir__ALL.a

$(VDIRFB)/Vsymfil__ALL.a: $(VDIRFB)/Vsymfil.mk
	$(SUBMAKE) $(VDIRFB)/ -f Vsymfil.mk Vsymfil__ALL.a

$(VDIRFB)/Vslowfil__ALL.a: $(VDIRFB)/Vslowfil.mk
	$(SUBMAKE) $(VDIRFB)/ -f Vslowfil.mk Vslowfil__ALL.a

$(VDIRFB)/Vslowfil_srl__ALL.a: $(VDIRFB)/Vslowfil_srl.mk
	$(SUBMAKE) $(VDIRFB)/ -f Vslowfil_srl.mk Vslowfil_srl__ALL.a

$(VDIRFB)/Vslowsymf__ALL.a: $(VDIRFB)/Vslowsymf.mk
	$(SUBMAKE) $(VDIRFB)/ -f Vslowsymf.mk Vslowsymf__ALL.a

$(VDIRFB)/Vshalfband__ALL.a: $(VDIRFB)/Vshalfband.mk
	$(SUBMAKE) $(VDIRFB)/ -f Vshalfband.mk Vshalfband__ALL.a

$(VDIRFB)/Viiravg__ALL.a: $(VDIRFB)/Viiravg.mk
	$(SUBMAKE) $(VDIRFB)/ -f Viiravg.mk Viiravg__ALL.a

$(VDIRFB)/Vsmplfir__ALL.a: $(VDIRFB)/Vsmplfir.mk
	$(SUBMAKE) $(VDIRFB)/ -f Vsmplfir.mk Vsmplfir__ALL.a

$(VDIRFB)/Vboxcar__ALL.a: $(VDIRFB)/Vboxcar.mk
	$(SUBMAKE) $(VDIRFB)/ -f Vboxcar.mk Vboxcar__ALL.a

$(VDIRFB)/Vlfsr_gal__ALL.a: $(VDIRFB)/Vlfsr_gal.mk
	$(SUBMAKE) $(VDIRFB)/ -f Vlfsr_gal.mk Vlfsr_gal__ALL.a

$(VDIRFB)/Vlfsr_fib__ALL.a: $(VDIRFB)/Vlfsr_fib.mk
	$(SUBMAKE) $(VDIRFB)/ -f Vlfsr_fib.mk Vlfsr_fib__ALL.a

$(VDIRFB)/Vlfsr__ALL.a: $(VDIRFB)/Vlfsr.mk
	$(SUBMAKE) $(VDIRFB)/ -f Vlfsr.mk Vlfsr__ALL.a

$(VDIRFB)/Vdelayw__ALL.a: $(VDIRFB)/Vdelayw.mk
	$(SUBMAKE) $(VDIRFB)/ -f Vdelayw.mk Vdelayw__ALL.a

$(VDIRFB)/Vsubfildown__ALL.a: $(VDIRFB)/Vsubfildown.mk
	$(SUBMAKE) $(VDIRFB)/ -f Vsubfildown.mk Vsubfildown__ALL.a

$(VDIRFB)/Vhistogram__ALL.a: $(VDIRFB)/Vhistogram.mk
	$(SUBMAKE) $(VDIRFB)/ -f Vhistogram.mk Vhistogram__ALL.a

.PHONY: clean
clean:
	rm -rf $(VDIRFB)/

DEPS=$(wildcard $(VDIRFB)/*.d)
ifneq ($(DEPS),)
include $(DEPS)
endif
