unit untPinyin;

interface

uses
  System.SysUtils, System.Generics.Collections;

function HanziToPinyin(const Hanzi: string): string;

function GetPinyinInitials(const Pinyin: string): string;

implementation

uses
  Winapi.Windows;

const
  LCMAP_PINYIN = $F0000000; // 拼音转换标志
  LOCALE_NAME_ZH_HANS = 'zh-Hans'; // 简体中文 Locale
  ToneMarks: array[0..4] of string = ('āáǎà', 'ēéěè', 'īíǐì', 'ōóǒò', 'ūúǔù');
  NoTone: array[0..4] of Char = ('a', 'e', 'i', 'o', 'u');

function HZtoPY(HZStr: WideString): string;
var
  s, c: AnsiString;
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(HZStr) do
  begin
    s := HZStr[i];
    if ByteType(s, 1) = mbSingleByte then
      c := s
    else
      case word(s[1]) shl 8 + word(s[2]) of
        $B0A1..$B0C4:
          c := 'A';
        $B0C5..$B2C0:
          c := 'B';
        $B2C1..$B4ED:
          c := 'C';
        $B4EE..$B6E9:
          c := 'D';
        $B6EA..$B7A1:
          c := 'E';
        $B7A2..$B8C0:
          c := 'F';
        $B8C1..$B9FD:
          c := 'G';
        $B9FE..$BBF6:
          c := 'H';
        $BBF7..$BFA5:
          c := 'J';
        $BFA6..$C0AB:
          c := 'K';
        $C0AC..$C2E7:
          c := 'L';
        $C2E8..$C4C2:
          c := 'M';
        $C4C3..$C5B5:
          c := 'N';
        $C5B6..$C5BD:
          c := 'O';
        $C5BE..$C6D9:
          c := 'P';
        $C6DA..$C8BA:
          c := 'Q';
        $C8BB..$C8F5:
          c := 'R';
        $C8F6..$CBF9:
          c := 'S';
        $CBFA..$CDD9:
          c := 'T';
        $CDDA..$CEF3:
          c := 'W';
        $CEF4..$D1B8:
          c := 'X';
        $D1B9..$D4D0:
          c := 'Y';
        $D4D1..$D7F9:
          c := 'Z';
      else
        c := s;
      end;
    Result := Result + c;
  end;
end;

function RemoveTone(const Pinyin: string): string;
var
  I: Integer;
begin
  Result := Pinyin;
  for I := Low(ToneMarks) to High(ToneMarks) do
    Result := StringReplace(Result, ToneMarks[I], NoTone[I], [rfReplaceAll, rfIgnoreCase]);
end;

function HanziToPinyin(const Hanzi: string): string;
var
  Buffer: array[0..511] of WideChar; // 加大缓冲区
  Len, I: Integer;
  C: Char;
  OutStr: string;
  Locale: LCID;
begin
  Result := '';
  // 获取简体中文 Locale
  Locale := LocaleNameToLCID(LOCALE_NAME_ZH_HANS, 0);
  if Locale = 0 then
    Locale := LOCALE_SYSTEM_DEFAULT; // 回退到系统默认

  for I := 1 to Length(Hanzi) do
  begin
    C := Hanzi[I];
    if Ord(C) >= $4E00 then // 汉字范围
    begin

      OutStr := HZtoPY(C);
      Result := Result + OutStr;

    end
    else
      Result := Result + C; // 非汉字保留
  end;
  Result := Trim(Result);
end;

function GetPinyinInitials(const Pinyin: string): string;
var
  Words: TArray<string>;
  Word: string;
begin
  Result := '';
  Words := Pinyin.Split([' ']);
  for Word in Words do
    if Word <> '' then
      Result := Result + Word[1];
end;

end.

