package CreateRed;
import reduce::*;
import pulse::*;
import datatypes::*;
import MAC::*;

interface Enab;
		method Action enabRed; 
		method ActionValue#(DataType) recv;
endinterface
#define S 30
(*synthesize*)
module mkCreateRed(Enab);
	
	Mac r <- mkMAC(S);
	Pulse _p[S];
	
	for(int i=0; i< S; i = i+1)
		_p[i] <- mkPulse;

	for(Int#(8) i = 0 ;i< S; i = i+1)
		rule sendData;
			_p[i].ishigh;
			r.a(5,i);
			r.b(5,i);
		endrule

	method Action enabRed;

		for(int i=0 ;i<S;i = i+1)
			_p[i].send;
	endmethod

	method ActionValue#(DataType) recv;
		let d <- r.result;
		return d;
	endmethod
endmodule

endpackage
