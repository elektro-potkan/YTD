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

unit downBreak;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils, Classes, Windows,
  uPCRE, HttpSend,
  uDownloader, uCommonDownloader, uHttpDownloader;

type
  TDownloader_Break = class(THttpDownloader)
    private
    protected
      MoviePlayerRegExp: TRegExp;
      VideoFromPlayerRegExp: TRegExp;
      TokenFromPlayerRegExp: TRegExp;
    protected
      function GetMovieInfoUrl: string; override;
      function AfterPrepareFromPage(var Page: string; Http: THttpSend): boolean; override;
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

// http://www.break.com/index/runaway-truck-crashes-and-flips-over.html
// http://www.break.com/usercontent/2007/10/South-Africa-Win-Rugby-World-Cup-385706.html
const
  URLREGEXP_BEFORE_ID = '^https?://(?:[a-z0-9-]+\.)*break\.com/';
  URLREGEXP_ID =        '[^?]+\.html';
  URLREGEXP_AFTER_ID =  '';

const
  REGEXP_MOVIE_TITLE = '<meta\s+name="title"\s+content="(?P<TITLE>[^"]+)"';
  REGEXP_MOVIE_PLAYER = '<link\s+rel="video_src"\s+href="(?P<URL>https?://[^"]+)"';
  REGEXP_VIDEO_FROM_PLAYER = '[?&]sVidLoc=(?P<URL>http[^&]+)';
  REGEXP_TOKEN_FROM_PLAYER = '[?&]icon=(?P<TOKEN>[0-9A-F]+)';

{ TDownloader_Break }

class function TDownloader_Break.Provider: string;
begin
  Result := 'Break.com';
end;

class function TDownloader_Break.UrlRegExp: string;
begin
  Result := URLREGEXP_BEFORE_ID + '(?P<' + MovieIDParamName + '>' + URLREGEXP_ID + ')' + URLREGEXP_AFTER_ID;
end;

constructor TDownloader_Break.Create(const AMovieID: string);
begin
  inherited Create(AMovieID);
  SetInfoPageEncoding(peUTF8);
  MovieTitleRegExp := RegExCreate(REGEXP_MOVIE_TITLE, [rcoIgnoreCase, rcoSingleLine]);
  MoviePlayerRegExp := RegExCreate(REGEXP_MOVIE_PLAYER, [rcoIgnoreCase, rcoSingleLine]);
  VideoFromPlayerRegExp := RegExCreate(REGEXP_VIDEO_FROM_PLAYER, [rcoIgnoreCase]);
  TokenFromPlayerRegExp := RegExCreate(REGEXP_TOKEN_FROM_PLAYER, [rcoIgnoreCase]);
end;

destructor TDownloader_Break.Destroy;
begin
  RegExFreeAndNil(MovieTitleRegExp);
  RegExFreeAndNil(MoviePlayerRegExp);
  RegExFreeAndNil(VideoFromPlayerRegExp);
  RegExFreeAndNil(TokenFromPlayerRegExp);
  inherited;
end;

function TDownloader_Break.GetMovieInfoUrl: string;
begin
  Result := 'http://www.break.com/' + MovieID;
end;

function TDownloader_Break.AfterPrepareFromPage(var Page: string; Http: THttpSend): boolean;
var Url, Url2, Token: string;
    Request: THttpSend;
begin
  inherited AfterPrepareFromPage(Page, Http);
  Result := False;
  if not GetRegExpVar(MoviePlayerRegExp, Page, 'URL', Url) then
    SetLastErrorMsg(_(ERR_FAILED_TO_LOCATE_MEDIA_INFO_PAGE))
  else
    begin
    Request := CreateHttp;
    try
      if not Request.HttpMethod('GET', Url) then
        SetLastErrorMsg(_(ERR_FAILED_TO_DOWNLOAD_MEDIA_INFO_PAGE))
      else if not CheckRedirect(Request, Url) then
        SetLastErrorMsg(_(ERR_FAILED_TO_DOWNLOAD_MEDIA_INFO_PAGE))
      else if not GetRegExpVar(VideoFromPlayerRegExp, Url, 'URL', Url2) then
        SetLastErrorMsg(_(ERR_FAILED_TO_LOCATE_MEDIA_URL))
      else if not GetRegExpVar(TokenFromPlayerRegExp, Url, 'TOKEN', Token) then
        SetLastErrorMsg(Format(_(ERR_VARIABLE_NOT_FOUND), ['token']))
      else
        begin
        MovieURL := UrlDecode(Url2) + '?' + Token;
        Result := True;
        SetPrepared(True);
        end;
    finally
      Request.Free;
      end;
    end;
end;

initialization
  RegisterDownloader(TDownloader_Break);

end.