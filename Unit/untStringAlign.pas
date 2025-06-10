unit untStringAlign;

interface

function GetDisplayWidth(const S: string): Integer;

function FormatAligned( S: string; TotalWidth: Integer): string;

implementation

uses
  System.SysUtils;

// �����ַ�������ʾ��ȣ�����ռ2��Ӣ��/����/����ռ1��
function GetDisplayWidth(const S: string): Integer;
var
  I: Integer;
  C: WideChar;
begin
  Result := 0;
  for I := 1 to Length(S) do
  begin
    C := S[I];
    // �����ַ���CJKͳһ���ַ�Χ��ռ2�����
    if (C >= #$4E00) and (C <= #$9FFF) then
      Inc(Result, 2)
    else
      Inc(Result, 1);
  end;
end;

// ��ʽ���ַ�����ȷ������ʾ���ΪTotalWidth������룬���|
function FormatAligned( S: string; TotalWidth: Integer): string;
var
  DisplayWidth, SpacesNeeded: Integer;
begin
  if length(S) > TotalWidth then
    delete(S, TotalWidth - 1, length(S));
  DisplayWidth := GetDisplayWidth(S);
  // ������Ҫ�Ŀո���������ʾ��ȣ�
  SpacesNeeded := TotalWidth - DisplayWidth;
  if SpacesNeeded < 0 then
    SpacesNeeded := 0; // ��ֹ����
  Result := S + StringOfChar(' ', SpacesNeeded) + '|';
end;

end.

