%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Filename: 	boxcar.m
%%
%% Project:	DSP Filtering Example Project
%%
%% Purpose:	
%%
%% Creator:	Dan Gisselquist, Ph.D.
%%		Gisselquist Technology, LLC
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Copyright (C) 2017, Gisselquist Technology, LLC
%%
%% This program is free software (firmware): you can redistribute it and/or
%% modify it under the terms of the GNU General Public License as published
%% by the Free Software Foundation, either version 3 of the License, or (at
%% your option) any later version.
%%
%% This program is distributed in the hope that it will be useful, but WITHOUT
%% ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
%% FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
%% for more details.
%%
%% You should have received a copy of the GNU General Public License along
%% with this program.  (It's in the $(ROOT)/doc directory.  Run make with no
%% target there if the PDF file isn't present.)  If not, see
%% <http://www.gnu.org/licenses/> for a copy.
%%
%% License:	GPL, v3, as defined and found on www.gnu.org,
%%		http://www.gnu.org/licenses/gpl.html
%%
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%
FTSZ=1024;
NAVG=5;
h = ones(1,NAVG);
h2 = conv(h,h);
h3 = conv(h2,h);
h4 = conv(h3,h);
h5 = conv(h4,h);
h6 = conv(h5,h);

fq = (0:(FTSZ-1))/(FTSZ-1);
H  = fft([h,  zeros(1,FTSZ-length(h ))]); H  = H  ./ max(abs(H));
H2 = fft([h2, zeros(1,FTSZ-length(h2))]); H2 = H2 ./ max(abs(H2));
H3 = fft([h3, zeros(1,FTSZ-length(h3))]); H3 = H3 ./ max(abs(H3));
H4 = fft([h4, zeros(1,FTSZ-length(h4))]); H4 = H4 ./ max(abs(H4));
H5 = fft([h5, zeros(1,FTSZ-length(h5))]); H5 = H5 ./ max(abs(H5));
H6 = fft([h6, zeros(1,FTSZ-length(h6))]); H6 = H6 ./ max(abs(H6));

plot(fq,20*log(abs(H))/log(10), ';NAVG=5;', ...
	fq, 20*log(abs(H2))/log(10), ';x2;', ...
	fq, 20*log(abs(H3))/log(10), ';x3;', ...
	fq, 20*log(abs(H4))/log(10), ';x4;',  ...
	fq, 20*log(abs(H5))/log(10), ';x5;', ...
	fq, 20*log(abs(H6))/log(10), ';x6;');

ylabel('Filter response (dB)');
xlabel('Normalized frequency (cycles/sample)');
axis([ 0 0.5 -80 3]);
grid on;
