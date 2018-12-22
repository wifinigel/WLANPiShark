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
REM # was tested with a Comfast CF-912AC adapter plugged in to a WLANPi.
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
set WLAN_PI_USER=wlanpi
set WLAN_PI_PWD=wlanpi
set WLAN_PI_IP=192.168.0.38
set WIRESHARK_EXE=C:\Program Files\Wireshark\Wireshark.exe
set PLINK=C:\Program Files (x86)\PuTTY\plink.exe
set WLAN_PI_IFACE=wlan0

REM ############### NOTHING TO set BELOW HERE #######################
:init
    set "__NAME=%~n0"
    set "__VERSION=0.08"
    set "__YEAR=2018"

    set "__BAT_FILE=%~0"
    set "__BAT_PATH=%~dp0"
    set "__BAT_NAME=%~nx0"

    set "CHANNEL_NUMBER="
    set "CHANNEL_WIDTH=20"
    set "FILTER="
    set "SLICE=0"

:parse
    if "%~1"=="" goto :validate

    rem  - handle single instance command line args (help, version etc.)
    if /i "%~1"=="/?"         call :header & goto :usage
    if /i "%~1"=="-h"         call :header & goto :usage
    if /i "%~1"=="--help"     call :header & goto :usage

    if /i "%~1"=="/??"        call :header & goto :extra_help
    if /i "%~1"=="-hh"        call :header & goto :extra_help
    if /i "%~1"=="--xhelp"    call :header & goto :extra_help
    
    if /i "%~1"=="/v"         call :version      & goto :end
    if /i "%~1"=="-v"         call :version      & goto :end
    if /i "%~1"=="--version"  call :version full & goto :end
    
    rem - Handle mutliple parameter entries
    
    rem - This var is passed in from the command line (1-14, 36 - 165)
    if /i "%~1"=="--channel"  set "CHANNEL_NUMBER=%~2" & shift & shift & goto :parse
    if /i "%~1"=="-c"         set "CHANNEL_NUMBER=%~2" & shift & shift & goto :parse
    
    if /i "%~1"=="--width"    set "CHANNEL_WIDTH=%~2"  & shift & shift & goto :parse
    if /i "%~1"=="-w"         set "CHANNEL_WIDTH=%~2"  & shift & shift & goto :parse
    
    if /i "%~1"=="--filter"   set "FILTER=%~2"         & shift & shift & goto :parse
    if /i "%~1"=="-f"         set "FILTER=%~2"         & shift & shift & goto :parse
    
    if /i "%~1"=="--slice"    set "SLICE=%~2"          & shift & shift & goto :parse
    if /i "%~1"=="-s"         set "SLICE=%~2"          & shift & shift & goto :parse
    
    if /i "%~1"=="--ip"       set "WLAN_PI_IP=%~2"     & shift & shift & goto :parse
    if /i "%~1"=="-i"         set "WLAN_PI_IP=%~2"     & shift & shift & goto :parse

    shift
    goto :parse

:validate
    rem Check mandatory fields supplied
    if not defined CHANNEL_NUMBER call :missing_argument "Channel Number" & goto :end

:width_check
    rem Set channel width to correct value to pass to WLANPi 
    if "%CHANNEL_WIDTH%"=="20"  set "CHANNEL_WIDTH=HT20"  & goto :main
    if "%CHANNEL_WIDTH%"=="40+" set "CHANNEL_WIDTH=HT40+" & goto :main
    if "%CHANNEL_WIDTH%"=="40-" set "CHANNEL_WIDTH=HT40-" & goto :main
    call :incorrect_argument "Channel Width" %CHANNEL_WIDTH% & goto :end

:main

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
"%PLINK%" -ssh -pw %WLAN_PI_PWD% %WLAN_PI_USER%@%WLAN_PI_IP% "echo %WLAN_PI_PWD% | sudo -S iw %WLAN_PI_IFACE% set channel %CHANNEL_NUMBER% %CHANNEL_WIDTH%" 2> null

echo Starting Wireshark (Slice = %SLICE%, Capture filter = %FILTER%)...
"%PLINK%" -ssh -pw %WLAN_PI_PWD% %WLAN_PI_USER%@%WLAN_PI_IP% "echo %WLAN_PI_PWD% | sudo -S tcpdump -n -i %WLAN_PI_IFACE% -U -s %SLICE% -w - %FILTER%" | "%WIRESHARK_EXE%" -k -i -

