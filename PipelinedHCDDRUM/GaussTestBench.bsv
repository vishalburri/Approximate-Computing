package GaussTestBench;
import TubeHeader::*;
import FixedPoint::*;
import GaussBlur::*;
import datatypes::*;

import "BDPI" function Action initialize_image(); 
import "BDPI" function Int#(32) readPixel1(Int#(32) ri, Int#(32) cj, Int#(32) ch);

#define IMG 1024
#define RATE1 2

module mkGaussTestBench();
	
       
       Reg#(int) c2 <- mkReg(0);
       Reg#(int) rows  <- mkReg(0);
       Reg#(int) cols  <- mkReg(0-RATE1);
       Reg#(int) clk   <-  mkReg(0);
       Reg#(int) index <- mkReg(0);
       Reg#(Bool) init <- mkReg(True);
       MultiStd dag <- mkGaussBlur();
      
      rule init_rule (init) ;
      		initialize_image();
      		init <= False;
      endrule
	
      rule update_clock;
                        cols <= (cols+RATE1)%IMG;
                        if(cols == IMG - RATE1) begin
                                rows <= rows + 1;
			end
                        clk <= clk + 1;
      endrule

      rule source (clk>=1);
		
                if(rows <= IMG-1) begin
			Int#(10) pxl0 = truncate(readPixel1(rows, cols+0,0));
			Int#(10) pxl1 = truncate(readPixel1(rows, cols+1,0));
	        	dag.send1(pxl0);
	        	dag.send2(pxl1);
		end
		else begin
			dag.send1(0);
			dag.send2(0);
		end

      endrule


     rule result;
           c2 <= c2+1;
           if(c2 < (IMG-8)/RATE1*(IMG-8)-2) begin
			let dr1 <- dag.receive1();
			$display("%d", dr1);

			let dr2 <- dag.receive2();
                        $display("%d", dr2);
	  end
          else begin
          	$finish(0);
          end
      endrule

		
endmodule 
endpackage
