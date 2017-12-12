package MultiTb;

// testbench for Mult1

import Multiplier::*;
import Drum::*;
import FixedPoint::*;




Tin notestinputs = 10;

(* synthesize *)
module mkMultiTb (Empty);

   Reg#(int) cycle <- mkReg(0);
   Reg#(Tin) c    <- mkReg(0);
   Reg#(Tin) d    <- mkReg(0);

   Reg#(int) cnt <- mkReg(0);
   let fh <- mkReg(InvalidFile) ;
   // The dut

   Multiplier_IFC dut <- mkMulti;

   // RULES ----------------
   rule cyclecount;
	  cycle <= cycle + 1;
   endrule

   rule rule_tb_1 (c < notestinputs);
   FixedPoint#(20,12) x = 1;
   FixedPoint#(8,32) y = 2;
   Bit#(32) op1 = pack(x);
   Bit#(40) op2 = pack(y);

   FixedPoint#(20,12) expected = fxptTruncate(fxptMult(x,y));
      $display ("expected: x = %b", expected);
      Bit#(6) k=6;
      dut.multiply (op1, op2,k);
      c<=c+1;
   endrule

   rule rule_tb_2;
      Bit#(72) z <- dut.result();
      FixedPoint#(28,44) tot = unpack(z);
      FixedPoint#(20,12) r1 = fxptTruncate(tot);
      $display("Result = %b %b",tot,r1);
      d<=d+1;
   endrule

   // TASK: Add a rule to invoke $finish(0) at the appropriate moment
   rule stop (d >= notestinputs);
       $finish(0);
   endrule


endmodule : mkMultiTb

endpackage : MultiTb
