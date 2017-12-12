package HarrisCornerMultirate;
import FIFO::*;
import bram::*;
import FixedPoint::*;
import StageX2X::*;
import datatypes::*;
import TubeHeader::*;
import drumcomb::*;


import "BDPI" function Action initialize_image();
import "BDPI" function Int#(32) readPixel1(Int#(32) ri, Int#(32) cj, Int#(32) ch);

(*synthesize*)
#define IMG 800
#define RATE 2
module mkHarrisCornerMultirate();

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
	MultirateFilter sIy <- mkStageX2X(3,IMG,IMG,coeffs1,RATE,False,f);
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
	MultirateFilter sIx <- mkStageX2X(3,IMG,IMG,coeffs2,RATE,False,f);
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
	MultirateFilter sSxx <- mkStageX2X(3,IMG-2,IMG-2,coeffs3,RATE,False,f);
	//#########################################################

	//###########################Sxy############################
	MultirateFilter sSxy <- mkStageX2X(3,IMG-2,IMG-2,coeffs3,RATE,False,f);
	//#########################################################

	//###########################Syy############################
	MultirateFilter sSyy <- mkStageX2X(3,IMG-2,IMG-2,coeffs3,RATE,False,f);
	//#########################################################




       Reg#(int) c0 <- mkReg(0);
       Reg#(int) c1 <- mkReg(0);
       Reg#(int) c2 <- mkReg(0);
       Reg#(int) c3 <- mkReg(0);
       Reg#(int) c4 <- mkReg(0);
       Reg#(int) rows  <- mkReg(0);
       Reg#(int) cols  <- mkReg(0-RATE);
       Reg#(int) clk   <-  mkReg(0);
       Reg#(int) index <- mkReg(0);
       Reg#(Bool) init <- mkReg(True);


      rule init_rule (init) ;
      initialize_image();
      init <= False;
      endrule

      rule update_clock;
                        cols <= (cols+RATE)%IMG;
                        if(cols == IMG - RATE) begin
                                rows <= rows + 1;
                        end
                        clk <= clk + 1;
      endrule

      rule source (clk>=1);
		if(rows <= IMG-1)
		for(Int#(8) i = 0; i< RATE; i = i +1) begin
			Int#(20) pxl = truncate(readPixel1(rows, cols+extend(i),0));
			sIy.send(fromInt(pxl),i);
			sIx.send(fromInt(pxl),i);
			end
		else
		for(Int#(8) i = 0; i< RATE; i = i +1) begin
			sIy.send(0,i);
			sIx.send(0,i);
		end

      endrule


      rule ixx_iyy_ixy;
	   c1 <= c1+1;
	   if(c1 < ((IMG-2)/RATE)*(IMG-2))
	    for(Int#(8) i = 0; i< RATE; i = i +1) begin
	   	let dy <- sIy.receive(i);
	   	let dx <- sIx.receive(i);

	   	let y = fxptMult1(dy,dy,2);
	   	let x = fxptMult1(dx,dx,2);
	   	let xy = fxptMult1(dx,dy,2);
	   	sSyy.send(fxptTruncate(y),i);
	   	sSxx.send(fxptTruncate(x),i);
	   	sSxy.send(fxptTruncate(xy),i);

            end
	   else
		for(Int#(8) i = 0; i< RATE; i = i +1) begin
	   		sSyy.send(0,i);
	   		sSxx.send(0,i);
	   		sSxy.send(0,i);
  	   	end
      endrule

      rule harris;
	   c2 <= c2+1;
	   DataType cons = 0.04;
	   if(c2 < ((IMG-4)/RATE)*(IMG-4))
	   for(Int#(8) i = 0; i< RATE; i = i +1) begin
	   	let sxx <- sSxx.receive(i);
	   	let syy <- sSyy.receive(i);
	  	let sxy <- sSxy.receive(i);


	   	let trace = fxptAdd(sxx,syy);
	   	let det = fxptSub(fxptMult1(sxx,syy,2),fxptMult1(sxy,sxy,2));
	   	let val =  fxptSub(det , fxptMult1(fxptMult1(cons,trace,2),trace,2));

		//$display(" %d", fxptGetInt(val));
	   	if(val <10000)
		     $display("%d",0);
           	else
		      $display("%d",255);

	  end
	  else begin
  	  //$display(" total execution time %d clock cycles", clk);
	  $finish(0);
	  end
      endrule

endmodule
endpackage
