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

unit uScriptedDownloader;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils, Classes, Windows,
  uPCRE, uXML, HttpSend, blcksock,
  uDownloader, uOptions, uScripts;

type
  TScriptedDownloader = class(TDownloader)
    private
      fScriptEngine: TScriptEngine;
      fScriptNode: TXmlNode;
      fDownloaderList: TList;
      fCurrentDownloadIndex: integer;
      fDebugFileName: string;
      fRelativeUrl: string;
    private
      function GetDownloaderCount: integer;
      function GetDownloader(Index: integer): TDownloader;
    protected
      function GetContentUrl: string; override;
      function GetFileName: string; override;
      function GetFileNameExt: string; override;
      procedure Clear;
      procedure AddDownloader(Downloader: TDownloader);
      property ScriptEngine: TScriptEngine read fScriptEngine;
      property ScriptNode: TXmlNode read fScriptNode;
      property DownloaderCount: integer read GetDownloaderCount;
      property Downloaders[Index: integer]: TDownloader read GetDownloader; default;
      property CurrentDownloadIndex: integer read fCurrentDownloadIndex;
      property DebugFileName: string read fDebugFileName write fDebugFileName;
      property RelativeUrl: string read fRelativeUrl write fRelativeUrl;
    protected
      class function ExtractWord(var Source: string; const Separator: string; out TheWord: string): boolean;
      function GetNodeContent(Node: TXmlNode; const Path, AttrName, AttrValue: string; Vars: TScriptVariables; out Content: string): boolean; overload;
      function GetNodeContent(Node: TXmlNode; const Path: string; Vars: TScriptVariables; out Content: string): boolean; overload;
      function GetNodeContent(Node: TXmlNode; const Path: string; Vars: TScriptVariables): string; overload;
      function GetNodeContent(Node: TXmlNode; const Path, AttrName, AttrValue: string; Vars: TScriptVariables): string; overload;
      procedure ProcessScript(Node: TXmlNode; Vars: TScriptVariables);
      procedure ProcessDebug(Node: TXmlNode; Vars: TScriptVariables);
      procedure ProcessSetVar(Node: TXmlNode; Vars: TScriptVariables);
      procedure ProcessBestVar(Node: TXmlNode; Vars: TScriptVariables);
      procedure ProcessMultiRegExp(Node: TXmlNode; Vars: TScriptVariables);
      procedure ProcessCommonDownload(Node: TXmlNode; Vars: TScriptVariables; out Url, Title, FileNameExt: string);
      procedure ProcessHttpDownload(Node: TXmlNode; Vars: TScriptVariables);
      procedure ProcessRtmpDownload(Node: TXmlNode; Vars: TScriptVariables);
      procedure ProcessNestedDownload(Node: TXmlNode; Vars: TScriptVariables);
      procedure ProcessHDSDownload(Node: TXmlNode; Vars: TScriptVariables);
      procedure ProcessHLSDownload(Node: TXmlNode; Vars: TScriptVariables);
      function ProcessNodeContent(Node: TXmlNode; Vars: TScriptVariables): string;
      function ProcessGetVar(Node: TXmlNode; Vars: TScriptVariables): string;
      function ProcessGetXmlVar(Node: TXmlNode; Vars: TScriptVariables): string;
      function ProcessDownloadPage(Node: TXmlNode; Vars: TScriptVariables): string;
      function ProcessRegExp(Node: TXmlNode; Vars: TScriptVariables): string;
      function ProcessCopy(Node: TXmlNode; Vars: TScriptVariables): string;
      function ProcessDecodeHtml(Node: TXmlNode; Vars: TScriptVariables): string;
      function ProcessDecodeUrl(Node: TXmlNode; Vars: TScriptVariables): string;
      function ProcessDecodeJS(Node: TXmlNode; Vars: TScriptVariables): string;
      function ProcessDecodeBase64(Node: TXmlNode; Vars: TScriptVariables): string;
      function ProcessStripTags(Node: TXmlNode; Vars: TScriptVariables): string;
      function ProcessTimestamp(Node: TXmlNode; Vars: TScriptVariables): string;
      function CreateRegExpFromNode(Node: TXmlNode; Vars: TScriptVariables; out RegExpNode: TXmlNode): TRegExp;
    public
      class function MainScriptEngine: TScriptEngine;
      class procedure InitMainScriptEngine(const FileName: string);
      class function IsSupportedUrl(const AUrl: string; out AMovieID: string): boolean; override;
      class function Provider: string; override;
      class function UrlRegExp: string; override;
      constructor Create(const AScriptID, AMovieID: string; AScriptEngine: TScriptEngine = nil); reintroduce; overload;
      constructor Create(const AMovieID: string); overload; override;
      destructor Destroy; override;
      function Prepare: boolean; override;
      function Download: boolean; override;
      {$IFDEF MULTIDOWNLOADS}
      function First: boolean; override;
      function Next: boolean; override;
      {$ENDIF}
    end;

implementation

