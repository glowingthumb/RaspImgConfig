#   Script to configure Raspbian Operating System image for Raspberry Pi.
#   Copyright (C) 2015  Subhajit Ghosh (subhajit@glowingthumb.com)
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.

#!/bin/bash
set +x

export RIC_RASP_LETEST_URL="https://downloads.raspberrypi.org/raspbian_latest"
export RIC_RASP_SRC_IMG_PATH=
export RIC_SD_PATH=
export RIC_DST_IMG_DIR=
export RIC_IP_ADD_ETHER=
export RIC_IP_ADD_WIFI=
export RIC_SUB_MASK=
export RIC_DEF_GATE=
export RIC_WIFI_SSID=
export RIC_WIFI_PASS=
export RIC_WIFI_SUB_MASK=
export RIC_WIFI_DEF_GATE=
#export RIC_NW_PRIO=
export RIC_TMP_WPA_FILE="wpa.conf"
export RIC_TMP_ETH_FILE="interfaces.conf"
export RIC_SUMM_FILE="summary.conf"
export RIC_NC_SERVER="nc_server.sh"
export RIC_NC_PORT="23871"
export RIC_IMG_FILE_NAME="raspimg.img"


ric_is_root()
{
	if [ "x$EUID" != "x0" ]
	then
		echo "The script needs to be run as root. Exiting."
		exit 1
	fi
	return 0
}

ric_is_space_enough()
{
	SIZE_DW=`df --output=avail ras_download/ | tail -n1`
        if [ $SIZE_DW -lt 4194304 ]
	then
                echo "Minimum 4GB disk space required to download and configure the image. Exiting."
		exit 1;
	fi
	return 0;
}

ric_is_perm()
{
        mkdir -p ras_download mo1 mo2
	if [ "$?" != "0" ]
	then
		echo "No permission to create directory or directory already present. Exiting."
		exit 1;
	fi
	return 0
}

ric_is_site_reachable()
{
	wget --spider --quiet $RIC_RASP_LETEST_URL
	if [ "$?" != "0" ]
	then
		echo "Latest Raspbian image URL is not reachable. Please check network connection."
                return 1
	fi
	return 0;
}

ric_download_image()
{
	echo "Starting download using wget utility. Its going to take some time."
        echo
        pushd ras_download > /dev/null
	wget $RIC_RASP_LETEST_URL
	if [ "x$?" != "x0" ]
	then
		echo "Download of the image failed. Exiting."
		exit 1
	fi
	mv raspbian_latest raspbian_latest.zip
	popd
	return 0
}

ric_copy_image()
{
        echo "Copying Image. Please wait..."
        cp $RIC_RASP_SRC_IMG_PATH ras_download &>/dev/null
	if [ "x$?" != "x0" ]
	then
		echo "Image copy failed. Exiting."
		exit 1
	fi

	return 0
}

check_sd() # Not to called directly, use the next function
{
	LIST=
	FINAL_LIST=
	cnt=0
	LIST=`lsblk -d --output NAME | tail -n +2 | grep sd`
	export FINAL_LIST
	export cnt
	for i in $LIST
		do mount | grep $i | grep -w \/ > /dev/null
		if [ "$?" != "0" ]
		then 
			FINAL_LIST[$cnt]="/dev/$i"
			cnt=$(($cnt + 1))
		fi
	done
	FINAL_LIST[$cnt]="Quit"
	cnt=$(($cnt + 1))
	FINAL_LIST[$cnt]="Insert SD card and revalidate"

	echo 'Please select the target SD card path: '
	echo "Save the modified image as a file by selecting \"Quit\""
	PS3='Option: '

	select opt in "${FINAL_LIST[@]}"
	do
	    case $opt in
	        "Quit")
                                echo "The input image file will be modified."
                                echo "Press Enter to continue..."
                                read
                                break
	            ;;
	        "Insert SD card and revalidate")
				echo "Revalidating..."
				unset FINAL_LIST
				sleep 5
	            return 1
				break
	            ;;
        	 *)
				echo $opt | grep "/dev/" > /dev/null
				if [ "$?" != "0" ]
				then
					echo "Invalid selection, try again."
					continue
				fi
				if [ -b $opt ]
				then
                                     echo "SD Card Path Selected: $opt"
                                     echo "Press Enter to continue..."
                                     read
                                     RIC_SD_PATH="$opt"
                                     PARTS=`ls -1 $opt?`
                                     for P in $PARTS
                                     do
                                        umount $P &>/dev/null
                                     done
				else
                                     echo "Path could not be verified to be a proper block device."
                                     echo "The input image file will be modified."
                                     echo "Press Enter to continue..."
                                     read

				fi
				break
				;;
	    esac
	done
	return 0
}


