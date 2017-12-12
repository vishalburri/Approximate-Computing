package Multiplier;

// Multiplier IFC
typedef Bit#(32) Tin;
typedef Bit#(64) Tout;
typedef Bit#(10) Kin;

interface Multiplier_IFC;
    method Bit#(72)  multiply (Tin m1, Bit#(40) m2,Bit#(6) k);
endinterface

endpackage
