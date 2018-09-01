unit uStrings;

interface

function MemoryToWideString(Data: PWideChar; DataChars: integer): WideString;
function CompareWideCharPtrs(Ptr1, Ptr2: PWideChar; Ptr1Chars, Ptr2Chars: integer; MaxChars: integer = MaxInt): integer;
function ReadlnWide(var Data: PWideChar; var DataChars: integer; out Line: PWideChar; out LineChars: integer): boolean;
function TrimWide(var Data: PWideChar; var DataChars: integer): boolean;
function SplitNameValueWide(Data: PWideChar; DataChars: integer; Separator: PWideChar; SeparatorChars: integer; out Name: PWideChar; out NameChars: integer; out Value: PWideChar; out ValueChars: integer): boolean;

implementation

function MemoryToWideString(Data: PWideChar; DataChars: integer): WideString;
begin
  SetLength(Result, DataChars);
  Move(Data^, Result[1], DataChars*Sizeof(WideChar));
end;

function CompareWideCharPtrs(Ptr1, Ptr2: PWideChar; Ptr1Chars, Ptr2Chars: integer; MaxChars: integer = MaxInt): integer;
begin
  Result := 0;
  if MaxChars > 0 then
    repeat
      if Ptr1Chars > 0 then
        if Ptr2Chars > 0 then
          if Ptr1^ > Ptr2^ then
            begin
            Result := 1;
            Break;
            end
          else if Ptr1^ < Ptr2^ then
            begin
            Result := -1;
            Break;
            end
          else
            begin
            end
        else
          begin
          Result := 1;
          Break;
          end
      else if Ptr2Chars > 0 then
        begin
        Result := -1;
        Break;
        end;
      Inc(Ptr1);
      Inc(Ptr2);
      Dec(Ptr1Chars);
      Dec(Ptr2Chars);
      Dec(MaxChars);
    until MaxChars <= 0;
end;

function ReadlnWide(var Data: PWideChar; var DataChars: integer; out Line: PWideChar; out LineChars: integer): boolean;
begin
  Result := False;
  if DataChars > 0 then
    begin
    Result := True;
    Line := Data;
    LineChars := 0;
    while (DataChars > 0) do
      begin
      if Data^=#13 then
        begin
        Inc(Data);
        Dec(DataChars);
        if (DataChars > 0) and (Data^ = #13) then
          begin
          Inc(Data);
          Dec(DataChars);
          end;
        Break;
        end
      else if Data^=#10 then
        begin
        Inc(Data);
        Dec(DataChars);
        Break;
        end
      else
        begin
        Inc(Data);
        Dec(DataChars);
        Inc(LineChars);
        end;
      end;
    end;
end;

function TrimWide(var Data: PWideChar; var DataChars: integer): boolean;
var P: PWideChar;
begin
  while (DataChars > 0) and ((Data^ = ' ') or (Data^ = #13) or (Data^ = #10) or (Data^ = #9)) do
    begin
    Inc(Data);
    Dec(DataChars);
    end;
  P := Data;
  Inc(P, DataChars);
  while (DataChars > 0) and ((P^ = ' ') or (P^ = #13) or (P^ = #10) or (P^ = #9)) do
    begin
    Dec(P);
    Dec(DataChars);
    end;
  Result := DataChars > 0;
end;

function SplitNameValueWide(Data: PWideChar; DataChars: integer; Separator: PWideChar; SeparatorChars: integer; out Name: PWideChar; out NameChars: integer; out Value: PWideChar; out ValueChars: integer): boolean;
begin
  Name := Data;
  NameChars := DataChars;
  Value := nil;
  ValueChars := 0;
  Result := False;
  if SeparatorChars > 0 then
    begin
    while DataChars > 0 do
      if CompareWideCharPtrs(Data, Separator, DataChars, SeparatorChars, SeparatorChars) = 0 then
        begin
        NameChars := Integer(DWORD(Data) - DWORD(Name)) div Sizeof(WideChar);
        Value := Data;
        Inc(Value, SeparatorChars);
        ValueChars := DataChars - SeparatorChars;
        Result := True;
        Break;
        end
      else
        begin
        Inc(Data);
        Dec(DataChars);
        end;
    end;
end;

end.