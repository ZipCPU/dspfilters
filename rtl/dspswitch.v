module	dspswitch(i_clk, i_areset_n, i_en, i_ce, i_sample, i_bypass,
		o_ce, o_sample);
	parameter	DW = 32;
	input	wire			i_clk, i_areset_n, i_en;
	//
	input	wire			i_ce;
	input	wire	[(DW-1):0]	i_sample, i_bypass;
	//
	output	reg			o_ce;
	output	reg	[(DW-1):0]	o_sample;
	
	initial	o_ce = 0;
	always @(posedge i_clk, negedge i_areset_n)
		if (!i_areset_n)
			o_ce <= 0;
		else
			o_ce <= i_ce;

	initial	o_sample = 0;
	always @(posedge i_clk, negedge i_areset_n)
		if (!i_areset_n)
			o_sample <= 0;
		else if (i_ce)
			o_sample <= (i_en) ? i_sample : i_bypass;

endmodule
