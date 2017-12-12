# This Makefile can be used from each of the Part subdirectories
# For example:    'make s1'

BSC=bsc

# ----------------------------------------------------------------
# Bluesim targets

.PHONY: dag usm harris harrisx red

red:
	$(BSC)  -verilog -u -cpp CreateRed.bsv
	$(BSC)  -sim  -u -g mkTestReducer  -show-schedule -cpp  TestReducer.bsv
	$(BSC)  -sim  -e mkTestReducer  -o red  *.ba image-utilities.cpp


dag:
	$(BSC)  -verilog -u -cpp GaussBlur.bsv
	$(BSC)  -sim  -u -g mkGaussTestBench  -show-schedule -cpp  GaussTestBench.bsv
	$(BSC)  -sim  -e mkGaussTestBench  -o gauss  *.ba image-utilities.cpp

usm:
	$(BSC)  -sim  -u -g mkUnsharpMask -show-schedule -cpp  UnsharpMask.bsv
	$(BSC)  -sim  -e mkUnsharpMask  -o usm  *.ba image-utilities.cpp

harris:
	$(BSC)  -verilog -u -cpp HarrisCorner.bsv
	$(BSC)  -sim  -u -g mkHarrisTestBench -show-schedule -cpp HarrisTestBench.bsv
	$(BSC)  -sim  -e mkHarrisTestBench  -o harr  *.ba image-utilities.cpp

harrisx:
	$(BSC)  -verilog -u -cpp HarrisCornerMultirate.bsv
	$(BSC)  -sim  -u -g mkHarrisCornerMultirate -show-schedule -cpp HarrisCornerMultirate.bsv
	$(BSC)  -sim  -e mkHarrisCornerMultirate  -o harrx  *.ba image-utilities.cpp


# -----------------------------------------------------------------

.PHONY: clean fullclean

# Clean all intermediate files
clean:
	rm -f  *~  *.bi  *.bo  *.ba  *.h  *.cxx  *.o

# Clean all intermediate files, plus Verilog files, executables, schedule outputs
fullclean:
	rm -f  *~  *.bi  *.bo  *.ba  *.h  *.cxx  *.o
	rm -f  *.exe   *.so  *.sched  *.v  *.vcd

