################################################################################
##
## Filename:	Makefile
## {{{
## Project:	DSP Filtering Example Project
##
## Purpose:	To test a group of Verilog DSP filters via Verilator wrappers.
##		This file directs the compilation and build of several
##	filtering test programs, to prove that the filters work.
##
## Creator:	Dan Gisselquist, Ph.D.
##		Gisselquist Technology, LLC
##
################################################################################
## }}}
## Copyright (C) 2017-2024, Gisselquist Technology, LLC
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
.PHONY: all
all:
CXX	:= g++
OBJDIR  := obj-pc
RTLD	:= ../../rtl
ifneq ($(VERILATOR_ROOT),)
VERILATOR:=$(VERILATOR_ROOT)/bin/verilator
else
VERILATOR_ROOT ?= $(shell bash -c 'verilator -V|grep VERILATOR_ROOT | head -1 | sed -e " s/^.*=\s*//"')
endif
export  $(VERILATOR)
VROOT  := $(VERILATOR_ROOT)
VDEFS  := $(shell ./vversion.sh)
INCS	:= -I$(RTLD)/obj_dir/ -I$(VROOT)/include -I../rtl/obj_dir
PROGRAMS := slowsymf_tb genericfir_tb fastfir_tb boxcar_tb lfsr_gal_tb lfsr_fib_tb delayw_tb slowfil_tb shalfband_tb lfsr_tb slowfil_srl_tb subfildown_tb cheapspectral_tb # symfil_tb
SOURCES := $(addsuffix .cpp,$(PROGRAMS)) filtertb.cpp downsampletb.cpp
VOBJDR	:= $(RTLD)/obj_dir
SYSVDR	:= $(VROOT)/include
VSRC	:= verilated.cpp verilated_vcd_c.cpp verilated_threads.cpp
VLIB	:= $(addprefix $(OBJDIR)/,$(subst .cpp,.o,$(VSRC)))
all:	$(PROGRAMS)
CFLAGS	:= -Wall -Og -g $(INCS) $(VDEFS)

.DELETE_ON_ERROR:

$(OBJDIR)/%.o: %.cpp
	$(mk-objdir)
	$(CXX) $(CFLAGS) $(INCS) -c $< -o $@

$(OBJDIR)/%.o: $(SYSVDR)/%.cpp
	$(mk-objdir)
	$(CXX) $(CFLAGS) $(INCS) -c $< -o $@

genericfir_tb: $(OBJDIR)/genericfir_tb.o $(VLIB) $(VOBJDR)/Vgenericfir__ALL.a
	$(CXX) $(CFLAGS) $(INCS) $^ -lpthread -o $@

fastfir_tb: $(OBJDIR)/fastfir_tb.o $(VLIB) $(VOBJDR)/Vfastfir__ALL.a
	$(CXX) $(CFLAGS) $(INCS) $^ -lpthread -o $@

slowfil_tb: $(OBJDIR)/slowfil_tb.o $(VLIB) $(VOBJDR)/Vslowfil__ALL.a
	$(CXX) $(CFLAGS) $(INCS) $^ -lpthread -o $@

slowfil_srl_tb: $(OBJDIR)/slowfil_srl_tb.o $(VLIB) $(VOBJDR)/Vslowfil_srl__ALL.a
	$(CXX) $(CFLAGS) $(INCS) $^ -lpthread -o $@

slowsymf_tb: $(OBJDIR)/slowsymf_tb.o $(VLIB) $(VOBJDR)/Vslowsymf__ALL.a
	$(CXX) $(CFLAGS) $(INCS) $^ -lpthread -o $@

shalfband_tb: $(OBJDIR)/shalfband_tb.o $(VLIB) $(VOBJDR)/Vshalfband__ALL.a
	$(CXX) $(FLAGS) $(INCS) $^ -lpthread -o $@

symfil_tb: $(OBJDIR)/symfil_tb.o $(VLIB) $(VOBJDR)/Vsymfil__ALL.a
	$(CXX) $(CFLAGS) $(INCS) $^ -lpthread -o $@

boxcar_tb: $(OBJDIR)/boxcar_tb.o $(VLIB) ../rtl/obj_dir/Vboxwrapper__ALL.a
	$(CXX) $(CFLAGS) $(INCS) $^ -lpthread -o $@

lfsr_gal_tb: $(OBJDIR)/lfsr_gal_tb.o $(VLIB) $(VOBJDR)/Vlfsr_gal__ALL.a
	$(CXX) $(CFLAGS) $(INCS) $^ -lpthread -o $@

lfsr_fib_tb: $(OBJDIR)/lfsr_fib_tb.o $(VLIB) $(VOBJDR)/Vlfsr_fib__ALL.a
	$(CXX) $(CFLAGS) $(INCS) $^ -lpthread -o $@

lfsr_tb: $(OBJDIR)/lfsr_tb.o $(VLIB) $(VOBJDR)/Vlfsr__ALL.a
	$(CXX) $(CFLAGS) $(INCS) $^ -lpthread -o $@

delayw_tb: $(OBJDIR)/delayw_tb.o $(VLIB) $(VOBJDR)/Vdelayw__ALL.a
	$(CXX) $(CFLAGS) $(INCS) $^ -lpthread -o $@

subfildown_tb: $(OBJDIR)/subfildown_tb.o $(VLIB) $(VOBJDR)/Vsubfildown__ALL.a
	$(CXX) $(FLAGS) $(INCS) $^ -lpthread -o $@

cheapspectral_tb: $(OBJDIR)/cheapspectral_tb.o $(VLIB) $(VOBJDR)/Vcheapspectral__ALL.a
	$(CXX) $(FLAGS) $(INCS) $^ -lpthread -o $@

#
# The "depends" target, to know what files things depend upon.  The depends
# file itself is kept in $(OBJDIR)/depends.txt
#
define	build-depends
	$(mk-objdir)
	@echo "Building dependency file"
	@$(CXX) $(CFLAGS) $(INCS) -MM $(SOURCES) > $(OBJDIR)/xdepends.txt
	@sed -e 's/^.*.o: /$(OBJDIR)\/&/' < $(OBJDIR)/xdepends.txt > $(OBJDIR)/depends.txt
	@rm $(OBJDIR)/xdepends.txt
endef

.PHONY: depends
depends: tags
	$(build-depends)

$(OBJDIR)/depends.txt: depends

#
define	mk-objdir
	@bash -c "if [ ! -e $(OBJDIR) ]; then mkdir -p $(OBJDIR); fi"
endef

#
# The "tags" target
#
tags:	$(SOURCES) $(HEADERS)
	@echo "Generating tags"
	@ctags $(SOURCES) $(HEADERS)

.PHONY: clean
clean:
	rm -f $(PROGRAMS)
	rm -rf $(OBJDIR)/
	rm -rf *.vcd
	rm -rf filter_tb.dbl dsp.64t
	rm -rf tags

ifneq ($(MAKECMDGOALS),clean)
-include $(OBJDIR)/depends.txt
endif
