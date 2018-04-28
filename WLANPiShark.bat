@ECHO OFF
setlocal
REM #################################################################
REM # 
REM # This script runs on a Windows 10 machine and will allow
REM # Wireshark on a Windows machine to decode captured frames,
REM # using a WLANPi as a wireless capture device. The Windows machine
REM # machine must have IP connectivity to your WLANPi via its Ethernet
REM # port. Run this script from a Windows command shell (CMD).
REM # 
REM # Set the variables below to point at your local copy of 
REM # Wireshark and configure the WLANPi credentials & IP address
REM # (Note that the user account on the WLANPi must be an admin 
REM # account to allow the sudo command to be executed - the default
REM # account wlanpi/wlanpi works fine. Please use a plain text
REM # editor to make the updates (e.g. Notepad)
REM # 
REM # You will need the 'plink.exe' executable that is bundled with
REM # Putty to run this batch file. https://www.putty.org/)
REM # 
REM # This batch file needs to be run from a Windows 10 command line
REM # and will stream tcpdump data back to Wireshark on your Windows
REM # machine from a WLANPi, allowing wireless frames decode. This script
REM # was tested with an Comfast CF-912AC adapter plugged in to a WLANPi.
REM # 
REM # The best way to use this script with your WLANPi is to hook up a
REM # ethernet cable between your laptop/PC and the WLANPi. Make sure you
REM # do this before powering on your WLANPi. Then, when the WLANPi powers
REM # up, you will see a 169.254.x.x address on the display of your WLANPi.
REM # Enter this address in the WLAN_PI_IP address is the variables area
REM # below. This should be a one-time operation, as the WLANPi should use
REM # the same 169.254.x.x address each time. This operation also assumes 
REM # your laptop/PC is set to use DHCP on its ethernet adapter (it will
REM # also uses its own 169.254.x.x address for comms when it gets no
REM # IP address from DHCP).
REM # 
REM # Note that each time you want to change channels or start a new capture,
REM # you will need to close Wireshark and re-run this script. 
REM # 
REM # (Suggestions & feedback: wifinigel@gmail.com)
REM # 
REM #################################################################

REM !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
REM !
REM ! Set variables here, but make sure no trailing spaces 
REM ! accidentally at end of lines - you WILL have issues!
REM ! 
REM !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SET WLAN_PI_USER=wlanpi
SET WLAN_PI_PWD=wlanpi
SET WLAN_PI_IP=192.168.0.60
SET WIRESHARK_EXE=C:\Program Files\Wireshark\Wireshark.exe
SET PLINK=C:\Program Files (x86)\PuTTY\plink.exe
SET WLAN_PI_IFACE=wlan0

REM ############### NOTHING TO SET BELOW HERE #######################
REM # This var is passed in from the command line (1-14, 36 - 165)
SET CHANNEL=%1
SET VERSION="WLANPiShark v0.7 (28th Apr 2018) WiFiNigel@gmail.com"

IF "%1"=="" (
   echo.
   echo *** No channel passed! Usage: ***
   GOTO usage
)

IF "%1"=="-h" GOTO usage

Rem - Command line arg 1
IF "%1"=="-v" (
 echo.
 echo %VERSION%
 EXIT /B
)

IF "%2"=="" (
 SET CHANNEL_WIDTH=HT20
)

Rem - Command line arg 2
IF "%2"=="40+" (
 SET CHANNEL_WIDTH=HT40+
)

IF "%2"=="40-" (
 SET CHANNEL_WIDTH=HT40-
)

IF "%2"=="20" (
 SET CHANNEL_WIDTH=HT20
)

Rem if CHANNEL_WIDTH still not set, must be inavlid option entered
IF "%CHANNEL_WIDTH%"=="" (
 echo.
 echo Inavlid channel width selection: %CHANNEL_WITDH%
 GOTO usage
)

echo Starting session to device %WLAN_PI_IP% ...

