# RaspImgConfig

Yes, we love to try embedded!! Lets buy a Raspberry Pi. Got it, the package arrived this morning. Hmm, lets see-- I have a USB cable for power, oh ok, we need a SD card, got it, removed it from my phone(I don't use Iphone). I think I got a network patch cable in my back pack which I (borrowed ;-) ) from my office.

Now hopefully we are all set to download the most popular Raspbian image on my laptop, burn it on to the SD card and start the Raspberry Pi with the SD card. Right?

Don't we need a monitor to see whats going on? Naa, we can SSH into it and control it. Right. But, is the network UP by default and can we SSH into it? Eee.

We first need a monitor, a keyboard and a mouse to configure the Raspbian Image. We need to run "raspiconfig". The "raspiconfig" script runs many tools which configure the image upon first boot.

It is s big inconvenience for people like us who just have a laptop and possibly a network cable or a wi-fi dongle to to experiment with embedded hardware. Some will advocate the use of virtualization such as qemu, etc. But tell me would you still prefer porn if you get a sexy girl willing to have sex with you. Real hardware is real, it gives that good feeling and things have become easy now. Lets make it easier.

There are OS images all over the Internet which has network and SSH enabled but we want Raspbian. Raspbian is the most versatile image in the market and it would be nice to pre-configure the image before we can put it on to the memory card and run the Raspberry Pi board.

How about a tool which can take the downloaded Raspbian Image ask the user for the option to set an IP address or DHCP, It will also ask you for the ssh password(username pi), modify the image and burn it on the SD card.

When the Raspberry Pi is started with the SD card, the network will already be up, so one can connect it directly to the laptop or through the router and ping the IP address of the Raspberry Pi. Then you can SSH into the Pi and run "raspiconfig" or it may run automatically.

This tool will eliminate the need for a VGA or a HDMI monitor or a keyboard/mouse and you can use the headless Pi and reap its awesome benefits.

Currently this is only Linux compatible. You can run Linux in a virtual machine environment such as vmware player or virtual-box and any Ubuntu distribution.

 
