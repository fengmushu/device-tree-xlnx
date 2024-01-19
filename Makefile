VERSION ?= 2021.1
XSCT ?= ~/workspace/xilinx/Vitis/$(VERSION)/bin/xsct
BOARD ?= zynq-zed-adv7511-ad9361-fmcomms2-3

XSA_FILE ?= '../openwifi-hw/boards/zed_fmcs2/openwifi_zed_fmcs2/system_top.xsa'
DTSI_FILE ?= '../openwifi/adi-linux/arch/arm/boot/dts/zynq-zed-adv7511.dtsi'

dts:
	# $(RM) -r zynq-7000
	$(XSCT) -eval "source build_dts.tcl; build_dts $(XSA_FILE)"

include_dtsi:
	$(XSCT) -eval "source build_dts.tcl; include_dtsi $(DTSI_FILE)"

compile:
	$(RM) -r zynq-7000/$(BOARD).dtb
	gcc -I zynq-7000 -E -nostdinc -undef -D__DTS__ -x assembler-with-cpp -o zynq-7000/$(BOARD).dts.tmp zynq-7000/$(BOARD).dts
	dtc -I dts -O dtb -o zynq-7000/$(BOARD).dtb zynq-7000/$(BOARD).dts.tmp

clean:
	$(RM) -r .Xil zynq-7000 *.bit *.mmi *.c *.h psu_init.tcl ps7_init.tcl *.html