uses
  uCompatibility,
  uMessages,
  uLanguages,
  uStrings,
  uStringConsts,
  uFunctions,
  uDownloadClassifier,
  uHttpDirectDownloader,
  uRtmpDirectDownloader,
  uNestedDirectDownloader,
  uHDSDirectDownloader,
  uHLSDirectDownloader,
  NativeXml;

const
  SCRIPTVAR_MOVIE_ID = '_movie_id';
  SCRIPTVAR_LAST_URL = '_http_last_url';
  SCRIPTVAR_LAST_COOKIES = '_http_last_cookies';

var
  fMainScriptEngine: TScriptEngine = nil;

{ TScriptedDownloader }

class function TScriptedDownloader.MainScriptEngine: TScriptEngine;
begin
  Result := fMainScriptEngine;
end;

class procedure TScriptedDownloader.InitMainScriptEngine(const FileName: string);
begin
  FreeAndNil(fMainScriptEngine);
  fMainScriptEngine := TScriptEngine.Create;
  fMainScriptEngine.LoadFromFile(FileName);
end;

class function TScriptedDownloader.Provider: string;
begin
  Result := 'YTD Script';
end;

class function TScriptedDownloader.UrlRegExp: string;
begin
  Raise EScriptedDownloaderError.Create(_('TScriptedDownloader.UrlRegExp may not be called.'));
end;

class function TScriptedDownloader.IsSupportedUrl(const AUrl: string; out AMovieID: string): boolean;
var
  ScriptNode: TXmlNode;
begin
  Result := False;
  if MainScriptEngine <> nil then
    if MainScriptEngine.GetScriptForUrl(AUrl, ScriptNode, AMovieID) then
      begin
      AMovieID := XmlAttribute(ScriptNode, 'id') + #0 + AMovieID;
      Result := True;
      end;
end;

constructor TScriptedDownloader.Create(const AScriptID, AMovieID: string; AScriptEngine: TScriptEngine = nil);
begin
  if AScriptEngine = nil then
    fScriptEngine := MainScriptEngine
  else
    fScriptEngine := AScriptEngine;
  if not ScriptEngine.GetScript(AScriptID, fScriptNode) then
    Raise EScriptedDownloaderError.CreateFmt(ERR_SCRIPTS_SCRIPT_NOT_FOUND, [AScriptID]);
  inherited Create(AMovieID);
  fDownloaderList := TList.Create;
end;

constructor TScriptedDownloader.Create(const AMovieID: string);
var
  ix: integer;
begin
  ix := Pos(#0, AMovieID);
  if ix <= 1 then
    Raise EScriptedDownloaderError.Create(_('Invalid MovieID - must define script and ID'));
  Create(Copy(AMovieID, 1, Pred(ix)), Copy(AMovieID, Succ(ix), MaxInt));
end;

destructor TScriptedDownloader.Destroy;
begin
  Clear;
  FreeAndNil(fDownloaderList);
  inherited;
end;

procedure TScriptedDownloader.Clear;
var
  i: integer;
begin
  for i := 0 to Pred(DownloaderCount) do
    Downloaders[i].Free;
  fDownloaderList.Clear;
  DebugFileName := '';
  RelativeUrl := '';
  First;
end;

function TScriptedDownloader.GetDownloaderCount: integer;
begin
  Result := fDownloaderList.Count;
end;

function TScriptedDownloader.GetDownloader(Index: integer): TDownloader;
begin
  Result := TDownloader(fDownloaderList[Index]);
end;

procedure TScriptedDownloader.AddDownloader(Downloader: TDownloader);
begin
  Downloader.Options := Self.Options;
  Downloader.OnProgress := Self.OnProgress;
  Downloader.OnFileNameValidate := Self.OnFileNameValidate;
  fDownloaderList.Add(Downloader);
end;

function TScriptedDownloader.Prepare: boolean;
var
  i: integer;
  Vars: TScriptVariables;
begin
  Result := False;
  SetPrepared(False);
  SetLastErrorMsg('');
  Clear;
  Vars := TScriptVariables.Create;
  try
    Vars[SCRIPTVAR_MOVIE_ID] := MovieID;
    Vars[SCRIPTVAR_LAST_URL] := '';
    Vars[SCRIPTVAR_LAST_COOKIES] := '';
    ProcessScript(ScriptNode, Vars);
  finally
    FreeAndNil(Vars);
    end;
  if DownloaderCount <= 0 then
    SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_INFO)
  else
    begin
    {$IFDEF MULTIDOWNLOADS}
    Result := True;
    for i := 0 to Pred(DownloaderCount) do
      Result := Result and Downloaders[i].Prepare;
    {$ELSE}
    Result := Downloaders[0].Prepare;
    {$ENDIF}
    SetPrepared(Result);
    end;
end;

function TScriptedDownloader.Download: boolean;
begin
  inherited Download;
  Result := False;
  if (fCurrentDownloadIndex >= 0) and (fCurrentDownloadIndex < DownloaderCount) then
    Result := Downloaders[fCurrentDownloadIndex].Download;
end;

