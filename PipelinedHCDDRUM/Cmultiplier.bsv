package Cmultiplier;

// Multiplier IFC
typedef Bit#(32) Tin;
typedef Bit#(64) Tout;
typedef Bit#(2) Kin;

interface Cmultiplier_IFC;
    method Tout  multiply (Tin m1, Tin m2,Bit#(6) k);
endinterface

endpackage
