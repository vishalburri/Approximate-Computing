package mult;
import mult_inf::*;

#define inp 32
#define out 64
(*synthesize*)
module multiplier(MultInf);
	Reg#(Int#(inp)) a <- mkReg(0);
	Reg#(Int#(inp)) b <- mkReg(0);
	Reg#(Int#(out)) res0 <- mkReg(0);
	Reg#(Int#(out)) res1 <- mkReg(0);
	Reg#(Int#(out)) res2 <- mkReg(0);
	Reg#(Int#(out)) res3 <- mkReg(0);

	rule one;
		res0 <= signedMul(a,b);
		res1 <= res0;
		res2 <= res1;
		res3 <= res2;
	endrule

method Action load(Int#(inp) aa,Int#(inp) bb);
	a <= aa;
	b <= bb;
endmethod

method Int#(out) read;
	return res3;
endmethod

endmodule
endpackage
