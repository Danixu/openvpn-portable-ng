;Copyright (C) 2004-2005 John T. Haller
;Portions Copyright 2007 Lukas Landis

;This software is OSI Certified Open Source Software.
;OSI Certified is a certification mark of the Open Source Initiative.

;This program is free software; you can redistribute it and/or
;modify it under the terms of the GNU General Public License
;as published by the Free Software Foundation; either version 2
;of the License, or (at your option) any later version.

;This program is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;GNU General Public License for more details.

;You should have received a copy of the GNU General Public License
;along with this program; if not, write to the Free Software
;Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

# Force Admin App
;!define Admin "true"
!include "LogicLib.nsh"
!include "StrFunc.nsh"
!include "OpenVPNPortable.nsh"
#!include "UAC.nsh"
!include "CommonVariables.nsh"
!include "NSISpcre.nsh"
!include "WordFunc.nsh"


!insertmacro DEFINES "OpenVPNPortable"
!insertmacro PROGRAM_DETAILS
!insertmacro RUNTIME_SWITCHES
!insertmacro PROGRAM_VARIABLES
!insertmacro PROGRAM_ICON "OpenVPNPortable"
!insertmacro REFind

WindowIcon Off
SilentInstall Silent
;ShowInstDetails show

!system 'md "${OutputFolder}"'

# Include language files
!include "Lang\OpenVPNPortable\*.nsh"

# Variables
Var PROGRAMDIRECTORY
Var DRIVERDIRECTORY
Var TAPINSTALLED
Var CONFIGDIRECTORY
Var LOGDIRECTORY
Var EXECSTRING
Var SHOWSPLASH
Var INSTBEHAVIOUR
Var UNINSTBEHAVIOUR
Var AUTOCONNECT
Var CHECKUPDATES
Var WindowsVersion
Var OpenVPNVersion
Var OpenVPNLatestVersion
Var CPU

Var Downloaded

# Call to initialize
${StrRep}
${StrLoc}

!include "OpenVPNPortable_Functions.nsh"


