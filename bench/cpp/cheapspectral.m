%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Filename: 	cheapspectral.m
%% {{{
%% Project:	DSP Filtering Example Project
%%
%% Purpose:	An Octave file for creating charts demonstrating the outputs of
%%		the cheapspectral simulation tests.
%%
%% Creator:	Dan Gisselquist, Ph.D.
%%		Gisselquist Technology, LLC
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% }}}
%% Copyright (C) 2020-2024, Gisselquist Technology, LLC
%% {{{
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
%% }}}
%% License:	LGPL, v3, as defined and found on www.gnu.org,
%% {{{
%%		http://www.gnu.org/licenses/lgpl.html
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% }}}

fid = fopen('cheapspectral.bin','r');
lglags = fread(fid, 1, 'int32');
lags = 2^lglags;
navg = 32768 / 8.0;

randdata = fread(fid, lags, 'int32');
zerodata = fread(fid, lags, 'int32');
onedata  = fread(fid, lags, 'int32');
altdata  = fread(fid, lags, 'int32');
slowdata = fread(fid, lags, 'int32');
sindata  = fread(fid, lags, 'int32');
rbwdata  = fread(fid, lags, 'int32');

fclose(fid);

ftw = 4*lags;
fq = (0:(ftw-1))./ftw;
tq = (0:(ftw-1));
zpad = zeros(lags, 1);
preftrand = [ flipud(randdata);zpad; 0; zpad; randdata(1:end-1) ];
preftzero = [ flipud(zerodata);zpad; 0; zpad; zerodata(1:end-1) ];
preftsin  = [ flipud(sindata); zpad; 0; zpad; sindata(1:end-1) ];
preftrbw  = [ flipud(rbwdata); zpad; 0; zpad; rbwdata(1:end-1) ];
preftone  = [ flipud(onedata); zpad; 0; zpad; onedata(1:end-1) ];
preftalt  = [ flipud(altdata); zpad; 0; zpad; altdata(1:end-1) ];
preftslow = [ flipud(slowdata);zpad; 0; zpad; slowdata(1:end-1) ];

ftrand = fft(preftrand);
ftsin  = fft(preftsin);
ftrbw  = fft(preftrbw);
ftalt  = fft(preftalt);
ftslow = fft(preftslow);

figure(1);
	plot(fq-0.5,fftshift(ftrand)); grid on; title('Random Waveform');
	plot(tq-(ftw/2),fftshift(preftrand/navg));
		grid on; title('Random Waveform');
		xlabel('Lag (samples)');
		ylabel('R[tau]');
figure(2);
	rsin = 0.5 * cos(2*pi*(7 / lags)*(-1+(1:length(sindata))))';
	rsin = [ rsin; zpad; 0; zpad; flipud(rsin(2:end)) ];
	s = 511 * 511 * navg;
	plot(fq-0.5, fftshift(fft(rsin)), ';Expected result;',
		fq-0.5,fftshift(ftsin)/s, ';Simulated result;');
		grid on; title('Sinewave Spectra');
		xlabel('Cycles per sample');
		ylabel('PSD(f)');
figure(3);
	plot(fq-0.5, fftshift(rsin), ';Expected result;',
		fq-0.5,fftshift(preftsin)/s, ';Simulated result;');
		% axis([ -0.25, 0.25, -0.55, 0.55 ]);
		axis([ -0.0625, 0.0625, -0.55, 0.55 ]);
		grid on; title('Fixed Sinewave Estimate');
		xlabel('Lag (samples)');
		ylabel('R[tau]');
figure(4);
	rrbw = 1-(0:(length(rbwdata)-1))/7;
	rrbw(7:length(rrbw)) = 0;
	rrbw = rrbw';
	rrbw = [ rrbw; zpad; 0; zpad; flipud(rrbw(2:end)) ];
	s = 511*511*navg;
	plot(fq-0.5,10*log(fftshift(ftrbw)/s)/log(10), ';Simulated Spectra;',
		fq-0.5,10*log(fftshift(fft(rrbw)))/log(10),
				';Expected Spectra;');
		axis([-0.5 0.5 -20 10]);
		grid on; title('Random Binary Waveform');
		xlabel('Cycles per sample');
		ylabel('10 * log_10 PSD(f)');
	% plot(tq-(ftw/2),fftshift(preftrbw)/s, ';Simulated Correlation;',
	%	tq-(ftw/2), fftshift(rrbw), ';Expected Correlation;');
	%	axis([-35 35 -0.05 1.05]);
	%	grid on; title('Random Binary Waveform');
	%	xlabel('Lag (Samples)');
	%	ylabel('R[tau]');
figure(5);
	ralt = (-1).^(0:(length(sindata)-1))';
	ralt = [ ralt; zpad; 0; zpad; flipud(ralt(2:end)) ];
	s = navg;
	plot(fq-0.5,fftshift(ftalt)/navg, ';Simulated Spectra;',
		fq-0.5,fftshift(ftalt)/navg, ';Expected Spectra;');
		grid on; title('Alternating Data');
		xlabel('Cycles per sample');
		ylabel('PSD(f)');
	% plot(tq-(ftw/2),fftshift(preftalt)/s, ';Simulated Correlation;',
	%	tq-(ftw/2), fftshift(ralt), ';Expected Correlation;');
	%	axis([ -4, 4, -1.2, 1.2 ]);
	%	grid on; title('Alternating Data');
	%	xlabel('Lag (Samples)');
	%	ylabel('R[tau]');
figure(6);
	plot(fq-0.5,fftshift(ftslow));
		grid on; title('Slowly Alternating Data');
		xlabel('Cycles per sample');
		ylabel('PSD(f)');