{$IFDEF MULTIDOWNLOADS}
function TScriptedDownloader.First: boolean;
begin
  if ValidatePrepare then
    begin
    fCurrentDownloadIndex := -1;
    Result := Next;
    end
  else
    Result := False;
end;

function TScriptedDownloader.Next: boolean;
begin
  Result := False;
  if ValidatePrepare then
    begin
    fCurrentDownloadIndex := Succ(fCurrentDownloadIndex);
    if (fCurrentDownloadIndex >= 0) and (fCurrentDownloadIndex < DownloaderCount) then
      begin
      SetName(Downloaders[fCurrentDownloadIndex].Name);
      SetFileName('');
      Result := True;
      end;
    end;
end;
{$ENDIF}

function TScriptedDownloader.GetContentUrl: string;
begin
  if (fCurrentDownloadIndex >= 0) and (fCurrentDownloadIndex < DownloaderCount) then
    Result := Downloaders[fCurrentDownloadIndex].ContentUrl
  else
    Result := inherited ContentUrl;
end;

function TScriptedDownloader.GetFileName: string;
begin
  if (fCurrentDownloadIndex >= 0) and (fCurrentDownloadIndex < DownloaderCount) then
    Result := Downloaders[fCurrentDownloadIndex].FileName
  else
    Result := inherited FileName;
end;

function TScriptedDownloader.GetFileNameExt: string;
begin
  if (fCurrentDownloadIndex >= 0) and (fCurrentDownloadIndex < DownloaderCount) then
    Result := Downloaders[fCurrentDownloadIndex].FileNameExt
  else
    Result := inherited FileNameExt;
end;

class function TScriptedDownloader.ExtractWord(var Source: string; const Separator: string; out TheWord: string): boolean;
var
  ix: integer;
begin
  if Source = '' then
    Result := False
  else
    begin
    ix := Pos(Separator, Source);
    if ix <= 0 then
      begin
      TheWord := Source;
      Source := '';
      end
    else
      begin
      TheWord := Copy(Source, 1, Pred(ix));
      System.Delete(Source, 1, ix + Length(Separator) - 1);
      end;
    Result := True;
    end;
end;

procedure TScriptedDownloader.ProcessScript(Node: TXmlNode; Vars: TScriptVariables);
var
  i: integer;
  ChildNode: TXmlNode;
begin
  for i := 0 to Pred(Node.NodeCount) do
    begin
    ChildNode := Node.Nodes[i];
    if ChildNode.ElementType = xeNormal then
      if ChildNode.Name = 'regexps' then
        // do nothing
      else if ChildNode.Name = 'debug' then
        ProcessDebug(ChildNode, Vars)
      else if ChildNode.Name = 'set_var' then
        ProcessSetVar(ChildNode, Vars)
      else if ChildNode.Name = 'best_var' then
        ProcessBestVar(ChildNode, Vars)
      else if ChildNode.Name = 'http_download' then
        ProcessHttpDownload(ChildNode, Vars)
      else if ChildNode.Name = 'rtmp_download' then
        ProcessRtmpDownload(ChildNode, Vars)
      else if ChildNode.Name = 'hds_download' then
        ProcessHDSDownload(ChildNode, Vars)
      else if ChildNode.Name = 'hls_download' then
        ProcessHLSDownload(ChildNode, Vars)
      else if ChildNode.Name = 'nested_download' then
        ProcessNestedDownload(ChildNode, Vars)
      else if ChildNode.Name = 'multi_regexp' then
        ProcessMultiRegExp(ChildNode, Vars)
      else
        ScriptError(MSG_SCRIPTS_UNKNOWN_COMMAND, ChildNode);
    end;
end;

procedure TScriptedDownloader.ProcessCommonDownload(Node: TXmlNode; Vars: TScriptVariables; out Url, Title, FileNameExt: string);
begin
  if not GetNodeContent(Node, 'url', Vars, Url) then
    ScriptError(ERR_SCRIPTS_URL_NOT_FOUND, Node);
  if Url = '' then
    begin
    SetLastErrorMsg(ERR_FAILED_TO_LOCATE_MEDIA_URL);
    Exit;
    end;
  Url := GetRelativeUrl(RelativeUrl, Url);
  Title := GetNodeContent(Node, 'title', Vars);
  FileNameExt := GetNodeContent(Node, 'extension', Vars);
end;

procedure TScriptedDownloader.ProcessHttpDownload(Node: TXmlNode; Vars: TScriptVariables);
var
  Downloader: THttpDirectDownloader;
  Url, Title, Ext: string;
begin
  ProcessCommonDownload(Node, Vars, Url, Title, Ext);
  Downloader := THttpDirectDownloader.CreateWithName(Url, Title);
  try
    Downloader.SetFileNameExt(Ext);
    AddDownloader(Downloader);
  except
    FreeAndNil(Downloader);
    Raise;
    end;
end;

procedure TScriptedDownloader.ProcessRtmpDownload(Node: TXmlNode; Vars: TScriptVariables);
var
  Downloader: TRtmpDirectDownloader;
  Url, Title, Ext, s: string;
