package PyramidBlending;
import FIFO::*;
import bramfifo::*;
import bram::*;
import FixedPoint::*;
import datatypes::*;
import switch::*;

import "BDPI" function Action initialize_image();
import "BDPI" function Int#(32) readPixel1(Int#(32) ri, Int#(32) cj, Int#(32) ch);
import "BDPI" function Int#(32) readPixel2(Int#(32) ri, Int#(32) cj, Int#(32) ch);
import "BDPI" function Int#(32) readPixel3(Int#(32) ri, Int#(32) cj, Int#(32) ch);

(*synthesize*)
#define IMG 1024
#define RATE 8
module mkPyramidBlending();
       
   

       Switch sw[3];
       Switch mem[3];
       Switch swUp[3];

       Switch sw1[3];
       Switch mem1[3];
       Switch swUp1[3];


       Switch swUp2 <- mkSwitch(2,4);
       Switch mem2 <- mkSwitch(4,4);

       Switch swUp3 <- mkSwitch(4,8);
       Switch mem3 <- mkSwitch(8,8);

       Reg#(int) c1[3];
       Reg#(int) c2[3];
       Reg#(int) c3[3];
       Reg#(int) c4[3];
       Reg#(int) c5[3];
       Reg#(int) c6 <- mkReg(0);
       Reg#(int) c7 <- mkReg(0);
       Reg#(int) c8 <- mkReg(0);
       Reg#(int) c9 <- mkReg(0);
       Reg#(int) c10 <- mkReg(0);
       Reg#(int) c0[3]; 

       FIFO#(DataType) _Laplacian1[3][8][8];
       FIFO#(DataType) _Laplacian2[3][4][4];
       FIFO#(DataType) _Laplacian3[3][2][2];

      


       for(int i=0;i< 3; i = i + 1) begin
       sw[i] <- mkSwitch(8,4);
       mem[i] <- mkSwitch(8,8);
       swUp[i] <- mkSwitch(4,8);


       sw1[i] <- mkSwitch(4,2);
       mem1[i] <- mkSwitch(4,4);
       swUp1[i] <- mkSwitch(2,4);

       c1[i] <- mkReg(0);
       c2[i] <- mkReg(0);
       c3[i] <- mkReg(0);
       c4[i] <- mkReg(0);
       c5[i] <- mkReg(0);


       for(int l = 0; l<2 ; l = l+1)
                for(int m = 0 ;m<2; m = m+1)
                        _Laplacian3[i][l][m] <- mkFIFO;
      
	
	for(int l = 0; l<8 ; l = l+1)
		for(int m = 0 ;m<8; m = m+1)
       			_Laplacian1[i][l][m] <- mkFIFO;

	for(int l = 0; l<4 ; l = l+1)
                for(int m = 0 ;m<4; m = m+1)
                        _Laplacian2[i][l][m] <- mkFIFO;

       end

       

       Reg#(int) rows  <- mkReg(0);
       Reg#(int) cols  <- mkReg(0);
       Reg#(Int#(20)) clk   <-  mkReg(0);
       Reg#(int) index <- mkReg(0);
       Reg#(Bool) init <- mkReg(True);

      rule init_rule (clk == 0);
        initialize_image();
        clk <= clk + 1;
      endrule

      rule update_clock (clk >=1);
                        cols <= (cols+1)%(IMG/RATE);
                        if(cols >= IMG/RATE-1)
                                rows <= rows + 1;
      endrule

      for(int im = 0; im < 3; im = im+1) begin
      rule source (clk>=1);

                if( rows < (IMG/RATE)) begin

		for(Int#(8) i = 0 ;i< RATE; i = i+1) 
                	for(Int#(8) j= 0 ;j< RATE; j = j + 1) begin

				Int#(20) pixl = 0;
				int r = (rows*RATE)+ extend(i);
				int c = (cols*RATE) + extend(j);
				if( im == 0)	
                        	pixl = truncate(readPixel1(r,c,0));
				if( im == 1)
                                pixl = truncate(readPixel2(r,c,0));
				if( im == 2)
                                pixl = truncate(readPixel3(r,c,0));
				sw[im].put(fromInt(pixl),i,j);
				mem[im].put(fromInt(pixl),i,j);
                	end
                end
                else begin
                	for(Int#(8) i=0; i< RATE ; i = i +1)
				for(Int#(8) j=0; j< RATE ; j = j +1) begin
                        		sw[im].put(0,i,j);
					mem[im].put(0,i,j);
			end
                end

      endrule


      rule gauss_1;

		c1[im] <= c1[im]+1;
		if(c1[im] < ((IMG/8) * (IMG/8))/(1*1)) 
		for(Int#(8)  i = 0; i< 4; i = i +1)
			for(Int#(8) j = 0; j<4; j = j +1) begin
				let d <- sw[im].get(i,j);
				swUp[im].put(d,i,j);
				sw1[im].put(d,i,j);
				mem1[im].put(d,i,j);
			end
		else begin
		for(Int#(8)  i = 0;i< 4; i = i +1)
			for(Int#(8) j = 0 ;j<4; j = j +1) begin
				swUp[im].put(0,i,j);
				sw1[im].put(0,i,j);
				mem1[im].put(0,i,j);
			end
		end


      endrule
      rule laplacian_1;
	      		c2[im] <= c2[im] + 1;
			if(c2[im] < ((IMG/8) * (IMG/8))/(1*1)) begin
				for(Int#(8)  i = 0;i< 8; i = i +1 )
					for(Int#(8) j = 0 ;j<8; j = j +1) begin
						DataType f <- mem[im].get(i,j);
						DataType d <- swUp[im].get(i,j);
						if(im != 2) begin
							DataType diff = fxptTruncate(fxptSub(d,f));
                                                	if(diff <0)
                                                	_Laplacian1[im][i][j].enq(0);
                                                	else
                                                	_Laplacian1[im][i][j].enq(diff);
						end
						else
							_Laplacian1[im][i][j].enq(d);
					end
			end
			else
			for(Int#(8)  i = 0;i< 8; i = i +1 )
                                       for(Int#(8) j = 0 ;j<8; j = j +1)
                                                _Laplacian1[im][i][j].enq(0);
	
      endrule

      rule gauss_2_laplacian_3;

                c3[im] <= c3[im]+1;
                if(c3[im] < ((IMG/8) * (IMG/8))/(1*1))
                for(Int#(8)  i = 0;i< 2; i = i +1 )
                        for(Int#(8) j = 0 ;j<2; j = j +1) begin
			let d <- sw1[im].get(i,j);
			swUp1[im].put(d,i,j);
			_Laplacian3[im][i][j].enq(d);
                        end
                else begin
		for(Int#(8)  i = 0;i< 2; i = i +1 )
                        for(Int#(8) j = 0 ;j<2; j = j +1) begin
				swUp1[im].put(0,i,j);
			end
                end


      endrule

      rule laplacian_2;
                        c4[im] <= c4[im] + 1;
                        if(c4[im] < ((IMG/8) * (IMG/8))/(1*1)) begin
                                for(Int#(8)  i = 0;i< 4; i = i +1 )
                                        for(Int#(8) j = 0 ;j<4; j = j +1) begin
                                                DataType f <- mem1[im].get(i,j);
                                                DataType d <- swUp1[im].get(i,j);
						if(im != 2) begin
                                                        DataType diff = fxptTruncate(fxptSub(d,f));
                                                        if(diff <0)
                                                        _Laplacian2[im][i][j].enq(0);
                                                        else
                                                        _Laplacian2[im][i][j].enq(diff);
                                                end
                                                else
                                                        _Laplacian2[im][i][j].enq(d);
                                        end
                        end
			else
				for(Int#(8)  i = 0;i< 4; i = i +1 )
                                        for(Int#(8) j = 0 ;j<4; j = j +1)
						_Laplacian2[im][i][j].enq(0);

      endrule

      end

      rule blend_1;

		c6 <= c6 +1;
		if(c6 < ((IMG/8) * (IMG/8))/(1*1)) 
		for(Int#(8) i=0;i<2;i = i+1)
                   for(Int#(8) j=0; j<2; j = j+1) begin
			let img1 = _Laplacian3[0][i][j].first; _Laplacian3[0][i][j].deq;
			let img2 = _Laplacian3[1][i][j].first; _Laplacian3[1][i][j].deq;
			let mask = _Laplacian3[2][i][j].first; _Laplacian3[2][i][j].deq;
			DataType one = 1;
			DataType pixl = fxptTruncate(fxptAdd(fxptMult(mask,img1), fxptMult(fxptSub(one,mask),img2))); 
			swUp2.put(pixl,i,j);
		end
		else begin
		for(Int#(8) i=0;i<2;i = i+1)
                   for(Int#(8) j=0; j<2; j = j+1)	
			swUp2.put(0,i,j);
		end

				
      endrule

      rule blend_2;
		c8 <= c8+1;
                if(c8 < ((IMG/8) * (IMG/8))/(1*1))
                for(Int#(8) i=0;i<4;i = i+1)
                   for(Int#(8) j=0; j<4; j = j+1) begin
                        let img1 = _Laplacian2[0][i][j].first; _Laplacian2[0][i][j].deq;
                        let img2 = _Laplacian2[1][i][j].first; _Laplacian2[1][i][j].deq;
                        let mask = _Laplacian2[2][i][j].first; _Laplacian2[2][i][j].deq;

			DataType one = 1;
                        let pixl = fxptTruncate(fxptAdd(fxptMult(mask,img1), fxptMult(fxptSub(one,mask),img2))); 
			mem2.put(pixl,i,j);
                end
                else begin
                for(Int#(8) i=0;i<4;i = i+1)
                   for(Int#(8) j=0; j<4; j = j+1)
                        mem2.put(0,i,j);
                end

      endrule
	
      rule blend_3;
                c9 <= c9+1;
                if(c9 < ((IMG/8) * (IMG/8))/(1*1))
                for(Int#(8) i=0;i<8;i = i+1)
                   for(Int#(8) j=0; j<8; j = j+1) begin
                        let img1 = _Laplacian1[0][i][j].first; _Laplacian1[0][i][j].deq;
                        let img2 = _Laplacian1[1][i][j].first; _Laplacian1[1][i][j].deq;
                        let mask = _Laplacian1[2][i][j].first; _Laplacian1[2][i][j].deq;



			DataType one = 1;
                        let pixl = fxptTruncate(fxptAdd(fxptMult(mask,img1), fxptMult(fxptSub(one,mask),img2))); 

                        mem3.put(pixl,i,j);
                end
                else begin
                for(Int#(8) i=0;i<8;i = i+1)
                   for(Int#(8) j=0; j<8; j = j+1)
                        mem3.put(0,i,j);
                end

      endrule


      rule blend_upsample_1;
		c7 <= c7 +1;
                if(c7 < ((IMG/8) * (IMG/8))/(1*1)-1) begin

			for(Int#(8) i=0;i<4;i = i+1)
				for(Int#(8) j=0; j<4; j = j+1) begin
					let d <- swUp2.get(i,j);
					let a <- mem2.get(i,j);
					let ad = fxptAdd(d,a);
					swUp3.put(fxptTruncate(ad),i,j);
				end
		end
		else begin
		for(Int#(8) i=0;i<4;i = i+1)
                                for(Int#(8) j=0; j<4; j = j+1)
					swUp3.put(0,i,j);	
		end

      endrule

     rule blend_upsample_2;

                c10 <= c10 +1;
                if(c10 < ((IMG/8) * (IMG/8))/(1*1)-1) begin

                        for(Int#(8) i=0;i<8;i = i+1)
                                for(Int#(8) j=0; j<8; j = j+1) begin
                                        let d <- swUp3.get(i,j);
                                        let a <- mem3.get(i,j);
                                        $display("%d", fxptGetInt(fxptAdd(a,d)));
                                end
                end
                else begin
                $finish(0);
                end

      endrule

endmodule 
endpackage 
