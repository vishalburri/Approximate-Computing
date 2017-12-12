package HarrisCorner;
import FIFO::*;
import bram::*;
import FixedPoint::*;
import Stage::*;
import datatypes::*;
import TubeHeader::*;
import pulse::*;

interface Std;
	method Action send(Int#(10) data);
        method ActionValue#(Int#(10)) receive();
endinterface

(*synthesize*)
#define IMG 800
module mkHarrisCorner(Std);

	ForwardHeader f;
        f.row = 2;
        f.col1 = 3;
        f.col2 = IMG-2;
        f.shiftVertical = 0 ;
        f.fifosize = IMG + 5 ;
       

	//###############################IY########################
	FixedPoint#(8,32) coeffs1[3][3];
	coeffs1[0][0] = -0.083;
	coeffs1[0][1] = -0.166;
	coeffs1[0][2] = -0.083;
	coeffs1[1][0] = 0;
	coeffs1[1][1] = 0;
	coeffs1[1][2] = 0;
	coeffs1[2][0] = 0.083;
	coeffs1[2][1] = 0.166;
	coeffs1[2][2] = 0.083;
	Filter sIy <- mkStage(3,IMG,IMG,coeffs1,False,f);
	//########################################################


	//###########################Ix############################
	FixedPoint#(8,32) coeffs2[3][3];
	coeffs2[0][0] = -0.083;
	coeffs2[0][1] = 0;
	coeffs2[0][2] = 0.083;
	coeffs2[1][0] = -0.166;
	coeffs2[1][1] = 0;
	coeffs2[1][2] = 0.166;
	coeffs2[2][0] = -0.083;
	coeffs2[2][1] = 0;
	coeffs2[2][2] = 0.083;
	Filter sIx <- mkStage(3,IMG,IMG,coeffs2,False,f);
	//#########################################################

	//###########################Sxx############################
	FixedPoint#(8,32) coeffs3[3][3];
	coeffs3[0][0] = 1;
	coeffs3[0][1] = 1;
	coeffs3[0][2] = 1;
	coeffs3[1][0] = 1;
	coeffs3[1][1] = 1;
	coeffs3[1][2] = 1;
	coeffs3[2][0] = 1;
	coeffs3[2][1] = 1;
	coeffs3[2][2] = 1;
	Filter sSxx <- mkStage(3,IMG-2,IMG-2,coeffs3,False,f);
	//#########################################################
	
	//###########################Sxy############################
	Filter sSxy <- mkStage(3,IMG-2,IMG-2,coeffs3,False,f);
	//#########################################################
	
	//###########################Syy############################
	Filter sSyy <- mkStage(3,IMG-2,IMG-2,coeffs3,False,f);
	//#########################################################


       Reg#(int) c1 <- mkReg(0);
       FIFO#(Int#(10)) instream <- mkFIFO;
       FIFO#(Int#(10)) forward <- mkFIFO;
       Pulse fpul <- mkPulse;
       Reg#(Int#(20)) colect <- mkReg(0);
       
      rule source; 
		let pxl = instream.first; instream.deq;
		sIy.send(fromInt(pxl));
		sIx.send(fromInt(pxl));

      endrule


      rule ixx_iyy_ixy;
	   c1 <= c1+1;
	   if(c1 < (IMG-2)*(IMG-2)) begin
	   
	   let dy <- sIy.receive();
	   let dx <- sIx.receive();

	   let y = fxptAdd(dy,dy);
	   let x = fxptAdd(dx,dx);
	   let xy = fxptAdd(dx,dy); 
		
	   sSyy.send(fxptTruncate(y));
	   sSxx.send(fxptTruncate(x));
	   sSxy.send(fxptTruncate(xy));
	   
           end
	   else begin
	   sSyy.send(0);
	   sSxx.send(0);
	   sSxy.send(0);
  	   end
      endrule
 
      rule harris;

	   DataType cons = 0.04;
	   let sxx <- sSxx.receive();
	   let syy <- sSyy.receive();
	   let sxy <- sSxy.receive();	
	   let d = fxptGetInt(sxx) + fxptGetInt(sxy) + fxptGetInt(syy);		
		if(d < 1000)
			forward.enq(0);
		else
			forward.enq(255);
      endrule

      method Action send(Int#(10) data);
                        instream.enq(data);
      endmethod

      method ActionValue#(Int#(10)) receive();
                        let d = forward.first; forward.deq;
                        return d;
      endmethod

endmodule 
endpackage
