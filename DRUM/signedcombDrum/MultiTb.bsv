package MultiTb;

// testbench for Multi

import Multiplier::*;
import Drum::*;
import LFSR::*;
import FixedPoint::*;

Tin notestinputs=1;

(* synthesize *)
module mkMultiTb (Empty);

   LFSR#(Bit#(32)) lfsr1 <- mkLFSR_32;
   LFSR#(Bit#(32)) lfsr2 <- mkLFSR_32;

   Reg#(Tin) c    <- mkReg(0);
   Reg#(Bool) starting <- mkReg(True);
   Reg#(int) cnt <- mkReg(0);
   let fh <- mkReg(InvalidFile) ;

      rule open(cnt==0);
      String dumpFile = "file1.txt" ;
      File lfh <- $fopen( dumpFile, "w" ) ;
      fh <= lfh ;
      cnt<=1;
      endrule

   // The dut
   Multiplier_IFC dut <- mkDrum;

   // RULES ----------------

   rule start (starting);
	   starting <= False;
   endrule

   rule rule_tb ((c < notestinputs) && !starting );
      //Tin op1 = lfsr1.value();
      //Tin op2 = lfsr2.value();
      //FixedPoint#(20,12) x = -2000.84389898;
      //FixedPoint#(20,12) y = 38.084987;
      Bit#(32) op1 = 2;//pack(x);
      Bit#(40) op2 = 2;//pack(y);

      Bit#(6) k=10;
      Bit#(72) result;
      //$display ("    x = %b, y = %b z=%b", op1, op2,op1*op2);
      result = dut.multiply (op1, op2,k);
      //FixedPoint#(20,12) expected = fxptTruncate(fxptMult(x,y));
      //FixedPoint#(40,24) tot = unpack(result);
      //FixedPoint#(20,12) r1 = fxptTruncate(tot);

      $display("    Result = %b \n    Expect = %b \n   ", result,result);

      c<=c+1;
      lfsr1.next();
      lfsr2.next();
      $display("\n");
   endrule

   // TASK: Add a rule to invoke $finish(0) at the appropriate moment
   rule stop (c >= notestinputs);
       $finish(0);
   endrule


endmodule : mkMultiTb

endpackage : MultiTb
