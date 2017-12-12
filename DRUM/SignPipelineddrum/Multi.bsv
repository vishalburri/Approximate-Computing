package Multi;

import Multiplier::*;

(* synthesize *)
module mkMulti( Multiplier_IFC );
Reg#(Bit#(1)) available <- mkReg(0);
Reg#(Bit#(1)) check <- mkReg(0);
Reg#(Bit#(1)) start <- mkReg(0);
Reg#(Bit#(1)) flag <- mkReg(0);
Reg#(Bit#(1)) fl <- mkReg(0);
Reg#(Bit#(1)) sign <- mkReg(0);

Reg#(Bit#(6)) regk <- mkReg(0);
Reg#(Bit#(6)) pos1 <- mkReg(0);
Reg#(Bit#(6)) pos2 <- mkReg(0);
Reg#(Bit#(6)) p1 <- mkReg(0);
Reg#(Bit#(6)) p2 <- mkReg(0);
Reg#(Tin) a <- mkReg(0);
Reg#(Tin) b <- mkReg(0);

Reg#(Tin) x <- mkReg(0);
Reg#(Tin) y <- mkReg(0);

Reg#(Kin) mplr <- mkReg(0);
Reg#(Kin) mcand <- mkReg(0);
Reg#(UInt#(12)) product <- mkReg(0);


rule cycle(available==1);

  if(a[31]==1)
    pos1<=31;
  else if(a[30]==1)
    pos1<=30;
  else if(a[29]==1)
    pos1<=29;
  else if(a[28]==1)
    pos1<=28;
  else if(a[27]==1)
      pos1<=27;
  else if(a[26]==1)
      pos1<=26;
  else if(a[25]==1)
      pos1<=25;
  else if(a[24]==1)
      pos1<=24;
  else if(a[23]==1)
      pos1<=23;
  else if(a[22]==1)
      pos1<=22;
  else if(a[21]==1)
      pos1<=21;
  else if(a[20]==1)
      pos1<=20;
  else if(a[19]==1)
      pos1<=19;
  else if(a[18]==1)
      pos1<=18;
  else if(a[17]==1)
      pos1<=17;
  else if(a[16]==1)
      pos1<=16;
  else if(a[15]==1)
      pos1<=15;
  else if(a[14]==1)
      pos1<=14;
  else if(a[13]==1)
      pos1<=13;
  else if(a[12]==1)
      pos1<=12;
  else if(a[11]==1)
      pos1<=11;
  else if(a[10]==1)
      pos1<=10;
  else if(a[9]==1)
      pos1<=9;
  else if(a[8]==1)
      pos1<=8;
  else if(a[7]==1)
      pos1<=7;
  else if(a[6]==1)
      pos1<=6;

      if(b[31]==1)
        pos2<=31;
      else if(b[30]==1)
        pos2<=30;
      else if(b[29]==1)
        pos2<=29;
      else if(b[28]==1)
        pos2<=28;
      else if(b[27]==1)
          pos2<=27;
      else if(b[26]==1)
          pos2<=26;
      else if(b[25]==1)
          pos2<=25;
      else if(b[24]==1)
          pos2<=24;
      else if(b[23]==1)
          pos2<=23;
      else if(b[22]==1)
          pos2<=22;
      else if(b[21]==1)
          pos2<=21;
      else if(b[20]==1)
          pos2<=20;
      else if(b[19]==1)
          pos2<=19;
      else if(b[18]==1)
          pos2<=18;
      else if(b[17]==1)
          pos2<=17;
      else if(b[16]==1)
          pos2<=16;
      else if(b[15]==1)
          pos2<=15;
      else if(b[14]==1)
          pos2<=14;
      else if(b[13]==1)
          pos2<=13;
      else if(b[12]==1)
          pos2<=12;
      else if(b[11]==1)
          pos2<=11;
      else if(b[10]==1)
          pos2<=10;
      else if(b[9]==1)
          pos2<=9;
      else if(b[8]==1)
          pos2<=8;
      else if(b[7]==1)
          pos2<=7;
      else if(b[6]==1)
          pos2<=6;


x<=a;
y<=b;
check<=1;
fl<=flag;
endrule

rule update(check==1);

if(pos1>=regk)
begin
  mplr <= x[pos1:pos1-regk+1];
  p1<=pos1;
end
else
begin
  p1<=regk-1;
  mplr <= x[regk-1:0];
end

if(pos2>=regk)
begin
  p2<=pos2;
  mcand <= y[pos2:pos2-regk+1];
end
else
begin
  p2<=regk-1;
  mcand <= y[regk-1:0];
end
sign<=fl;
endrule


method Action multiply(Tin m1, Tin m2, Bit#(6) k);
  if(m1[31]==1)
  a<=(~m1)+1;
  else
  a<=m1;
  if(m2[31]==1)
  b<=(~m2)+1;
  else
  b<=m2;
  regk<=k;
  if(m1[31]!=m2[31])
  flag<=1;
  else
  flag<=0;
  available<=1;
endmethod

method Tout result() ;
if(sign==0)
  return {0,pack(unsignedMul(unpack(mcand),unpack(mplr)))}<<p1+p2-2*regk+2;
else
  return {~{0,pack(unsignedMul(unpack(mcand),unpack(mplr)))<<p1+p2-2*regk+2}+1};
endmethod

endmodule : mkMulti

endpackage : Multi
