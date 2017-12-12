package MAC;
import reduce::*;
import pulse::*;
import FIFO::*;
import datatypes::*;
import FixedPoint::*;
import Multiplier::*;
import Drum::*;

interface Mac;
		method Action a(DataType data, Int#(8) i);
		method Action b(CoeffType data, Int#(8) i);
		method ActionValue#(DataType) result;
endinterface

module mkMAC#(Integer dim)(Mac);

	Reducer red <- mkReducer(dim);
	FIFO#(DataType) instreamA[dim];
	FIFO#(CoeffType) instreamB[dim];
	Reg#(DataType) valA[dim];
	Reg#(CoeffType) valB[dim];
	Reg#(DataType) valC[dim];
	Pulse	       _q[dim];
	Pulse	       _p[dim];
	Multiplier_IFC dut[dim];


   	for(int i=0;i< fromInteger(dim) ; i = i+1) begin
        	instreamA[i] <- mkFIFO;
        	instreamB[i] <- mkFIFO;

		valA[i] <- mkReg(0);
		valB[i] <- mkReg(0);
		valC[i] <- mkReg(0);

		_q[i] <- mkPulse;
		_p[i] <- mkPulse;
		dut[i] <- mkDrum;

   	end


	for(Int#(8) i = 0; i< fromInteger(dim) ; i = i+1) begin
		rule leaves;
			_q[i].send;
			valA[i] <= instreamA[i].first; instreamA[i].deq;
                        valB[i] <= instreamB[i].first; instreamB[i].deq;
                endrule


		rule leafValues;
			_q[i].ishigh;
			Bit#(32) weight = (pack(valA[i]));
			Bit#(40) coeff = (pack(valB[i]));
			 dut[i].multiply(weight,coeff,2);
			 //FixedPoint#(28,44) tot = unpack(r);
			 //valC[i] <= fxptTruncate(tot);
			 //valC[i] <= fxptTruncate(fxptMult(valA[i] , valB[i]));
			_p[i].send;
		endrule

		rule calculate;
				Bit#(72) r <- dut[i].result();
				FixedPoint#(28,44) tot = unpack(r);
				valC[i] <= fxptTruncate(tot);
		endrule

		rule send_values;
			_p[i].ishigh;
			red.send(valC[i],i);
		endrule

	end

	method Action a(DataType data, Int#(8) i);
			instreamA[i].enq(data);
	endmethod

	method Action b(CoeffType data, Int#(8) i);
			instreamB[i].enq(data);
	endmethod

	method ActionValue#(DataType) result;
		let d <- red.reduced;
		return d;
	endmethod

endmodule
endpackage
