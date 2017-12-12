package Multiplier;
import FixedPoint::*;
// Multiplier IFC
typedef FixedPoint#(16,16) Tin;
typedef FixedPoint#(32,32) Tout;
typedef FixedPoint#(16,6) Kin;
typedef FixedPoint#(32,12) Kout;
typedef Bit#(TAdd#(32,12)) Fout;

interface Multiplier_IFC;
  method  Tout multiply(Tin m1,Tin m2);
endinterface

endpackage
