; Inno Setup Script for MangaBaka App
; Automates the generation of a standard, classic Windows installer wizard.

[Setup]
AppName=MangaBaka
AppVersion={#AppVersion}
AppPublisher=Oazzies
DefaultDirName={userappdata}\MangaBaka
DefaultGroupName=MangaBaka
OutputDir=.
OutputBaseFilename=windows-mangabaka-app-v{#AppVersion}-setup
Compression=lzma
SolidCompression=yes
SetupIconFile=windows\runner\resources\app_icon.ico
ArchitecturesInstallIn64BitMode=x64
DisableDirPage=yes
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\MangaBaka.exe

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\MangaBaka"; Filename: "{app}\MangaBaka.exe"
Name: "{userdesktop}\MangaBaka"; Filename: "{app}\MangaBaka.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Run]
Filename: "{app}\MangaBaka.exe"; Description: "{cm:LaunchProgram,MangaBaka}"; Flags: nowait postinstall skipifsilent
