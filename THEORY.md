Raspbian is the most popular Linux based image for Raspberry Pi. The image is versatile and developer friendly.
Raspberry Pi is the favourite choice for embedded developers as it is the most supported and 
cost effective board available in the market.
Anyone who wants to explore embedded systems using real hardware should consider getting a Raspberry Pi.
From here on I will simply call Raspberry Pi as the "board".

Below are the steps to boot the Raspberry for the first time:-
1. Download the Raspbian Image.
2. Unzip the image.
3. Burn the image on to the SD card connected to your computer.
4. Insert the SD card in the SD card slot of the board.
5. Connect a HDMI monitor with the board.
6. Connect a Keyboard and Mouse with the board.
7. Connect a network cable to your PC/Laptop or Ethernet switch/ADSL Modem/Router, I hope you got the point. 
8. Connect the USB power cable from the board to you PC/Laptop or to a power adapter.
9. After you insert the USB power cable you will see in the monitor a configuration prompt
   asking you to continue. You will have to use your keyboard to navigate.
10.You can now use the board in graphical mode with X enabled or command line mode
   through SSH using network, you will find a lot of articles over the internet related to this.
   
Playing with real hardware is lot more fun than virtualization. You can also use QEMU on Linux to 
emulate an ARM hardware and do experiments on that but with real hardware you can make real projects which
works.

Having said that, if you want to build some project which does not require a monitor or keyboard or mouse
or even a network, suppose an "automatic pump controller" or "NAS server" or some system which does not have any
use for a monitor or a keyboard, you will require a network to communicate with the board.

The basic approach of any embedded development is a 'Host' machine and a 'Target' machine. The host machine in
this case will be your Laptop/PC and the target will be the Raspberry Pi. If you have a Raspberry Pi without a 
monitor, you will either use Putty or some terminal emulator in Windows to SSH into the board via Ethernet.
Either you can develop your code/script in the host machine and transfer the contents to the target machine
or you can directly operate on the target machine as you have an SSH connection. 

The below mentioned link directs you to a topic which describes how you can configure headless Raspbian without
keyboard or mouse or monitor for the first time. The article solves all the issues except that the network is
in DHCP mode and if you are using cross cable directly with you Laptop/PC, the board will not get an IP and
you will not be able to connect with the board using SSH. Further in DHCP also you need to run some commands
to find the board and SSH into it and run the configuration(raspiconfig).

https://www.raspberrypi.org/forums/viewtopic.php?f=91&t=74176

Having an image which is preconfigured for your hardware will reduce the need for monitor, mouse or keyboard, 
only a network cable will do. There can also be a situation where you are carrying the Raspberry Pi board for
some demonstration and due to some faulty configurations you managed to corrupt the image. As you are travelling 
you may not have a keyboard or monitor or a router/switch handy. How are you going to configure your board after 
burning a new image to your SD card as due to DHCP your board does not manage to get an IP address?

The RaspImgConfig.sh solves this problem. The script optionally downloads the latest Raspbian image from the Internet 
It asks you details of WiFi and Ethernet and writes the relevant files to the image and configures the image before 
burning it on the SD card.

Please read the README.md for further details.

The RaspImgConfig.sh is a shell(bash) script and only works with Linux for now. 
