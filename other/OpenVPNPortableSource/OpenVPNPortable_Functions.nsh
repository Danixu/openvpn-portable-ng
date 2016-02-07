######################################################################
### TimeStamp
######################################################################
!ifndef TimeStamp
	!define TimeStamp "!insertmacro _TimeStamp"
	!macro _TimeStamp FormatedString
		Call __TimeStamp
		Pop ${FormatedString}
	!macroend

Function __TimeStamp
    ClearErrors
    ## Store the needed Registers on the stack
        Push $0 ; Stack $0
        Push $1 ; Stack $1 $0
        Push $2 ; Stack $2 $1 $0
        Push $3 ; Stack $3 $2 $1 $0
        Push $4 ; Stack $4 $3 $2 $1 $0
        Push $5 ; Stack $5 $4 $3 $2 $1 $0
        Push $6 ; Stack $6 $5 $4 $3 $2 $1 $0
        Push $7 ; Stack $7 $6 $5 $4 $3 $2 $1 $0
        ;Push $8 ; Stack $8 $7 $6 $5 $4 $3 $2 $1 $0
 
    ## Call System API to get the current system Time
        System::Alloc 16
        Pop $0
        System::Call 'kernel32::GetLocalTime(i) i(r0)'
        System::Call '*$0(&i2, &i2, &i2, &i2, &i2, &i2, &i2, &i2)i (.r1, .r2, n, .r3, .r4, .r5, .r6, .r7)'
        System::Free $0
 
        IntFmt $2 "%02i" $2
        IntFmt $3 "%02i" $3
        IntFmt $4 "%02i" $4
        IntFmt $5 "%02i" $5
        IntFmt $6 "%02i" $6
 
    ## Generate Timestamp
        ;StrCpy $0 "YEAR=$1$\nMONTH=$2$\nDAY=$3$\nHOUR=$4$\nMINUITES=$5$\nSECONDS=$6$\nMS$7"
        StrCpy $0 "$1/$2/$3 $4:$5:$6.$7"
 
    ## Restore the Registers and add Timestamp to the Stack
        ;Pop $8  ; Stack $7 $6 $5 $4 $3 $2 $1 $0
        Pop $7  ; Stack $6 $5 $4 $3 $2 $1 $0
        Pop $6  ; Stack $5 $4 $3 $2 $1 $0
        Pop $5  ; Stack $4 $3 $2 $1 $0
        Pop $4  ; Stack $3 $2 $1 $0
        Pop $3  ; Stack $2 $1 $0
        Pop $2  ; Stack $1 $0
        Pop $1  ; Stack $0
        Exch $0 ; Stack ${TimeStamp}
FunctionEnd
!endif
###########

######################################################################
### ${LogWithTime} $message
######################################################################
!ifndef LogWithTime
	!define LogWithTime "!insertmacro LogWithTime"
	!macro LogWithTime text
		Push `${text}`
		Call LogWithTime
	!macroend

	Function LogWithTime
		Pop $0
		${TimeStamp} $1
		LogEx::Write "$1 - $0"
	FunctionEnd
!endif
###########

######################################################################
### ${IfFileExists} $return $file
######################################################################
!ifndef IfFileExists
	!define IfFileExists "!insertmacro _IfFileExists"

	!macro _IfFileExists return_var Filename
	  Push "${Filename}"
	  Call __IfFileExists
	  Pop ${return_var}
	!macroend

	Function __IfFileExists
		Pop $0
		IfFileExists "$0" _Exist _Noexist
		
		_Exist:
		Push True
		Return
		
		_Noexist:
		Push False
	FunctionEnd
!endif
###########

######################################################################
### ${GetLatestVersion} $return
######################################################################
!ifndef GetLatestVersion
	!define GetLatestVersion "!insertmacro GetLatestVersion"
	!macro GetLatestVersion return_var
		Call GetLatestVersion
		Pop `${return_var}`
		${LogWithTime} "Done. Latest version is ${return_var}"
	!macroend

	Function GetLatestVersion
		ClearErrors
		${LogWithTime} "Downloading the latest version info..."
		inetc::get /SILENT ${VERSIONCHECKURL} "$PLUGINSDIR\LATEST.txt" /END
		Pop $R0
		${If} "$R0" == "OK"
			${LogWithTime} "File downloaded. Geting the version number..."
			FileOpen $0 "$PLUGINSDIR\LATEST.txt" "r"
			loop:
				FileRead $0 $2
				IfErrors done
				${StrLoc} $R1 "$2" "openvpn-install-latest-stable" ">"
				;MessageBox MB_YESNO|MB_ICONQUESTION $R1
				${If} $R1 != ""
					${REFind} $R0 "([0-9]+\.[0-9]+\.[0-9]+)" "$2"
					;MessageBox MB_YESNO|MB_ICONQUESTION $R0
					${If} $R0 == 1
						;MessageBox MB_YESNO|MB_ICONQUESTION $R0
						Goto done
					${EndIf}
					${REFindClose}
					Goto done
				${EndIf}
				;Quit
				Goto loop
				done:
					FileClose $0
		${Else}
			MessageBox MB_OK|MB_ICONSTOP "Unable to download file $2 ($R0)"
			Push -1
		${EndIf}		
	FunctionEnd
