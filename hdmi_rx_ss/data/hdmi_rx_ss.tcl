#
# (C) Copyright 2018 Xilinx, Inc.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#

proc generate {drv_handle} {
	foreach i [get_sw_cores device_tree] {
		set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
		if {[file exists $common_tcl_file]} {
			source $common_tcl_file
			break
		}
	}
	set node [gen_peripheral_nodes $drv_handle]
	if {$node == 0} {
		return
	}
	set compatible [get_comp_str $drv_handle]
	set compatible [append compatible " " "xlnx,v-hdmi-rx-ss-3.0"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set connected_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "VIDEO_OUT"]
	set connected_ip_type [get_property IP_NAME $connected_ip]
	if {[string match -nocase $connected_ip_type "v_proc_ss"]} {
		set ports_node [add_or_get_dt_node -n "ports" -l hdmirx_ports -p $node]
		hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
		hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
		set port_node [add_or_get_dt_node -n "port" -l hdmirx_port -u 0 -p $ports_node]
		hsi::utils::add_new_dts_param "${port_node}" "/* Fill the fields xlnx,video-format and xlnx,video-width based on user requirement */" "" comment
		hsi::utils::add_new_dts_param "$port_node" "xlnx,video-format" 0 int
		hsi::utils::add_new_dts_param "$port_node" "xlnx,video-width" 10 int
		hsi::utils::add_new_dts_param "$port_node" "reg" 0 int
		set hdmi_rx_node [add_or_get_dt_node -n "endpoint" -l hdmi_rx_out -p $port_node]
		set topology [get_property CONFIG.C_TOPOLOGY $connected_ip]
		if {$topology == 0} {
			hsi::utils::add_new_dts_param "$hdmi_rx_node" "remote_end_point" vpss_scaler_in reference
		} else {
			hsi::utils::add_new_dts_param "$hdmi_rx_node" "remote_end_point" csc_in reference
		}
	}
	if {[string match -nocase $connected_ip_type "v_scenechange"]} {
		set ports_node [add_or_get_dt_node -n "ports" -l hdmi_rx_ports -p $node]
		hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
		hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
		set port_node [add_or_get_dt_node -n "port" -l hdmi_rx_port -u 0 -p $ports_node]
		hsi::utils::add_new_dts_param "${port_node}" "/* Fill the fields xlnx,video-format and xlnx,video-width based on user requirement */" "" comment
		hsi::utils::add_new_dts_param "$port_node" "xlnx,video-format" 0 int
		hsi::utils::add_new_dts_param "$port_node" "xlnx,video-width" 10 int
		hsi::utils::add_new_dts_param "$port_node" "reg" 0 int
		set hdmi_rx_node [add_or_get_dt_node -n "endpoint" -l hdmirx_out -p $port_node]
		hsi::utils::add_new_dts_param "$hdmi_rx_node" "remote_end_point" scd_in reference
	}
	if {[string match -nocase $connected_ip_type "v_frmbuf_wr"]} {
		set ports_node [add_or_get_dt_node -n "ports" -l hdmirx_ports -p $node]
		hsi::utils::add_new_dts_param "$ports_node" "#address-cells" 1 int
		hsi::utils::add_new_dts_param "$ports_node" "#size-cells" 0 int
		set port_node [add_or_get_dt_node -n "port" -l hdmirx_port -u 0 -p $ports_node]
		hsi::utils::add_new_dts_param "$port_node" "reg" 0 int
		set hdmi_rx_node [add_or_get_dt_node -n "endpoint" -l hdmi_rx_out -p $port_node]
		hsi::utils::add_new_dts_param "$hdmi_rx_node" "remote_end_point" vcap_hdmi_in reference
		set dts_file [current_dt_tree]
		set bus_node "amba_pl"
		set vcap_hdmirx [add_or_get_dt_node -n "vcap_hdmi" -d $dts_file -p $bus_node]
		hsi::utils::add_new_dts_param $vcap_hdmirx "compatible" "xlnx,video" string
		hsi::utils::add_new_dts_param $vcap_hdmirx "dmas" "$connected_ip 0" reference
		hsi::utils::add_new_dts_param $vcap_hdmirx "dma-names" "port0" string
		set vcap_audio_hdmi_node [add_or_get_dt_node -n "ports" -l vcap_hdmi_ports -p $vcap_hdmirx]
		hsi::utils::add_new_dts_param "$vcap_audio_hdmi_node" "#address-cells" 1 int
		hsi::utils::add_new_dts_param "$vcap_audio_hdmi_node" "#size-cells" 0 int
		set vcap_audio_hdmiport_node [add_or_get_dt_node -n "port" -l vcap_hdmi_port -u 0 -p $vcap_audio_hdmi_node]
		hsi::utils::add_new_dts_param "$vcap_audio_hdmiport_node" "reg" 0 int
		hsi::utils::add_new_dts_param "$vcap_audio_hdmiport_node" "direction" input string
		set vcap_audio_hdmi_in_node [add_or_get_dt_node -n "endpoint" -l vcap_hdmi_in -p $vcap_audio_hdmiport_node]
		hsi::utils::add_new_dts_param "$vcap_audio_hdmi_in_node" "remote_end_point" hdmi_rx_out reference
	}

	set link_data0 [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "LINK_DATA0_IN"]
	if {[string match -nocase $link_data0 "vid_phy_controller"]} {
		append phy_names " " "hdmi-phy0"
		append phys  "vphy_lane0 0 1 1 0>,"
	}
	set link_data1 [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "LINK_DATA1_IN"]
	if {[string match -nocase $link_data1 "vid_phy_controller"]} {
		append phy_names " " "hdmi-phy1"
		append phys  " <&vphy_lane1 0 1 1 0>,"
	}
	set link_data2 [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "LINK_DATA2_IN"]
	if {[string match -nocase $link_data2 "vid_phy_controller"]} {
		append phy_names " " "hdmi-phy2"
		append phys " <&vphy_lane2 0 1 1 0"
	}
	hsi::utils::add_new_dts_param "$node" "phy-names" $phy_names stringlist
	hsi::utils::add_new_dts_param "$node" "phys" $phys reference
	set input_pixels_per_clock [get_property CONFIG.C_INPUT_PIXELS_PER_CLOCK [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,input-pixels-per-clock" $input_pixels_per_clock int
	set max_bits_per_component [get_property CONFIG.C_MAX_BITS_PER_COMPONENT [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,max-bits-per-component" $max_bits_per_component int
	set edid_ram_size [get_property CONFIG.C_EDID_RAM_SIZE [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,edid-ram-size" $edid_ram_size hexint
	set audio_out_connect_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "AUDIO_OUT"]
	if {[llength $audio_out_connect_ip] != 0} {
		set audio_out_connect_ip_type [get_property IP_NAME $audio_out_connect_ip]
		if {[string match -nocase $audio_out_connect_ip_type "axis_switch"]} {
			 set connected_ip [hsi::utils::get_connected_stream_ip $audio_out_connect_ip "M00_AXIS"]
                        if {[llength $connected_ip] != 0} {
                                hsi::utils::add_new_dts_param "$node" "xlnx,xlnx-snd-pcm" $connected_ip reference
                        }
		}
	}
	hsi::utils::add_new_dts_param "${node}" "/* User needs to change the property xlnx,audio-enabled=<0x1> based on the HDMI audio path */" "" comment
	hsi::utils::add_new_dts_param "${node}" "xlnx,audio-enabled" 0 hexint
}