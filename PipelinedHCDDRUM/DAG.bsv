package DAG;
import TubeHeader::*;
import FIFO::*;
import bram::*;
import FixedPoint::*;
import Stage2e::*;
import Vector::*;
import SpecialFIFOs::*;
import datatypes::*;

#define IMG 1200
(*synthesize*)
module mkDAG(StdIO);

	//#########################################################//

	Vector#(9, FixedPoint#(8,32)) coeffs = newVector;
	
	coeffs[0] = 0.077847;
        coeffs[1] = 0.123317;
        coeffs[2] = 0.077847;
        coeffs[3] = 0.123317;
        coeffs[4] = 0.195346;
        coeffs[5] = 0.123317;
        coeffs[6] = 0.077847;
        coeffs[7] = 0.123317;
        coeffs[8] = 0.077847;

	//########################################################//


	ForwardingHeader f;
        f.location = 2*IMG+2;
        f.forcols = 2;
        f.startC = 0;
        f.endC = IMG-4;
        f.extent = 2;
        f.size = 2*IMG;

	Reg#(Bool) enab <- mkReg(False);

	Vector#(1,ForwardingHeader) forwards = newVector;
	forwards[0] = f;

	Domain domain;
	domain.rows=IMG; domain.cols=IMG; domain.stencil=3;

	Domain domain2;
	domain2.rows=IMG-2; domain2.cols=IMG-2; domain2.stencil=3;



        Filter gaussR <- mkStage2e(domain,9,coeffs,True,1,forwards);
        //Filter gaussG <- mkStage2e(domain,9,coeffs,False,forwards);
        //Filter gaussB <- mkStage2e(domain,9,coeffs,False,forwards);

	Filter gaussR1 <- mkStage2e(domain,9,coeffs,False,1,forwards);
        //Filter gaussG1 <- mkStage2e(domain,9,coeffs,False,forwards);
        //Filter gaussB1 <- mkStage2e(domain,9,coeffs,False,forwards);

       
	
       Reg#(int) c0 <- mkReg(0);
       Reg#(int) c1 <- mkReg(0);
       Reg#(int) c2 <- mkReg(0);
       Reg#(int) rows  <- mkReg(0);
       Reg#(int) cols  <- mkReg(0);
       Reg#(int) clk   <-  mkReg(0);
       Reg#(int) index <- mkReg(0);
       Reg#(Int#(20)) upward <- mkReg(-1);
       FIFO#(Int#(10)) instream <- mkFIFO;
       FIFO#(Int#(10)) forward <- mkFIFO;
       Reg#(Bool) init <- mkReg(True);
       
       
       Reg#(Bool) blur_enab <- mkReg(False);
       /*Reg#(DataType) dr <- mkReg(0);
       Reg#(DataType) fr <- mkReg(0);
       Reg#(Int#(20)) r <- mkReg(0);*/

     
      rule source; 
		c0 <= c0+1;
		if(c0 < IMG*IMG) begin
		let pxl = instream.first; instream.deq;
		gaussR.send(fromInt(pxl));
		//gaussG.send(fromInt(pxl2));
		//gaussB.send(fromInt(pxl3));
		end
		else begin
			gaussR.send(0);
			//gaussG.send(0);
			//gaussB.send(0);
		end
       endrule


       rule blur1;
	   c1 <= c1+1;
	   if(c1 < (IMG-2)*(IMG-2)) begin
           let dr <-  gaussR.receive();
           //let dg <- gaussG.receive();
           //let db <- gaussB.receive();


	   gaussR1.send(dr);
	   //gaussG1.send(dg);
	   //gaussB1.send(db);
	  end
	  
	  else begin
		//$finish(0);
           gaussR1.send(0);
	   //gaussG1.send(0);
	   //gaussB1.send(0);

	  end
      endrule

      /*rule blurred_intr;
 	    let x <- gaussR1.receive();
            let y <- gaussR.forwarded(0);
	    r  <=  fxptGetInt(y)-fxptGetInt(x);
	    blur_enab <= True;
      endrule */     

      rule blurred; //(blur_enab == True);
           c2 <= c2+1;
           if(c2 < (IMG-4)*(IMG-4)) begin
           let dr <- gaussR1.receive();
           let fr <- gaussR.forwarded(0);
           //let dg <- gaussG1.receive();
           //let db <- gaussB1.receive();
           let r = fxptGetInt(dr);//-fxptGetInt(dr);
           forward.enq(truncate(r));
           //$display("%d %d",fxptGetInt(dr), fxptGetInt(fr));
           //$display("%d",fxptGetInt(db));
          end
          //else begin
          //$display(" end of execution  %d" , c0);
          //$finish(0);
          //end
      endrule
      
      method Action send(Int#(10) data);
                        instream.enq(data);
      endmethod

      method ActionValue#(Int#(10)) receive();
                        let d = forward.first; forward.deq;
                        return d;
      endmethod



endmodule 
endpackage: DAG
