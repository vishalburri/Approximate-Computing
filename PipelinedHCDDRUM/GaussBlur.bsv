package GaussBlur;
import FIFO::*;
import bram::*;
import FixedPoint::*;
import TubeHeader::*;
import StageX2X::*;

interface MultiStd;
	method Action send1(Int#(10) data);
	method Action send2(Int#(10) data);
        method ActionValue#(Int#(10)) receive1();
        method ActionValue#(Int#(10)) receive2();
endinterface 

#define IMG 1024
#define RATE1 2
(*synthesize*)
module mkGaussBlur(MultiStd);
      

        FixedPoint#(8,32) coeffs1[3][3];
        for(int i = 0; i < 3; i = i+1)
                for(int j= 0 ;j< 3; j = j+1)
                        coeffs1[i][j] = 0.11;


        FixedPoint#(8,32) coeffs2[5][5];
        for(int i = 0; i < 5; i = i+1)
                for(int j= 0 ;j< 5; j = j+1)
                        coeffs2[i][j] = 0.04;

	FixedPoint#(8,32) coeffs3[9][9];
        for(int i = 0; i < 9; i = i+1)
                for(int j= 0 ;j< 9; j = j+1)
                        coeffs3[i][j] = 0.01;

        ForwardHeader f;
        f.row = 0;
        f.col1 = 5;
        f.col2 = IMG-4;
        f.shiftVertical = 4 ;
        f.fifosize = IMG + 5 ;

        MultirateFilter stage1 <- mkStageX2X(5,IMG-4,IMG-4,coeffs2,RATE1,False,f);
        MultirateFilter  stage <- mkStageX2X(5,IMG,IMG,coeffs2,RATE1,True,f);

        Reg#(int) c1 <- mkReg(0);
        Reg#(int) c2 <- mkReg(0);
        
    
       
        FIFO#(Int#(10)) instream[RATE1];
        FIFO#(Int#(10)) forward[RATE1];

	for(Int#(8) i=0; i<RATE1; i = i+1) begin
		instream[i] <- mkFIFO;
		forward[i] <- mkFIFO;
	end

      rule source;
		
                for(Int#(8) i= 0 ;i< RATE1; i = i + 1) begin
			let pxl = instream[i].first; instream[i].deq;
	        	stage.send(fromInt(pxl),i);
		end

      endrule


      rule blur;
	   c1 <= c1+1;
	   if(c1 < (IMG-4)/RATE1*(IMG-4)) begin
	   for(Int#(8) i=0;i<RATE1; i = i+1) begin
	   	let d <- stage.receive(i);
		stage1.send(d,i);
	   	end
	  end
	  else
		for(Int#(8) i=0;i<RATE1; i = i+1)
			stage1.send(0,i);
      endrule

      rule blur2;
           c2 <= c2+1;
           if(c2 < (IMG-8)/RATE1*(IMG-8))
           for(Int#(8) i=0;i<RATE1; i = i+1) begin
                let d <- stage1.receive(i);
                let f <- stage.forwarded(i);
                        forward[i].enq(truncate(fxptGetInt(d)-fxptGetInt(f)));
          end
       
      endrule

      method Action send1(Int#(10) data);
                        instream[0].enq(data);
      endmethod
      
      method Action send2(Int#(10) data);
                        instream[1].enq(data);
      endmethod

      method ActionValue#(Int#(10)) receive1();
                        let d = forward[0].first; forward[0].deq;
                        return d;
      endmethod

      method ActionValue#(Int#(10)) receive2();
                        let d = forward[1].first; forward[1].deq;
                        return d;
      endmethod



endmodule 
endpackage

