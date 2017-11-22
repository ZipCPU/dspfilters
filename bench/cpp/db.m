function [out] = db(in)
	out = 20 * log(abs(in))/log(10);
