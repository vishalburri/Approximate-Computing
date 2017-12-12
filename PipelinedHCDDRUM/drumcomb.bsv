package drumcomb;
import FixedPoint::*;
import Cmultiplier::*;

function Bit#(rf) mulN(Bit#(af) a, Bit#(bf) b,Bit#(6) k)
 provisos (Add#(af,bf,rf),
	Add#(a__, 64, rf),
	Add#(b__, 4, rf)
	   // rf = af + bf
            );

  Kin m1,m2;
  Bit#(1) flag=0;
  Bit#(6) pos1=k-1;
  Bit#(6) pos2=k-1;
  if(a[valueOf(af)-1]!=b[valueOf(bf)-1])
  flag=1;

  if(a[valueOf(af)-1]==1)
    a = ~a+1;
  if(b[valueOf(bf)-1]==1)
    b= ~b+1;
    for(int i=0;i<=fromInteger(valueOf(af)-1);i=i+1)
      begin
        if(a[i]==1)
        pos1 = pack(i)[5:0];
      end

    for(int i=0;i<=fromInteger(valueOf(bf)-1);i=i+1)
      begin
        if(b[i]==1)
        pos2 = pack(i)[5:0];
      end

    if(pos1<k)
      pos1=k-1;
    if(pos2<k)
      pos2=k-1;

m1 = a[pos1:pos1-k+1];
m2 = b[pos2:pos2-k+1];
if(flag==0)
  return {0,pack(unsignedMul(unpack(m1),unpack(m2)))}<<pos1+pos2-2*k+2;
else
  return ~({0,pack(unsignedMul(unpack(m1),unpack(m2)))}<<pos1+pos2-2*k+2)+1;
endfunction


function FixedPoint#(r1,r2) fxptMult1(FixedPoint#(a1,a2) x,FixedPoint#(b1,b2) y,Bit#(6) k)
 provisos (Add#(a1,b1,r1)   // ri = ai + bi
             ,Add#(a2,b2,r2)   // rf = af + bf
             ,Add#(a1,a2,ab)
             ,Add#(b1,b2,bb)
             ,Add#(ab,bb,rb)
             ,Add#(r1,r2,rb)
	      ,Add#(a__, 64, rb)
	      ,Add#(b__, 4, rb)
            ) ;

	Bit#(ab) x1 = pack(x);
	Bit#(bb) y1 = pack(y);
	Bit#(rb) res=mulN(x1,y1,k);
	return unpack(res);
endfunction

endpackage
