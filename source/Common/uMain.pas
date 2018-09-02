(******************************************************************************

______________________________________________________________________________

YTD v1.00                                                    (c) 2009-12 Pepak
http://www.pepak.net/ytd                                  http://www.pepak.net
______________________________________________________________________________


Copyright (c) 2009-12 Pepak (http://www.pepak.net)
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Pepak nor the
      names of his contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL PEPAK BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

******************************************************************************)

unit uMain;
{$INCLUDE 'ytd.inc'}

interface

procedure Main;

implementation

uses
  SysUtils, Classes, Windows, CommCtrl,
  {$IFDEF SETUP}
    ShlObj,
    FileCtrl,
    uSetup,
    uCompatibility,
    {$IFDEF SETUP_GUI}
      {$IFDEF GUI_WINAPI}
        guiSetupWINAPI,
      {$ELSE}
        guiSetupVCL,
      {$ENDIF}
    {$ENDIF}
  {$ENDIF}
  {$IFDEF CLI}
    uYTD,
    uConsoleApp,
  {$ENDIF}
  {$IFDEF GUI}
    {$IFDEF GUI_WINAPI}
      guiMainWINAPI,
    {$ELSE}
      Forms,
      guiMainVCL,
    {$ENDIF}
  {$ENDIF}
  uFunctions, uMessages;

type
  TStartupType = ( {$IFDEF CLI} stCLI, {$ENDIF} {$IFDEF GUI} stGUI, stGUIexplicit, {$ENDIF} {$IFDEF SETUP} stInstall, {$ENDIF} stNone);

var
  StartedFromIDE: boolean;
  {$IFDEF GUI}
    {$IFDEF CLI}
    RunExternal: boolean;
    {$ENDIF}
  {$ENDIF}
  ErrorMsg: string;
  {$IFDEF SETUP}
  InstallDir: string;
  DesktopShortcut, StartMenuShortcut, RestartYTD: boolean;
  {$ENDIF}

function FindStartupType( {$IFDEF SETUP} var InstallDir: string; var DesktopShortcut, StartMenuShortcut, RestartYTD: boolean {$ENDIF} ): TStartupType;
{$IFDEF SETUP}
var
  i: integer;
  Param: string;
  {$IFDEF SETUP_GUI}
  F: TFormSetup;
  {$ENDIF}
{$ENDIF}
begin
  Result := Low(TStartupType);
  // No parameters runs GUI if available, otherwise CLI
  {$IFDEF GUI}
  if ParamCount = 0 then
    Result := stGUI
  else
  {$ENDIF}
  // Otherwise check for startup-type parameters
  {$IFDEF SETUP}
  for i := 1 to ParamCount do
    begin
    Param := ParamStr(i);
    if False then
      begin
      end
    {$IFDEF GUI}
    else if Param = SETUP_PARAM_GUI then
      begin
      Result := stGUIexplicit;
      Break;
      end
    {$ENDIF}
    {$IFDEF SETUP_GUI}
    else if Param = SETUP_PARAM_SETUP then
      begin
      {$IFNDEF DEBUG}
        {$IFNDEF FPC}
          FreeConsole;
          IsConsole := False;
        {$ENDIF}
      {$ENDIF}
      F := TFormSetup.Create(nil);
      try
        case F.ShowModal of
          idOK:
            begin
            Result := stInstall;
            InstallDir := F.DestinationDir;
            DesktopShortcut := F.DesktopShortcut;
            StartMenuShortcut := F.StartMenuShortcut;
            RestartYTD := True;
            end;
          idIgnore:
            Result := {$IFDEF GUI} stGUI {$ELSE} {$IFDEF CLI} stCli {$ELSE} stNone {$ENDIF} {$ENDIF} ;
          else
            Result := stNone;
          end;
      finally
        FreeAndNil(F);
        end;
      Break;
      end
    {$ENDIF}
    else if (Param = SETUP_PARAM_UPGRADE) or (Param = SETUP_PARAM_UPGRADE_GUI) or (Param = SETUP_PARAM_INSTALL) or (Param = SETUP_PARAM_INSTALL_GUI) then
      begin
      if i < ParamCount then
        begin
        Result := stInstall;
        InstallDir := ParamStr(Succ(i));
        DesktopShortcut := (Param = SETUP_PARAM_INSTALL) or (Param = SETUP_PARAM_INSTALL_GUI);
        StartMenuShortcut := (Param = SETUP_PARAM_INSTALL) or (Param = SETUP_PARAM_INSTALL_GUI);
        RestartYTD := (Param = SETUP_PARAM_UPGRADE_GUI) or (Param = SETUP_PARAM_INSTALL_GUI);
        Sleep(500); // to give some time for the caller to quit
        Break;
        end;
      end;
    end;
  {$ENDIF}
end;

{$IFDEF CLI}
procedure RunCLI;
begin
  ExitCode := ExecuteConsoleApp(TYTD);
  if StartedFromIDE then
    begin
    Writeln;
    Write(MSG_PRESS_ANY_KEY_TO_QUIT);
    Readln;
    end;
end;
{$ENDIF}

{$IFDEF GUI}
procedure RunGUI;
begin
  {$IFNDEF DEBUG}
    {$IFNDEF FPC}
      FreeConsole;
      IsConsole := False;
    {$ENDIF}
  {$ENDIF}
  {$IFDEF GUI_WINAPI}
    with TFormMain.Create do
      try
        ShowModal;
      finally
        Free;
        end;
  {$ELSE}
    Application.Initialize;
    Application.Title := 'YTD';
    Application.CreateForm(TFormYTD, FormYTD);
    Application.Run;
  {$ENDIF}
end;
{$ENDIF}

{$IFDEF SETUP}
procedure RunInstall(const InstallDir: string; DesktopShortcut, StartMenuShortcut, RestartYTD: boolean);

  function CopyFiles(const SourceDir, DestinationDir: string): boolean;
    var SR: TSearchRec;
    begin
      Result := True;
      ForceDirectories(ExpandFileName(DestinationDir));
      if FindFirst(SourceDir + '*.*', faAnyFile, SR) = 0 then
        try
          repeat
            if Longbool(SR.Attr and faDirectory) then
              begin
              if (SR.Name <> '.') and (SR.Name <> '..') then
                if not CopyFiles(SourceDir + SR.Name + '\', DestinationDir + SR.Name + '\') then
                  Result := False;
              end
            else
              begin
              if not CopyFile(PChar(SourceDir + SR.Name), PChar(DestinationDir + SR.Name), False) then
                Result := False;
              end;
          until FindNext(SR) <> 0;
        finally
          SysUtils.FindClose(SR);
          end;
    end;

var OK: boolean;
    InstDir, InstExe: string;
begin
  OK := False;
  InstDir := IncludeTrailingPathDelimiter(InstallDir);
  InstExe := InstDir + ExtractFileName(ParamStr(0));
  if InstallDir <> '' then
    begin
    OK := CopyFiles(ExtractFilePath(ParamStr(0)), InstDir);
    if OK then
      begin
      if DesktopShortcut then
        CreateShortcut(APPLICATION_SHORTCUT, '', CSIDL_DESKTOPDIRECTORY, InstExe);
      if StartMenuShortcut then
        CreateShortcut(APPLICATION_SHORTCUT, '', CSIDL_PROGRAMS, InstExe);
      end;
    end;
  if not OK then
    begin
    {$IFDEF FPC}
      Writeln(ERR_INSTALL_FAILED);
    {$ELSE}
      {$IFDEF CLI}
      if TConsoleApp.HasConsole = csOwnConsole then
        Writeln(ERR_INSTALL_FAILED)
      else
      {$ENDIF}
        MessageBox(0, PChar(ERR_INSTALL_FAILED), PChar(APPLICATION_TITLE), MB_OK or MB_ICONERROR or MB_TASKMODAL);
    {$ENDIF}
    ExitCode := 253;
    end
  else
    begin
    ExitCode := 0;
    if RestartYTD then
      Run(InstExe, '', ExcludeTrailingPathDelimiter(InstDir));
    end;
end;
{$ENDIF}

procedure Main;
begin
  try
    ExitCode := 0;
    InitCommonControls; // Needed because of the manifest file
    // Test for IDE
    StartedFromIDE := False;
    {$IFNDEF FPC}
      {$IFDEF DELPHI7_UP}
        {$WARN SYMBOL_PLATFORM OFF}
      {$ENDIF}
      if DebugHook <> 0 then
        StartedFromIDE := True;
      {$IFDEF DELPHI7_UP}
        {$WARN SYMBOL_PLATFORM ON}
      {$ENDIF}
    {$ENDIF}
    // Determine the startup type and parameters
    {$IFDEF SETUP}
    InstallDir := '';
    DesktopShortcut := False;
    StartMenuShortcut := False;
    RestartYTD := False;
    {$ENDIF}
    case FindStartupType( {$IFDEF SETUP} InstallDir, DesktopShortcut, StartMenuShortcut, RestartYTD {$ENDIF} ) of
      {$IFDEF CLI}
      stCLI:
        RunCLI;
      {$ENDIF}
      {$IFDEF GUI}
      stGUIexplicit:
        RunGUI;
      stGUI:
        begin
        {$IFDEF CLI}
          RunExternal := (not StartedFromIDE);
          {$IFNDEF FPC}
            if RunExternal then
              begin
              FreeConsole;
              if not TConsoleApp.ParentHasConsole then
                RunExternal := False;
              end;
          {$ENDIF}
          if (not RunExternal) or (not Run(ParamStr(0), {$IFDEF SETUP} SETUP_PARAM_GUI {$ELSE} '' {$ENDIF} )) then
        {$ENDIF}
          RunGUI;
        end;
      {$ENDIF}
      {$IFDEF SETUP}
      stInstall:
        RunInstall(InstallDir, DesktopShortcut, StartMenuShortcut, RestartYTD);
      {$ENDIF}
      end;
  except
    on E: Exception do
      begin
      ErrorMsg := Format(ERR_EXCEPTION_MESSAGE, [E.ClassName, E.Message]);
      {$IFDEF FPC}
        Writeln(ErrorMsg);
      {$ELSE}
        {$IFDEF CLI}
        if TConsoleApp.HasConsole = csOwnConsole then
          Writeln(ErrorMsg)
        else
        {$ENDIF}
          MessageBox(0, PChar(ErrorMsg), PChar(APPLICATION_TITLE), MB_OK or MB_ICONERROR or MB_TASKMODAL);
      {$ENDIF}
      ExitCode := 255;
      end;
    end;
end;

end.