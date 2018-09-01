unit uApiFunctions;

interface
{$INCLUDE 'uApi.inc'}

uses
  SysUtils, Classes, Windows, CommCtrl,
  uApiCommon;

//----- Generic Windows functions ----------------------------------------------
type
  EApiError = class(Exception);

procedure ShowApiError(IsError: boolean); overload;
procedure ShowApiError(LastError: DWORD); overload;
function GetWindowTextAsString(hwnd: HWND): string;
function MakePoints(lParam: LPARAM): TPoint;

//----- Clipboard --------------------------------------------------------------
function GetClipboardAsText(Owner: THandle; out Text: string): boolean; overload;
function GetClipboardAsText(Owner: THandle): string; overload;
function SetClipboardAsText(Owner: THandle; const Text: string): THandle;

//----- Listview ---------------------------------------------------------------
function ListViewInsertColumn(ListView: THandle; Index, Subitem: integer; Alignment: TAlignment; Width: integer; const Title: string): integer;
function ListViewGetItemCount(ListView: THandle): integer;
function ListViewIsItemSelected(ListView: THandle; Index: integer): boolean;
function ListViewSelectItem(ListView: THandle; Index: integer; Selected: boolean): boolean;
function ListViewGetSelectedItems(ListView: THandle; out Indexes: TList; MaxCount: integer = 0): boolean;
function ListViewGetSelectedItem(ListView: THandle): integer;
//------------------------------------------------------------------------------

implementation

procedure ShowApiError(IsError: boolean);
begin
  if IsError then
    ShowApiError(GetLastError);
end;

procedure ShowApiError(LastError: DWORD);
var Buf: array[0..32768] of char;
    n: DWORD;
    Msg: string;
begin
  if LastError <> NO_ERROR then
    begin
    n := FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, nil, LastError, 0, Buf, Sizeof(Buf), nil);
    if n = 0 then
      Msg := Format('Unknown error (%u, %08.8x).', [LastError, LastError])
    else
      begin
      Buf[n] := #0;
      Msg := string(Buf);
      end;
    Raise EApiError.Create(Msg);
    end;
end;

function GetWindowTextAsString(hwnd: HWND): string;
var Buf: array of char;
    n: integer;
begin
  Result := '';
  n := GetWindowTextLength(hwnd);
  if n > 0 then
    begin
    Inc(n);
    SetLength(Buf, n);
    n := GetWindowText(hwnd, PChar(Buf), n);
    if n > 0 then
      SetString(Result, PChar(Buf), n);
    end;
end;

function MakePoints(lParam: LPARAM): TPoint;
begin
  Result.x := lParam and $ffff;
  Result.y := lParam shr 16;
end;

function GetClipboardAsText(Owner: THandle; out Text: string): boolean;
var Data: THandle;
    P: PChar;
begin
  Result := False;
  Text := '';
  if IsClipboardFormatAvailable(CF_TEXT) then
    if OpenClipboard(Owner) then
      try
        Data := GetClipboardData(CF_TEXT);
        if Data <> 0 then
          begin
          P := GlobalLock(Data);
          if P <> nil then
            try
              Text := string(P);
              Result := True;
            finally
              GlobalUnlock(Data);
              end;
          end;
      finally
        CloseClipboard;
        end;
end;

function GetClipboardAsText(Owner: THandle): string;
begin
  if not GetClipboardAsText(Owner, Result) then
    Result := '';
end;

function SetClipboardAsText(Owner: THandle; const Text: string): THandle;
var Data: HGLOBAL;
    DataPtr: Pointer;
    s: string;
begin
  Result := 0;
  if OpenClipboard(Owner) then
    try
      s := Text + #0;
      Data := GlobalAlloc(GMEM_MOVEABLE, Length(s) * sizeof(Char));
      if Data <> 0 then
        begin
        DataPtr := GlobalLock(Data);
        try
          Move(s[1], DataPtr^, Length(s) * sizeof(Char));
        finally
          GlobalUnlock(Data);
          end;
        Result := SetClipboardData(CF_TEXT, Data);
        end;
    finally
      CloseClipboard;
      end;
end;

function ListViewInsertColumn(ListView: THandle; Index, Subitem: integer; Alignment: TAlignment; Width: integer; const Title: string): integer;
const Alignments: array[TAlignment] of integer = (LVCFMT_LEFT, LVCFMT_RIGHT, LVCFMT_CENTER);
var Column: LV_COLUMN;
begin
  Column.mask := LVCF_FMT or LVCF_TEXT;
  if Width > 0 then
    Column.mask := Column.mask or LVCF_WIDTH;
  if Subitem > 0 then
    Column.mask := Column.mask or LVCF_SUBITEM;
  Column.fmt := Alignments[Alignment];
  Column.cx := Width;
  Column.pszText := PChar(Title);
  Column.cchTextMax := 0;
  Result := SendMessage(ListView, LVM_INSERTCOLUMN, Index, integer(@Column));
end;

function ListViewGetItemCount(ListView: THandle): integer;
begin
  Result := SendMessage(ListView, LVM_GETITEMCOUNT, 0, 0);
end;

function ListViewIsItemSelected(ListView: THandle; Index: integer): boolean;
begin
  Result := Longbool(SendMessage(ListView, LVM_GETITEMSTATE, Index, LVIS_SELECTED) and LVIS_SELECTED);
end;

function ListViewSelectItem(ListView: THandle; Index: integer; Selected: boolean): boolean;
const SelectedFlag: array[boolean] of DWORD = (0, LVIS_SELECTED);
var Item: LV_ITEM;
begin
  Result := False;
  Item.state := SelectedFlag[Selected];
  Item.stateMask := LVIS_SELECTED;
  if SendMessage(ListView, LVM_SETITEMSTATE, Index, LPARAM(@Item)) <> 0 then
    Result := True;
end;

function ListViewGetSelectedItems(ListView: THandle; out Indexes: TList; MaxCount: integer): boolean;
var i, n: integer;
begin
  Result := False;
  Indexes := nil;
  n := ListViewGetItemCount(ListView);
  if n > 0 then
    for i := 0 to Pred(n) do
      if ListViewIsItemSelected(ListView, i) then
        begin
        if not Result then
          begin
          Indexes := TList.Create;
          Result := True;
          end;
        Indexes.Add(Pointer(i));
        if MaxCount > 0 then
          if Indexes.Count >= MaxCount then
            Break;
        end;
end;

function ListViewGetSelectedItem(ListView: THandle): integer;
begin
  Result := SendMessage(ListView, LVM_GETNEXTITEM, -1, LVNI_FOCUSED or LVNI_SELECTED);
end;

end.
