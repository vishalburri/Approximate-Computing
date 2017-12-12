package HarrisTestBench;
import TubeHeader::*;
import FixedPoint::*;
import HarrisCorner::*;
import datatypes::*;

import "BDPI" function Action initialize_image();
import "BDPI" function Int#(32) readPixel1(Int#(32) ri, Int#(32) cj, Int#(32) ch);

#define IMG 800
module mkHarrisTestBench();
	
       Reg#(int) c0 <- mkReg(0);
       Reg#(int) c2 <- mkReg(0);
       Reg#(int) rows  <- mkReg(0);
       Reg#(int) cols  <- mkReg(0);
       Reg#(int) clk   <-  mkReg(0);
       Std dag <- mkHarrisCorner;
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
		Int#(10) pxl0 = truncate(readPixel1(rows, cols,0));
		dag.send(pxl0);
		end
		else
		dag.send(0);
       endrule

     rule blurred;
           c2 <= c2+1;
           if(c2 < (IMG-4)*(IMG-4)-1) begin
           let dr <- dag.receive();
           $display("%d",dr);
          end
          else begin
          $finish(0);
          end
      endrule

		
endmodule 
endpackage
