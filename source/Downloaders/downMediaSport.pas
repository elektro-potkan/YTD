(******************************************************************************

______________________________________________________________________________

YouTube Downloader                                           (c) 2009-11 Pepak
http://www.pepak.net/download/youtube-downloader/         http://www.pepak.net
______________________________________________________________________________


Copyright (c) 2011, Pepak (http://www.pepak.net)
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

unit downMediaSport;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils, Classes,
  uPCRE, uXml, HttpSend, SynaUtil,
  uDownloader, uCommonDownloader, uHttpDownloader;

type
  TDownloader_MediaSport = class(THttpDownloader)
    private
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

// http://www.mediasport.cz/rally-cz/video/09_luzicke_cerny_rz1.html
const
  URLREGEXP_BEFORE_ID = '^https?://(?:[a-z0-9-]+\.)*mediasport\.cz/';
  URLREGEXP_ID =        '[^/]+/video/.+';
  URLREGEXP_AFTER_ID =  '';

const
  REGEXP_EXTRACT_URL = '\bflashvars\.id\s*=\s*"[^"]*\|HQ\|(?P<URL>https?://.+?)[|"]';

{ TDownloader_MediaSport }

class function TDownloader_MediaSport.Provider: string;
begin
  Result := 'MediaSport.cz';
end;

class function TDownloader_MediaSport.UrlRegExp: string;
begin
  Result := Format(URLREGEXP_BEFORE_ID + '(?P<%s>' + URLREGEXP_ID + ')' + URLREGEXP_AFTER_ID, [MovieIDParamName]);;
end;

constructor TDownloader_MediaSport.Create(const AMovieID: string);
begin
  inherited Create(AMovieID);
  InfoPageEncoding := peUTF8;
  MovieUrlRegExp := RegExCreate(REGEXP_EXTRACT_URL);
end;

destructor TDownloader_MediaSport.Destroy;
begin
  RegExFreeAndNil(MovieUrlRegExp);
  inherited;
end;

function TDownloader_MediaSport.GetMovieInfoUrl: string;
begin
  Result := 'http://www.mediasport.cz/' + MovieID;
end;

function TDownloader_MediaSport.AfterPrepareFromPage(var Page: string; PageXml: TXmlDoc; Http: THttpSend): boolean;
var Protocol, User, Password, Host, Port, Path, Params: string;
    i: integer;
begin
  Result := inherited AfterPrepareFromPage(Page, PageXml, Http);
  if Result then
    begin
    ParseURL(MovieURL, Protocol, User, Password, Host, Port, Path, Params);
    i := Length(Path);
    while (i > 0) and (Path[i] <> '/') do
      Dec(i);
    if i > 0 then
      Path := Copy(Path, Succ(i), MaxInt);
    SetName(ChangeFileExt(Path, ''));
    end;
end;

initialization
  RegisterDownloader(TDownloader_MediaSport);

end.
