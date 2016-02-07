!macro DEFINES PNAME
       !define NAME "${PNAME}"
       !define FRIENDLYNAME "OpenVPN Portable"
       !define APP "OpenVPN"
       !define VER "1.0.0.0"	;Version of the Portable App, Version of OpenVPN is found on .\app\appinfo\appinfo.ini
       ;!define SUBVER "RC4"
       !define WEBSITE "https://bitbucket.org/Danixu86/openvpn-portable"
       !define DEFAULTAPPDIR "app\%WinVer%\bin"
       !define DEFAULTDRVDIR "app\%WinVer%\driver\$CPU"
       !define DEFAULTCONFIGDIR "data\config"
       !define DEFAULTLOGDIR "data\log"
       !define TAPINSTALLEXE32 "tapinstallWin32.exe"
       !define TAPINSTALLEXE64 "tapinstallWin64.exe"
       !define DRIVERFILE "OemWin2k.inf"
       !define DRIVERNAME "tap0901"
       !define DRIVERID "{4d36e972-e325-11ce-bfc1-08002be10318}"
       !define CONFIGFILE "*.ovpn"
	   !define DEFAULTCHECKUPDATES "false"
	   !define INIFILE "$EXEDIR\Data\OpenVPNPortable.ini"
	   
	   !define VERSIONCHECKURL "http://build.openvpn.net/downloads/releases/latest/LATEST.txt"
	   !define DOWNLOADURL "http://build.openvpn.net/downloads/releases"
!macroend

!macro PROGRAM_DETAILS
       ;=== Program Details
       Name "${NAME}"
       Caption "${FRIENDLYNAME} - OpenVPN Made Portable"
       VIProductVersion "${VER}"
       VIAddVersionKey FileDescription "${FRIENDLYNAME}"
       VIAddVersionKey LegalCopyright "Lukas Landis"
       VIAddVersionKey Comments "Allows ${APP} to be run from a removable drive."
       VIAddVersionKey OriginalFilename "${NAME}.exe"
       VIAddVersionKey FileVersion "${VER}"
!macroend

!macro PROGRAM_VARIABLES
		RequestExecutionLevel admin
		OutFile "${OutputFolder}\${NAME}.exe"
!macroend

!macro RUNTIME_SWITCHES
       ;=== Runtime Switches
       CRCCheck On
	   ;Unicode True
       ;WindowIcon Off
       ;SilentInstall Silent
       AutoCloseWindow True
       SetCompressor /SOLID LZMA
!macroend

!macro PROGRAM_ICON ICONNAME
       ;=== Program Icon
       Icon "${ICONNAME}.ico"
       !define MUI_ICON "${ICONNAME}.ico"
!macroend

