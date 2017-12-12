import BRAM::*;
import DefaultValue::*;
import FIFO::*;
import FixedPoint::*;
import datatypes::*;

interface FIFORand;
        method Action enq(DataType val);
	method Action latchData;
        method Action deq;
        method DataType get;
endinterface: FIFORand


module mkBuffer#(Integer width)(FIFORand);
	BRAM_Configure cfg = defaultValue;
	cfg.allowWriteResponseBypass = False;
	cfg.memorySize = width;
	BRAM2Port#(Int#(16), DataType) memory <- mkBRAM2Server(cfg);

	Reg#(Int#(16)) rear <- mkReg(0);
	Reg#(Int#(16)) front <- mkReg(0);
	Reg#(DataType) _cache <- mkReg(0);
	Reg#(DataType) _cach2 <- mkReg(0);

	Reg#(int) clk <- mkReg(0);
	Reg#(Bool) _startDeq <- mkReg(False);
	Reg#(Bool) open <- mkReg(False);

	function BRAMRequest#(Int#(16), DataType) makeRequest(Bool write, Int#(16)  addr, DataType data);
        return BRAMRequest {
                write : write,
                responseOnWrite : False,
                address : addr,
                datain : data
        };
	endfunction
	method Action latchData;

		let d <- memory.portB.response.get;
		_cache <= d;

	endmethod


	method Action enq(DataType data);
			memory.portA.request.put(makeRequest(True, rear, data));
		if (rear == fromInteger(width)-1)
				rear <= 0; 
		else
			rear <= rear +1;
	endmethod

	
	method Action deq;
		memory.portB.request.put(makeRequest(False, front, 0));
		if (front == fromInteger(width)-1)
			front <= 0;
		else 
		front <= front+1;
	endmethod


	method DataType get;
		return _cache;
	endmethod
	
endmodule: mkBuffer