Rem - Start remote commands on WLANPi
echo Killing old tcpdump processes...
"%PLINK%" -ssh -pw %WLAN_PI_PWD% %WLAN_PI_USER%@%WLAN_PI_IP% "echo %WLAN_PI_PWD% | sudo -S pkill -f tcpdump > /dev/null 2>&1

echo Killing processes that may interfere with airmon-ng...
"%PLINK%" -ssh -pw %WLAN_PI_PWD% %WLAN_PI_USER%@%WLAN_PI_IP% "echo %WLAN_PI_PWD% | sudo -S airmon-ng check kill > /dev/null 2>&1

echo Bringing WLAN card up...
"%PLINK%" -ssh -pw %WLAN_PI_PWD% %WLAN_PI_USER%@%WLAN_PI_IP% "echo %WLAN_PI_PWD% | sudo -S ifconfig %WLAN_PI_IFACE% up" 2> null

echo Setting wireless adapter to monitor mode
"%PLINK%" -ssh -pw %WLAN_PI_PWD% %WLAN_PI_USER%@%WLAN_PI_IP% "echo %WLAN_PI_PWD% | sudo -S iw %WLAN_PI_IFACE% set monitor none" 2> null

echo Setting wireless adapter to channel %CHANNEL% (channel width %CHANNEL_WIDTH%)
"%PLINK%" -ssh -pw %WLAN_PI_PWD% %WLAN_PI_USER%@%WLAN_PI_IP% "echo %WLAN_PI_PWD% | sudo -S iw %WLAN_PI_IFACE% set channel %CHANNEL% %CHANNEL_WIDTH%" 2> null

echo Starting Wireshark....
"%PLINK%" -ssh -pw %WLAN_PI_PWD% %WLAN_PI_USER%@%WLAN_PI_IP% "echo %WLAN_PI_PWD% | sudo -S tcpdump -n -i %WLAN_PI_IFACE% -U -s 65535 -w - " | "%WIRESHARK_EXE%" -k -i -

EXIT /B

:usage
 echo.
 echo     WLANPIShark.bat [ch number] { 20 ^| 40+ ^| 40- }
 echo     WLANPIShark.bat -v
 echo     WLANPIShark.bat -h
 EXIT /B

REM #################################################################
REM # 
REM # Version history;
REM # 
REM # v0.1 - N.Bowden 2nd Apr 2018
REM #
REM #        Channel setting does not work reliably - every time set,
REM #        when tcpdump runs, adapter often cycles through all
REM #        channels for some reason. Also, after few frames, the
REM #        stream of frames stops for some reason. Resetting the
REM #        WLAN Pi seems to clear up some of these issues. When 
REM #        exiting Wireshark, this batch file does not exit.
REM # 
REM #  v0.2 - N.Bowden 3rd Apr 2018
REM # 
REM #         Added airmon-ng check kill call & interface start 
REM #         command. 
REM #
REM #  v0.3 - N.Bowden 4th Apr 2018
REM # 
REM #         Took out all pause commands and added in redirection 
REM #         of messages to null for tidier output
REM #
REM #  v0.4 - N.Bowden 6th Apr 2018
REM # 
REM #         Added notes about using direct ethernet connection and
REM #         169.254.x.x address 
REM #
REM #  v0.5 - N.Bowden 6th Apr 2018
REM # 
REM #         Added -U option to switch off buffering of tcpdump and
REM #         improve frame capture rate
REM #
REM #  v0.6 - N.Bowden 7th Apr 2018
REM #
REM #         Added channel width option to command line options
REM # 
REM #  v0.7 - N.Bowden 28th Apr 2018
REM #
REM #         Tidied up usage output & added -h option. Also fixed
REM #         bad channel width option detection (local vars) between
REM #         script invocations. Changed Wireshark -s from 0 to 65535
REM #         to limit number of bad frames
REM # 
REM #################################################################