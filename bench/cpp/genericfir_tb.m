%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Filename: 	generic_fir.m
%%
%% Project:	DSP Filtering Example Project
%%
%% Purpose:	To plot the results of the filter frequency response, assuming
%%		that the filter's coefficients are given in twelvebfltr.m.
%%
%% Creator:	Dan Gisselquist, Ph.D.
%%		Gisselquist Technology, LLC
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Copyright (C) 2017-2020, Gisselquist Technology, LLC
%%
%% This file is part of the DSP filtering set of designs.
%%
%% The DSP filtering designs are free RTL designs: you can redistribute them
%% and/or modify any of them under the terms of the GNU Lesser General Public
%% License as published by the Free Software Foundation, either version 3 of
%% the License, or (at your option) any later version.
%%
%% The DSP filtering designs are distributed in the hope that they will be
%% useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTIBILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
%% General Public License for more details.
%%
%% You should have received a copy of the GNU Lesser General Public License
%% along with these designs.  (It's in the $(ROOT)/doc directory.  Run make
%% with no target there if the PDF file isn't present.)  If not, see
%% <http://www.gnu.org/licenses/> for a copy.
%%
%% License:	LGPL, v3, as defined and found on www.gnu.org,
%%		http://www.gnu.org/licenses/lgpl.html
%%
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%
% Read the results from the file
fid  =fopen('filter_tb.dbl','r'); dat=fread(fid,[2 inf],'double'); fclose(fid);
%
% Convert these results into complex values
cdat = dat(1:2:end)+j*dat(2:2:end);
% Generate a frequency array which can be used to describe these coefficients
fq = (0:(length(cdat)-1))/length(cdat)/2;
%
% Read in the original filter's taps
twelvebfltr;

% Calculate the frequency response of the quantized taps
lnq = length(quantized);
Hln = 2^(ceil(log(lnq)/log(2)))*16
hqpad = [ quantized, zeros(1,Hln-lnq) ];
Hq = fft(hqpad);
Hfq = (0:(Hln-1))/Hln;

% Calculate the frequency response of the filter as it was designed
lnd = length(design);
Hdln = 2^(ceil(log(lnd)/log(2)))*16
hdpad = [ design, zeros(1,Hdln-lnd) ];
Hd = fft(hdpad);
Hfd = (0:(Hdln-1))/Hdln;

%
%
% Plot the absolute value of the frequency response function
%
figure(1);
plot(
	fq(1), abs(cdat(1)), '-x1;Estimated;', ...
	fq, abs(cdat), '1;;', ...
	fq(1:256:end), abs(cdat(1:256:end)), 'x1;;', ...
	Hfq(1),abs(Hq(1)), '-+3;Calculated;',
	Hfq(1:(length(Hq)/2)),abs(Hq(1:(length(Hq)/2))), '3;;',
	Hfq(32:128:(length(Hq)/2)),abs(Hq(32:128:(length(Hq)/2))), '+3;;',
	Hfd(1),Hq(1)*abs(Hd(1)), '-o5;Design;',
	Hfd(1:(length(Hd)/2)),Hq(1)*abs(Hd(1:(length(Hd)/2))), '5;;',
	Hfd(64:128:(length(Hd)/2)),Hq(1)*abs(Hd(64:128:(length(Hd)/2))), 'o5;;');
grid on;

ylabel('|H(f)|');
xlabel('Normalized Frequency (CPS)');

%
%
% Plot the frequency response function in Decibel's
%
figure(2);
plot(fq(1), db(abs(cdat(1))), '-x1;Estimated;', ...
	fq, db(abs(cdat)), '1;;', ...
	fq(1:256:end), db(abs(cdat(1:256:end))), 'x1;;', ...
	Hfq(1),db(abs(Hq(1))),'-+3;Calculated;',
	Hfq(1:(length(Hq)/2)),db(abs(Hq(1:(length(Hq)/2)))),'3;;',
	Hfq(32:128:(length(Hq)/2)),db(abs(Hq(32:128:(length(Hq)/2)))),'+3;;',
	Hfd(1),db(Hq(1)*abs(Hd(1))), '-o5;Design;',
	Hfd(1:(length(Hd)/2)),db(Hq(1)*abs(Hd(1:(length(Hd)/2)))), '5;;',
	Hfd(64:128:(length(Hd)/2)),db(Hq(1)*abs(Hd(64:128:(length(Hd)/2)))), 'o5;;');
grid on;

ylabel('20*log|H(f)| (dB)');
xlabel('Normalized Frequency (CPS)');

%
%
% Plot the phase of the frequency response function
%
figure(3);
plot(fq, arg(cdat));

ylabel('20*log|H(f)| (dB)');
xlabel('Normalized Frequency (CPS)');
