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

unit downStupidVideos;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils, Classes, Windows,
  uPCRE, HttpSend,
  uDownloader, uCommonDownloader, uHttpDownloader,
  downGrindTV;

type
  TDownloader_StupidVideos = class(TDownloader_GrindTV)
    private
    protected
      function GetMovieInfoUrl: string; override;
      function BaseUrl: string; override;
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

// http://www.stupidvideos.com/tv/homepage_1/Amazing_Aquarium/
// http://www.stupidvideos.com/video/Fliers_Fall_Under_Friendly_Fire/?m=new
const
  URLREGEXP_BEFORE_ID = '^https?://(?:[a-z0-9-]+\.)*stupidvideos\.com/(?:video|tv/[^/]+)/';
  URLREGEXP_ID =        '[^/?&]+';
  URLREGEXP_AFTER_ID =  '';

const
  REGEXP_MOVIE_TITLE = '<META\s+name="title"\s+content="(?P<TITLE>.*?)"';
  REGEXP_MOVIE_ID = '\bvar\s+videoID\s*=\s*''(?P<VIDEOID>[0-9]+)''\s*;';

{ TDownloader_StupidVideos }

class function TDownloader_StupidVideos.Provider: string;
begin
  Result := 'StupidVideos.com';
end;

class function TDownloader_StupidVideos.UrlRegExp: string;
begin
  Result := URLREGEXP_BEFORE_ID + '(?P<' + MovieIDParamName + '>' + URLREGEXP_ID + ')' + URLREGEXP_AFTER_ID;
end;

constructor TDownloader_StupidVideos.Create(const AMovieID: string);
begin
  inherited;
  SetInfoPageEncoding(peUnknown);
  RegExFreeAndNil(MovieTitleRegExp);
  MovieTitleRegExp := RegExCreate(REGEXP_MOVIE_TITLE, [rcoIgnoreCase, rcoSingleLine]);
  RegExFreeAndNil(MovieIdRegExp);
  MovieIdRegExp := RegExCreate(REGEXP_MOVIE_ID, [rcoIgnoreCase, rcoSingleLine]);
end;

destructor TDownloader_StupidVideos.Destroy;
begin
  RegExFreeAndNil(MovieTitleRegExp);
  RegExFreeAndNil(MovieIdRegExp);
  inherited;
end;

function TDownloader_StupidVideos.GetMovieInfoUrl: string;
begin
  Result := 'http://www.stupidvideos.com/video/' + MovieID + '/';
end;

function TDownloader_StupidVideos.BaseUrl: string;
begin
  Result := 'http://videos.stupidvideos.com/2/';
end;

initialization
  RegisterDownloader(TDownloader_StupidVideos);

end.