unit downWrzuta;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils, Classes, Windows,
  uPCRE, HttpSend,
  uDownloader, uCommonDownloader, uHttpDownloader;

type
  TDownloader_Wrzuta = class(THttpDownloader)
    private
    protected
      MovieUrlPartsRegExp: TRegExp;
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

// http://w772.wrzuta.pl/film/7KI3ZUDHrUK/
// http://goovnoh.wrzuta.pl/audio/8U1t8UQ4f8W/
const
  URLREGEXP_BEFORE_ID = '^';
  URLREGEXP_ID =        'https?://(?:[a-z0-9-]+\.)+wrzuta\.pl/(?:film|audio)/.+';
  URLREGEXP_AFTER_ID =  '';

const
  REGEXP_MOVIE_TITLE = '<meta\s+name="title"\s+content="(?P<TITLE>.*?)"';
  REGEXP_MOVIE_URL_PARTS = '^(?P<DOMAIN>https?://(?:[a-z0-9-]+\.)+wrzuta\.pl/)(?:film|audio)/(?P<ID>[^/?&]+)/';

{ TDownloader_Wrzuta }

class function TDownloader_Wrzuta.Provider: string;
begin
  Result := 'Wrzuta.com';
end;

class function TDownloader_Wrzuta.UrlRegExp: string;
begin
  Result := URLREGEXP_BEFORE_ID + '(?P<' + MovieIDParamName + '>' + URLREGEXP_ID + ')' + URLREGEXP_AFTER_ID;
end;

constructor TDownloader_Wrzuta.Create(const AMovieID: string);
begin
  inherited;
  SetInfoPageEncoding(peUTF8);
  MovieTitleRegExp := RegExCreate(REGEXP_MOVIE_TITLE, [rcoIgnoreCase, rcoSingleLine]);
  MovieUrlPartsRegExp := RegExCreate(REGEXP_MOVIE_URL_PARTS, [rcoIgnoreCase, rcoSingleLine]);
end;

destructor TDownloader_Wrzuta.Destroy;
begin
  RegExFreeAndNil(MovieTitleRegExp);
  RegExFreeAndNil(MovieUrlPartsRegExp);
  inherited;
end;

function TDownloader_Wrzuta.GetMovieInfoUrl: string;
begin
  Result := MovieID;
end;

function TDownloader_Wrzuta.AfterPrepareFromPage(var Page: string; Http: THttpSend): boolean;
var Url: string;
begin
  inherited AfterPrepareFromPage(Page, Http);
  Result := False;
  if not MovieUrlPartsRegExp.Match(MovieID) then
    SetLastErrorMsg(_(ERR_FAILED_TO_LOCATE_MEDIA_INFO_PAGE))
  else
    begin
    Url := MovieUrlPartsRegExp.SubexpressionByName('DOMAIN') + 'sr/f/' + MovieUrlPartsRegExp.SubexpressionByName('ID');
    if not DownloadPage(Http, Url, hmHEAD) then
      SetLastErrorMsg(_(ERR_FAILED_TO_LOCATE_MEDIA_URL))
    else
      begin
      MovieURL := LastURL;
      SetPrepared(True);
      Result := True;
      end;
    end;
end;

initialization
  RegisterDownloader(TDownloader_Wrzuta);

end.