EXIT /B


:header
    echo.
    echo  
    echo  %__NAME% v%__VERSION% - A Windows batch file to stream tcpdump
    echo  running on a WLANPi to Wireshark on a Windows machine
    echo.
    goto :eof
    
    
:usage
    echo  USAGE:
    echo.
    echo   %__BAT_NAME% [--channel nn] { --width 20 ^| 40+ ^| 40- } { --filter "capture filter"} { --slice nnn } { --ip nnn.nnn.nnn.nnn }
    echo.
    echo   %__BAT_NAME% [-c nn] { -w 20 ^| 40+ ^| 40- } { -f "capture filter"} { -s nnn } { -i nnn.nnn.nnn.nnn}
    echo.
    echo.  %__BAT_NAME% /?, -h, --help           shows basic help
    echo.  %__BAT_NAME% /??, -hh, --xhelp        shows extra help
    echo.  %__BAT_NAME% /v, -v, --version        shows the version
    goto :end    
    
    
:extra_help
    echo  HELP:
    echo.
    echo   %__BAT_NAME% [--channel nn] { --width 20 ^| 40+ ^| 40- } { --filter "capture filter"} { --slice nnn } { --ip nnn.nnn.nnn.nnn }
    echo.
    echo   %__BAT_NAME% [-c nn] { -w 20 ^| 40+ ^| 40- } { -f "capture filter"} { -s nnn } { -i nnn.nnn.nnn.nnn}
    echo.
    echo.  %__BAT_NAME% /?, -h, --help           shows basic help
    echo.  %__BAT_NAME% /??, -hh, --xhelp        shows extra help
    echo.  %__BAT_NAME% /v, -v, --version        shows the version
    echo.
    echo   Command Line Capture Options:
    echo.
    echo    --channel or -c : (Mandatory) Channel number to capture (1-13, 36-165)
    echo.
    echo    --width or -w   : (Optional) Channel width to be used for capture 
    echo                       Available values: 20, 40+, 40- (default: 20Mhz)
    echo.
    echo    --filter or -f  : (Optional) tcpdump capture filter (must be enclosed in quotes)
    echo                       Examples: 
    echo                                "wlan type mgt" - capture only management frames
    echo                                "wlan type ctl" - capture only control frames
    echo                                "wlan type mgt subtype beacon" - capture only beacon frames
    echo.
    echo     See more details at: http://wifinigel.blogspot.com/2018/04/wireshark-capture-filters-for-80211.html
    echo.
    echo    --slice or -s   : (Optional) Slice captured frames to capture only headers and reduce size of capture
    echo                                 file. Provide value for number of bytes to be captured per frame.
    echo.
    echo    --ip or -i      : (Optional) IP address of WLANPi. Note that if this is ommitted, the hard coded version in the 
    echo                                 batch file itself will be used
    echo.
    echo   Example:
    echo.
    echo    1. Capture all frames on channel 36:
    echo.
    echo        WLANPiShark.bat -c 36
    echo.
    echo    2. Capture the first 200 bytes of beacon frames on 20MHz channel 48:
    echo.
    echo        WLANPiShark.bat -c 48 -w 20 -s 200 -f "wlan type mgt subtype beacon"
    echo.
    echo    Bugs:
    echo        Please report to wifinigel@gmail.com
    echo.
    echo    More Information:
    echo        Visit: https://github.com/wifinigel/WLANPiShark
    echo.
    goto :end
    
    
:version
    echo.
    echo.  %__BAT_NAME% 
    echo   Version: %__VERSION%
    echo.
    goto :eof
    
    
:missing_argument
    echo.
    echo  **** Error: Missing required argument: %~1  ****
    echo.
    call :usage & goto :eof
    
    
:incorrect_argument
    echo.
    echo  **** Error: Incorrect argument supplied for %~1 : %~2  ****
    echo.
    call :usage & goto :eof
    
    
:end
    exit /B
    
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
REM #         script invocations.
REM # 
REM #  v0.8 - N.Bowden 22nd Dec 2018
REM #
REM #         Major re-write to improve CLI syntax & add features:
REM #
REM #         1. Added "filter" option to allow capture filters
REM #         2. Added "slice" option to allow captured frame sizes to be reduced
REM #         3. Use named CLI parameters instead of positional
REM #         4. Added "ip" option to allow WLANPi address to be passed in via CLI
REM #         5. Improved help info (--xhelp)
REM #
REM #################################################################