begin
  ProcessCommonDownload(Node, Vars, Url, Title, Ext);
  Downloader := TRtmpDirectDownloader.CreateWithName(Url, Title);
  try
    Downloader.SetFileNameExt(Ext);
    if not GetNodeContent(Node, 'rtmp_url', Vars, s) then
      Downloader.RtmpUrl := Url
    else
      Downloader.RtmpUrl := s;
    if GetNodeContent(Node, 'rtmp_app', Vars, s) then
      Downloader.RtmpApp := s;
    if GetNodeContent(Node, 'playpath', Vars, s) then
      Downloader.Playpath := s;
    if GetNodeContent(Node, 'swf_url', Vars, s) then
      Downloader.SwfUrl := s;
    if GetNodeContent(Node, 'tc_url', Vars, s) then
      Downloader.TcUrl := s;
    if GetNodeContent(Node, 'page_url', Vars, s) then
      Downloader.PageUrl := s;
    if GetNodeContent(Node, 'swf_vfy', Vars, s) then
      Downloader.SwfVfy := s;
    if GetNodeContent(Node, 'flashver', Vars, s) then
      Downloader.FlashVer := s
    else
      Downloader.FlashVer := FLASH_DEFAULT_VERSION;
    //if GetNodeContent(Node, 'secure_token', Vars, s) then
    //  Downloader.SecureToken := Self.Token;
    if GetNodeContent(Node, 'live', Vars, s) then
      Downloader.Live := StrToIntDef(s, 0) <> 0;
    if GetNodeContent(Node, 'realtime', Vars, s) then
      Downloader.Realtime := StrToIntDef(s, 0) <> 0;
    Downloader.SaveRtmpDumpOptions;
    AddDownloader(Downloader);
  except
    FreeAndNil(Downloader);
    Raise;
    end;
end;

procedure TScriptedDownloader.ProcessNestedDownload(Node: TXmlNode; Vars: TScriptVariables);
var
  Downloader: TNestedDirectDownloader;
  Url, Title, Ext: string;
begin
  ProcessCommonDownload(Node, Vars, Url, Title, Ext);
  Downloader := TNestedDirectDownloader.CreateWithName(Url, Title);
  try
    Downloader.SetFileNameExt(Ext);
    AddDownloader(Downloader);
  except
    FreeAndNil(Downloader);
    Raise;
    end;
end;

procedure TScriptedDownloader.ProcessHDSDownload(Node: TXmlNode; Vars: TScriptVariables);
var
  Downloader: THDSDirectDownloader;
  Url, Title, Ext: string;
begin
  ProcessCommonDownload(Node, Vars, Url, Title, Ext);
  Downloader := THDSDirectDownloader.CreateWithName(Url, Title);
  try
    Downloader.SetFileNameExt(Ext);
    AddDownloader(Downloader);
  except
    FreeAndNil(Downloader);
    Raise;
    end;
end;

procedure TScriptedDownloader.ProcessHLSDownload(Node: TXmlNode; Vars: TScriptVariables);
var
  Downloader: THLSDirectDownloader;
  Url, Title, Ext: string;
begin
  ProcessCommonDownload(Node, Vars, Url, Title, Ext);
  Downloader := THLSDirectDownloader.CreateWithName(Url, Title);
  try
    Downloader.SetFileNameExt(Ext);
    AddDownloader(Downloader);
  except
    FreeAndNil(Downloader);
    Raise;
    end;
end;

procedure TScriptedDownloader.ProcessSetVar(Node: TXmlNode; Vars: TScriptVariables);
var
  VarName, VarValue: string;
begin
  VarName := XmlAttribute(Node, 'id');
  if VarName = '' then
    ScriptError(ERR_SCRIPTS_VARIABLE_NAME_MUST_BE_NONEMPTY, Node);
  VarValue := ProcessNodeContent(Node, Vars);
  Vars[VarName] := VarValue;
end;

procedure TScriptedDownloader.ProcessBestVar(Node: TXmlNode; Vars: TScriptVariables);

  function GetVarOrder(const Value, Order: string): integer;
    begin
      Result := Pos(Value, ',' + Order + ',');
      if Result <= 0 then
        Result := MaxInt;
    end;
const
  BEST_VAR_PREFIX = '__BEST_';
var
  VarName, BestVarName, VarValue, BestVarValue: string;
  SortType, Order: string;
  ResetVars, ResetVar: string;
  WasReset, BetterValue: boolean;
