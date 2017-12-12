package switch;
import datatypes::*;
import FIFO::*;
import reduce::*;
import FIFO::*;
import FixedPoint::*;
import pulse::*;


interface Switch;
	  method Action put(DataType data, Int#(8) i, Int#(8) j);
	  method ActionValue#(DataType) get(Int#(8) i, Int#(8) j);
endinterface:Switch

	module mkSwitch#(Integer inDim, Integer outDim)(Switch);
	FIFO#(DataType) outstream[outDim][outDim];
	Reducer reduction[outDim][outDim];
	Int#(8) factor=0;
	FixedPoint#(8,12) coeffs[2][2];

		coeffs[0][0] = 0.3;
		coeffs[0][1] = 0.3;
		coeffs[1][0] = 0.3;
		coeffs[1][1] = 0.3;

	if (fromInteger(inDim) > fromInteger(outDim))
		factor = fromInteger(inDim)/fromInteger(outDim);
	else
		factor = fromInteger(outDim)/fromInteger(inDim);
	

	for(Int#(8) i = 0;i < fromInteger(outDim); i = i +1)
                for(Int#(8) j = 0;j < fromInteger(outDim); j = j +1) begin
			outstream[i][j] <- mkSizedFIFO(16);
		end


	if (fromInteger(inDim) > fromInteger(outDim)) begin

	for(Int#(8) i = 0;i < fromInteger(outDim); i = i +1)
                for(Int#(8) j = 0;j < fromInteger(outDim); j = j +1) 
			reduction[i][j] <- mkReducer((inDim/outDim)*(inDim/outDim));
		
	for(Int#(8) i = 0;i < fromInteger(outDim); i = i +1)
                for(Int#(8) j = 0;j < fromInteger(outDim); j = j +1)
			rule generator;
					let d <- reduction[i][j].reduced;
					outstream[i][j].enq(d);
					
			endrule
	end
		
	method Action put(DataType data, Int#(8) k, Int#(8) l);

			if (fromInteger(inDim) > fromInteger(outDim)) begin

						DataType coeff = 0.25;
						DataType data2 = fxptTruncate(fxptMult(coeff,data));
                                        	reduction[k/factor][l/factor].send(data2, ((k%factor)*factor) + l%factor);
                                end
                        else if(fromInteger(inDim) < fromInteger(outDim)) begin 
                                    	for(Int#(8) i = 0;i < 2; i = i +1)
                				for(Int#(8) j = 0;j < 2; j = j +1)
                                        		outstream[k*2 + i][l*2 + j].enq(data);

                        end
			
			else
				
                                        outstream[k][l].enq(data);

	endmethod

	
	method ActionValue#(DataType) get(Int#(8) i, Int#(8) j);
			let d = outstream[i][j].first; outstream[i][j].deq;
			return d;
	endmethod
	endmodule

endpackage
