package StageX2X;
import Vector::*;
import bram::*;
import FIFO::*;
import StmtFSM::*;
import pulse::*;
import BRAMFIFO::*;
import FixedPoint::*;
import TubeHeader::*;
import datatypes::*;
import MAC::*;


                module mkStageX2X#(Integer stencil, Integer imgROWS, Integer imgWIDTH, FixedPoint#(8,32) coeffs[][], Integer _rate, Bool _forwardEnable, ForwardHeader _hf)(MultirateFilter);
			     	

		Reg#(Bool) _enableForwarding[_rate];
                FIFO#(DataType)     		forwardingQ[_rate];
		
		for(Int#(8) i=0; i<fromInteger(_rate);i = i+1) begin
                        
                        forwardingQ[i] <- mkSizedBRAMFIFO(_hf.fifosize);
                	_enableForwarding[i] <- mkReg(False);
		end
			
		Integer extraCh = _rate-1;
		Integer _stencilDim = stencil + extraCh;
		Integer _stencilDimPadded = _stencilDim + _stencilDim%_rate;
		Integer forcols = 0 ;
		Integer foraddress = 0;
		Integer col1 = _hf.col1 + _rate;
		if( col1 > _stencilDimPadded) begin
			Integer shifts =  (col1-_stencilDimPadded)/_rate;
			Integer forcols1 = _stencilDimPadded + shifts*_rate;
			
                        if(((col1 - _stencilDimPadded)%_rate) > 0)
				forcols = forcols1 +  _rate;
			else
				forcols = forcols1;
			
			foraddress = _stencilDimPadded - (forcols - _hf.col1) - 1;
		end
		else
		foraddress = _hf.col1 - 1;


	
		Integer incr = 0;
		if(_rate == 1)
			incr = 0;
		else
			incr = _rate;
			
		FIFORand lineBuffer[stencil][_rate];
		Reg#(DataType) windowBuffer[stencil][_stencilDimPadded];
			
		Reg#(Int#(8)) strideCounter <- mkReg(0);
		Reg#(UInt#(4)) mapCounter <- mkReg(0);
		Reg#(int) res <- mkReg(0);
		Reg#(Int#(32)) row <- mkReg(0);
		Reg#(Bool) _startDeq <- mkReg(False);

		FIFO#(DataType) 			instream[_rate];
		FIFO#(DataType) 			forward[_rate];
		Reg#(DataType) 				data[_rate];
		Pulse                                   _recvEnable[_rate];
		Pulse                                   _forwEnable[_rate];
		Pulse                                   _link[stencil][_rate];
		Reg#(DataType)                           recvData[_rate];
		Reg#(int)                               _forCols[_rate]; 
		Mac 					mac[_rate];
		for(Int#(8) i = 0;i<fromInteger(_rate); i = i +1) begin
			instream[i] <- mkFIFO;
			forward[i] <- mkFIFO;
			data[i] <- mkReg(0);
			_recvEnable[i] <- mkPulse;
			_forwEnable[i] <- mkPulse;
			recvData[i] <- mkReg(0);
			_forCols[i] <- mkReg(fromInteger(_stencilDimPadded));
			mac[i] <- mkMAC(stencil*stencil);
		end  

		Pulse 					collPulse <- mkPulse;
		Pulse 					_compPulse <- mkPulse;
		Reg#(Bool)                              _init <- mkReg(True);
                Reg#(Int#(8))                           fid <- mkReg(0);
                Reg#(UInt#(16))                          pixC <- mkReg(0);
		Reg#(int)                               _changeCh   <- mkReg(0);
		Reg#(int)                               _forCount  <- mkReg(0);


                Pulse _macPulse[_rate][stencil][stencil];
			
		for(int k=0;k<fromInteger(_rate);k = k+1)
		for(int i=0; i<fromInteger(stencil); i = i+1)
			for(int j=0;j<fromInteger(stencil); j = j+1)
				_macPulse[k][i][j] <- mkPulse;
		
		for(int i=0;i< fromInteger(stencil) ;i = i +1)
			for(int j=0;j<fromInteger(_rate); j = j+1) begin
				lineBuffer[i][j] <- mkBuffer(imgWIDTH/_rate);
				_link[i][j] <- mkPulse;
		end
		
		for(int i =0 ;i< fromInteger(stencil); i = i+1) begin
			for(int j=0;j<fromInteger(_stencilDimPadded); j = j+1)
				windowBuffer[i][j] <- mkReg(0);
		end

		function DataType calculate(Reg#(DataType) wB[][], Int#(8) _rateID);
			 
			DataType accumulator = 0;
			for(Int#(8) i=0;i<fromInteger(stencil);i = i+1)
				for(Int#(8) j=_rateID ;j< fromInteger(stencil) +_rateID; j = j+1) begin
					let d = fxptMult(coeffs[i][j-_rateID], wB[i][j]);
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
	
			if(pixC == fromInteger(imgWIDTH/_rate)-1) begin
                                pixC <= 0;
				
                                if (fid >= fromInteger(stencil)-1)
                                        fid <= 0;
                                else
                                        fid <= fid+1;
                        end

                        else begin
                                pixC <= pixC + 1;
                        end
			
			if(fid >= fromInteger(stencil)-1 && pixC >=2) begin
				_startDeq <= True;
			end

			//if(_startDeq == True) begin
			
				for(Int#(8) i = 0; i< fromInteger(stencil); i = i+1)
					for(Int#(8) j = 0 ; j<fromInteger(_rate) ; j = j+1)
                            	    		_link[i][j].send;
                            
			//end


			for(Int#(8) i = 0; i < fromInteger(_rate); i = i+1) begin
                                let d =  instream[i].first; instream[i].deq;
                                data[i] <= d;
                   		lineBuffer[fid][i].enq (data[i]);
			end

                endrule


		for(Int#(8) i = 0; i< fromInteger(stencil); i = i+1)
                    	for(Int#(8) j = 0 ; j<fromInteger(_rate); j = j+1)
				rule startDeques(_startDeq == True);
					_link[i][j].ishigh;
					lineBuffer[i][j].deq;
				endrule



		for(Int#(8) k = 0 ;k< fromInteger(stencil); k= k +1 ) begin
			rule latch; 
				for(int i = 0; i<fromInteger(_rate); i = i +1) begin
					lineBuffer[k][i].latchData;
				end
				if (k == fromInteger(stencil)-1) begin
					collPulse.send;
				end
			endrule
		end

		rule collect;
	
			collPulse.ishigh;
			for (UInt#(4) i = 0;i < fromInteger(stencil); i = i+1) begin
				let index = (i+mapCounter)%(fromInteger(stencil));
				for(Int#(8) j = 0; j<fromInteger(_rate); j = j+1) begin
					let d = lineBuffer[index][j].get;
		                	windowBuffer[i][fromInteger(_stencilDimPadded)-fromInteger(_rate)+j] <= d;
				end


			end

			for(Int#(8) i= 0; i< fromInteger(stencil); i = i +1)
                                for(int j=0; j< fromInteger(_stencilDimPadded)-fromInteger(_rate); j = j+1)
                                        windowBuffer[i][j] <= windowBuffer[i][j+fromInteger(_rate)];
			
			if(res == fromInteger(imgWIDTH/_rate)-1)
				res <= 0;
			else
				res <= res + 1;

			if(res >= fromInteger(_stencilDimPadded/_rate) -1) begin

				for(int i = 0; i<fromInteger(_rate); i = i +1)
                                _forwEnable[i].send;
				_compPulse.send;
			end

			_changeCh <= _changeCh + 1;
			
			if(_changeCh >= fromInteger(imgWIDTH/_rate)-1 && res == fromInteger(imgWIDTH/_rate)-1) begin

					_forCount <= _forCount + 1;
                                       if(mapCounter == fromInteger(stencil)-1)
                                                mapCounter<=0;
                                        else
                                                mapCounter <= mapCounter + 1;
                        end
		endrule

		for(int i= 0 ; i< fromInteger(_rate); i = i+1) begin
			
			rule sendForwards(_forwardEnable == True);
				
				_forwEnable[i].ishigh;
				if ((_forCount >= fromInteger(_hf.shiftVertical)) || _enableForwarding[i] == True) begin
					_enableForwarding[i] <= True;
					/*if(_forCols[i] >= fromInteger(imgWIDTH))
						_forCols[i] <= fromInteger(_stencilDimPadded);
					else
						_forCols[i] <= _forCols[i] + fromInteger(_rate);*/

					//if(_forCols[i] >= fromInteger(_hf.col1) + fromInteger(_rate) && _forCols[i]-fromInteger(_rate) <= fromInteger(_hf.col2)) begin
						let f = windowBuffer[fromInteger(_hf.row)][fromInteger(foraddress) +i];
					 	forwardingQ[i].enq(f);
					//end
				end
			endrule
		end

		rule compute;
                        _compPulse.ishigh;	
                        for(Int#(8) k=0;k<fromInteger(_rate);k = k+1)
                        	for(Int#(8) i=0;i<fromInteger(stencil);i = i+1)
                               		for(Int#(8) j=0 ;j< fromInteger(stencil); j = j+1) begin
                                        	_macPulse[k][i][j].send;
                        end
                endrule


		
		for(Int#(8) k = 0 ; k <fromInteger(_rate); k = k+1) 
                	for(Int#(8) i=0;i<fromInteger(stencil);i = i+1)
                               for(Int#(8) j=0 ;j< fromInteger(stencil); j = j+1)
                                        rule pushMac;
                                                	_macPulse[k][i][j].ishigh;
							mac[k].b(coeffs[i][j], truncate(i*fromInteger(stencil)+j));
                                                	mac[k].a(windowBuffer[i][j+k], truncate(i*fromInteger(stencil) +j));
                                        endrule
		
		for(Int#(8) k = 0 ; k <fromInteger(_rate); k = k+1) 
                			rule getComputeResult;
                        				let d <- mac[k].result;
                        				forward[k].enq(d);
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
		
	endmodule: mkStageX2X

endpackage: StageX2X
