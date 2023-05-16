@echo off
REM setup_crankk_nebra_rock_pi.bat
REM ------------------------------
REM
REM author: pedro.marques@eibiba.com
REM
REM version 1.0.1
REM
REM This script automates almost all the necessary steps to install crankk in to Nebra RockPI Indoor.
REM
REM 
REM
REM Usage: setup_crankk_nebra_rock_pi.bat
REM
REM This script must be executed on Windows, and is provided as-is. The author of this script should not be liable for any damage this script may cause.
REM
REM
setlocal disableDelayedExpansion
:: -------- Begin macro definitions ----------
:: macros code from: https://stackoverflow.com/posts/13924161/revisions
set ^"LF=^
%= This creates a variable containing a single linefeed (0x0A) character =%
^"
:: Define %\n% to effectively issue a newline with line continuation
set ^"\n=^^^%LF%%LF%^%LF%%LF%^^"

:: @strLen  StrVar  [RtnVar]
::
::   Computes the length of string in variable StrVar
::   and stores the result in variable RtnVar.
::   If RtnVar is is not specified, then prints the length to stdout.
::
set @strLen=for %%. in (1 2) do if %%.==2 (%\n%
  for /f "tokens=1,2 delims=, " %%1 in ("!argv!") do ( endlocal%\n%
    set "s=A!%%~1!"%\n%
    set "len=0"%\n%
    for %%P in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (%\n%
      if "!s:~%%P,1!" neq "" (%\n%
        set /a "len+=%%P"%\n%
        set "s=!s:~%%P!"%\n%
      )%\n%
    )%\n%
    for %%V in (!len!) do endlocal^&if "%%~2" neq "" (set "%%~2=%%V") else echo %%V%\n%
  )%\n%
) else setlocal enableDelayedExpansion^&setlocal^&set argv=,

:: -------- End macro definitions ----------
set /P "ipaddr=Please enter gateway IP address: "
echo.
rem check if IP is valid
echo %ipaddr% |findstr /r "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" > NUL
if errorlevel 1 (
    echo Invalid IP address. Abort.
    goto :EOF
)
::goto tmpjump
set "keyfilename=nebra-rockPI-rsa"
set /P "keyfilename=Please enter key filename: [%keyfilename%]"
echo.
if "%keyfilename%" == "" (
	echo "key filename cannot be empty. Abort.
	goto :EOF
)
set /P "keypass=Please enter passphrase: "
echo.
if "%keypass%" == "" (
	echo "Passphrase cannot be empty. Abort.
	goto :EOF
)
cd %userprofile%
echo Let's create rsa keys...
ssh-keygen -f %keyfilename% -N %keypass% 
IF %ERRORLEVEL% NEQ 0 (
	Echo Error: ssh-keygen not found or could not generate rsa keys. Abort.
	goto :EOF
)
IF NOT EXIST %userprofile%\.ssh (
	Echo Folder .ssh does not exist. Let's create it...
	mkdir %userprofile%\.ssh > NUL
	IF %ERRORLEVEL% NEQ 0 (
		Echo Error: could not create .ssh folder. Abort.
		goto :EOF
	)
)
move %userprofile%\%keyfilename% %userprofile%\.ssh\ > NUL
move %userprofile%\%keyfilename%.pub %userprofile%\.ssh\ > NUL
IF %ERRORLEVEL% NEQ 0 (
	Echo Error: could not copy %keyfilename% to .ssh folder. Abort.
	goto :EOF
)
echo.
echo Next, you'll be asked THREE TIMES to input a password.
echo The password is 1234
echo.
echo Maybe, before that, you'll be asked to accept the fingerprint key. In that case, input "yes".
echo.
set /p "waitreq=Press enter to proceed..." 
ssh root@%ipaddr% -t "mount /dev/mmcblk1p4 /mnt" 
scp root@%ipaddr%:/mnt/config.json config.json.tmp
IF %ERRORLEVEL% NEQ 0 (
	Echo Error: could not connect to Nebra and get a copy of config.json file. Abort.
	goto :EOF
)
:tmpjump
set "rtn="
set /p new_config=<config.json.tmp
del config.json.tmp
set /p public_key=<%userprofile%\.ssh\%keyfilename%.pub
%@strLen% new_config rtn
:findBracket
set /a rtn=%rtn%-1
set "lastchar="
:bracketfinder
set lastchar=%new_config:~-1%
call set new_config=%%new_config:~0,%rtn%%%
set /a rtn=%rtn%-1
if "%lastchar%" NEQ "}" (goto bracketfinder)
)
set new_config=%new_config%,"os":{"sshKeys":["%public_key%"]}}
echo %new_config% > new_config.json
scp new_config.json root@%ipaddr%:/mnt/config.json
IF %ERRORLEVEL% NEQ 0 (
	Echo Error: could not connect to Nebra and update config.json file. Abort.
	del new_config.json 
	goto :EOF
)
del new_config.json
echo.
Echo Ok, at this moment:
echo.
echo    - power off the Nebra gateway
echo    - remove the SD card
echo    - close the gateway
echo    - power it up
echo    - wait a couple of minutes.
Echo.
Echo Then, open the Crankk Setup.
Echo.
set /p "waitreq=Press enter to proceed..." 
echo.
Echo Now, let's generate an OpenSSH version of the private key.
echo.
Echo You need to have PUTTYgen installed. Open PUTTYgen and:
Echo.
Echo    - At the top menu, click "File"
Echo    - Select "Load Private Key"
Echo    - In the combo box right above the "Open" and "Cancel" buttons (at the bottom right), select "All files (*.*)".
Echo    - goto ".ssh" folder and select "%keyfilename%" file.
Echo    - click "Open"
Echo    - Then, at the top menu, click "Conversions"
echo    - Select "Export OpenSSH key"
echo    - Type in a file name (example: %keyfilename%-openssh )
echo    - Click "Save" (it should save it in ".ssh" folder)
echo. 
echo Now, open the OpenSSH private key you just converted with Notepad.
Echo Select all the text and copy it (using Ctrl+C)
echo Next, you need to copy it into the Crankk Setup. 
echo Open Crankk Setup and, in the "SSH login" dialog, select "private key" and then paste (Ctrl+V) the openssh key into the text box at the right side.
Echo The password to use in Crank Setup is your passphrase (%keypass%).
echo.
Echo You're done here. Continue in the Crankk Setup.

