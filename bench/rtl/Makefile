################################################################################
##
## Filename:	Makefile
## {{{
## Project:	DSP Filtering Example Project
##
## Purpose:	To direct the Verilator build of any RTL sources used for
##		bench testing.  The result is C++ code (built by Verilator),
##	that is then built (herein) into a library.
##
## Targets:	The default target, all, builds the target test, which includes
##		the libraries necessary for Verilator testing.
##
## Creator:	Dan Gisselquist, Ph.D.
##		Gisselquist Technology, LLC
##
################################################################################
## }}}
## Copyright (C) 2017-2022, Gisselquist Technology, LLC
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
VFLAGS := -O3 -Wall -MMD -trace -y ../../rtl -cc
SUBMAKE := make --no-print-directory -C

.PHONY: all boxwrapper
## {{{
all: boxwrapper
## }}}

boxwrapper:	$(VDIRFB)/Vboxwrapper__ALL.a

$(VDIRFB)/V%.cpp $(VDIRFB)/V%.h $(VDIRFB)/V%.mk: $(FBDIR)/%.v
	$(VERILATOR) $(VFLAGS) $*.v

$(VDIRFB)/Vboxwrapper__ALL.a: $(VDIRFB)/Vboxwrapper.mk
	$(SUBMAKE) $(VDIRFB)/ -f Vboxwrapper.mk Vboxwrapper__ALL.a

.PHONY: clean
## {{{
clean:
	rm -rf $(VDIRFB)/
## }}}

## Dependencies
## {{{
DEPS=$(wildcard $(VDIRFB)/*.d)
ifneq ($(MAKECMDGOALS),clean)
ifneq ($(DEPS),)
include $(DEPS)
endif
endif
## }}}
