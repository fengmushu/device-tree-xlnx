VERSION ?= 2021.1
XSCT=~/workspace/xilinx/Vitis/$(VERSION)/bin/xsct

dts:
	$(RM) -r zynq-7000
	$(XSCT) -eval "source build_dts.tcl; build_dts $(XSA_FILE)"

include_dtsi:
	$(XSCT) -eval "source build_dts.tcl; include_dtsi $(DTSI_FILE)"

compile:
	$(RM) -r zynq-7000/system-top.dtb
	gcc -I zynq-7000 -E -nostdinc -undef -D__DTS__ -x assembler-with-cpp -o zynq-7000/system-top.dts.tmp zynq-7000/system-top.dts
	dtc -I dts -O dtb -o zynq-7000/system-top.dtb zynq-7000/system-top.dts.tmp

clean:
	$(RM) -r .Xil zynq-7000 *.bit *.mmi *.c *.h psu_init.tcl ps7_init.tcl *.html