ric_is_sd_card_present()
{
        clear
	unset FINAL_LIST
	while [ TRUE ]
	do
		check_sd
		if [ "$?" == 0 ]
		then 
			echo 
			break
		fi
	done
	return 0
}

ric_is_sw_state_ok()
{
        which bash &> /dev/null
	if [ "x$?" != "x0" ]
	then
		echo "Bash could not be located. Exiting"
		exit 1
	fi
        which wget &> /dev/null
	if [ "x$?" != "x0" ]
	then
		echo "wget could not be located. Exiting"
		echo "Install wget."
		exit 1
	fi
        which unzip &>/dev/null
	if [ "x$?" != "x0" ]
	then
		echo "uzip could not be located. Exiting"
		echo "Install zip"
		exit 1
	fi
        which lsblk &>/dev/null
	if [ "x$?" != "x0" ]
	then
		echo "lsblk could not be located. Exiting"
		echo "Install zip"
		exit 1
	fi
	return 0
}


ric_copy_unzip_img()
{
	NO_OF_FILES=`ls -1 ras_download/ | wc -l`
	if [ "$NO_OF_FILES" -gt "2" ]
	then
		echo "More than 2 files in the download directory. Exiting."
		exit 1
	fi
	if [ "$NO_OF_FILES" == "1" ]
	then
                pushd ras_download > /dev/null
		NAME=`ls -1`
                TYPE=`file -b $NAME | cut -d' ' -f1`
		if [ "x$TYPE" == "xx86" ]
		then
                        popd > /dev/null
			return 0
		elif [ "x$TYPE" == "xZip" ]
		then
			echo "Unzipping file. It is going to take some time."
			unzip $NAME
			if [ "x$?" != "x0" ]
			then
                                popd > /dev/null
				echo "Unzip failure. Exiting."
                                exit 1
			fi
                else
                        echo "Not a valid file. Exiting."
                        exit 1
		fi
                UNZIP_NAME=`ls -1 *.img`
                mv $UNZIP_NAME $RIC_IMG_FILE_NAME
                popd > /dev/null
                return 0
	fi
	if [ "x$NO_OF_FILES" == "x2" ]
	then
                pushd ras_download > /dev/null
		NAMES=`ls -1`
		export GOTIT=0
		for i in $NAMES
		do
			TYPE=`file -b $i | cut -d' ' -f1`
			if [ "x$TYPE" == "xx86" ]
			then
				GOTIT=1
                                mv $i $RIC_IMG_FILE_NAME
			fi
		done
		if [ "x$GOTIT" != "x1" ]
		then
			echo "Image file not found. Someting wrong. Run script with --clean option. \
			Back up the image file as it will be deleted from ras_download directory."
                        popd > /dev/null
			exit 1
		fi
                popd > /dev/null
		return 0
	fi
}

