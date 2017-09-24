################################################################################
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
## Copyright (C) 2015-2016, Gisselquist Technology, LLC
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
all:
YYMMDD=`date +%Y%m%d`
CXX   := g++
FBDIR := .
VDIRFB:= $(FBDIR)/obj_dir
VERILATOR := verilator
VFLAGS := -O3 -Wall -MMD -trace -cc
SUBMAKE := make --no-print-directory -C

.PHONY: all genericfir symmetricfir slowfil
all: genericfir symmetricfir slowfil iiravg smplfir fastfir

genericfir:	$(VDIRFB)/Vgenericfir__ALL.a
fastfir:	$(VDIRFB)/Vfastfir__ALL.a
symmetricfir:	$(VDIRFB)/Vsymmetricfir__ALL.a
slowfil:	$(VDIRFB)/Vslowfil__ALL.a
smplfir:	$(VDIRFB)/Vsmplfir__ALL.a
iiravg:		$(VDIRFB)/Viiravg__ALL.a

$(VDIRFB)/V%.cpp $(VDIRFB)/V%.h $(VDIRFB)/V%.mk: $(FBDIR)/%.v
	$(VERILATOR) $(VFLAGS) $*.v

#$(VDIRFB)/V%__ALL.a: $(VDIRFB)/V%.mk
#	$(SUBMAKE) $(VDIRFB)/ -f $< $(subst $(VDIRFB)/,,$@)

$(VDIRFB)/Vgenericfir__ALL.a: $(VDIRFB)/Vgenericfir.mk
	$(SUBMAKE) $(VDIRFB)/ -f Vgenericfir.mk Vgenericfir__ALL.a

$(VDIRFB)/Vfastfir__ALL.a: $(VDIRFB)/Vfastfir.mk
	$(SUBMAKE) $(VDIRFB)/ -f Vfastfir.mk Vfastfir__ALL.a

$(VDIRFB)/Vsymmetricfir__ALL.a: $(VDIRFB)/Vsymmetricfir.mk
	$(SUBMAKE) $(VDIRFB)/ -f Vsymmetricfir.mk Vsymmetricfir__ALL.a

$(VDIRFB)/Vslowfil__ALL.a: $(VDIRFB)/Vslowfil.mk
	$(SUBMAKE) $(VDIRFB)/ -f Vslowfil.mk Vslowfil__ALL.a

$(VDIRFB)/Viiravg__ALL.a: $(VDIRFB)/Viiravg.mk
	$(SUBMAKE) $(VDIRFB)/ -f Viiravg.mk Viiravg__ALL.a

$(VDIRFB)/Vsmplfir__ALL.a: $(VDIRFB)/Vsmplfir.mk
	$(SUBMAKE) $(VDIRFB)/ -f Vsmplfir.mk Vsmplfir__ALL.a

.PHONY: clean
clean:
	rm -rf $(VDIRFB)/

DEPS=$(wildcard $(VDIRFB)/*.d)
ifneq ($(DEPS),)
include $(DEPS)
endif
