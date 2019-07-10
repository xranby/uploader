!include LogicLib.nsh
!include WinVer.nsh

RequestExecutionLevel admin

!macro customInit

  ReadINIStr $9 "$TEMP\TidepoolUploader.ini" "InstallCount" "Value"
  IfFileExists "$TEMP\TidepoolUploader.ini" "+3" ""
    StrCpy $8 "1"
  goto +3
    IntOp $8 $9 + 1
    StrCpy $R7 "You have ran this setup program $9 times so far!\n\n"

  UserInfo::GetAccountType
  pop $0
  ${If} $0 != "admin"
      MessageBox MB_OK|MB_ICONSTOP "You need administrator rights to install the Tidepool Uploader."
      SetErrorLevel 740 ;ERROR_ELEVATION_REQUIRED
      Abort
  ${EndIf}

  ${If} ${IsWin7}
    IfSilent +1 +4
      MessageBox MB_OK|MB_ICONSTOP "This installer can not run in silent mode on Windows 7!"
      SetErrorLevel 2 ; aborted by script
      Abort
  ${EndIf}

!macroend

!macro customInstall

  Var /GLOBAL DriverDir
  Var /GLOBAL Installer_x64
  Var /GLOBAL Installer_x86

  ClearErrors

  StrCpy $DriverDir "$INSTDIR\resources\driver"

  ; Add our certificate to the local store to prevent unnecessary pop-up
  nsExec::ExecToStack 'certutil -addstore "TrustedPublisher" "$DriverDir\tidepool.cer"'
  Pop $1
  WriteINIStr "$TEMP\TidepoolUploader.ini" "CertInstallResult" "Value" "$1"

  ${If} ${IsWin10}
    ; Windows 10 uses drivers with attestation signing
    CopyFiles /SILENT $DriverDir\win10\* $DriverDir
  ${EndIf}


  StrCpy $Installer_x64 "$DriverDir\TidepoolUSBDriver_x64.exe /q"
  StrCpy $Installer_x86 "$DriverDir\TidepoolUSBDriver_x86.exe /q"

  IfSilent +3 ; don't use quiet flag if not silent install
  StrCpy $Installer_x64 "$DriverDir\TidepoolUSBDriver_x64.exe"
  StrCpy $Installer_x86 "$DriverDir\TidepoolUSBDriver_x86.exe"

  ${If} ${RunningX64}
      ${If} ${IsWin7}
        ; 64-bit Windows 7
        CopyFiles $DriverDir\win7x64\* $DriverDir\amd64
        ExecWait $Installer_x64
      ${Else}
        ExecWait $Installer_x64
      ${EndIf}
  ${Else}
      ${If} ${IsWin7}
        ; 32-bit Windows 7
        CopyFiles $DriverDir\win7x86\* $DriverDir\i386
        ExecWait $Installer_x86
      ${Else}
        ExecWait $Installer_x86
      ${EndIf}
  ${EndIf}

  IfErrors 0 +2
	MessageBox MB_OK "Error occurred during installation." IDOK +2

  WriteINIStr "$TEMP\TidepoolUploader.ini" "InstallCount" "Value" "$8"

!macroend
