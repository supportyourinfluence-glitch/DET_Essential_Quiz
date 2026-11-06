; 단어 행성 탐험대 PC 설치 프로그램. 인터넷 없이 실행되도록 게임 전체를 넣는다.
; 빌드: ISCC.exe tools\installer\word-planet.iss (결과: dist\)
#define AppTitle "단어 행성 탐험대"
#define AppVer "1.1.0"

[Setup]
AppId={{7C1F3E52-9A44-4B6E-8D21-5E0B7A3C9F10}
AppName={#AppTitle}
AppVersion={#AppVer}
AppPublisher=supportyourinfluence-glitch
DefaultDirName={localappdata}\Programs\WordPlanet
DefaultGroupName={#AppTitle}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\..\dist
OutputBaseFilename=WordPlanet-Setup-{#AppVer}
SetupIconFile=app.ico
UninstallDisplayIcon={app}\app.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "korean"; MessagesFile: "compiler:Languages\Korean.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"

[Files]
Source: "..\..\game\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "app.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppTitle}"; Filename: "{code:AppTarget}"; Parameters: "{code:AppArgs}"; IconFilename: "{app}\app.ico"
Name: "{userdesktop}\{#AppTitle}"; Filename: "{code:AppTarget}"; Parameters: "{code:AppArgs}"; IconFilename: "{app}\app.ico"; Tasks: desktopicon

[Run]
Filename: "{code:AppTarget}"; Parameters: "{code:AppArgs}"; Description: "{cm:LaunchProgram,{#AppTitle}}"; Flags: postinstall nowait skipifsilent shellexec

[Code]
function EdgePath(): String;
begin
  Result := '';
  if not RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe', '', Result) then
    RegQueryStringValue(HKCU, 'SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe', '', Result);
  if (Result <> '') and not FileExists(Result) then
    Result := '';
end;

{ Edge가 있으면 앱 창으로 열고, 없으면 기본 브라우저로 연다 }
function AppTarget(Param: String): String;
begin
  Result := EdgePath();
  if Result = '' then
    Result := ExpandConstant('{app}\index.html');
end;

function AppArgs(Param: String): String;
var
  Url: String;
begin
  Result := '';
  if EdgePath() = '' then
    Exit;
  Url := ExpandConstant('{app}\index.html');
  StringChangeEx(Url, '%', '%25', True);
  StringChangeEx(Url, ' ', '%20', True);
  StringChangeEx(Url, '#', '%23', True);
  StringChangeEx(Url, '\', '/', True);
  Result := '--app="file:///' + Url + '"';
end;
