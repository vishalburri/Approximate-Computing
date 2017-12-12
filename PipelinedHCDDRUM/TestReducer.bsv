package TestReducer;
import FixedPoint::*;
import CreateRed::*;
import Real::*;

(*synthesize*)

module mkTestReducer();

	Enab m <- mkCreateRed;

	Reg#(int) c <- mkReg(0);	
	rule push;
		m.enabRed;
	endrule

	rule get;
		c <= c+1;
		let d <- m.recv;
		
		if(c>2)
		$finish(0);
		else
		$display("%d", fxptGetInt(d));
	endrule	

endmodule
endpackage

