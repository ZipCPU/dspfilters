#!/bin/bash
################################################################################
##
## Filename:	vversion.sh
##
## Project:	DSP Filtering Example Project
##
## Purpose:	To determine whether or not the verilator prefix for internal
##		variables is v__DOT__ or the name of the top level followed by
##	__DOT__.  If it is the later, output -DNEW_VERILATOR, else be silent.
##
##
## Creator:	Dan Gisselquist, Ph.D.
##		Gisselquist Technology, LLC
##
################################################################################
##
## Copyright (C) 2017-2020, Gisselquist Technology, LLC
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
if [[ -x ${VERILATOR_ROOT}/bin/verilator ]];
then
  export VERILATOR=${VERILATOR_ROOT}/bin/verilator
fi
if [[ ! -x ${VERILATOR} ]];
then
  export VERILATOR=verilator
fi
if [[ ! -x `which ${VERILATOR}` ]];
then
  echo "Verilator not found in environment or in path"
  exit -1
fi

VVERLINE=`${VERILATOR} -V | grep -i ^Verilator`
VVER=`echo ${VVERLINE} | cut -d " " -f 2`
LATER=`echo $VVER \>= 3.9 | bc`
if [[ $LATER > 0 ]];
then
  echo "-DNEW_VERILATOR"
else
  echo "-DOLD_VERILATOR"
fi
exit 0
