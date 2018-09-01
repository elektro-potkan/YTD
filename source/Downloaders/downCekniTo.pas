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

unit downCekniTo;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils, Classes,
  uPCRE, HttpSend,
  uDownloader, uCommonDownloader, uHttpDownloader;

type
  TDownloader_CekniTo = class(THttpDownloader)
    private
    protected
      MovieIDRegExp: TRegExp;
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

// http://www.ceknito.cz/video/446074
const
  URLREGEXP_BEFORE_ID = '^https?://(?:[a-z0-9-]+\.)*ceknito\.(?:cz|sk)/video/';
  URLREGEXP_ID =        '[0-9]+';
  URLREGEXP_AFTER_ID =  '';

const
  REGEXP_EXTRACT_TITLE = '<h1>(?P<TITLE>.*?)</h1>';
  REGEXP_EXTRACT_MOVIEID = '<param\s+name="flashvars"\s+value="fid=(?P<ID>[^&"]+)';

{ TDownloader_CekniTo }

class function TDownloader_CekniTo.Provider: string;
begin
  Result := 'CekniTo.sk';
end;

class function TDownloader_CekniTo.UrlRegExp: string;
begin
  Result := URLREGEXP_BEFORE_ID + '(?P<' + MovieIDParamName + '>' + URLREGEXP_ID + ')' + URLREGEXP_AFTER_ID;
end;

constructor TDownloader_CekniTo.Create(const AMovieID: string);
begin
  inherited Create(AMovieID);
  SetInfoPageEncoding(peUTF8);
  MovieTitleRegExp := RegExCreate(REGEXP_EXTRACT_TITLE, [rcoIgnoreCase, rcoSingleLine]);
  MovieIDRegExp := RegExCreate(REGEXP_EXTRACT_MOVIEID, [rcoIgnoreCase, rcoSingleLine]);
end;

destructor TDownloader_CekniTo.Destroy;
begin
  RegExFreeAndNil(MovieTitleRegExp);
  RegExFreeAndNil(MovieIDRegExp);
  inherited;
end;

function TDownloader_CekniTo.GetMovieInfoUrl: string;
begin
  Result := 'http://www.ceknito.sk/video/' + MovieID;
end;

function TDownloader_CekniTo.AfterPrepareFromPage(var Page: string; Http: THttpSend): boolean;
var ID: string;
begin
  inherited AfterPrepareFromPage(Page, Http);
  Result := False;
  if not GetRegExpVar(MovieIDRegExp, Page, 'ID', ID) then
    SetLastErrorMsg(_(ERR_FAILED_TO_LOCATE_MEDIA_INFO))
  else if not DownloadPage(Http, 'http://vid4.ceknito.sk/v.php?id=' + ID, hmHEAD) then
    SetLastErrorMsg(_(ERR_FAILED_TO_DOWNLOAD_MEDIA_INFO_PAGE))
  else
    begin
    MovieURL := LastURL;
    Result := True;
    SetPrepared(True);
    end;
end;

initialization
  RegisterDownloader(TDownloader_CekniTo);

end.