begin
  WasReset := False;
  if XmlAttribute(Node, 'reset', ResetVars) then
    while ExtractWord(ResetVars, ',', ResetVar) do
      if ResetVar <> '' then
        begin
        Vars[BEST_VAR_PREFIX + ResetVar] := '';
        WasReset := True;
        end;
  VarName := XmlAttribute(Node, 'id');
  if VarName = '' then
    if WasReset then
      Exit
    else
      ScriptError(ERR_SCRIPTS_VARIABLE_NAME_MUST_BE_NONEMPTY, Node);
  VarValue := Vars[VarName];
  BestVarName := BEST_VAR_PREFIX + VarName;
  if not Vars.Exists[BestVarName] then
    Vars[BestVarName] := '';
  BestVarValue := Vars[BestVarName];
  SortType := XmlAttribute(Node, 'type');
  BetterValue := False;
  if SortType = 'numeric_ascending' then
    BetterValue := StrToInt(VarValue) > StrToIntDef(BestVarValue, -MaxInt)
  else if SortType = 'numeric_descending' then
    BetterValue := StrToInt(VarValue) < StrToIntDef(BestVarValue, MaxInt)
  else if SortType = 'enumeration' then
    if not XmlAttribute(Node, 'order', Order) then
      ScriptError(Format(ERR_SCRIPTS_ATTRIBUTE_MUST_BE_NONEMPTY, ['order']), Node)
    else
      BetterValue := GetVarOrder(VarValue, Order) < GetVarOrder(BestVarValue, Order)
  else
    ScriptError(Format(ERR_SCRIPTS_INVALID_ATTRIBUTE_VALUE, ['type', SortType]), Node);
  if BetterValue then
    begin
    Vars[BestVarName] := VarValue;
    ProcessScript(Node, Vars);
    end;
end;

function TScriptedDownloader.GetNodeContent(Node: TXmlNode; const Path: string; Vars: TScriptVariables; out Content: string): boolean;
begin
  Result := GetNodeContent(Node, Path, '', '', Vars, Content);
end;

function TScriptedDownloader.GetNodeContent(Node: TXmlNode; const Path, AttrName, AttrValue: string; Vars: TScriptVariables; out Content: string): boolean;
var
  ContentNode: TXmlNode;
begin
  if not XmlNodeByPathAndAttr(Node, Path, AttrName, AttrValue, ContentNode) then
    Result := False
  else
    begin
    Content := ProcessNodeContent(ContentNode, Vars);
    Result := True;
    end;
end;

function TScriptedDownloader.GetNodeContent(Node: TXmlNode; const Path: string; Vars: TScriptVariables): string;
begin
  if not GetNodeContent(Node, Path, Vars, Result) then
    Result := '';
end;

function TScriptedDownloader.GetNodeContent(Node: TXmlNode; const Path, AttrName, AttrValue: string; Vars: TScriptVariables): string;
begin
  if not GetNodeContent(Node, Path, AttrName, AttrValue, Vars, Result) then
    Result := '';
end;

function TScriptedDownloader.ProcessNodeContent(Node: TXmlNode; Vars: TScriptVariables): string;
var
  ChildNode: TXmlNode;
  i: integer;
begin
  case Node.ElementType of
    xeCData:
      Result := {$IFDEF UNICODE} string {$ENDIF} (Node.ValueAsUnicodeString);
    xeCharData:
      Result := {$IFDEF UNICODE} string {$ENDIF} (Node.ValueAsUnicodeString);
    xeComment:
      Result := '';
    xeNormal:
      begin
      Result := {$IFDEF UNICODE} string {$ENDIF} (Node.ValueAsUnicodeString);
      for i := 0 to Pred(Node.NodeCount) do
        begin
        ChildNode := Node.Nodes[i];
        if ChildNode.ElementType = xeNormal then
          if ChildNode.Name = 'get_var' then
            Result := Result + ProcessGetVar(ChildNode, Vars)
          else if ChildNode.Name = 'get_xml_var' then
            Result := Result + ProcessGetXmlVar(ChildNode, Vars)
          else if ChildNode.Name = 'download_page' then
            Result := Result + ProcessDownloadPage(ChildNode, Vars)
          else if ChildNode.Name = 'regexp' then
            Result := Result + ProcessRegExp(ChildNode, Vars)
          else if ChildNode.Name = 'copy' then
            Result := Result + ProcessCopy(ChildNode, Vars)
          else if ChildNode.Name = 'decode_html' then
            Result := Result + ProcessDecodeHtml(ChildNode, Vars)
          else if ChildNode.Name = 'decode_url' then
            Result := Result + ProcessDecodeUrl(ChildNode, Vars)
          else if ChildNode.Name = 'decode_js' then
            Result := Result + ProcessDecodeJS(ChildNode, Vars)
          else if ChildNode.Name = 'decode_base64' then
            Result := Result + ProcessDecodeBase64(ChildNode, Vars)
          else if ChildNode.Name = 'strip_tags' then
            Result := Result + ProcessStripTags(ChildNode, Vars)
          else if ChildNode.Name = 'timestamp' then
            Result := Result + ProcessTimestamp(ChildNode, Vars)
          else
            ScriptError(MSG_SCRIPTS_UNKNOWN_COMMAND, ChildNode)
        else
          Result := Result + ProcessNodeContent(ChildNode, Vars);
        end;
      end;
    else
      ScriptError(MSG_SCRIPTS_UNEXPECTED_NODE_TYPE, Node);
    end;
end;

function TScriptedDownloader.ProcessDownloadPage(Node: TXmlNode; Vars: TScriptVariables): string;
var
  Http: THttpSend;
  HeadersNode: TXmlNode;
  Url, PostData, MimeType, MethodStr, EncodingStr, XmlPath, XmlAttr: string;
  OK, WantXml: Boolean;
  ExtraHeaders: array of string;
  Method: THttpMethod;
  Encoding: TPageEncoding;
  i, n: integer;
