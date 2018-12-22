# WLANPiShark

This is a windows bat file to be used in conjunction with a WLANPi device. It is run from a Windows command prompt and will start a remote streamed capture from a WLANPi device to Wireshark on a Windows machine running this bat file. This allows a Windows machine to run an over the air wireless capture, using the WLANPi as a remote sensor.

The file requires some minor configuration using a simple text editor such as notepad to configure it for your Windows machine. The WLANPi requires no configuration - this batch files has been created specifically to ensure that no changes need to be made by the user on the WLAN device. You can build a WLANPi as per the instructions at (WLANPi.com)[http://WLANPi.com] and use this batch file with WLANPi the out of the box config.

Here are the README details from the batch file (which you can view by opening the batch file itself with a text editor):

```
################################################################
 
 This script runs on a Windows 10 machine and will allow
 Wireshark on a Windows machine to decode captured frames,
 using a WLANPi as a wireless capture device. The Windows machine
 machine must have IP connectivity to your WLANPi via its Ethernet
 port. Run this script from a Windows command shell (CMD).
 
 Set the variables below to point at your local copy of 
 Wireshark and configure the WLANPi credentials & IP address
 (Note that the user account on the WLANPi must be an admin 
 account to allow the sudo command to be executed - the default
 account wlanpi/wlanpi works fine. Please use a plain text
 editor to make the updates (e.g. Notepad)
 
 You will need the 'plink.exe' executable that is bundled with
 Putty to run this batch file. https://www.putty.org/)
 
 This batch file needs to be run from a Windows 10 command line
 and will stream tcpdump data back to Wireshark on your Windows
 machine from a WLANPi, allowing wireless frames decode. This script
 was tested with an Comfast CF-912AC adapter plugged in to a WLANPi.
 
 The best way to use this script with your WLANPi is to hook up a
 ethernet cable between your laptop/PC and the WLANPi. Make sure you
 do this before powering on your WLANPi. Then, when the WLANPi powers
 up, you will see a 169.254.x.x address on the display of your WLANPi.
 Enter this address in the WLAN_PI_IP address is the variables area
 below. This should be a one-time operation, as the WLANPi should use
 the same 169.254.x.x address each time. This operation also assumes 
 your laptop/PC is set to use DHCP on its ethernet adapter (it will
 also uses its own 169.254.x.x address for comms when it gets no
 IP address from DHCP).
 
 Note that each time you want to change channels or start a new capture,
 you will need to close Wireshark and re-run this script. 
 
 (Suggestions & feedback: wifinigel@gmail.com)
 
################################################################
```

## Configuration

There are a few variable you will need to set before running the batch file on your Windows machine - do this by editing the batch file with a simple text editor such as Notepad:

```
SET WLAN_PI_USER=wlanpi
SET WLAN_PI_PWD=wlanpi
SET WLAN_PI_IP=192.168.0.60
SET WIRESHARK_EXE=C:\Program Files\Wireshark\Wireshark.exe
SET PLINK=C:\Program Files (x86)\PuTTY\plink.exe
SET WLAN_PI_IFACE=wlan0
```
## Usage

```
 USAGE:

  WLANPiShark.bat [--channel nn] { --width 20 | 40+ | 40- } { --filter "capture filter"} { --slice nnn } { --ip nnn.nnn.nnn.nnn }

  WLANPiShark.bat [-c nn] { -w 20 | 40+ | 40- } { -f "capture filter"} { -s nnn } { -i nnn.nnn.nnn.nnn}

  WLANPiShark.bat /?, -h, --help           shows basic help
  WLANPiShark.bat /??, -hh, --xhelp        shows extra help
  WLANPiShark.bat /v, -v, --version        shows the version
 
 ```
## Additional Help

```
HELP:

  WLANPiShark.bat [--channel nn] { --width 20 | 40+ | 40- } { --filter "capture filter"} { --slice nnn } { --ip nnn.nnn.nnn.nnn }

  WLANPiShark.bat [-c nn] { -w 20 | 40+ | 40- } { -f "capture filter"} { -s nnn } { -i nnn.nnn.nnn.nnn}

  WLANPiShark.bat /?, -h, --help           shows basic help
  WLANPiShark.bat /??, -hh, --xhelp        shows extra help
  WLANPiShark.bat /v, -v, --version        shows the version

  Command Line Capture Options:

   --channel or -c : (Mandatory) Channel number to capture (1-13, 36-165)

   --width or -w   : (Optional) Channel width to be used for capture
                      Available values: 20, 40+, 40- (default: 20Mhz)

   --filter or -f  : (Optional) tcpdump capture filter (must be enclosed in quotes)
                      Examples:
                               "wlan type mgt" - capture only management frames
                               "wlan type ctl" - capture only control frames
                               "wlan type mgt subtype beacon" - capture only beacon frames

    See more details at: http://wifinigel.blogspot.com/2018/04/wireshark-capture-filters-for-80211.html

   --slice or -s   : (Optional) Slice captured frames to capture only headers and reduce size of capture
                                file. Provide value for number of bytes to be captured per frame.

   --ip or -i      : (Optional) IP address of WLANPi. Note that if this is ommitted, the hard coded version in the
                                batch file itself will be used

  Example:

   1. Capture all frames on channel 36:

       WLANPiShark.bat -c 36

   2. Capture the first 200 bytes of beacon frames on 20MHz channel 48:

       WLANPiShark.bat -c 48 -w 20 -s 200 -f "wlan type mgt subtype beacon"

   Bugs:
       Please report to wifinigel@gmail.com

   More Information:
       Visit: https://github.com/wifinigel/WLANPiShark

```
## Screenshots

![Screenshot1](https://github.com/wifinigel/WLANPiShark/blob/master/screenshot1.png)

![Screenshot2](https://github.com/wifinigel/WLANPiShark/blob/master/screenshot2.png)

## Caveats
- Note that this is work in progress and I cannot guarantee its reliability - use at your own risk
