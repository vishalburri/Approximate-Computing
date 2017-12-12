package Multiplier;

// Multiplier IFC
typedef Bit#(32) Tin;
typedef Bit#(72) Tout;
typedef Bit#(6) Kin;
typedef Bit#(12) Kout;



interface Multiplier_IFC;
    method Action  multiply (Tin m1, Bit#(40) m2,Bit#(6) k);
       method ActionValue#(Bit#(72)) result();
    //method Tout  result();
endinterface

endpackage
