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

unit downIPrima;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils, Classes, Windows,
  uPCRE, uXml, HttpSend,
  uDownloader, uCommonDownloader, uHttpDownloader, downStream;

type
  TDownloader_iPrima = class(TDownloader_Stream)
    private
    protected
      StreamIDRegExp: TRegExp;
    protected
      function GetMovieInfoUrl: string; override;
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

// http://www.iprima.cz/videoarchiv/44524/all/all
const
  URLREGEXP_BEFORE_ID = '^https?://(?:[a-z0-9-]+\.)*iprima.cz/(?:videoarchiv|videoplayer)/';
  URLREGEXP_ID =        '[0-9]+';
  URLREGEXP_AFTER_ID =  '';

const
  REGEXP_STREAM_ID = '<param\s+name="flashvars"\s+value="[^"]*&id=(?P<STREAMID>[0-9]+)';

{ TDownloader_iPrima }

class function TDownloader_iPrima.Provider: string;
begin
  Result := 'iPrima.cz';
end;

class function TDownloader_iPrima.UrlRegExp: string;
begin
  Result := URLREGEXP_BEFORE_ID + '(?P<' + MovieIDParamName + '>' + URLREGEXP_ID + ')' + URLREGEXP_AFTER_ID;
end;

constructor TDownloader_iPrima.Create(const AMovieID: string);
begin
  inherited Create(AMovieID);
  InfoPageEncoding := peUTF8;
  StreamIDRegExp := RegExCreate(REGEXP_STREAM_ID, [rcoIgnoreCase]);
end;

destructor TDownloader_iPrima.Destroy;
begin
  RegExFreeAndNil(StreamIDRegExp);
  inherited;
end;

function TDownloader_iPrima.GetMovieInfoUrl: string;
var Info: THttpSend;
    Url, Page, ID: string;
begin
  Result := '';
  Info := CreateHttp;
  try
    Url := 'http://www.iprima.cz/videoarchiv/' + MovieID + '/all/all';
    if DownloadPage(Info, Url, Page, peUTF8) then
      if GetRegExpVar(StreamIDRegExp, Page, 'STREAMID', ID) then
        Result := GetMovieInfoUrlForID(ID);
  finally
    Info.Free;
    end;
end;

initialization
  RegisterDownloader(TDownloader_iPrima);

end.
