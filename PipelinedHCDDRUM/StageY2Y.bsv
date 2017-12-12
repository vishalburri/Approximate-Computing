package StageY2Y;
import Vector::*;
import bram::*;
import FIFO::*;
import StmtFSM::*;
import pulse::*;
import BRAMFIFO::*;
import FixedPoint::*;
import TubeHeader::*;
import datatypes::*;

                module mkStageY2Y#(Integer stencil, Integer imgROWS, Integer imgWIDTH, FixedPoint#(8,32) coeffs[][], Integer _rate, Bool _forwardEnable, ForwardHeader _hf)(MultirateFilter);
			     	

		//###################################################################
		Reg#(Bool) _enableForwarding[_rate];
                FIFO#(DataType)     		forwardingQ[_rate];
		
		for(Int#(4) i=0; i<fromInteger(_rate);i = i+1) begin
                        
                        forwardingQ[i] <- mkSizedBRAMFIFO(_hf.fifosize);
                	_enableForwarding[i] <- mkReg(False);
		end
			
		//###################################################################

		Integer extraCh = _rate-1;
		Integer _stencilDim = stencil + extraCh;
		Integer _stencilDimPadded = _stencilDim + _stencilDim%_rate;
	
		Integer incr = 0;
		if(_rate == 1)
			incr = 0;
		else
			incr = _rate;
			
		FIFORand lineBuffer[_stencilDimPadded];
		Reg#(DataType) windowBuffer[stencil+extraCh][stencil];
			
		Reg#(Int#(8)) strideCounter <- mkReg(0);
		Reg#(Int#(8)) mapCounter <- mkReg(0);
		Reg#(int) res <- mkReg(0);
		Reg#(Int#(32)) row <- mkReg(0);
		Reg#(Bool) _startDeq <- mkReg(False);

		FIFO#(DataType) 			instream[_rate];
		FIFO#(DataType) 			forward[_rate];
		Reg#(DataType) 				data[_rate];
		Pulse                                   _recvEnable[_rate];
		Reg#(DataType)                           recvData[_rate];
		Pulse                                   _forwEnable[_rate];

		for(Int#(8) i = 0;i<fromInteger(_rate); i = i +1) begin
			instream[i] <- mkFIFO;
			forward[i] <- mkFIFO;
			data[i] <- mkReg(0);
			_recvEnable[i] <- mkPulse;
			recvData[i] <- mkReg(0);
			_forwEnable[i] <- mkPulse;
		end  

		Pulse 					collPulse <- mkPulse;
		Pulse 					_compPulse <- mkPulse;
		Reg#(Bool)                              _init <- mkReg(True);
                Reg#(Int#(8))                           fid <- mkReg(0);
                Reg#(Int#(32))                          pixC <- mkReg(0);
		Reg#(int)                               _changeCh   <- mkReg(0);
		Reg#(int)				_forCount <- mkReg(0);
			
		
		for(int i=0;i< fromInteger(_stencilDimPadded) ;i = i +1)
			lineBuffer[i] <- mkBuffer(imgWIDTH);
		
		for(int i =0 ;i< fromInteger(_stencilDim); i = i+1) begin
			for(int j=0;j<fromInteger(stencil); j = j+1)
				windowBuffer[i][j] <- mkReg(0);
		end

		function DataType calculate(Reg#(DataType) wB[][], Int#(8) _rateID);
			 
			DataType accumulator = 0;
			for(Int#(8) i=_rateID;i<fromInteger(stencil)+_rateID;i = i+1)
				for(Int#(8) j=0 ;j< fromInteger(stencil); j = j+1) begin
					let d = fxptMult(coeffs[i-_rateID][j], wB[i][j]);
					accumulator = fxptTruncate(fxptAdd(accumulator,d));
				end
			return accumulator;

		endfunction

		rule init (_init == True);
                        
			for(Int#(8) i = 0; i < fromInteger(_rate); i = i+1) begin
				let d =  instream[i].first; instream[i].deq;
				data[i] <= d;
			end
			_init <= False;

                endrule

                rule accumulate (_init == False);
	
			if(pixC == fromInteger(imgWIDTH)-1) begin
                                pixC <= 0;
				
				row <= row + fromInteger(_rate);

                                if ((fid + fromInteger(incr)) >= fromInteger(_stencilDimPadded)-1)
                                        fid <= 0;
                                else
                                        fid <= fid+fromInteger(_rate);
                        end

                        else begin
                                pixC <= pixC + 1;
                        end
			
			if( ( fid + fromInteger(incr)) >= fromInteger(_stencilDim)-1 && pixC >=3)
				_startDeq <= True;

			  if(_startDeq == True) begin
				for(Int#(8) i = 0; i< fromInteger(_stencilDimPadded); i = i+1) begin
                            	    lineBuffer[i].deq;
				end
                            
			end
			for(Int#(8) i = 0; i < fromInteger(_rate); i = i+1) begin
                                let d =  instream[i].first; instream[i].deq;
                                data[i] <= d;
                   		lineBuffer[fid+i].enq (data[i]);
			end

                endrule

		for(Int#(8) k = 0 ;k< fromInteger(_stencilDimPadded); k= k +1 ) begin

			rule latch; 
				lineBuffer[k].latchData;
				if(k == fromInteger(_stencilDimPadded)-1) begin
					collPulse.send;
				end
			endrule
		end

		rule collect;
	
			collPulse.ishigh;

			for(int i=0; i< fromInteger(_rate); i = i +1)
                                _forwEnable[i].send;

			for (Int#(8) i = 0;i < fromInteger(_stencilDim); i = i+1) begin
				let index = (i+mapCounter)%(fromInteger(_stencilDimPadded));
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
				_compPulse.send;
			end

			_changeCh <= _changeCh +1;
			
			if(_changeCh >= fromInteger(imgWIDTH)-1 && res == fromInteger(imgWIDTH)-1) begin

					_forCount <= _forCount + fromInteger(_rate);
                                        if(mapCounter >= fromInteger(_stencilDim)-fromInteger(_rate))
                                                mapCounter <=0;
                                        else
                                                mapCounter <= mapCounter + fromInteger(_rate);
                        end
		endrule


		//#################################################################################################################################

		for(Int#(4) i= 0 ; i< fromInteger(_rate); i = i+1) begin
			
			rule sendForwards(_forwardEnable == True);
				 _forwEnable[i].ishigh;
                                if (_forCount >= fromInteger(_hf.shiftVertical )|| _enableForwarding[i] == True) begin
					_enableForwarding[i] <= True;
					if(res >= fromInteger(_hf.col1) && res <= fromInteger(_hf.col2)) begin
						let f = windowBuffer[fromInteger(_hf.row)+i][fromInteger(stencil)-1];
					 	forwardingQ[i].enq(f);
					end
				end
			endrule
		end
		
	       //###################################################################################################################################
		
	    	rule compute;
			_compPulse.ishigh;
			for(Int#(8) i = 0 ;i<fromInteger(_rate); i = i+1) begin
				let value = calculate(windowBuffer,i);
				forward[i].enq(value);   
			end

		endrule
		

		for(Int#(8) i = 0;i < fromInteger(_rate) ; i = i+1) begin
			rule receivePort;
                                recvData[i] <= forward[i].first; forward[i].deq;
                                _recvEnable[i].send;
                	endrule
		end

                method Action send(DataType d, Int#(8) index);
				instream[index].enq(d);
                endmethod
 
                method ActionValue#(DataType) receive(Int#(8) index); 
                        _recvEnable[index].ishigh;
                        return recvData[index];
                endmethod

		method ActionValue#(DataType) forwarded(Int#(8) index);
				let d = forwardingQ[index].first; forwardingQ[index].deq; 
				return d;
		endmethod
		
	endmodule: mkStageY2Y

endpackage: StageY2Y