ric_calc_mnt_img()
{
    pushd ras_download > /dev/null
    FIRST_OFFSET=`fdisk -l $RIC_IMG_FILE_NAME | grep -A2 Device | head -n2 | tail -n1 | awk '{print $2}'`
    SECOND_OFFSET=`fdisk -l $RIC_IMG_FILE_NAME | grep -A2 Device | tail -n1 | awk '{print $2}'`
    FIRST_OFFSET=$(( $FIRST_OFFSET * 512 ))
    SECOND_OFFSET=$(( $SECOND_OFFSET * 512 ))
    mount -o loop,offset=$FIRST_OFFSET $RIC_IMG_FILE_NAME ../mo1
    if [ "x$?" != "x0" ]
    then
        echo "Mounting failed. Exiting."
        popd > /dev/null
        exit 1;
    fi
    mount -o loop,offset=$SECOND_OFFSET $RIC_IMG_FILE_NAME ../mo2
    if [ "x$?" != "x0" ]
    then
	echo "Mounting failed. Exiting."
        popd > /dev/null
        exit 1;
    fi
    popd > /dev/null
    return 0
}

ric_calc_mnt_img_card()
{
    if [ ! -b "${RIC_IMG_FILE_NAME}1" -o ! -b "${RIC_IMG_FILE_NAME}2" ]
    then
        echo "Correct partitions not detected in SD Card. Exiting..."
        exit 1
    fi
    umount "${RIC_IMG_FILE_NAME}1" &> /dev/null
    umount "${RIC_IMG_FILE_NAME}2" &> /dev/null
    mount ${RIC_IMG_FILE_NAME}1 mo1
    if [ "x$?" != "x0" ]
    then
        echo "Mounting failed. Exiting."
        exit 1;
    fi
    mount ${RIC_IMG_FILE_NAME}2 mo2
    if [ "x$?" != "x0" ]
    then
        echo "Mounting failed. Exiting."
        exit 1;
    fi
    return 0
}

ric_ask_eth()
{
        clear
	export cnt=0
	while [ $cnt == 0 ]
	do
		echo "Please enter the ip address to be assigned to the Ethernet port. Default=DHCP."
		echo -n "IP: "
		read RIC_IP_ADD_ETHER
                clear
		if [ "x$RIC_IP_ADD_ETHER" == "x" ]
		then
			RIC_IP_ADD_ETHER="DHCP"
		fi
                clear
		echo "Please enter the subnet mask. Default=Auto."
		echo -n "MASK: "	
		read RIC_SUB_MASK
		if [ "x$RIC_SUB_MASK" == "x" ]
		then
			RIC_SUB_MASK="AUTO"
		fi
                clear
                echo "Please enter the default gateway. Default=Auto."
                echo -n "GATEWAY: "
                read RIC_DEF_GATE
                if [ "x$RIC_DEF_GATE" == "x" ]
                then
                        RIC_DEF_GATE="AUTO"
                fi
                clear
				echo "IP ADDRESS:		$RIC_IP_ADD_ETHER"
				echo "SUBNET MASK:		$RIC_SUB_MASK"
                echo "DEFAULT GATEWAY:	$RIC_DEF_GATE"
                echo " "
                echo "Please verify the details as they will not be internally verified and will be"
                echo "updated to the image as it is. Press 'Y' to confirm, 'N' to reject and 'Q' to quit the script."
		echo -n "Selection: "
		read val
                echo " "
                if [ "x$val" == "xy" -o "x$val" == "xY" ]
		then
			cnt=1
                elif [ "x$val" == "xq" -o "x$val" == "xQ" ]
                then
			echo "Exiting."
			exit 1
                elif [ "x$val" == "xn" -o "x$val" == "xN" ]
                then
			cnt=0
		else
                        clear
                        echo "Invalid selection."
		fi
	done
	return 0;
}