begin
  // Default values
  Method := hmGET;
  Encoding := peUnknown;
  Url := '';
  PostData := '';
  MimeType := HTTP_FORM_URLENCODING;
  XmlPath := '';
  XmlAttr := '';
  WantXml := False;
  SetLength(ExtraHeaders, 0);
  // HTTP method
  MethodStr := XmlAttribute(Node, 'method');
  if MethodStr = 'get' then
    Method := hmGET
  else if MethodStr = 'post' then
    Method := hmPOST
  else if MethodStr = 'head' then
    Method := hmHEAD;
  // Page encoding
  EncodingStr := XmlAttribute(Node, 'encoding');
  if EncodingStr = 'utf8' then
    Encoding := peUTF8
  else if EncodingStr = 'utf16' then
    Encoding := peUTF16
  else if EncodingStr = 'ansi' then
    Encoding := peAnsi
  else if EncodingStr = 'xml' then
    begin
    Encoding := peXml;
    WantXml := True;
    end;
  // URL
  if not GetNodeContent(Node, 'url', Vars, Url) then
    ScriptError(ERR_SCRIPTS_URL_NOT_FOUND, Node);
  // POST Data
  if GetNodeContent(Node, 'post_data', Vars, PostData) then
    Method := hmPOST
  else
    PostData := '';
  // POST MIME type
  if GetNodeContent(Node, 'mime_type', Vars, MimeType) then
    Method := hmPOST
  else
    MimeType := '';
  // XML variable
  if GetNodeContent(Node, 'xml_path', Vars, XmlPath) then
    begin
    WantXml := True;
    Encoding := peXml;
    end
  else
    XmlPath := '';
  if GetNodeContent(Node, 'xml_attr', Vars, XmlAttr) then
    begin
    WantXml := True;
    Encoding := peXml;
    end
  else
    XmlAttr := '';
  // Extra headers
  if XmlNodeByPath(Node, 'headers', HeadersNode) then
    for i := 0 to Pred(HeadersNode.NodeCount) do
      if HeadersNode.Nodes[i].Name = 'header' then
        begin
        n := Length(ExtraHeaders);
        SetLength(ExtraHeaders, Succ(n));
        ExtraHeaders[n] := ProcessNodeContent(HeadersNode, Vars);
        end;
  // Actual download
  if RelativeUrl = '' then
    RelativeUrl := Url;
  Http := CreateHttp;
  try
    if WantXml then
      if Method = hmPOST then
        if XmlAttr = '' then
          OK := DownloadXmlVar(Http, Url, {$IFDEF UNICODE} AnsiString {$ENDIF} (PostData), MimeType, XmlPath, Result)
        else
          OK := DownloadXmlAttr(Http, Url, {$IFDEF UNICODE} AnsiString {$ENDIF} (PostData), MimeType, XmlPath, XmlAttr, Result)
      else
        if XmlAttr = '' then
          if XmlPath = '' then
            OK := DownloadPage(Http, Url, Result, Encoding, Method)
          else
            OK := DownloadXmlVar(Http, Url, XmlPath, Result, Method)
        else
          OK := DownloadXmlAttr(Http, Url, XmlPath, XmlAttr, Result, Method)
    else
      if Method = hmPOST then
        OK := DownloadPage(Http, Url, {$IFDEF UNICODE} AnsiString {$ENDIF} (PostData), MimeType, ExtraHeaders, Result, Encoding)
      else
        OK := DownloadPage(Http, Url, Result, Encoding, Method);
    if not OK then
     ScriptError(Format(MSG_SCRIPTS_DOWNLOAD_FAILED, [Url]), Node)
    else
      begin
      Vars[SCRIPTVAR_LAST_URL] := Self.LastURL;
      Vars[SCRIPTVAR_LAST_COOKIES] := Http.Cookies.Text;
      end;
  finally
    FreeAndNil(Http);
    end;
end;

function TScriptedDownloader.ProcessGetVar(Node: TXmlNode; Vars: TScriptVariables): string;
var
  VarName: string;
begin
  VarName := XmlAttribute(Node, 'id');
  if VarName = '' then
    ScriptError(ERR_SCRIPTS_VARIABLE_NAME_MUST_BE_NONEMPTY, Node)
  else
    Result := Vars[VarName];
end;

function TScriptedDownloader.ProcessGetXmlVar(Node: TXmlNode; Vars: TScriptVariables): string;
var
  VarName, ResultAttribute: string;
  DataNode: TXmlNode;
