package MultiTb;

// testbench for Multi

import Multiplier::*;
import Drum::*;
import LFSR::*;
import Real :: *;
import FixedPoint::*;
Tin notestinputs=1;

(* synthesize *)
module mkMultiTb (Empty);

   LFSR#(Bit#(32)) lfsr1 <- mkLFSR_32;
   LFSR#(Bit#(32)) lfsr2 <- mkLFSR_32;

   Reg#(Tin) c    <- mkReg(0);
   Reg#(Bool) starting <- mkReg(True);
   Reg#(int) cnt <- mkReg(0);


   // The dut
   Multiplier_IFC dut <- mkDrum;

   // RULES ----------------

   rule start (starting);
	   starting <= False;
   endrule

  rule rule_tb ((c < notestinputs) && !starting );
   FixedPoint#(16,16) op1 = 3.1415926;
   FixedPoint#(16,16) op2 = 3.1415926;
   FixedPoint#(32,32) result = dut.multiply(op1,op2);
   FixedPoint#(32,32) expected = fxptMult(op1,op2);
   Int#(32) i_part = fxptGetInt(result);
   UInt#(32) f_part = fxptGetFrac(result);
   c<=c+1;
   $display("Actual: %b \nExpect :%b\ninteger: %b\nfraction:%b\n",result,expected,i_part,f_part);
  endrule

   // TASK: Add a rule to invoke $finish(0) at the appropriate moment
   rule stop (c >= notestinputs);
       $finish(0);
   endrule


endmodule : mkMultiTb

endpackage : MultiTb