ric_ask_wifi()
{
        clear
	NO_NM_CLI=0
	export NO_NMCLI
        which nmcli &>/dev/null
	if [ "$?" != "0" ]
	then
		echo "Wireless Auto-detection not possible."
		NO_NMCLI=1
	fi
	RIC_WIFI_SSID_AUTO=`nmcli -t -f active,ssid dev wifi | egrep '^yes' | cut -d\' -f2`
	if [ "x$RIC_WIFI_SSID_AUTO" == "x" ]
	then
                echo "Computer not connected to Wireless."
	fi
	export cnt=0
	while [ $cnt == 0 ]
	do
		echo "Please note: All the WLAN dongle's drivers are not provided in the image."
		echo " "
                echo "Please enter the IP address to be assigned to the WLAN. Default=DHCP."
		echo -n "WIFI IP: "
                read RIC_IP_ADD_WIFI
                if [ "x$RIC_IP_ADD_WIFI" == "x" ]
		then
                        RIC_IP_ADD_WIFI="DHCP"
		fi
                clear
		echo "Please enter the subnet mask. Default=Auto."
		echo -n "WIFI MASK: "
		read RIC_WIFI_SUB_MASK
		if [ "x$RIC_WIFI_SUB_MASK" == "x" ]
		then
			RIC_WIFI_SUB_MASK="AUTO"
		fi
                clear
                echo "Please enter the default gateway. Default=Auto."
                echo -n "GATEWAY: "
                read RIC_WIFI_DEF_GATE
                if [ "x$RIC_WIFI_DEF_GATE" == "x" ]
                then
                        RIC_WIFI_DEF_GATE="AUTO"
                fi
                clear
		if [ "x$NM_CLI" == "x0" ]
		then
			WL=`nmcli -t -f ssid dev wifi | cut -d\' -f2`
			if [ "x$WL" == "x" ]
			then
				echo "No wireless AP in range or Wireless turned off."
			fi
                else
                        echo "List of Wireless network available:-"
                        nmcli -t -f ssid dev wifi | cut -d\' -f2
		fi
                echo " "
		echo "Please enter the WLAN SSID. Default=$RIC_WIFI_SSID_AUTO"
		echo -n "SSID: "
		read RIC_WIFI_SSID
		if [ "x$RIC_WIFI_SSID" == "x" ]
		then
                        RIC_WIFI_SSID=$RIC_WIFI_SSID_AUTO
		fi
                clear
		echo "Please enter the WLAN PASSWORD."
		echo -n "PASSWORD: "
		read RIC_WIFI_PASS
                echo " "
                echo "IP WLAN:          $RIC_IP_ADD_WIFI"
                echo "SUBNET MASK:      $RIC_WIFI_SUB_MASK"
                echo "DEFAULT GATEWAY:  $RIC_WIFI_DEF_GATE"
                echo "WLAN SSID:        $RIC_WIFI_SSID"
                echo "WLAN PASSWORD:    $RIC_WIFI_PASS"
                echo " "
                echo "Please verify the details as they will not be internally verified and will be"
                echo "updated to the image as it is. Press 'Y' to confirm, 'N' to reject and 'Q' to quit the script."
		echo -n "Selection: "
		read val
                if [ "x$val" == "xy" -o "x$val" == "xY" ]
		then
			cnt=1
                elif [ "x$val" == "xq" -o "x$val" == "xQ" ]
                then
			echo "Exiting."
			exit 1
                elif [ "x$val" == "xn" -o "x$val" == "xN" ]
                then
			cnt=0
		else
                        clear
                        echo "Invalid selection."
		fi
	done
	return 0;
}

ric_ask_nw_prio()
{
        clear
	option=("Wireless" "Ethernet")
        PS3="Please select network connection priority: "
	select opt in ${option[@]}
	do
		case $opt in 
			"Wireless")
				RIC_NW_PRIO="WIRELESS"
				break
				;;
			"Ethernet")
				RIC_NW_PRIO="ETHERNET"
				break
				;;
			*)
				echo "Invalid option"
				;;	
		esac
	done
}

ric_ask_img_path()
{
    export selp=1
    echo "Please enter the absolute path of the image file: "
    read RIC_RASP_SRC_IMG_PATH
    while [ "$selp" == "1" ]
    do
        clear
        ls $RIC_RASP_SRC_IMG_PATH &> /dev/null
        if [ "$?" != "0" ]
        then
            option=("Try_again" "Quit")
            PS3="Invalid image path. Please select option: "
            select opt in ${option[@]}
            do
                case $opt in
                     "Try_again")
                                 echo "Enter path: "
                                 read RIC_RASP_SRC_IMG_PATH
                                 break
                             ;;
                     "Quit")
                             echo "Thank you. Exiting."
                             exit 1
                             break
                             ;;
                     *)
                             echo "Invalid option"
                             ;;
                esac
            done
        else
            selp=0
        fi
    done
    return 0
}