begin
  VarName := XmlAttribute(Node, 'id');
  if VarName = '' then
    ScriptError(ERR_SCRIPTS_VARIABLE_NAME_MUST_BE_NONEMPTY, Node)
  else if not XmlNodeByPathAndAttr(Vars.Xml[VarName], XmlAttribute(Node, 'path'), XmlAttribute(Node, 'attr'), XmlAttribute(Node, 'attr_value'), DataNode) then
    ScriptError(ERR_XML_ELEMENT_NOT_FOUND, Node)
  else
    begin
    ResultAttribute := XmlAttribute(Node, 'result_attr');
    if ResultAttribute = '' then
      Result := XmlValueIncludingCData(DataNode)
    else if not XmlAttribute(DataNode, ResultAttribute, Result) then
      ScriptError(ERR_XML_ELEMENT_NOT_FOUND, Node);
    end;
end;

function TScriptedDownloader.CreateRegExpFromNode(Node: TXmlNode; Vars: TScriptVariables; out RegExpNode: TXmlNode): TRegExp;
var
  Options: TRegExpOptions;
  OptionsStr, Pattern, PatternID: string;
  Plus: boolean;
  i: integer;
begin
  Result := nil;
  RegExpNode := Node;
  Options := REGEXP_DEFAULT_OPTIONS;
  if XmlAttribute(Node, 'options', OptionsStr) then
    begin
    Plus := True;
    for i := 1 to Length(OptionsStr) do
      case OptionsStr[i] of
        '-': Plus := False;
        '+': Plus := True;
        'i': if Plus then Options := Options + [rcoIgnoreCase] else Options := Options - [rcoIgnoreCase];
        'm': if Plus then Options := Options + [rcoMultiLine] else Options := Options - [rcoMultiLine];
        's': if Plus then Options := Options + [rcoSingleLine] else Options := Options - [rcoSingleLine];
        'x': if Plus then Options := Options + [rcoIgnorePatternWhitespace] else Options := Options - [rcoIgnorePatternWhitespace];
        'A': if Plus then Options := Options + [rcoAnchored] else Options := Options - [rcoAnchored];
        'U': if Plus then Options := Options + [rcoUngreedy] else Options := Options - [rcoUngreedy];
        'N': if Plus then Options := Options + [rcoNoAutoCapture] else Options := Options - [rcoNoAutoCapture];
        end;
    end;
  if not XmlAttribute(Node, 'id', PatternID) then
    ScriptError(ERR_SCRIPTS_PATTERN_ID_MUST_BE_NONEMPTY, Node)
  else if PatternID = '' then
    ScriptError(ERR_SCRIPTS_PATTERN_ID_MUST_BE_NONEMPTY, Node)
  else
    if XmlNodeByPathAndAttr(ScriptNode, 'regexps/regexp', 'id', PatternID, RegExpNode) then
      Pattern := ProcessNodeContent(RegExpNode, Vars)
    else if ScriptEngine.GetRegExp(PatternID, RegExpNode) then
      Pattern := ProcessNodeContent(RegExpNode, Vars)
    else
      ScriptError(Format(ERR_SCRIPTS_PATTERN_NOT_FOUND, [PatternID]), Node);
  if Pattern = '' then
    ScriptError(ERR_SCRIPTS_PATTERN_MUST_BE_NONEMPTY, Node)
  else
    Result := RegExCreate(Pattern, Options);
end;

function TScriptedDownloader.ProcessRegExp(Node: TXmlNode; Vars: TScriptVariables): string;
var
  RE: TRegExp;
  RegExpNode: TXmlNode;
  Text, VarName: string;
begin
  RE := CreateRegExpFromNode(Node, Vars, RegExpNode);
  try
    if XmlAttribute(Node, 'content', VarName) then
      Text := Vars[VarName]
    else
      Text := ProcessNodeContent(Node, Vars);
    if not XmlAttribute(Node, 'match', VarName) then
      if not XmlAttribute(RegExpNode, 'match', VarName) then
        ScriptError(ERR_SCRIPTS_SUBEXPRESSION_MUST_BE_NONEMPTY, Node);
    if not GetRegExpVar(RE, Text, VarName, Result) then
      ScriptError(ERR_SCRIPTS_FAILED_TO_MATCH_REGEXP, Node);
  finally
    RegExFreeAndNil(RE);
    end;
end;

procedure TScriptedDownloader.ProcessMultiRegExp(Node: TXmlNode; Vars: TScriptVariables);
var
  RE: TRegExp;
  RegExpNode: TXmlNode;
  i, n, Skip, Count: integer;
  Text, VarName, MatchesStr, MatchesStrCopy, Match, VarPrefix, SkipStr, CountStr: string;
  Matches: array of string;