Section "Main"
	CreateDirectory "$EXEDIR\Data\log"
	
	${IfFileExists} $0 ${INIFILE}
	${If} $0 == False
		SetOutPath "$EXEDIR\Data"
		File "OpenVPNPortable.ini"
	${EndIf}
	
	# Allow download popups to be showed.
	setsilent normal
	
	# Define LogFile
	LogEx::Init "$EXEDIR\Data\log\${APP}.log"
	
	${LogWithTime} "#################################################################################################################"
	${LogWithTime} "#################################################################################################################"
	${LogWithTime} "Starting the app..."
	${LogWithTime} "Checking if the app is already running"

	# Ckeck if the app is running
	System::Call 'kernel32::CreateMutexA(i 0, i 0, t "${NAME}Mutex") i .r1 ?e'
    Pop $R5
    StrCmp $R5 0 +5
    MessageBox MB_OK|MB_ICONQUESTION|MB_TOPMOST `$(MAIN_App_Running)`
	${LogWithTime} "The app is already running. Exiting..."
    Quit

	${LogWithTime} "Detecting OS version..."

	# Get the OS version (5 = XP, other = Vista+)
	nsisos::osversion
	${If} "$0" == "5"
		StrCpy "$WindowsVersion" "XP"
		${LogWithTime} "OS: Windows XP"
	${Else}
		StrCpy "$WindowsVersion" "Vista"
		${LogWithTime} "OS: Windows Vista o superior"
	${EndIf}
	
	${LogWithTime} "Checking the os architecture..."

	# Check the OS Architecture
	System::Call "kernel32::GetCurrentProcess() i .s"
	System::Call "kernel32::IsWow64Process(i s, *i .r0)"
	
	${If} $0 == 0
		StrCpy $CPU `win32`
		${LogWithTime} "Detected x86 OS"
	${Else}
		StrCpy $CPU `win64`
		${LogWithTime} "Detected x64 OS"
	${EndIf}

	# Checking if ini file exist and getting all configuration
	${IfFileExists} $0 ${INIFILE}
	${If} $0 == True
		${LogWithTime} "INI File found, getting custom configuration..."
		ReadINIStr $0 "${INIFILE}" "OpenVPNPortable" "OpenVPNDirectory"
		${StrRep} "$PROGRAMDIRECTORY" "$EXEDIR\$0" "%WinVer%" "$WindowsVersion"
			
		ReadINIStr $0 "${INIFILE}" "Drivers" "DriverDirectory"
		${StrRep} "$DRIVERDIRECTORY" "$EXEDIR\$0" "%WinVer%" "$WindowsVersion"
		${StrRep} "$DRIVERDIRECTORY" "$DRIVERDIRECTORY" "%CPU%" "$CPU"
			
		ReadINIStr $0 "${INIFILE}" "OpenVPNPortable" "ConfigDirectory"
		StrCpy $CONFIGDIRECTORY "$EXEDIR\$0"

		ReadINIStr $0 "${INIFILE}" "OpenVPNPortable" "LogDirectory"
		StrCpy $LOGDIRECTORY "$EXEDIR\$0"
	
		ReadINIStr $0 "${INIFILE}" "OpenVPNPortable" "ShowSplash"
		StrCpy $SHOWSPLASH "$0"

		ReadINIStr $0 "${INIFILE}" "OpenVPNPortable" "DriverInstBehaviour"
		StrCpy $INSTBEHAVIOUR "$0"

		ReadINIStr $0 "${INIFILE}" "OpenVPNPortable" "DriverUnInstBehaviour"
		StrCpy $UNINSTBEHAVIOUR "$0"

		ReadINIStr $0 "${INIFILE}" "OpenVPNPortable" "AutoConnect"
		StrCpy $AUTOCONNECT "$0"
		
		ReadINIStr $0 "${INIFILE}" "OpenVPNPortable" "AutoUpdate"
		StrCpy $CHECKUPDATES "$0"
		
		ReadINIStr $0 "${INIFILE}" "Program" "CurrentVersion"
		StrCpy $OpenVPNVersion "$0"
	${Else}
		${LogWithTime} "INI File not found, using the default settings..."
	${EndIf}
	
	# If any configuration don't exist, the program use the default.
	${If} $PROGRAMDIRECTORY == ""
		${LogWithTime} "Program Directory varible is empty, using the default"
		StrCpy "$PROGRAMDIRECTORY" "$EXEDIR\${DEFAULTAPPDIR}"
	${EndIf}
	
	${If} $DRIVERDIRECTORY == ""
		${LogWithTime} "Driver Directory varible is empty, using the default"
		StrCpy "$DRIVERDIRECTORY" "$EXEDIR\${DEFAULTDRVDIR}"
	${EndIf}
	
	${If} $CONFIGDIRECTORY == ""
		${LogWithTime} "Config Directory varible is empty, using the default"
		StrCpy $CONFIGDIRECTORY "$EXEDIR\${DEFAULTCONFIGDIR}"
	${EndIf}
	
	${If} $LOGDIRECTORY == ""
		${LogWithTime} "Logs Directory varible is empty, using the default"
		StrCpy $LOGDIRECTORY "$EXEDIR\${DEFAULTLOGDIR}"
	${EndIf}
	
	${If} $SHOWSPLASH == ""
		${LogWithTime} "Show Splash varible is empty, using the default"
		StrCpy $SHOWSPLASH "true"
	${EndIf}
	
	${If} $INSTBEHAVIOUR == ""
		${LogWithTime} "Installation Behaviour varible is empty, using the default"
		StrCpy $INSTBEHAVIOUR "ask"
	${EndIf}
	
	${If} $UNINSTBEHAVIOUR == ""
		${LogWithTime} "Uninstallation Behaviour varible is empty, using the default"
		StrCpy $UNINSTBEHAVIOUR "ask"
	${EndIf}
	
	${If} $AUTOCONNECT == ""
		${LogWithTime} "Autoconnect varible is empty, using the default"
		StrCpy $AUTOCONNECT "false"
	${EndIf}
	
	${If} $CHECKUPDATES == ""
		${LogWithTime} "Autoconnect varible is empty, using the default"
		StrCpy $CHECKUPDATES ${DEFAULTCHECKUPDATES}
	${EndIf}
	
	# Logging the configuration
	${LogWithTime} "Program Directory: $PROGRAMDIRECTORY"
	${LogWithTime} "Driver Directory: $DRIVERDIRECTORY"
	${LogWithTime} "Config fies Directory: $CONFIGDIRECTORY"
	${LogWithTime} "Logs Directory: $LOGDIRECTORY"
	${LogWithTime} "Show Splash?: $SHOWSPLASH"
	${LogWithTime} "Instalation Behabiour: $INSTBEHAVIOUR"
	${LogWithTime} "Uninstalation Behaviour: $UNINSTBEHAVIOUR"
	${LogWithTime} "Autoconnect?: $AUTOCONNECT"

	# Check if the main program exe exist
	CheckEXE:
	${IfFileExists} $0 "$PROGRAMDIRECTORY\openvpn-gui.exe"
	${IfFileExists} $1 "$PROGRAMDIRECTORY\openvpn.exe"
	
	${If} $0 == False
	${OrIf} $1 == False
		${LogWithTime} "Main program exe don't exist. Asking user to download."
		MessageBox MB_YESNO|MB_ICONQUESTION `$(MAIN_Download_Program)` IDNO Salir
		${GetLatestVersion} $OpenVPNLatestVersion
		${DownloadOpenVPN} $0 $OpenVPNLatestVersion
		
		${LogWithTime} "Return is: $0"
		
		${If} $Downloaded == True
			${LogWithTime} "Download complete..."
			WriteINIStr "${INIFILE}" "Program" "CurrentVersion" "$OpenVPNLatestVersion"
			MessageBox MB_OK|MB_ICONQUESTION `$(MAIN_Download_Complete)`
			Goto CheckEXE
		${Else}
			${LogWithTime} "WTF? $0"
			${LogWithTime} "There was an error downloading the new version."
			Abort
		${EndIf}
	${Else}
		${LogWithTime} "Main program exe exist."
		${If} $CHECKUPDATES == "true"
			${GetLatestVersion} $OpenVPNLatestVersion
		
			${VersionCompare} "$OpenVPNLatestVersion" "$OpenVPNVersion" $R0
			${If} "$R0" == "1"
				${LogWithTime}  "There is a new OpenVPN version."
				MessageBox MB_YESNO|MB_ICONQUESTION `$(MAIN_Download_Update)` IDNO NoUpdate
				${LogWithTime} "Deleting old files..."
				Delete "$PROGRAMDIRECTORY\*.*"
				IfErrors ErrorUpdate

				${DownloadOpenVPN} $0 $OpenVPNLatestVersion
				WriteINIStr "${INIFILE}" "Program" "CurrentVersion" "$OpenVPNLatestVersion"
				MessageBox MB_OK|MB_ICONQUESTION `$(Main_Download_Update_Complete)`
				Goto NoUpdate
				
				ErrorUpdate:
					${LogWithTime} "There was an error downloading the new version."
				NoUpdate:
			${EndIf}
		${EndIf}
	${EndIf}
	
	${LogWithTime} "Checking configuration files..."
	
	${IfFileExists} $0 "$CONFIGDIRECTORY\${CONFIGFILE}"
	${If} $0 == False
		MessageBox MB_OK|MB_ICONEXCLAMATION `$(MAIN_No_Config)`
		${LogWithTime} "There are no config files."
		Abort
	${EndIf}
	
	IfFileExists "$LOGDIRECTORY\*.*" +3
		${LogWithTime} "Creating log folder..."
		CreateDirectory "$LOGDIRECTORY"

	${LogWithTime} "Checking if there is a Tap driver installed."
	
	InstDrv::InitDriverSetup /NOUNLOAD "${DRIVERID}" "${DRIVERNAME}"
	InstDrv::CountDevices
	Pop $0
	${If} "$0" == "0"
		${LogWithTime} "No tap driver installed, asking for install."
		${If} $INSTBEHAVIOUR == "ask"
			MessageBox MB_YESNO|MB_ICONQUESTION `$(MAIN_Install_Tap)` IDNO Salir
		${EndIf}
		
		${LogWithTime} "Extracting tap driver to temp folder"
	
		SetOutPath "$PLUGINSDIR\Driver"
		
		${If} "$WindowsVersion" == "XP"
			${If} "$CPU" == "win32"
				File "drivers\XP\win32\OemWin2k.inf"
				File "drivers\XP\win32\tap0901.cat"
				File "drivers\XP\win32\tap0901.sys"
				File "bin\tapinstallWin32.exe"
			${Else}
				File "drivers\XP\win64\OemWin2k.inf"
				File "drivers\XP\win64\tap0901.cat"
				File "drivers\XP\win64\tap0901.sys"
				File "bin\tapinstallWin64.exe"
			${EndIf}
		${Else}
			${If} "$CPU" == "win32"
				File "drivers\Vista\win32\OemWin2k.inf"
				File "drivers\Vista\win32\tap0901.cat"
				File "drivers\Vista\win32\tap0901.sys"
				File "bin\tapinstallWin32.exe"
			${Else}
				File "drivers\Vista\win64\OemWin2k.inf"
				File "drivers\Vista\win64\tap0901.cat"
				File "drivers\Vista\win64\tap0901.sys"
				File "bin\tapinstallWin64.exe"
			${EndIf}
		${EndIf}
		
		${LogWithTime} "Checking if driver file was extracted correctly"
		IfFileExists "$PLUGINSDIR\Driver\${DRIVERFILE}" DriverExists
		MessageBox MB_OK|MB_ICONEXCLAMATION `$PLUGINSDIR\Driver\${DRIVERFILE} $(MAIN_Not_Found)`
		${LogWithTime} "Driver file not found. Check the configuration file."
		${LogWithTime} "---------------------------------------------------------------------------------------------------"
		LogEx::Close
		Abort
	
	DriverExists:
		${LogWithTime} "Driver file exists. Running install command:"
		${LogWithTime} `"$PLUGINSDIR\Driver\tapinstall$CPU.exe" install "$PLUGINSDIR\Driver\${DRIVERFILE}" ${DRIVERNAME}`
		Push "ExecDos::End" ;Add a marker for the loop to test for.
		ExecDos::exec /TOSTACK `"$PLUGINSDIR\Driver\tapinstall$CPU.exe" install "$PLUGINSDIR\Driver\${DRIVERFILE}" ${DRIVERNAME}` ""
		Pop $0
		${If} $0 != "0" ;If we got an error..
			Goto ErrorInstalling
		${ElseIF} $0 == "0" ;If it was successfully uninstalled...## Loop through stack.
			LoopIn:
				Pop $1
				StrCmp $1 "ExecDos::End" ExitLoopIn
				${StrLoc} $0 "$1" "failed" "<"
				${IfNotThen} $0 == "" ${|} Goto ErrorInstalling ${|}
				Goto LoopIn
			ExitLoopIn:

			Goto SalirDriver
		${EndIf}
		
		ErrorInstalling:
			${LogWithTime} "There was an error installing the TAP driver."
			${LogWithTime} "-----------------------------------------------------------------------------------------------------------------"
			${LogWithTime} "-----------------------------------------------------------------------------------------------------------------$\n$\n"
			MessageBox MB_OK|MB_ICONEXCLAMATION `$(MAIN_Install_Tap_Error)`

			LogEx::Close
			Abort
			
		SalirDriver:
			${LogWithTime} "Installation of TAP driver sucessfull."
			StrCpy $TAPINSTALLED true
	${EndIf}
	
	# MessageBox MB_OK|MB_ICONQUESTION "Inicio..."
	
	${LogWithTime} "Running the main program."
	
	StrCpy "$EXECSTRING" ' --config_dir "$CONFIGDIRECTORY" --ext_string "ovpn" --exe_path "$PROGRAMDIRECTORY\openvpn.exe" --log_dir "$LOGDIRECTORY" --priority_string "NORMAL_PRIORITY_CLASS" --append_string "0"'
	
	${If} $AUTOCONNECT != "false"
		StrCpy "$EXECSTRING" "$EXECSTRING --connect_to $AUTOCONNECT"
	${EndIf}
	
	Call GetParameters
	Pop $0	
	${If} "$0" != ""
		StrCpy "$EXECSTRING" "$EXECSTRING $0"
	${EndIf}
	
	${If} $SHOWSPLASH == "true"
		File /oname=$PLUGINSDIR\splash.jpg "${NAME}.jpg"
		newadvsplash::show /NOUNLOAD 2000 400 400 -1 /NOCANCEL $PLUGINSDIR\splash.jpg
	${EndIf}
	
	${LogWithTime} "$EXECSTRING"

	# MessageBox MB_OK|MB_ICONQUESTION '"$PROGRAMDIRECTORY\openvpn-gui.exe" $EXECSTRING'
	ExecWait '"$PROGRAMDIRECTORY\openvpn-gui.exe" $EXECSTRING'
	
	# MessageBox MB_OK|MB_ICONQUESTION "Out"
	
	${LogWithTime} "Checking if tap driver was installed by the program."
	
	${If} $TAPINSTALLED == true
	${OrIf} $UNINSTBEHAVIOUR == "alwaysask"
		${If} $UNINSTBEHAVIOUR == "ask"
		${OrIf} $UNINSTBEHAVIOUR == "alwaysask"
			${LogWithTime} "Asking the user to uninstall"
			MessageBox MB_YESNO|MB_ICONQUESTION `$(MAIN_Uninstall_Tap)` IDNO Salir
		${ElseIf} $UNINSTBEHAVIOUR == "false"
			Goto Salir
		${EndIf}
		
		${LogWithTime} "Uninstalling the tap driver"
		
		SetOutPath "$PLUGINSDIR\"
		
		${If} "$CPU" == "win32"
			File "bin\tapinstallWin32.exe"
		${Else}
			File "bin\tapinstallWin64.exe"
		${EndIf}
		
		${LogWithTime} `"$PLUGINSDIR\tapinstall$CPU.exe" remove ${DRIVERNAME}`
	
		Push "ExecDos::End" ;Add a marker for the loop to test for.
		ExecDos::exec /TOSTACK `"$PLUGINSDIR\tapinstall$CPU.exe" remove ${DRIVERNAME}` ""
		Pop $0
		${If} $0 != "0" ;If we got an error...
			Goto ErrorUnInstalling
		${ElseIF} $0 == "0" ;If it was successfully uninstalled...## Loop through stack.
			LoopUn:
				Pop $1
				StrCmp $1 "ExecDos::End" ExitLoopUn
				${StrLoc} $0 "$1" "failed" "<"
				${IfNotThen} $0 == "" ${|} Goto ErrorUnInstalling ${|}
				Goto LoopUn
			ExitLoopUn:

			Goto OkUninstalling
		${EndIf}

		Goto OkUninstalling
		
		ErrorUnInstalling:
			${LogWithTime} "Error uninstalling the tap driver"
			MessageBox MB_OK|MB_ICONEXCLAMATION `$(MAIN_Uninstall_Tap_Error)`
			Abort

		OkUninstalling:
			${LogWithTime} "Tap driver uninstalled"
			MessageBox MB_OK `$(MAIN_Uninstall_Tap_Ok)`
	${EndIf}
	
	Salir:
		newadvsplash::stop /WAIT
		Sleep 2000*/
		${LogWithTime} "-----------------------------------------------------------------------------------------------------------------"
		${LogWithTime} "-----------------------------------------------------------------------------------------------------------------$\n$\n"
		SetErrorLevel 0
SectionEnd

Function GetParameters
	; GetParameters
	; input, none
	; output, top of stack (replaces, with e.g. whatever)
	; modifies no other variables. 

	Push $R0
	Push $R1
	Push $R2
	Push $R3

	StrCpy $R2 1
	StrLen $R3 $CMDLINE

	;Check for quote or space
	StrCpy $R0 $CMDLINE $R2
	StrCmp $R0 '"' 0 +3
		StrCpy $R1 '"'
		Goto loop
	StrCpy $R1 " "

	loop:
		IntOp $R2 $R2 + 1
		StrCpy $R0 $CMDLINE 1 $R2
		StrCmp $R0 $R1 get
		StrCmp $R2 $R3 get
		Goto loop
  
	get:
		IntOp $R2 $R2 + 1
		StrCpy $R0 $CMDLINE 1 $R2
		StrCmp $R0 " " get
		StrCpy $R0 $CMDLINE "" $R2

	Pop $R3
	Pop $R2
	Pop $R1
	Exch $R0
FunctionEnd