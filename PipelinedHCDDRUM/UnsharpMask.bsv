package UnsharpMask;
import Stage::*;
import FIFO::*;
import TubeHeader::*;
import FixedPoint::*;
import datatypes::*;

import "BDPI" function Action initialize_image(); 
import "BDPI" function Int#(32) readPixel1(Int#(32) ri, Int#(32) cj, Int#(32) ch);

(*synthesize*)
#define IMG 800
module mkUnsharpMask();
       
	
	//###################################################//
        CoeffType coeffs1[3][3];
        for(int i = 0; i < 3; i = i+1)
                for(int j= 0 ;j< 3; j = j+1)
                        coeffs1[i][j] = 0.11;


        CoeffType coeffs2[5][5];
        for(int i = 0; i < 5; i = i+1)
                for(int j= 0 ;j< 5; j = j+1)
                        coeffs2[i][j] = 0.04;

        CoeffType coeffs3[9][9];
        for(int i = 0; i < 9; i = i+1)
                for(int j= 0 ;j< 9; j = j+1)
                        coeffs3[i][j] = 0.01;


        //#####################################################//

	ForwardHeader f;
        f.row = 2;
        f.col1 = 3;
        f.col2 = IMG-2;
        f.shiftVertical = 0 ;
        f.fifosize = IMG + 5 ;

        Filter  stageR <- mkStage(5,IMG,IMG,coeffs2,True,f);
        Filter  stageG <- mkStage(5,IMG,IMG,coeffs2,True,f);
        Filter  stageB <- mkStage(5,IMG,IMG,coeffs2,True,f);



       Reg#(int) c0 <- mkReg(0);
       Reg#(int) c1 <- mkReg(0);
       Reg#(int) c2 <- mkReg(0);
       Reg#(int) c3 <- mkReg(0);
       Reg#(int) c4 <- mkReg(0);
       Reg#(int) rows  <- mkReg(0);
       Reg#(int) cols  <- mkReg(0);
       Reg#(int) clk   <-  mkReg(0);
       Reg#(int) index <- mkReg(0);
       Reg#(Bool) init <- mkReg(True);

      rule init_rule (init) ;
      initialize_image();
      init <= False;
      endrule
	
      rule update_clock;
                        cols <= (cols+1)%IMG;
                        if(cols == IMG - 1) begin
                                rows <= rows + 1;
                        end
                        clk <= clk + 1;
      endrule

      rule source (clk>=1);

                if(rows <= IMG-1) begin
		Int#(20) pxl0 = truncate(readPixel1(rows, cols,0));
		Int#(20) pxl1 = truncate(readPixel1(rows, cols,1));
		Int#(20) pxl2 = truncate(readPixel1(rows, cols,2));
	        	stageR.send(fromInt(pxl0));
	        	stageG.send(fromInt(pxl1));
	        	stageB.send(fromInt(pxl2));
		end
		else begin
			stageR.send(0);
			stageG.send(0);
			stageB.send(0);
		end

      endrule
   
      rule blur;
	   c4 <= c4+1;
	   if(c4 < (IMG-4)*(IMG-4)) begin
           let d0 <- stageR.receive();
           let d1 <- stageG.receive();
           let d2 <- stageB.receive();

	   DataType w1 = 2;
	   DataType w2 = 1;
	   let f0 <- stageR.forwarded();
	   let f1 <- stageG.forwarded();
	   let f2 <- stageB.forwarded();

		if(fxptSub(f0,d0) < 0.01)
		$display("%d",fxptGetInt(d0));
		else begin
		let val1 = fxptSub(fxptMult(f0,w1), fxptMult(d0,w2));
		$display("%d",fxptGetInt(val1));
		end

		if(fxptSub(f1,d1) < 0.01)
		$display("%d",fxptGetInt(d1));
		else begin
		let val2 = fxptSub(fxptMult(f1,w1), fxptMult(d1,w2));
		$display("%d",fxptGetInt(val2));
		end

		if(fxptSub(f2,d2) < 0.01)
		$display("%d",fxptGetInt(d2));
		else begin
		let val3 = fxptSub(fxptMult(f2,w1), fxptMult(d2,w2));
		$display("%d",fxptGetInt(val3));
		end

	  end
	  else begin
          $finish(0);
	  end
      endrule

endmodule 
endpackage