begin
  RE := CreateRegExpFromNode(Node, Vars, RegExpNode);
  try
    if (not XmlAttribute(Node, 'content', VarName)) or (VarName = '') then
      ScriptError(Format(ERR_SCRIPTS_ATTRIBUTE_MUST_BE_NONEMPTY, ['content']), Node)
    else
      Text := Vars[VarName];
    if (not XmlAttribute(Node, 'var_prefix', VarPrefix)) or (VarPrefix = '') then
      ScriptError(Format(ERR_SCRIPTS_ATTRIBUTE_MUST_BE_NONEMPTY, ['var-prefix']), Node);
    if not XmlAttribute(Node, 'match', MatchesStr) then
      if not XmlAttribute(RegExpNode, 'match', MatchesStr) then
        ScriptError(ERR_SCRIPTS_SUBEXPRESSION_MUST_BE_NONEMPTY, Node);
    if MatchesStr = '' then
      ScriptError(ERR_SCRIPTS_SUBEXPRESSION_MUST_BE_NONEMPTY, Node);
    n := 0;
    MatchesStrCopy := MatchesStr;
    while ExtractWord(MatchesStrCopy, ',', Match) do
      Inc(n);
    SetLength(Matches, n);
    n := 0;
    while ExtractWord(MatchesStr, ',', Match) do
      begin
      Matches[n] := Match;
      Inc(n);
      end;
    SetLength(Matches, n);
    if XmlAttribute(Node, 'skip', SkipStr) then
      Skip := StrToIntDef(SkipStr, 0)
    else
      Skip := 0;
    if XmlAttribute(Node, 'count', CountStr) then
      Count := StrToIntDef(CountStr, MaxInt)
    else
      Count := MaxInt;
    if Count > 0 then
      if RE.Match(Text) then
        repeat
          if Skip > 0 then
            Dec(Skip)
          else
            begin
            for i := 0 to Pred(Length(Matches)) do
              Vars[VarPrefix + Matches[i]] := RE.SubexpressionByName(Matches[i]);
            ProcessScript(Node, Vars);
            Dec(Count);
            end;
        until (Count <= 0) or (not RE.MatchAgain)
      else
        ScriptError(ERR_SCRIPTS_FAILED_TO_MATCH_REGEXP, Node);
  finally
    RegExFreeAndNil(RE);
    end;
end;

function TScriptedDownloader.ProcessCopy(Node: TXmlNode; Vars: TScriptVariables): string;
var
  CopyStart, CopyLength, SourceLength: integer;
  CopyStartStr, CopyLengthStr, Source: string;
begin
  CopyStartStr := XmlAttribute(Node, 'start');
  CopyStart := StrToIntDef(CopyStartStr, 0);
  CopyLengthStr := XmlAttribute(Node, 'length');
  CopyLength := StrToIntDef(CopyLengthStr, MaxInt);
  Source := ProcessNodeContent(Node, Vars);
  SourceLength := Length(Source);
  if CopyStart < 0 then
    CopyStart := SourceLength - CopyStart;
  if CopyStart < 0 then
    CopyStart := 0;
  if CopyLength < 0 then
    CopyLength := SourceLength - CopyStart + CopyLength;
  if CopyLength <= 0 then
    Result := ''
  else if CopyLength > 0 then
    Result := Copy(Source, Succ(CopyStart), CopyLength);
end;

procedure TScriptedDownloader.ProcessDebug(Node: TXmlNode; Vars: TScriptVariables);
var
  Content: string;
  FirstDebug: boolean;
  T: TextFile;
begin
  Content := ProcessNodeContent(Node, Vars);
  if DebugFileName = '' then
    begin
    FirstDebug := True;
    DebugFileName := ExtractFilePath(ParamStr(0)) + 'ytd-debug.log';
    end
  else
    FirstDebug := False;
  AssignFile(T, DebugFileName);
  if (not FirstDebug) and FileExists(DebugFileName) then
    Append(T)
  else
    Rewrite(T);
  try
    Writeln(T, Content);
  finally
    CloseFile(T);
    end;
end;

function TScriptedDownloader.ProcessDecodeHtml(Node: TXmlNode; Vars: TScriptVariables): string;
begin
  Result := HtmlDecode(ProcessNodeContent(Node, Vars));
end;

function TScriptedDownloader.ProcessDecodeUrl(Node: TXmlNode; Vars: TScriptVariables): string;
begin
  Result := UrlDecode(ProcessNodeContent(Node, Vars));
end;

function TScriptedDownloader.ProcessDecodeJS(Node: TXmlNode; Vars: TScriptVariables): string;
begin
  Result := JSDecode(ProcessNodeContent(Node, Vars));
end;

function TScriptedDownloader.ProcessDecodeBase64(Node: TXmlNode; Vars: TScriptVariables): string;
begin
  Result := Base64Decode(ProcessNodeContent(Node, Vars));
end;

function TScriptedDownloader.ProcessStripTags(Node: TXmlNode; Vars: TScriptVariables): string;
begin
  Result := StripTags(ProcessNodeContent(Node, Vars));
end;

function TScriptedDownloader.ProcessTimestamp(Node: TXmlNode; Vars: TScriptVariables): string;
var
  TimestampType: string;
begin
  TimestampType := XmlAttribute(Node, 'type');
  if (TimestampType = '') or (AnsiCompareText(TimestampType, 'unix') = 0) then
    Result := IntToStr(Trunc((Now - 25569) * 24*60*60))
  else
    ScriptError(Format(ERR_SCRIPTS_INVALID_ATTRIBUTE_VALUE, ['type', TimestampType]), Node);
end;

initialization
  fMainScriptEngine := nil;
  RegisterDownloader(TScriptedDownloader);

finalization
  FreeAndNil(fMainScriptEngine);

end.