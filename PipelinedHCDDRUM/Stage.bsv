package Stage;
import Vector::*;
import bram::*;
import FIFO::*;
import StmtFSM::*;
import pulse::*;
import BRAMFIFO::*;
import FixedPoint::*;
import datatypes::*;
import TubeHeader::*;
import MAC::*;


               module mkStage#(Integer stencil, Integer imgROWS, Integer imgWIDTH, CoeffType coeffs[][],Bool _forwardEnable, ForwardHeader _hf)(Filter);


                //###################################################################
                Reg#(Bool) _enableForwarding <- mkReg(False);
                FIFO#(DataType)                 forwardingQ <- mkSizedBRAMFIFO(_hf.fifosize);

                //###################################################################

	     	
		FIFORand lineBuffer[stencil];
		Reg#(DataType) windowBuffer[stencil][stencil];
		Reg#(Int#(8)) strideCounter <- mkReg(0);
		Reg#(UInt#(4)) mapCounter <- mkReg(0);
		Reg#(int) res <- mkReg(0);
		Reg#(Int#(32)) clk <- mkReg(0);
		FIFO#(DataType) instream <- mkFIFO;
		Reg#(DataType) data <- mkReg(0);
		FIFO#(DataType) forward <- mkFIFO;	
		Mac mac <- mkMAC(stencil*stencil);
		Pulse _macPulse[stencil][stencil];

		Pulse 	collPulse <- mkPulse;
		Pulse 	_compPulse <- mkPulse;
		Pulse                                   _recvEnable <- mkPulse;
		Reg#(DataType)                           recvData    <- mkReg(0);
		Reg#(Bool)                              _init <- mkReg(True);
                Reg#(Int#(8))                           fid <- mkReg(0);
                Reg#(Int#(32))                          pixC <- mkReg(0);
		Reg#(int)                               _changeCh   <- mkReg(0);
		Pulse                                   _forwEnable <- mkPulse;
		Reg#(int) 				_forCount <- mkReg(0);
				
		for(int i =0 ;i< fromInteger(stencil); i = i+1) begin
			lineBuffer[i] <- mkBuffer(imgWIDTH);
			for(int j=0;j<fromInteger(stencil); j = j+1) begin
			windowBuffer[i][j] <- mkReg(0);
			_macPulse[i][j] <- mkPulse;
			end
		end

		/*function Action calculate(Reg#(DataType) wB[][]);

			//DataType accumulator = 0;
			return 
				action
				for(int i=0;i<fromInteger(stencil);i = i+1)
					for(int j=0 ;j< fromInteger(stencil); j = j+1) begin
					mac.a(coeffs[i][j], i*fromInteger(stencil)+j)
					mac.b(wB[i][j], i*fromInteger(stencil) +j);
					//let d = fxptMult(coeffs[i][j], wB[i][j]);
					//accumulator = fxptTruncate(fxptAdd(accumulator,d));
					end
				endaction;
			//return accumulator;
			//return wB[0][0];

		endfunction*/


		rule init (_init == True);
                        let d =  instream.first; instream.deq;
			data <= d;
                        _init <= False;

                endrule


                rule accumulate (_init == False);
                        clk <= clk + 1;
                        if(pixC == fromInteger(imgWIDTH)-1) begin
                                pixC <= 0;
                                if (fid == fromInteger(stencil)-1)
                                        fid <= 0;
                                else
                                        fid <= fid+1;
                        end
                        else begin
                                pixC <= pixC + 1;
                        end
                        let d =  instream.first; instream.deq;
			data <= d;

                        if(clk >= ((fromInteger(stencil)-1)*fromInteger(imgWIDTH) + 3)) begin

				for(Int#(6) i = 0; i< fromInteger(stencil); i = i+1)
                            	    lineBuffer[i].deq;
                            
			end

                        lineBuffer[fid].enq (data);
                endrule

		for(Int#(8) i = 0 ;i< fromInteger(stencil); i= i +1 ) begin

			rule latch;
				lineBuffer[i].latchData;
				if(i==fromInteger(stencil)-1)
					collPulse.send;
			endrule
		end
		rule collect;
	
			collPulse.ishigh;
			_forwEnable.send;
			
			for (UInt#(4) i = 0;i < fromInteger(stencil); i = i+1) begin
				let index = (i+mapCounter)%fromInteger(stencil);
				let d = lineBuffer[index].get;
		                windowBuffer[i][fromInteger(stencil)-1] <= d;
				for(int j=0; j< fromInteger(stencil)-1; j = j+1)
					windowBuffer[i][j] <= windowBuffer[i][j+1];

			end
			
			if(res == fromInteger(imgWIDTH)-1)
				res <= 0;
			else
				res <= res + 1;

			if(res >= fromInteger(stencil)-1) begin
				for(Int#(8) i=0;i<fromInteger(stencil);i = i+1)
                               		for(Int#(8) j=0 ;j< fromInteger(stencil); j = j+1)
                                        	_macPulse[i][j].send;
			end

			_changeCh <= _changeCh +1;
			
			if(_changeCh >= fromInteger(imgWIDTH)-1 && res == fromInteger(imgWIDTH)-1) begin

					_forCount <= _forCount + 1;
                                        if(mapCounter == fromInteger(stencil)-1)
                                                mapCounter<=0;
                                        else
                                                mapCounter <= mapCounter + 1;
                        end
		endrule
		rule sendForwards(_forwardEnable == True);
                                 _forwEnable.ishigh;
                                if (_forCount >= fromInteger(_hf.shiftVertical )|| _enableForwarding == True) begin
                                        _enableForwarding <= True;
                                        if(res >= fromInteger(_hf.col1) && res <= fromInteger(_hf.col2)) begin
                                                let f = windowBuffer[fromInteger(_hf.row)][fromInteger(stencil)-1];
                                                forwardingQ.enq(f);
                                        end
                                end
                        endrule

		/*rule compute;
			_compPulse.ishigh;
			for(Int#(8) i=0;i<fromInteger(stencil);i = i+1)
                               for(Int#(8) j=0 ;j< fromInteger(stencil); j = j+1) begin
					_macPulse[i][j].send;
                                        //mac.b(coeffs[i][j], truncate(i*fromInteger(stencil)+j));
                                        //mac.a(windowBuffer[i][j], truncate(i*fromInteger(stencil) +j));  
			end
		endrule*/

		for(Int#(8) i=0;i<fromInteger(stencil);i = i+1)
                               for(Int#(8) j=0 ;j< fromInteger(stencil); j = j+1) 
					rule pushMac;
						_macPulse[i][j].ishigh;
						mac.b(coeffs[i][j], truncate(i*fromInteger(stencil)+j));
                                        	mac.a(windowBuffer[i][j], truncate(i*fromInteger(stencil) +j));
					endrule

		rule getComputeResult;
			let d <- mac.result;
			forward.enq(d);
		endrule


		rule receivePort;
                                recvData <= forward.first; forward.deq;
                                _recvEnable.send;
                endrule

                method Action send(DataType dat);
                        instream.enq(dat);
                endmethod
 
                method ActionValue#(DataType) receive; 
                        _recvEnable.ishigh;
                        return recvData;
                endmethod

		method ActionValue#(DataType) forwarded;
                                let d = forwardingQ.first; forwardingQ.deq;
                                return d;
                endmethod	

	endmodule: mkStage

endpackage: Stage
