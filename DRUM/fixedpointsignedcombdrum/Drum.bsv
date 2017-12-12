
package Drum;
import Multiplier::*;
import FixedPoint::*;

(* synthesize *)
module mkDrum(Multiplier_IFC);

function Tout multN(Tin a, Tin b);
  int pos1=1,pos2=1,flag=0;
  Bit#(32) a1=pack(a);
  Bit#(32) b1=pack(b);
  if(a1[31]!=b1[31])
  flag=1;
  if(a1[31]==1)
   a1 = ~a1+1;
  if(b1[31]==1)
   b1 = ~b1+1;

  a = unpack(a1);
  b = unpack(b1);
  Kin m1;
  Kin m2;

  m1 = fxptTruncate(a);
  m2 = fxptTruncate(b);
  Kout res = fxptMult(m1,m2);
  Fout out = pack(res);
  if(flag==1)
    out=~out+1;
  res = unpack(out);
  Tout ans = fxptZeroExtend(res);
  return ans;
endfunction

function Tout mult(Tin m1,Tin m2) = multN(m1,m2);

method  Tout multiply(Tin m1, Tin m2);
    return mult(m1, m2);
endmethod

endmodule
endpackage: Drum
