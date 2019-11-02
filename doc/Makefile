################################################################################
##
## Filename: 	Makefile
##
## Project:	DSP Filtering Example Project
##
## Purpose:	To coordinate the build of documentation PDFs from their
##		LaTeX sources.
##
##	Targets include:
##		all		Builds all documents
##
##		lgpl-3.0.pdf	Builds the GPL license these files are released
##					under.
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
all:	lgpl
pdf:	lgpl
DSRC := src
LICENSE := lgpl-3.0

.PHONY: lgpl
lgpl: $(LICENSE).pdf

$(LICENSE).pdf: $(DSRC)/$(LICENSE).tex
	latex $(DSRC)/$(LICENSE).tex
	latex $(DSRC)/$(LICENSE).tex
	dvips -q -z -t letter -P pdf -o $(LICENSE).ps $(LICENSE).dvi
	ps2pdf -dAutoRotatePages=/All $(LICENSE).ps $(LICENSE).pdf
	rm $(LICENSE).dvi $(LICENSE).log $(LICENSE).aux $(LICENSE).ps

.PHONY: clean
clean:
	rm -f $(DSRC)/*.dvi $(DSRC)/*.log
	rm -f $(DSRC)/*.aux $(DSRC)/*.toc
	rm -f $(DSRC)/*.lot $(DSRC)/*.lof
	rm -f $(DSRC)/*.out spec.ps spec.pdf
	rm -f $(LICENSE).pdf

