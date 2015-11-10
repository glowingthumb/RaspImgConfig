Script Name:
	RaspImgConfig.sh

Description:
	The main purpose of the script is to configure the Raspbian Image with network and wireless settings so that when you start the Raspberry Pi
	for the first time with a new Raspbian image, it can directly get connected with your WiFi router with static or dynamic IP or if you
	want to connect the Raspberry Pi with your PC/Laptop with a ethernet patch cable having a P2P connection by giving static IP to both your PC
	and Raspberry Pi.
	Tested with Ubuntu 14.04
	IMPORTANT: Downloading the latest Raspbian Linux Image requires a lot of time, progress will be shown, be patient :-)

How to use the script to configure:

	1. Download the script from <www.github.com/glowingthumb/raspimgconfig> by navigating to the page and using the "Download Zip" option or you
	   can "git clone" the repository.

	2. Make sure you have atleast 4GB space where you are downloading, making a new directory is advised.

	3. Either use "sudo" or change to "root" user as this script does mounting/unmounting stuff.

	4. Give execute permission to the script- "chomd +x RaspImgConfig.sh"

	5. Execute it "./RaspImgConfig.sh --configure"

	6. You will get the option to either download the latest image of Raspbian Linux OS or if you have the image downloaded, you can give the full
	   path of the image- "/home/timon_pumba/Downloads/2015-04-19-Raspbian-XXX-XXX.Zip". If you have the Raspbian OS already in the SD card, you 
	   can select the option "Use_image_on_SD_card" to configure the image directly on the SD card.

	7. You can burn the modified image to an SD card or choose to just modify the image file and keep it. If you choose the later, choose the "Quit"
	   option when asked for "Please select the target SD card path:".

	8. You will be asked to enter the various Ethernet and Wi-Fi parameters and verify them. If your Laptop is already connected to a Wi-Fi network, 
	   the script will automatically detect the hotspot(SSID) as default and ask you for the password. 

	9. After you finish feeding all the parameters, the script will configure the image and either burn the image on an SD card or simply
	   exit according to the selection made in the beginning.

	10. If the script has been interrupted in a previous occasion and is not working presently then use "--clean" option to delete any files and
		directories generated by the script. Keep a backup of the original downloaded Raspbian Image. In case this script was used to download
		the latest image- backup the "raspbian_latest" file inside the "ras_download" directory. "raspbian_latest" is the latest Raspbian Image. 

How to use the script to connect(SSH) to a Raspberry Pi:

	1. "nmap" tool must be installed to use this feature. Use "apt-get install nmap" for Ubuntu. Use your distribution's package manager to install
	   "nmap".

	2. Run the script - "./RaspImgConfig --connect". The script will find the device and SSH into it with username - "pi" and will give you a 
	   password prompt where you will have to give the password(raspberry) and you will get an SSH prompt. 

	3. The script installs a server script "nc_server.sh" in the "/home/pi", which opens the port "23871". When --connect option is used the 
	   nmap utility searches for the open port mentioned above. If not required the script can be deleted once SSH connection is established.
	   Port number can be changed from the script. 


Issues:

	Visit www.glowingthumb.com and navigate to "Raspberry Pi" section for videos, tutorials and solutions. You can leave a comment about any issues 
	you are facing and we will get back to you.
