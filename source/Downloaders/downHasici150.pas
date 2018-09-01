(******************************************************************************

______________________________________________________________________________

YouTube Downloader                                        (C) 2009, 2010 Pepak
http://www.pepak.net/download/youtube-downloader/         http://www.pepak.net
______________________________________________________________________________


Copyright (c) 2010, Pepak (http://www.pepak.net)
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

unit downHasici150;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils, Classes,
  uPCRE, uXml, HttpSend,
  uDownloader, uCommonDownloader, uRtmpDownloader;

type
  TDownloader_Hasici150 = class(TRtmpDownloader)
    private
    protected
      ConfigRegExp: TRegExp;
      RtmpRegExp: TRegExp;
    protected
      function GetMovieInfoUrl: string; override;
      function AfterPrepareFromPage(var Page: string; PageXml: TXmlDoc; Http: THttpSend): boolean; override;
    public
      class function Provider: string; override;
      class function UrlRegExp: string; override;
      constructor Create(const AMovieID: string); override;
      destructor Destroy; override;
    end;

implementation

uses
  uDownloadClassifier,
  uMessages;

// http://www.hasici150.tv/cz/Videogalerie/Slavnostni-vyhlaseni-Extraliga-CR-v-PU-2010_____93/
const
  URLREGEXP_BEFORE_ID = '^https?://(?:[a-z0-9-]+\.)*hasici150\.tv/cz/Videogalerie/';
  URLREGEXP_ID =        '[^/?&]+';
  URLREGEXP_AFTER_ID =  '';

const
  REGEXP_EXTRACT_TITLE = '<title>(?:[^<]*\|\s*)?(?P<TITLE>.*?)</title>';
  REGEXP_EXTRACT_CONFIG = '\bsrc="(?P<CONFIG>https?://[^"]+/vod\.php\?stream=(?P<STREAM>.+?))"';
  REGEXP_EXTRACT_RTMP = '\bstreamhosting\s*:\s*\{[^}]*\bnetConnectionUrl\s*:\s*''(?P<RTMP>rtmpe?://.+?)''';

{ TDownloader_Hasici150 }

class function TDownloader_Hasici150.Provider: string;
begin
  Result := 'Hasici150.tv';
end;

class function TDownloader_Hasici150.UrlRegExp: string;
begin
  Result := URLREGEXP_BEFORE_ID + '(?P<' + MovieIDParamName + '>' + URLREGEXP_ID + ')' + URLREGEXP_AFTER_ID;
end;

constructor TDownloader_Hasici150.Create(const AMovieID: string);
begin
  inherited Create(AMovieID);
  InfoPageEncoding := peUtf8;
  MovieTitleRegExp := RegExCreate(REGEXP_EXTRACT_TITLE, [rcoIgnoreCase, rcoSingleLine]);
  ConfigRegExp := RegExCreate(REGEXP_EXTRACT_CONFIG, [rcoIgnoreCase, rcoSingleLine]);
  RtmpRegExp := RegExCreate(REGEXP_EXTRACT_RTMP, [rcoIgnoreCase, rcoSingleLine]);
end;

destructor TDownloader_Hasici150.Destroy;
begin
  RegExFreeAndNil(MovieTitleRegExp);
  RegExFreeAndNil(ConfigRegExp);
  RegExFreeAndNil(RtmpRegExp);
  inherited;
end;

function TDownloader_Hasici150.GetMovieInfoUrl: string;
begin
  Result := 'http://www.hasici150.tv/cz/Videogalerie/' + MovieID + '/';
end;

function TDownloader_Hasici150.AfterPrepareFromPage(var Page: string; PageXml: TXmlDoc; Http: THttpSend): boolean;
var ConfigUrl, Stream, VodProvider, Server: string;
begin
  inherited AfterPrepareFromPage(Page, PageXml, Http);
  Result := False;
  if not GetRegExpVars(ConfigRegExp, Page, ['CONFIG', 'STREAM'], [@ConfigUrl, @Stream]) then
    SetLastErrorMsg(_(ERR_FAILED_TO_LOCATE_MEDIA_INFO_PAGE))
  else if not DownloadPage(Http, ConfigUrl, VodProvider) then
    SetLastErrorMsg(_(ERR_FAILED_TO_DOWNLOAD_MEDIA_INFO_PAGE))
  else if not GetRegExpVar(RtmpRegExp, VodProvider, 'RTMP', Server) then
    SetLastErrorMsg(_(ERR_FAILED_TO_LOCATE_MEDIA_SERVER))
  else
    begin
    MovieUrl := Server + '/' + Stream;
    AddRtmpDumpOption('r', MovieURL);
    AddRtmpDumpOption('y', Stream);
    SetPrepared(True);
    Result := True;
    end;
end;

initialization
  RegisterDownloader(TDownloader_Hasici150);

end.