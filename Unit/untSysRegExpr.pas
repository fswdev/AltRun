unit untSysRegExpr;

interface

uses
  System.RegularExpressions, SysUtils;

type
  TRegExpr = class
  private
    FMatch: TMatch;
    FInput: string;
    FOptions: TRegExOptions;

  private
    function GetMatchPos(Index: Integer): Integer;
    function GetMatchStr(Index: Integer): string;
  public
    Expression: string;
    function Exec(const AInput: string): Boolean;
    function Replace(const AInput, AReplace: string; ReplaceAll: Boolean = True): string;
    property Match: TMatch read FMatch;
    property MatchPos[Index: Integer]: Integer read GetMatchPos;
    property MatchStr[Index: Integer]: string read GetMatchStr;
    constructor Create;
  end;

implementation

constructor TRegExpr.Create;
begin
  inherited Create;
  FOptions := [];
end;

function TRegExpr.Exec(const AInput: string): Boolean;
begin
  FInput := AInput;
  FMatch := TRegEx.Match(AInput, Expression, FOptions);
  Result := FMatch.Success;
end;



function TRegExpr.Replace(const AInput, AReplace: string; ReplaceAll: Boolean): string;
begin
  if ReplaceAll then
    Result := TRegEx.Replace(AInput, Expression, AReplace, FOptions)
  else
  begin
    // 只替换第一个
    var m := TRegEx.Match(AInput, Expression, FOptions);
    if m.Success then
      Result := Copy(AInput, 1, m.Index-1) + AReplace + Copy(AInput, m.Index + m.Length, MaxInt)
    else
      Result := AInput;
  end;
end;

function TRegExpr.GetMatchPos(Index: Integer): Integer;
begin
  if (Index = 0) and FMatch.Success then
    Result := FMatch.Index + 1 // Delphi字符串下标从1开始
  else if (Index > 0) and (Index < FMatch.Groups.Count) then
    Result := FMatch.Groups[Index].Index + 1
  else
    Result := 0;
end;

function TRegExpr.GetMatchStr(Index: Integer): string;
begin
  if (Index = 0) and FMatch.Success then
    Result := FMatch.Value
  else if (Index > 0) and (Index < FMatch.Groups.Count) then
    Result := FMatch.Groups[Index].Value
  else
    Result := '';
end;

end.

