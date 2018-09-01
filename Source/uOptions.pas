unit uOptions;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils,
  {$IFDEF INIFILE} IniFiles, {$ENDIF}
  Classes, HttpSend;

type
  TOverwriteMode = (omNever, omAlways, omRename, omAsk);

  TYTDOptions = class
    private
      fOverwriteMode: TOverwriteMode;
      fDestinationPath: string;
      fErrorLog: string;
      fDontUseRegistry: boolean;
      fSections: TStringList;
    protected
      function IniFileName(out FileName: string): boolean; overload; virtual;
      function IniFileName: string; overload; virtual;
      procedure ReadFromIniFile; virtual;
      property Sections: TStringList read fSections;
    public
      constructor Create; virtual;
      destructor Destroy; override;
      procedure Init; virtual;
      procedure Save; virtual;
      function ReadProviderOption(const Provider, Option: string; out Value: string): boolean; virtual;
      function GetNewestVersion(out Version, Url: string): boolean; virtual;
      property OverwriteMode: TOverwriteMode read fOverwriteMode write fOverwriteMode;
      property DestinationPath: string read fDestinationPath write fDestinationPath;
      property ErrorLog: string read fErrorLog write fErrorLog;
      property DontUseRegistry: boolean read fDontUseRegistry write fDontUseRegistry;
    end;

implementation

const
  OverwriteModeStrings: array[TOverwriteMode] of string
    = ('never', 'always', 'rename', 'ask');

{ TYTDOptions }

constructor TYTDOptions.Create;
begin
  inherited Create;
  fSections := TStringList.Create;
  Init;
end;

destructor TYTDOptions.Destroy;
var i: integer;
begin
  for i := 0 to Pred(Sections.Count) do
    TStringList(Sections.Objects[i]).Free;
  FreeAndNil(fSections);
  inherited;
end;

procedure TYTDOptions.Init;
begin
  fOverwriteMode := omAsk;
  fDestinationPath := '';
  fErrorLog := '';
  fDontUseRegistry := True;
  {$IFDEF INIFILE}
  ReadFromIniFile;
  {$ENDIF}
end;

function TYTDOptions.IniFileName(out FileName: string): boolean;
begin
  {$IFDEF INIFILE}
  FileName := ChangeFileExt(ParamStr(0), '.ini');
  Result := FileExists(FileName);
  {$ELSE}
  FileName := '';
  Result := False;
  {$ENDIF}
end;

function TYTDOptions.IniFileName: string;
begin
  if not IniFileName(Result) then
    Result := '';
end;

procedure TYTDOptions.ReadFromIniFile;
{$IFDEF INIFILE}
var FileName, s: string;
    OM: TOverwriteMode;
    i: integer;
    L: TStringList;
{$ENDIF}
begin
  {$IFDEF INIFILE}
  try
    if IniFileName(FileName) then
      with TIniFile.Create(FileName) do
        try
          ReadSections(Sections);
          for i := 0 to Pred(Sections.Count) do
            begin
            L := TStringList.Create;
            Sections.Objects[i] := L;
            ReadSectionValues(Sections[i], L);
            end;
          s := ReadString('YTD', 'OverwriteMode', '');
          if s <> '' then
            for OM := Low(TOverwriteMode) to High(TOverwriteMode) do
              if AnsiCompareText(s, OverwriteModeStrings[OM]) = 0 then
                begin
                fOverwriteMode := OM;
                Break;
                end;
          fDestinationPath := ReadString('YTD', 'DestinationPath', DestinationPath);
          fErrorLog := ReadString('YTD', 'ErrorLog', ErrorLog);
          fDontUseRegistry := ReadBool('YTD', 'DontUseRegistry', DontUseRegistry);
        finally
         Free;
         end;
  except
    on Exception do
      ;
    end;
  {$ENDIF}
end;

procedure TYTDOptions.Save;
{$IFDEF INIFILE}
var FileName: string;
{$ENDIF}
begin
  {$IFDEF INIFILE}
  IniFileName(FileName);
  if FileName <> '' then
    with TIniFile.Create(FileName) do
      try
        WriteString('YTD', 'OverwriteMode', OverwriteModeStrings[OverwriteMode]);
        WriteString('YTD', 'DestinationPath', DestinationPath);
        WriteString('YTD', 'ErrorLog', ErrorLog);
      finally
        Free;
        end;
  {$ENDIF}
end;

function TYTDOptions.ReadProviderOption(const Provider, Option: string; out Value: string): boolean;
var i: integer;
    Section: TStringList;
begin
  Result := False;
  for i :=  0 to Pred(Sections.Count) do
    if AnsiCompareText(Sections[i], Provider) = 0 then
      begin
      Section := TStringList(Sections.Objects[i]);
      if Section <> nil then
        if Section.IndexOfName(Option) >= 0 then
          begin
          Value := Section.Values[Option];
          Result := True;
          Break;
          end;
      end;
end;

function TYTDOptions.GetNewestVersion(out Version, Url: string): boolean;

  function FindHeader(Http: THttpSend; Header: string; out Value: string): boolean;
    var i: integer;
        HdrLen: integer;
    begin
      Result := False;
      Header := Trim(Header) + ':';
      HdrLen := Length(Header);
      for i := 0 to Pred(Http.Headers.Count) do
        if AnsiCompareText(Copy(Http.Headers[i], 1, HdrLen), Header) = 0 then
          begin
          Value := Trim(Copy(Http.Headers[i], Succ(HdrLen), MaxInt));
          Result := True;
          Break;
          end;
    end;

var Http: THttpSend;
    Ver: string;
    n: integer;
begin
  Result := False;
  Version := '';
  Url := 'http://ytd.pepak.net' {$IFNDEF XXX} + '/?lite=1' {$ENDIF};
  Http := THttpSend.Create;
  try
    if Http.HttpMethod('HEAD', Url) then
      if (Http.ResultCode >= 200) and (Http.ResultCode < 400) then
        if FindHeader(Http, 'X-YTD-Version', Version) then
          Result := True
        else if FindHeader(Http, 'Location', Url) then
          begin
          Ver := ChangeFileExt(Url, '');
          n := Length(Ver);
          if n >= 4 then
            if (Ver[n-3] in ['0'..'9']) and (Ver[n-2] = '.') and (Ver[n-1] in ['0'..'9']) and (Ver[n] in ['0'..'9']) then
              begin
              Version := Copy(Ver, n-3, 4);
              Result := True;
              end;
          end;
  finally
    Http.Free;
    end;
end;

end.