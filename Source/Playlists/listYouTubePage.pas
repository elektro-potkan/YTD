unit listYouTubePage;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils, Classes,
  PCRE, HttpSend,
  uDownloader, uCommonDownloader, uHttpDownloader, uPlaylistDownloader;

type
  TPlaylist_YouTube_Page = class(TPlaylistDownloader)
    private
    protected
      function GetMovieInfoUrl: string; override;
      function GetPlayListItemURL(Match: IMatch; Index: integer): string; override;
    public
      class function Provider: string; override;
      class function MovieIDParamName: string; override;
      class function UrlRegExp: string; override;
      constructor Create(const AMovieID: string); override;
      destructor Destroy; override;
    end;

implementation

uses
  uDownloadClassifier;

const PAGE_ITEM_REGEXP = '<div\s+id="playnav-video-play-uploads-[0-9]+-(?P<ID>[^"]{11})["-]';

{ TPlaylist_YouTube_Page }

constructor TPlaylist_YouTube_Page.Create(const AMovieID: string);
begin
  inherited;
  PlayListItemRegExp := RegExCreate(PAGE_ITEM_REGEXP, [rcoIgnoreCase, rcoSingleLine]);
end;

destructor TPlaylist_YouTube_Page.Destroy;
begin
  PlayListItemRegExp := nil;
  inherited;
end;

class function TPlaylist_YouTube_Page.Provider: string;
begin
  Result := 'YouTube Page';
end;

class function TPlaylist_YouTube_Page.MovieIDParamName: string;
begin
  Result := 'YOUTUBEPAGE';
end;

class function TPlaylist_YouTube_Page.UrlRegExp: string;
begin
  // http://www.youtube.com/titanicpiano14
  Result := '^https?://(?:[a-z0-9-]+\.)*youtube\.com/(?P<' + MovieIDParamName + '>[^/?]+)$';
end;

function TPlaylist_YouTube_Page.GetMovieInfoUrl: string;
begin
  Result := 'http://www.youtube.com/' + MovieID;
end;

function TPlaylist_YouTube_Page.GetPlayListItemURL(Match: IMatch; Index: integer): string;
begin
  Result := 'http://www.youtube.com/watch?v=' + Match.Groups.ItemsByName['ID'].Value;
end;

initialization
  RegisterDownloader(TPlaylist_YouTube_Page);

end.
 