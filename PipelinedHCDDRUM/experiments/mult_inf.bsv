package mult_inf;

#define inp 32
#define out 64	

interface MultInf;
	method Action load(Int#(inp) aa, Int#(inp) bb);
	method Int#(out) read;
endinterface

endpackage
