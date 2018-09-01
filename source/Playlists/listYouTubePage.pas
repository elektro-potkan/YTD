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

unit listYouTubePage;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils, Classes,
  uPCRE, HttpSend,
  uDownloader, uCommonDownloader, uHttpDownloader, uPlaylistDownloader;

type
  TPlaylist_YouTube_Page = class(TPlaylistDownloader)
    private
    protected
      function GetMovieInfoUrl: string; override;
      function GetPlayListItemURL(Match: TRegExpMatch; Index: integer): string; override;
    public
      class function Provider: string; override;
      class function UrlRegExp: string; override;
      constructor Create(const AMovieID: string); override;
      destructor Destroy; override;
    end;

implementation

uses
  uDownloadClassifier;

// http://www.youtube.com/titanicpiano14
// http://www.youtube.com/user/titanicpiano14
const
  URLREGEXP_BEFORE_ID = '^https?://(?:[a-z0-9-]+\.)*youtube\.com/';
  URLREGEXP_ID =        '(?:user/)?[^/?&]+';
  URLREGEXP_AFTER_ID =  '$';

const
  REGEXP_PAGE_ITEM = '<div\s+id="playnav-video-play-uploads-[0-9]+-(?P<ID>[^"]{11})["-]';

{ TPlaylist_YouTube_Page }

class function TPlaylist_YouTube_Page.Provider: string;
begin
  Result := 'YouTube.com';
end;

class function TPlaylist_YouTube_Page.UrlRegExp: string;
begin
  Result := Format(URLREGEXP_BEFORE_ID + '(?P<%s>' + URLREGEXP_ID + ')' + URLREGEXP_AFTER_ID, [MovieIDParamName]);;
end;

constructor TPlaylist_YouTube_Page.Create(const AMovieID: string);
begin
  inherited;
  PlayListItemRegExp := RegExCreate(REGEXP_PAGE_ITEM);
end;

destructor TPlaylist_YouTube_Page.Destroy;
begin
  RegExFreeAndNil(PlayListItemRegExp);
  inherited;
end;

function TPlaylist_YouTube_Page.GetMovieInfoUrl: string;
begin
  Result := 'http://www.youtube.com/' + MovieID;
end;

function TPlaylist_YouTube_Page.GetPlayListItemURL(Match: TRegExpMatch; Index: integer): string;
begin
  Result := 'http://www.youtube.com/watch?v=' + Match.SubexpressionByName('ID');
end;

initialization
  RegisterDownloader(TPlaylist_YouTube_Page);

end.
 