!endif
###########

!ifndef DownloadOpenVPN
	!define DownloadOpenVPN "!insertmacro DownloadOpenVPN"
	!macro DownloadOpenVPN return_var OpenVPNVERSION
		;Push ${WindowsVersion}
		Push ${OpenVPNVERSION}
		Call DownloadOpenVPN
		Pop ${return_var}
	!macroend


	Function DownloadOpenVPN
		ClearErrors
		Pop "$R0"
		;Pop "$R1"
		${LogWithTime} "Downloading latest OpenVPN version..."
		
		${If} "$WindowsVersion" == "XP"
			${LogWithTime} "URL: ${DOWNLOADURL}/openvpn-install-$R0-I001-i686.exe"
			inetc::get /POPUP "" /CAPTION "Get latest openvpn version for XP..." "${DOWNLOADURL}/openvpn-install-$R0-I001-i686.exe" "$PLUGINSDIR\latest.7z" /END
		${Else}
			${LogWithTime} "URL: ${DOWNLOADURL}/openvpn-install-$R0-I601-i686.exe"
			inetc::get /POPUP "" /CAPTION "Get latest openvpn version for Vista+..." "${DOWNLOADURL}/openvpn-install-$R0-I601-i686.exe" "$PLUGINSDIR\latest.7z" /END
		${EndIf}
		
		Pop $9
		${If} "$9" != "OK"
			StrCpy "$9" "Download Error: $9"
			Goto ErrorOUT
		${EndIf}
		
		${LogWithTime} "Extracting 7-zip program..."
		SetOutPath "$PLUGINSDIR\"
		File "bin\7z.exe"
		File "bin\7z.dll"
		
		${LogWithTime} 'Running extract command: "$PLUGINSDIR\7z.exe" x "$PLUGINSDIR\latest.7z" -o"$PLUGINSDIR\"'
		ExecDos::exec '"$PLUGINSDIR\7z.exe" x "$PLUGINSDIR\latest.7z" -o"$PLUGINSDIR\"' 'D:\salida.log'
		
		${LogWithTime} "Creating and copying the openvpn files"
		CreateDirectory "$PROGRAMDIRECTORY"
		Pop $9
		IfErrors ErrorOut

		${LogWithTime} "Copying file libeay32.dll..."
		CopyFiles "$PLUGINSDIR\bin\libeay32.dll" "$PROGRAMDIRECTORY"
		IfErrors ErrorOut
		
		${LogWithTime} "Copying file liblzo2-2.dll..."
		CopyFiles "$PLUGINSDIR\bin\liblzo2-2.dll" "$PROGRAMDIRECTORY"
		IfErrors ErrorOut
		
		${LogWithTime} "Copying file libpkcs11-helper-1.dll..."
		CopyFiles "$PLUGINSDIR\bin\libpkcs11-helper-1.dll" "$PROGRAMDIRECTORY"
		IfErrors ErrorOut
		
		${LogWithTime} "Copying file openssl.exe..."
		CopyFiles "$PLUGINSDIR\bin\openssl.exe" "$PROGRAMDIRECTORY"
		IfErrors ErrorOut
		
		${LogWithTime} "Copying file openvpn.exe..."
		CopyFiles "$PLUGINSDIR\bin\openvpn.exe" "$PROGRAMDIRECTORY"
		IfErrors ErrorOut
		
		${LogWithTime} "Copying file openvpnserv.exe..."
		CopyFiles "$PLUGINSDIR\bin\openvpnserv.exe" "$PROGRAMDIRECTORY"
		IfErrors ErrorOut
		
		${LogWithTime} "Copying file ssleay32.dll..."
		CopyFiles "$PLUGINSDIR\bin\ssleay32.dll" "$PROGRAMDIRECTORY"
		IfErrors ErrorOut
		
		${LogWithTime} "Extracting file openvpn-gui.exe..."
		SetOutPath "$PROGRAMDIRECTORY\"
		File "bin\openvpn-gui.exe"
		IfErrors ErrorOut		
		
		Goto End
			
		ErrorOUT:
			${LogWithTime} "There was an error: $9"
			MessageBox MB_OK|MB_ICONSTOP "There was an error: $9"
			Push -1
		End:
			Push 0
			StrCpy $Downloaded True
	FunctionEnd
!endif