ric_check_nmap()
{
    which nmap
    if [ "$?" != "0" ]
    then
        echo "'nmap' utility not present. Install nmap to discover Raspberry Pi. Ubuntu: apt-get install nmap"
        return 1
    fi
    return 0
}


ric_wpa_supplicant()
{
cat > $RIC_TMP_WPA_FILE << EOF
network={
    ssid="$RIC_WIFI_SSID"
    psk="$RIC_WIFI_PASS"
}
EOF
    return 0
}

ric_nw()
{
    if [ "x$1" == "xstatic" -a "x$2" == "xstatic" ] #$1 -> Ethernet. $2 -> Wifi
    then
cat << EOF > $RIC_TMP_ETH_FILE
auto lo eth0
iface lo inet loopback
iface eth0 inet static
address $RIC_IP_ADD_ETHER
netmask $RIC_SUB_MASK
gateway $RIC_DEF_GATE
allow-hotplug wlan0
iface wlan0 inet static
wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
address $RIC_IP_ADD_WIFI
netmask $RIC_WIFI_SUB_MASK
gateway $RIC_WIFI_DEF_GATE
post-up /home/pi/$RIC_NC_SERVER
EOF
    elif [ "x$1" == "x" -a "x$2" == "x" ]
    then
cat << EOF > $RIC_TMP_ETH_FILE
auto lo eth0
iface lo inet loopback
iface eth0 inet dhcp
allow-hotplug wlan0
iface wlan0 inet dhcp
wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
#iface default inet dhcp
post-up /home/pi/$RIC_NC_SERVER
EOF
    elif [ "x$1" == "xstatic" -a "x$2" == "x" ]
    then
cat << EOF > $RIC_TMP_ETH_FILE
auto lo eth0
iface lo inet loopback
iface eth0 inet static
address $RIC_IP_ADD_ETHER
netmask $RIC_SUB_MASK
gateway $RIC_DEF_GATE
allow-hotplug wlan0
iface wlan0 inet dhcp
wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
#iface default inet dhcp
post-up /home/pi/$RIC_NC_SERVER
EOF
    elif [ "x$1" == "xdynamic" -a "x$2" == "xstatic" ]
    then
cat << EOF > $RIC_TMP_ETH_FILE
auto lo eth0
iface lo inet loopback
iface eth0 inet dhcp
allow-hotplug wlan0
iface wlan0 inet static
wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
address $RIC_IP_ADD_WIFI
netmask $RIC_WIFI_SUB_MASK
gateway $RIC_WIFI_DEF_GATE
post-up /home/pi/$RIC_NC_SERVER
EOF
    else
        echo "Wireless settings not proper. Not writing wireless settings."
    fi
    return 0
}

ric_nc_server()
{
    echo "#!/bin/bash" >$RIC_NC_SERVER
    echo "nc -l $RIC_NC_PORT &" >>$RIC_NC_SERVER
    cp $RIC_NC_SERVER mo2/home/pi/
    chmod +x mo2/home/pi/$RIC_NC_SERVER
}

ric_prep_cfg_summ()
{
    RIC_MY_IP=`ifconfig | grep "inet addr" | grep -v "127.0.0.1" | awk -F: '{print $2}' | awk '{print $1}' | head -n1`
    RAS_IP_ETH=$RIC_IP_ADD_ETHER
    RAS_IP_WIFI=$RIC_IP_ADD_WIFI
    echo "MY_IP=$RIC_MY_IP" > $RIC_SUMM_FILE
    echo "RAS_IP_ETH=$RAS_IP_ETH" >> $RIC_SUMM_FILE
    echo "RAS_IP_WIFI=$RAS_IP_WIFI" >> $RIC_SUMM_FILE
}


