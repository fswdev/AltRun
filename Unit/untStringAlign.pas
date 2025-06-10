unit untStringAlign;

interface

function GetDisplayWidth(const S: string): Integer;

function FormatAligned( S: string; TotalWidth: Integer): string;

implementation

uses
  System.SysUtils;

// 计算字符串的显示宽度（中文占2，英文/数字/其他占1）
function GetDisplayWidth(const S: string): Integer;
var
  I: Integer;
  C: WideChar;
begin
  Result := 0;
  for I := 1 to Length(S) do
  begin
    C := S[I];
    // 中文字符（CJK统一汉字范围）占2个宽度
    if (C >= #$4E00) and (C <= #$9FFF) then
      Inc(Result, 2)
    else
      Inc(Result, 1);
  end;
end;

// 格式化字符串，确保总显示宽度为TotalWidth，左对齐，后接|
function FormatAligned( S: string; TotalWidth: Integer): string;
var
  DisplayWidth, SpacesNeeded: Integer;
begin
  if length(S) > TotalWidth then
    delete(S, TotalWidth - 1, length(S));
  DisplayWidth := GetDisplayWidth(S);
  // 计算需要的空格数（按显示宽度）
  SpacesNeeded := TotalWidth - DisplayWidth;
  if SpacesNeeded < 0 then
    SpacesNeeded := 0; // 防止负数
  Result := S + StringOfChar(' ', SpacesNeeded) + '|';
end;

end.

