################################################################################
##
## Filename:	Makefile
##
## Project:	DSP Filtering Example Project
##
## Purpose:	To test a group of Verilator modules: txuart (UART transmitter),
##		rxuart (UART receiver/sink) and wbuart (UART module, containing
##	both receiver and transmitter, with FIFOs, controlled via wishbone).
##
##
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
.PHONY: all
all:
CXX	:= g++
OBJDIR  := obj-pc
RTLD	:= ../../rtl
VERILATOR_ROOT ?= $(shell bash -c 'verilator -V|grep VERILATOR_ROOT | head -1 | sed -e " s/^.*=\s*//"')
VROOT   := $(VERILATOR_ROOT)
INCS	:= -I$(RTLD)/obj_dir/ -I$(VROOT)/include -I../rtl/obj_dir
PROGRAMS := genericfir_tb slowfil_tb fastfir_tb boxcar_tb lfsr_gal_tb lfsr_fib_tb delayw_tb # symfil_tb
SOURCES := $(addsuffix .cpp,$(PROGRAMS)) filtertb.cpp
VOBJDR	:= $(RTLD)/obj_dir
SYSVDR	:= $(VROOT)/include
VSRC	:= verilated.cpp verilated_vcd_c.cpp
VLIB	:= $(addprefix $(OBJDIR)/,$(subst .cpp,.o,$(VSRC)))
all:	$(PROGRAMS)
CFLAGS	:= -Wall -Og -g $(INCS)

$(OBJDIR)/%.o: %.cpp
	$(mk-objdir)
	$(CXX) $(CFLAGS) $(INCS) -c $< -o $@

$(OBJDIR)/%.o: $(SYSVDR)/%.cpp
	$(mk-objdir)
	$(CXX) $(CFLAGS) $(INCS) -c $< -o $@

genericfir_tb: $(OBJDIR)/genericfir_tb.o $(VLIB) $(VOBJDR)/Vgenericfir__ALL.a
	$(CXX) $(FLAGS) $(INCS) $^ -o $@

fastfir_tb: $(OBJDIR)/fastfir_tb.o $(VLIB) $(VOBJDR)/Vfastfir__ALL.a
	$(CXX) $(FLAGS) $(INCS) $^ -o $@

slowfil_tb: $(OBJDIR)/slowfil_tb.o $(VLIB) $(VOBJDR)/Vslowfil__ALL.a
	$(CXX) $(FLAGS) $(INCS) $^ -o $@

symfil_tb: $(OBJDIR)/symfil_tb.o $(VLIB) $(VOBJDR)/Vsymfil__ALL.a
	$(CXX) $(FLAGS) $(INCS) $^ -o $@

boxcar_tb: $(OBJDIR)/boxcar_tb.o $(VLIB) ../rtl/obj_dir/Vboxwrapper__ALL.a
	$(CXX) $(FLAGS) $(INCS) $^ -o $@

lfsr_gal_tb: $(OBJDIR)/lfsr_gal_tb.o $(VLIB) $(VOBJDR)/Vlfsr_gal__ALL.a
	$(CXX) $(FLAGS) $(INCS) $^ -o $@

lfsr_fib_tb: $(OBJDIR)/lfsr_fib_tb.o $(VLIB) $(VOBJDR)/Vlfsr_fib__ALL.a
	$(CXX) $(FLAGS) $(INCS) $^ -o $@

lfsr_tb: $(OBJDIR)/lfsr_tb.o $(VLIB) $(VOBJDR)/Vlfsr__ALL.a
	$(CXX) $(FLAGS) $(INCS) $^ -o $@

delayw_tb: $(OBJDIR)/delayw_tb.o $(VLIB) $(VOBJDR)/Vdelayw__ALL.a
	$(CXX) $(FLAGS) $(INCS) $^ -o $@

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

-include $(OBJDIR)/depends.txt