ric_configure()
{
    if [ "x$RIC_IP_ADD_ETHER" == "xDHCP" -a "x$RIC_IP_ADD_WIFI" == "xDHCP" ]
    then
        ric_nw
    elif [ "x$RIC_IP_ADD_ETHER" != "xDHCP" -a "x$RIC_IP_ADD_WIFI" != "xDHCP" ]
    then
        ric_nw static static
    elif [ "x$RIC_IP_ADD_ETHER" == "xDHCP" -a "x$RIC_IP_ADD_WIFI" != "xDHCP" ]
    then
        ric_nw dynamic static
    elif [ "x$RIC_IP_ADD_ETHER" != "xDHCP" -a "x$RIC_IP_ADD_WIFI" == "xDHCP" ]
    then
        ric_nw static
    else
        echo "Network parameters not correct. Network settings unsuccessful."
    fi
    ric_wpa_supplicant
    cp $RIC_TMP_ETH_FILE mo2/etc/network/interfaces
    if [ "$?" != "0" ]
    then
        echo "Could not write Ethernet settings."
    fi
    cp $RIC_TMP_WPA_FILE mo2/etc/wpa_supplicant/wpa_supplicant.conf
    if [ "$?" != "0" ]
    then
        echo "Could not write WiFi settings."
    fi
    ric_nc_server
    ric_prep_cfg_summ
    sync
    umount mo1
    if [ "$?" != "0" ]
    then
        echo "Could not unmount partition. Please close any window named \"mo1\" and \"mo2\" and press any key."
        read
        umount mo1
        if [ "$?" != "0" ]
        then
            echo "Could not unmount. Exiting"
            exit 1
        fi
    fi
    sync
    umount mo2
    if [ "$?" != "0" ]
    then
        echo "Could not unmount partition. Please close any window named \"mo1\" and \"mo2\" and press any key."
        read
        umount mo2
        if [ "$?" != "0" ]
        then
            echo "Could not unmount. Exiting"
            exit 1
        fi
    fi
    sync
}

ric_burn()
{
	clear
    which pv > /dev/null
    if [ "$?" == "0" ]
    then
        echo "Burning Image. Pease wait"
        pushd ras_download > /dev/null
        dd if=$RIC_IMG_FILE_NAME bs=512 | pv | dd of=$RIC_SD_PATH bs=512
        popd > /dev/null
        echo "Burning complete."
    else
        echo "Burning Image. Pease wait"
        pushd ras_download > /dev/null
        dd if=$RIC_IMG_FILE_NAME of=$RIC_SD_PATH bs=512
        popd
        echo "Burning complete."
    fi
    return 0
}

ric_finish()
{
    # do cleanup, leave only summary file and image file.
    rm -rf mo1 mo2 $RIC_TMP_WPA_FILE $RIC_TMP_ETH_FILE
}


ric_search_connect()
{
    IP=`ifconfig | grep "inet addr" | grep -v "127.0.0.1" | awk -F: '{print $2}' | awk '{print $1}' | head -n1`
    echo "Running NetCat client, Please wait..."
    echo "It takes about 4 to 5 minutes for RPi to boot up and start the NC server."
    echo "If you do not get the password prompt even after 5 minutes"
    echo "check your network connection."
    nmap -p 23871 ${IP}/24 --open -oG out.txt >/dev/null
    RAS_IP=`cat out.txt | grep open | grep -v '#' | grep 'Host' | awk '{print $2}'`
    if [ "x$RAS_IP" == "x" ]
    then
        echo "Not Found. Please try again."
        rm out.txt
    else
        rm out.txt
        ssh pi@$RAS_IP
    fi
}

echo_gpl()
{
echo
echo "RaspImgConfig.sh Copyright (C) 2015 Subhajit Ghosh (subhajit@glowingthumb.com)
This program comes with ABSOLUTELY NO WARRANTY;
This is free software, and you are welcome to redistribute it
under certain conditions; eMail <subhajit@glowingthumb.com> for details.
Please read LICENSE.md"
echo
}

ric_clean()
{
    ric_is_root
    ric_is_perm
    clear
    echo "Please wait..."
    sync
    umount mo1 &>/dev/null
    sync
    umount mo2 &>/dev/null
    rm -rf mo1 mo2 $RIC_TMP_WPA_FILE $RIC_TMP_ETH_FILE $RIC_SUMM_FILE ras_download $RIC_NC_SERVER
    echo "Cleaning complete"
    return 0
}


ric_help()
{
echo
echo "--configure   If you want to download the latest Raspbian OS image and configure its network settings
              or you already have the Image saved and you want to configure it. You can also burn the
              Image directly on an attached SD card.

--connect     If you want to SSH into a Raspberry Pi connected to your network(subnet). This script has the
              capability to find and SSH to the freshly configured Raspberry Pi in the network.
			  If you have given static IP to Raspberry Pi, you need not use this option. You can directly
			  Ping and SSH on that IP. This option only lets you discover the freshly configured Raspberry Pi
			  using \"netcat\" server client utility if DHCP or AUTO option was selected.

--clean       If the script is not working or previous invocation of the script has generated files and directories.
              Warning: Please keep a backup of the Master image or the Original Raspbian Zip image which you have
              downloaded as this option will delete everything. In case of download through this script, please back
              up th file nemed \"raspbian_latest\" in the directory \"ras_download\"- this is your Zip image
              of the latest Raspbian OS.

--copying     See GPL license.

--help        See this menu."
echo
}

ric_main()
{
    ric_is_root
    ric_is_perm
    ric_is_space_enough
    ric_is_sw_state_ok
    clear
    export sel="0"
    option=("Download_latest_image" "Use_downloaded_image" "Use_image_on_SD_card")
    PS3="Would you like to download the latest image of Raspbian or use downloaded image in this PC? "
    select opt in ${option[@]}
    do
            case $opt in
                    "Download_latest_image")
                            echo "Please wait..."
                            sel="1"
                            break
                            ;;
                    "Use_downloaded_image")
                            sel="2"
                            break
                            ;;
                    "Use_image_on_SD_card")
                            sel="3"
                            break
                            ;;
                    *)
                            echo "Invalid option"
                            ;;
            esac
    done

    if [ "$sel" == "1" ]
    then
        ric_is_site_reachable
        if [ "$?" != "0" ]
        then
            echo "Check network and run again."
            exit 1
        fi
        ric_download_image
        ric_copy_unzip_img
        ric_is_sd_card_present
        ric_calc_mnt_img
    elif [ "$sel" == "2" ]
    then
        ric_ask_img_path
        ric_copy_image
        ric_copy_unzip_img
        ric_is_sd_card_present
        ric_calc_mnt_img
    elif [ "$sel" == "3" ]
    then
        ric_is_sd_card_present
        if [ "x$RIC_SD_PATH" == "x" ]
        then
            echo "SD Card path not selected./SD Card not found."
            echo "Quitting."
            exit 0
        fi
        RIC_IMG_FILE_NAME=$RIC_SD_PATH
        ric_calc_mnt_img_card
    fi
    # If reached here then preliminary requirements are fulfilled. Begin asking.
    ric_ask_eth
    ric_ask_wifi
    #ric_ask_nw_prio
    # Asking ends, job begins.
    ric_configure
    if [ "x$RIC_SD_PATH" != "x" -a "x$sel" != "x3" ]
    then
        ric_burn
    else
        echo "Configuration complete."
    fi
    ric_finish
}

if [ "x" != "x$2" ]
then
    echo "Only one option supported at a time."
    ric_help
    exit 1
fi

case "$1" in
    --configure)
        ric_main
        ;;
    --connect)
        ric_search_connect
        ;;
    --clean)
        ric_clean
        ;;
    --copying)
        echo_gpl
        ;;
    --help)
        clear
        ric_help
        ;;
        *)
        clear
        echo "Invalid Option(s)."
        ric_help
        ;;
esac
exit 0
