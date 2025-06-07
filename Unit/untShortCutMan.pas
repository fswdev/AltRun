unit untShortCutMan;

interface

uses
  Windows, Dialogs, SysUtils, Classes, Forms, Contnrs, ComCtrls, ShellAPI,
  RegExpr, Controls, frmParam, untClipboard, untUtilities, untALTRunOption,
  untLogger;

const
  SHORTCUT_FILENAME = 'ShortCutList.txt';
  FAVOURIT_FILENAME = 'FavoriteList.txt';
  PARAM_DELIMITER = '/\';
  MAX_LATEST_NUM = 10;

type
  //���������
  TShortCutType = (scOther, scItem, scBlank, scRemark);

  //��������
  TParamType = (ptNone, ptNoEncoding, ptURLQuery, ptUTF8Query);

  //�����ͼ��
  TShortCutIcon = (siItem, siInfo);

  TCmdObject = class
  public
    Command: string;
    WorkingDir: string;
    Param: string;
    ParamType: TParamType;
  end;

  //�����
  TShortCutItem = class
  public
    ShortCutType: TShortCutType;
    ParamType: TParamType;
    ShortCut: string;
    Name: string;
    CommandLine: string;
    Rank: Integer;
    Freq: Integer;
  end;

  //������б�
  TShortCutList = TObjectList;

  //����������
  TShortCutMan = class
  private
    m_WriteDefaultShortCutList: Boolean;
    m_ShortCutFileName: string;
    m_FavoriteListFileName: string;
    m_FileModifyTime: string;
    m_ShortCutList: TShortCutList;
    m_SortedShortCutList: TStringList;
    m_FavoriteList: TStringList;
    m_LatestList: TStringList;
    m_Regex: TRegExpr;
    m_NeedRefresh: Boolean;
    m_Param: array[0..5] of string;
    function GetParam(Index: Integer): string;
    procedure SetParam(Index: Integer; const Value: string);

  public
    property WriteDefaultShortCutList: Boolean read m_WriteDefaultShortCutList write m_WriteDefaultShortCutList;
    property ShortCutFileName: string read m_ShortCutFileName write m_ShortCutFileName;
    property ShortCutList: TShortCutList read m_ShortCutList write m_ShortCutList;
    property NeedRefresh: Boolean read m_NeedRefresh write m_NeedRefresh;
    property Param[Index: Integer]: string read GetParam write SetParam;

    constructor Create;
    destructor Destroy; override;

    function LoadShortCutList(FileName: string = ''): Boolean;
    function SaveShortCutList(FileName: string = ''): Boolean;
    procedure CloneShortCutList(SrcList: TShortCutList; var NewList: TShortCutList);
    procedure FillListView(lvw: TListView);
    procedure LoadFromListView(lvw: TListView);

    function LoadFavoriteList: Boolean;
    function SaveFavoriteList: Boolean;

    function AddLatestShortCutItem(ShortCutItem: TShortCutItem): Boolean;
    function GetLatestShortCutItemList(var StringList: TStringList): Boolean;
    function GetLatestShortCutIndexList: string;
    function SetLatestShortCutIndexList(IndexList: string): Boolean;

    function ParamTypeToString(ParamType: TParamType): string;
    function StringToParamType(str: string; var ParamType: TParamType): Boolean;
    function ShortCutItemToString(ShortCutType: TShortCutType; ParamType: TParamType = ptNone; ShortCut: string = ''; Name: string = ''; CommandLine: string = ''; Freq: Integer = 0): string; overload;
    function ShortCutItemToString(ShortCutItem: TShortCutItem): string; overload;
    function StringToShortCutItem(str: string; var ShortCutItem: TShortCutItem): Boolean;

    procedure CloneShortCutItem(ShortCutItem: TShortCutItem; var NewItem: TShortCutItem);
    procedure AppendShortCutItem(ShortCutType: TShortCutType; ShortCut, Name, CommandLine: string); overload;
    procedure AppendShortCutItem(ShortCutItem: TShortCutItem); overload;
    procedure ModifyShortCutItem(ShortCutType: TShortCutType; ShortCut, Name, CommandLine: string; Index: Integer); overload;
    procedure ModifyShortCutItem(ShortCutItem: TShortCutItem; Index: Integer); overload;
    function ContainShortCutItem(ShortCutType: TShortCutType; ParamType: TParamType; ShortCut, Name, CommandLine: string): Boolean; overload;
    function ContainShortCutItem(ShortCutItem: TShortCutItem): Boolean; overload;
    function InsertShortCutItem(ShortCutType: TShortCutType; ParamType: TParamType; ShortCut, Name, CommandLine: string; Index: Integer): Boolean; overload;
    function InsertShortCutItem(ShortCutItem: TShortCutItem; Index: Integer): Boolean; overload;
    function DeleteShortCutItem(Index: Integer): Boolean; overload;
    function GetShortCutItemIndex(ShortCutItem: TShortCutItem): Integer;
    function GetShortCutItemByShortCut(ShortCut: string; var ShortCutItem: TShortCutItem): Boolean;

    function FilterKeyWord(KeyWord: string; var StringList: TStringList): Boolean;

    //Sort
    function SelectPivot(p, r: Integer): Integer; overload;
    function Partition(var StringList: TStringList; p, r: Integer): Integer; overload;
    procedure QuickSort(var StringList: TStringList; p, r: integer); overload;
    procedure BubbleSort(var StringList: TStringList; p, r: integer); overload;
    function Partition(var StringList: TObjectList; p, r: Integer): Integer; overload;
    procedure QuickSort(var StringList: TObjectList; p, r: integer); overload;
    procedure BubbleSort(var StringList: TObjectList; p, r: integer); overload;

    procedure Sort;

    //Execute
    function Execute(ShortCutItem: TShortCutItem): Boolean; overload;
    function Execute(cmdobj: TCmdObject): Boolean; overload;
    function Execute(ShortCutItem: TShortCutItem; KeyWord: string): Boolean; overload;

    function AddFileShortCut(FileName: string): Boolean;
    function ExtractShortCutItemFromFileName(var ShortCutItem: TShortCutItem; FileName: string): Boolean;
    function ReplaceEnvStr(str: string): string;
    function Test: Boolean;
    procedure PrintStringList(Title: string; StringList: TStringList; p, q: Integer); overload;
    procedure PrintStringList(Title: string; StringList: TObjectList; p, q: Integer); overload;
  end;

var
  ShortCutMan: TShortCutMan;

implementation

uses
  frmShortCut, AnsiStrings;

function ExecuteCmd(cmd: Pointer): LongInt; stdcall;
var
  PCommandStr, PParamStr, PWorkingDir: PChar;
  cmdobj: TCmdObject;
  Regex: TRegExpr;
  strCommand, strTemp: string;
  ret: Integer;
  ShowCmd: Integer;
begin
  cmdobj := TCmdObject(cmd);
  PCommandStr := nil;
  PParamStr := nil;
  PWorkingDir := nil;

  ShowCmd := SW_SHOWNORMAL;
  if Pos(SHOW_MAX_FLAG, cmdobj.Command) = 1 then
  begin
    cmdobj.Command := Trim(CutLeftString(cmdobj.Command, Length(SHOW_MAX_FLAG)));
    ShowCmd := SW_SHOWMAXIMIZED;
  end
  else if Pos(SHOW_MIN_FLAG, cmdobj.Command) = 1 then
  begin
    cmdobj.Command := Trim(CutLeftString(cmdobj.Command, Length(SHOW_MIN_FLAG)));
    ShowCmd := SW_SHOWMINIMIZED;
  end
  else if Pos(SHOW_HIDE_FLAG, cmdobj.Command) = 1 then
  begin
    cmdobj.Command := Trim(CutLeftString(cmdobj.Command, Length(SHOW_HIDE_FLAG)));
    ShowCmd := SW_HIDE
  end;

  //�������·�� ".\", "..\"������У��ͽ��������·������
  if (Pos('.\', cmdobj.Command) > 0) or (Pos('..\', cmdobj.Command) > 0) then
    cmdobj.WorkingDir := ExtractFileDir(Application.ExeName);

  case cmdobj.ParamType of
    ptNone:
      begin
        PCommandStr := PChar(cmdobj.Command);
        PParamStr := nil;
        PWorkingDir := PChar(cmdobj.WorkingDir);
      end;

    ptNoEncoding:
      begin
        //����������в�����־�����滻����
        if Pos(NEW_PARAM_FLAG, cmdobj.Command) > 0 then
        begin
          try
            Regex := TRegExpr.Create;
            Regex.Expression := NEW_PARAM_FLAG;
            cmdobj.Command := Regex.Replace(cmdobj.Command, cmdobj.Param, False);
          finally
            freeandNil(Regex);
          end;

          PCommandStr := PChar(cmdobj.Command);
          PParamStr := nil;
        end
        else if Pos(PARAM_FLAG, cmdobj.Command) > 0 then
        begin
          try
            Regex := TRegExpr.Create;
            Regex.Expression := PARAM_FLAG;
            cmdobj.Command := Regex.Replace(cmdobj.Command, cmdobj.Param, False);
          finally
            Regex.Free;
          end;

          PCommandStr := PChar(cmdobj.Command);
          PParamStr := nil;
        end
        else if Pos(CLIPBOARD_FLAG, cmdobj.Command) > 0 then
        begin
          try
            Regex := TRegExpr.Create;
            Regex.Expression := CLIPBOARD_FLAG;
            cmdobj.Command := Regex.Replace(cmdobj.Command, cmdobj.Param, False);
          finally
            Regex.Free;
          end;

          PCommandStr := PChar(cmdobj.Command);
          PParamStr := nil;
        end
        else if Pos(FOREGROUND_WINDOW_ID_FLAG, cmdobj.Command) > 0 then
        begin
          try
            Regex := TRegExpr.Create;
            Regex.Expression := FOREGROUND_WINDOW_ID_FLAG;
            cmdobj.Command := Regex.Replace(cmdobj.Command, cmdobj.Param, False);
          finally
            Regex.Free;
          end;

          PCommandStr := PChar(cmdobj.Command);
          PParamStr := nil;
        end
        else if Pos(FOREGROUND_WINDOW_TEXT_FLAG, cmdobj.Command) > 0 then
        begin
          try
            Regex := TRegExpr.Create;
            Regex.Expression := FOREGROUND_WINDOW_TEXT_FLAG;
            cmdobj.Command := Regex.Replace(cmdobj.Command, cmdobj.Param, False);
          finally
            Regex.Free;
          end;

          PCommandStr := PChar(cmdobj.Command);
          PParamStr := nil;
        end
        else if Pos(FOREGROUND_WINDOW_CLASS_FLAG, cmdobj.Command) > 0 then
        begin
          try
            Regex := TRegExpr.Create;
            Regex.Expression := FOREGROUND_WINDOW_CLASS_FLAG;
            cmdobj.Command := Regex.Replace(cmdobj.Command, cmdobj.Param, False);
          finally
            Regex.Free;
          end;

//          PCommandStr := PChar(cmdobj.Command);
          PCommandStr := PChar(cmdobj.Command);
          PParamStr := nil;
        end
        else
        begin
//          PCommandStr := PChar(cmdobj.Command);
          PCommandStr := PChar(cmdobj.Command);
          PParamStr := PChar(cmdobj.Param);
        end;

        PWorkingDir := PChar((cmdobj.WorkingDir));
      end;

    ptURLQuery, ptUTF8Query:
      begin
        //����������в�����־�����滻����
        if Pos(NEW_PARAM_FLAG, cmdobj.Command) > 0 then
        begin
          try
            Regex := TRegExpr.Create;
            Regex.Expression := NEW_PARAM_FLAG;
            cmdobj.Command := Regex.Replace(cmdobj.Command, cmdobj.Param, False);
          finally
            Regex.Free;
          end;

          PCommandStr := PChar((cmdobj.Command));
        end
        else if Pos(PARAM_FLAG, cmdobj.Command) > 0 then
        begin
          try
            Regex := TRegExpr.Create;
            Regex.Expression := PARAM_FLAG;
            cmdobj.Command := Regex.Replace(cmdobj.Command, cmdobj.Param, False);
          finally
            Regex.Free;
          end;

          PCommandStr := PChar((cmdobj.Command));
        end
        else if Pos(CLIPBOARD_FLAG, cmdobj.Command) > 0 then
        begin
          try
            Regex := TRegExpr.Create;
            Regex.Expression := CLIPBOARD_FLAG;
            cmdobj.Command := Regex.Replace(cmdobj.Command, cmdobj.Param, False);
          finally
            Regex.Free;
          end;

          PCommandStr := PChar((cmdobj.Command));
        end
        else
        begin
          PCommandStr := PChar((cmdobj.Command + cmdobj.Param));
        end;

        PParamStr := nil;
        PWorkingDir := nil;
      end;
  end;

  //�滻��������
  PCommandStr := PChar(ReplaceEnvStr(string(StrPas(PCommandStr))));

  ret := ShellExecute(GetDesktopWindow, nil, PCommandStr, PParamStr, PWorkingDir, ShowCmd);
  if ret < 33 then
  begin
    TraceMsg('ShellExecute(%s, %s, %s) Failed', [StrPas(PCommandStr), StrPas(PParamStr), StrPas(PWorkingDir)]);

    ret := WinExec(pansichar(ansistring(strpas(PCommandStr))), ShowCmd);
    if ret < 33 then
    begin
      TraceMsg('WinExec(%s) Failed', [StrPas(PCommandStr)]);
      Application.MessageBox(PChar(Format(resCanNotExecute, [StrPas(PCommandStr), StrPas(PParamStr)])), PChar(resWarning), MB_OK + MB_ICONWARNING);
    end;
  end;

  //�ͷŶ���
  cmdobj.Free;
end;

{ TShortCutMan }

procedure TShortCutMan.AppendShortCutItem(ShortCutType: TShortCutType; ShortCut, Name, CommandLine: string);
var
  Item: TShortCutItem;
begin
  Item := TShortCutItem.Create;
  Item.ShortCutType := ShortCutType;
  Item.ShortCut := ShortCut;
  Item.Name := Name;
  Item.CommandLine := CommandLine;

  m_ShortCutList.Add(Item);
end;

function TShortCutMan.AddFileShortCut(FileName: string): Boolean;
var
  ShortCutForm: TShortCutForm;
  Item: TShortCutItem;
  ExistItem: TShortCutItem;
begin
  TraceMsg('AddFileShortCut(%s)', [FileName]);

  Result := False;

  Item := TShortCutItem.Create;
  ShortCutForm := TShortCutForm.Create(nil);

  try
    with ShortCutForm do
    begin
      if not ExtractShortCutItemFromFileName(Item, FileName) then
      begin
        Application.MessageBox(PChar(resGetFileNameFail), PChar(resInfo), MB_OK + MB_ICONINFORMATION + MB_TOPMOST);

        Item.Free;
        Exit;
      end;

      lbledtShortCut.Text := Item.ShortCut;
      lbledtName.Text := Item.Name;
      lbledtCommandLine.Text := Trim(Item.CommandLine);
      rgParam.ItemIndex := 0;

      ShowModal;

      if ModalResult = mrCancel then
      begin
        Item.Free;
        Exit;
      end;

      if (Trim(lbledtShortCut.Text) <> '') and (Trim(lbledtCommandLine.Text) <> '') then
      begin
        Item.ShortCutType := scItem;
        Item.ParamType := TParamType(rgParam.ItemIndex);
        Item.ShortCut := lbledtShortCut.Text;
        Item.Name := lbledtName.Text;
        Item.CommandLine := Trim(lbledtCommandLine.Text);
      end
      else
      begin
        Application.MessageBox(PChar(resBlankLineAdded), PChar(resInfo), MB_OK + MB_ICONINFORMATION + MB_TOPMOST);

        Item.ShortCutType := scBlank;
        Item.ParamType := ptNone;
        Item.ShortCut := '';
        Item.Name := '';
        Item.CommandLine := '';
      end;

      //���·������
      if Pos(LowerCase(ExtractFileDir(Application.ExeName)), LowerCase(Item.CommandLine)) > 0 then
      begin
        if Application.MessageBox(PChar(resRelativePathSuggestion), PChar(resInfo), MB_OKCANCEL + MB_ICONQUESTION + MB_TOPMOST) = IDOK then
        begin
          Item.CommandLine := StringReplace(Item.CommandLine, ExtractFileDir(Application.ExeName), '.', [rfReplaceAll, rfIgnoreCase]);
        end;
      end;

      //�����ظ����򱨴�
      {if ContainShortCutItem(Item) then
      begin
        Application.MessageBox(PChar(resShortCutExisted), PChar(resInfo),
          MB_OK + MB_ICONINFORMATION + MB_TOPMOST);

        //������ͷ�Item���ͻ��ڴ�й¶
        Item.Free;
        Exit;
      end;}

      //����ShortCut��ͬ(����Name��ͬ)������ʾ�Ƿ��滻ԭ�е�
      if (Item.ShortCutType = scItem) and GetShortCutItemByShortCut(Item.ShortCut, ExistItem) then
      begin
        if Application.MessageBox(PChar(Format(resShortCutExisted, [ExistItem.ShortCut, ExistItem.Name, ExistItem.CommandLine])), PChar(resInfo), MB_YESNO + MB_ICONINFORMATION + MB_TOPMOST) = IDYES then
        begin
          CloneShortCutItem(Item, ExistItem);
          Item.Free;
          SaveShortCutList;
          LoadShortCutList(m_ShortCutFileName);
          Exit;
        end
        else
        begin
          Item.Free;
          Exit;
        end;
      end;

      //���Append����Ͳ���Free��Item
      AppendShortCutItem(Item);
      SaveShortCutList;
      LoadShortCutList(m_ShortCutFileName);

      Result := True;
    end;
  finally
    ShortCutForm.Free;
  end;
end;

function TShortCutMan.AddLatestShortCutItem(ShortCutItem: TShortCutItem): Boolean;
var
  ItemIndex: Integer;
begin
  result := false;
  ItemIndex := m_LatestList.IndexOfObject(ShortCutItem);

  //��������Ѿ�������б��У����Ƶ���һ��
  if ItemIndex >= 0 then
    m_LatestList.Move(ItemIndex, 0)
  else
  begin
    //�����ǰ�б��Ѿ�����������ɾ�����һ��
    if m_LatestList.Count >= MAX_LATEST_NUM then
      m_LatestList.Delete(MAX_LATEST_NUM - 1);

    m_LatestList.InsertObject(0, ShortCutItem.Name, ShortCutItem);
  end;
end;

procedure TShortCutMan.AppendShortCutItem(ShortCutItem: TShortCutItem);
begin
  m_ShortCutList.Add(ShortCutItem);
end;

procedure TShortCutMan.BubbleSort(var StringList: TObjectList; p, r: integer);
var
  i, j: Integer;
  Flag: Boolean;
begin
  PrintStringList(Format('Before BubbleSort(%d, %d)', [p, r]), StringList, p, r);

  if (r - p) < 1 then
    Exit;

  if (r - p) = 1 then
    if TShortCutItem(StringList.Items[p]).Rank < TShortCutItem(StringList.Items[r]).Rank then
      StringList.Exchange(p, r);

  if (r - p) > 1 then
    for i := p to r - 1 do
    begin
      Flag := True;
      for j := r - 1 downto i do
        if TShortCutItem(StringList.Items[j + 1]).Rank > TShortCutItem(StringList.Items[j]).Rank then
        begin
          StringList.Exchange(j, j + 1);
          Flag := False;
        end;

      if Flag then
        Exit;
    end;

  PrintStringList(Format('After BubbleSort(%d, %d)', [p, r]), StringList, p, r);
end;

procedure TShortCutMan.CloneShortCutItem(ShortCutItem: TShortCutItem; var NewItem: TShortCutItem);
begin
  if ShortCutItem = nil then
    ShowMessage('Error NIL');

  NewItem.ShortCutType := ShortCutItem.ShortCutType;
  NewItem.ParamType := ShortCutItem.ParamType;
  NewItem.ShortCut := ShortCutItem.ShortCut;
  NewItem.Name := ShortCutItem.Name;
  NewItem.CommandLine := ShortCutItem.CommandLine;
end;

procedure TShortCutMan.CloneShortCutList(SrcList: TShortCutList; var NewList: TShortCutList);
var
  i: Cardinal;
begin
  NewList.Clear;
  if SrcList.Count = 0 then
    Exit;

  for i := 0 to SrcList.Count - 1 do
    NewList.Add(SrcList.Items[i]);
end;

function TShortCutMan.ContainShortCutItem(ShortCutItem: TShortCutItem): Boolean;
var
  i: Cardinal;
  Item: TShortCutItem;
begin
  Result := False;

  //�б�Ϊ�գ���Ȼ������
  if m_ShortCutList.Count = 0 then
    Exit;

  //ֻҪ���ǿ�������ͣ�����
  if ShortCutItem.ShortCutType <> scItem then
    Exit;

  for i := 0 to m_ShortCutList.Count - 1 do
  begin
    Item := TShortCutItem(m_ShortCutList.Items[i]);

    //ȫ��һ�������ǰ�����
    if (Item.ShortCutType = scItem) and (Item.ParamType = ShortCutItem.ParamType) and (Item.ShortCut = ShortCutItem.ShortCut) and (Item.Name = ShortCutItem.Name) and (Item.CommandLine = ShortCutItem.CommandLine) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function TShortCutMan.ContainShortCutItem(ShortCutType: TShortCutType; ParamType: TParamType; ShortCut, Name, CommandLine: string): Boolean;
var
  ShortCutItem: TShortCutItem;
begin
  ShortCutItem := TShortCutItem.Create;
  ShortCutItem.ShortCutType := ShortCutType;
  ShortCutItem.ShortCut := ShortCut;
  ShortCutItem.Name := Name;
  ShortCutItem.CommandLine := CommandLine;
  ShortCutItem.ParamType := ParamType;

  Result := ContainShortCutItem(ShortCutItem);
  ShortCutItem.free;
end;

constructor TShortCutMan.Create;
begin
  //��ʼ��������б��ļ���
  m_ShortCutFileName := ExtractFilePath(Application.ExeName) + SHORTCUT_FILENAME;

  //���������б��ļ������ڣ�д��֮
  m_WriteDefaultShortCutList := True;

  //��ʼ���ļ��޸�ʱ��
  m_FileModifyTime := '';

  //��ʼ���б��Զ��ͷŶ���
  m_ShortCutList := TShortCutList.Create(True);

  m_SortedShortCutList := TStringList.Create;
  m_LatestList := TStringList.Create;

  //��ʼ�������б��ļ���
  m_FavoriteListFileName := ExtractFilePath(Application.ExeName) + FAVOURIT_FILENAME;
  m_FavoriteList := TStringList.Create;
  LoadFavoriteList;

  //������ʽ
  m_Regex := TRegExpr.Create;
end;

function TShortCutMan.DeleteShortCutItem(Index: Integer): Boolean;
var
  ItemIndex: Integer;
begin
  Result := False;

  if (Index < 0) or (Index >= m_ShortCutList.Count) then
    Exit;

  //�������б��а��������ɾ��֮
  ItemIndex := m_LatestList.IndexOfObject(m_ShortCutList.Items[Index]);
  if ItemIndex >= 0 then
    m_LatestList.Delete(ItemIndex);

  m_ShortCutList.Delete(Index);

  SaveShortCutList(m_ShortCutFileName);
  LoadShortCutList(m_ShortCutFileName);

  Result := True;
end;

destructor TShortCutMan.Destroy;
begin
  //���� m_ShortCutFileName
  TraceMsg('Backup the ShortCutFileName file');

  if GetFileSize(m_ShortCutFileName) > 0 then
    CopyFile(PChar(m_ShortCutFileName), PChar(m_ShortCutFileName + '.bak'), False);

  m_Regex.Free;
  m_ShortCutList.Free;
  m_SortedShortCutList.Free;
  m_LatestList.Free;

  SaveFavoriteList;
  m_FavoriteList.Free;
end;

function TShortCutMan.Execute(ShortCutItem: TShortCutItem): Boolean;
var
  str: string;
  cmdobj: TCmdObject;
  FlagPos: Integer;
  TrueCmdFile: string;
begin
  Result := False;

  if ShortCutItem.ShortCutType <> scItem then
    Exit;

  //ע��: ��������������ͷţ���Ҫ���߳������ͷţ�
  cmdobj := TCmdObject.Create;

  //�ȳ�ʼ�����
  cmdobj.Command := '';
  cmdobj.WorkingDir := '';
  cmdobj.Param := '';
  cmdobj.ParamType := ptNone;

  //��ֵ
  cmdobj.Command := ShortCutItem.CommandLine;

  //�滻��������
  cmdobj.Command := ReplaceEnvStr(cmdobj.Command);

  //����"..."�������ļ������Ȱ�ȥ���˵�""
  str := RemoveQuotationMark(Trim(ShortCutItem.CommandLine), '"');

  //����"\\"��ͷ�ģ���Ҫȥ����FileExist�����������
  if Pos('\\', str) <> 1 then
  begin
    if FileExists(str) then
      cmdobj.WorkingDir := ExtractFileDir(str)
    else
    begin
      //���ֵ�ҲҪ��ȷ����
      //"C:\Program Files\Mozilla Firefox\firefox.exe" -Profile "Profiles"
      if str[1] = '"' then
      begin
        //�ȳ�ʼ��Ϊ�հ�
        cmdobj.WorkingDir := '';

        // ȥ����ͷ��"
        TrueCmdFile := Copy(str, 2, Length(str) - 1);

        FlagPos := Pos('"', TrueCmdFile);
        if FlagPos > 0 then
        begin
          //ȡ�õ�һ��"֮ǰ������
          TrueCmdFile := Copy(TrueCmdFile, 1, FlagPos - 1);

          if FileExists(TrueCmdFile) then
          begin
            cmdobj.Command := TrueCmdFile;
            cmdobj.WorkingDir := ExtractFileDir(TrueCmdFile);
            cmdobj.Param := Trim(Copy(str, FlagPos + 2, Length(str) - FlagPos - 1));
          end;

        end;
      end;
    end;
  end;

  if ShortCutItem.ParamType = ptNone then
  begin
    //cmdobj.Param := '';
    //cmdobj.ParamType := ptNone;

    if cmdobj.Param = '' then
      cmdobj.ParamType := ptNone
    else
      cmdobj.ParamType := ptNoEncoding;

    Result := Execute(cmdobj);
  end
  else
  begin
    if Pos(CLIPBOARD_FLAG, cmdobj.Command) > 0 then               // ������
    begin
      cmdobj.Param := m_Param[0];
    end
    else if Pos(FOREGROUND_WINDOW_ID_FLAG, cmdobj.Command) > 0 then    // ǰ̨����ID
    begin
      cmdobj.Param := m_Param[1];
    end
    else if Pos(FOREGROUND_WINDOW_TEXT_FLAG, cmdobj.Command) > 0 then  // ǰ̨����Text
    begin
      cmdobj.Param := m_Param[2];
    end
    else if Pos(FOREGROUND_WINDOW_CLASS_FLAG, cmdobj.Command) > 0 then  // ǰ̨����Class
    begin
      cmdobj.Param := m_Param[3];
    end
    else
    begin
      ParamForm.Caption := ShortCutItem.Name;
      if ParamForm <> nil then
        if ParamForm.ShowModal = mrCancel then
        begin
          cmdobj.Free;
          Exit;
        end;

      cmdobj.Param := ParamForm.cbbParam.Text;
    end;

    cmdobj.ParamType := ShortCutItem.ParamType;

    case ShortCutItem.ParamType of
      ptNoEncoding:
        ;

      ptURLQuery:
        cmdobj.Param := GetURLQueryString(cmdobj.Param);

      ptUTF8Query:
        cmdobj.Param := GetUTF8QueryString(cmdobj.Param);
    end;

    Result := Execute(cmdobj);
  end;
end;

function TShortCutMan.ExtractShortCutItemFromFileName(var ShortCutItem: TShortCutItem; FileName: string): Boolean;
var
  TempFileName: string;
begin
 // Result := False;

  if Trim(FileName) = '' then
  begin
    with ShortCutItem do
    begin
      ShortCutType := scBlank;
      ParamType := ptNone;
      ShortCut := '';
      Name := '';
      CommandLine := '';
    end;
  end
  else
  begin
    //�����LNK��ݷ�ʽ�ļ�������ȡ������ļ�·��
    //Ҫ���ǵ�"....lnk"����ǰ�����"���ļ�
    if (LowerCase(Copy(FileName, Length(FileName) - 3, 4)) = '.lnk') or ((FileName[1] = '"') and (FileName[Length(FileName)] = '"') and (LowerCase(Copy(FileName, Length(FileName) - 4, 4)) = '.lnk')) then
    begin
      TempFileName := ResolveLink(FileName);

      //�е�ʱ�򣬿�ݷ�ʽָ��գ��Ǿ�ֱ�Ӱ������ݷ�ʽ��ɿ����
      //�����������ֽ�������ļ�����ʵû��ֱ�ӵ��ã�����ֱ�ӵ���lnk�ļ�
      //C:\WINDOWS\Installer\{90120000-0011-0000-0000-0000000FF1CE}\wordicon.exe
      if (Trim(TempFileName) <> '') and (Pos(GetEnvironmentVariable('windir') + '\Installer\{', TempFileName) <= 0) then
        FileName := TempFileName;
    end;

    with ShortCutItem do
    begin
      ShortCutType := scItem;
      ParamType := ptNone;
      CommandLine := FileName;
      if Pos('http://', LowerCase(FileName)) = 1 then
      begin
        FileName := Copy(FileName, 8, Length(FileName) - 7);
        if Pos('/', FileName) > 0 then
          ShortCut := Copy(FileName, 1, Pos('/', FileName) - 1)
        else
          ShortCut := FileName;
      end
      else
      begin
        FileName := ExtractFileName(FileName);

        //����ǰ����""���ļ�����Ŀ¼����ɾ������"
        if FileName[Length(FileName)] = '"' then
          FileName := Copy(FileName, 1, Length(FileName) - 1);

        //����Chrome�Ŀ�ݷ�ʽ����
        //"C:\Documents and Settings\cnh31515\Local Settings\Application Data\Google\Chrome\Application\chrome.exe"  --app=http://www.douban.com/group/topic/4876691/
        //ExtractFileName֮����� '//www.douban.com/group/topic/4876691/'
        if (Pos('//', FileName) = 1) then
        begin
          //����https://shit.com֮�����ַ��ExtractFileName֮�����'//shit.com'
          if (FileName[Length(FileName)] = '/') then
            ShortCut := Copy(FileName, 3, Length(FileName) - 3)
          else
            ShortCut := Copy(FileName, 3, Length(FileName) - 2);
        end
        else
        begin
          // ������ļ��У����ļ��н���"1.2ͼƬ"���Ͳ���ȥ�����"��չ�� (.2ͼƬ)"
          if DirectoryExists(RemoveQuotationMark(ShortCutItem.CommandLine, '"')) then
            ShortCut := FileName
          else
            ShortCut := Copy(FileName, 1, Length(FileName) - Length(ExtractFileExt(FileName)));
        end;
      end;

      Name := ShortCut;
    end;
  end;

  Result := True;
end;

procedure TShortCutMan.FillListView(lvw: TListView);
var
  i: Cardinal;
  ShortCutItem: TShortCutItem;
  lvwitm: TListItem;
begin
  lvw.Clear;
  if m_ShortCutList.Count = 0 then
    Exit;

  for i := 0 to m_ShortCutList.Count - 1 do
  begin
    ShortCutItem := TShortCutItem(m_ShortCutList.Items[i]);

    case ShortCutItem.ShortCutType of
      scItem:
        begin
          lvwitm := lvw.Items.Add;
          lvwitm.Caption := ShortCutItem.ShortCut;
          lvwitm.SubItems.Add(ShortCutItem.Name);
          lvwitm.SubItems.Add(ParamTypeToString(ShortCutItem.ParamType));
          lvwitm.SubItems.Add(ShortCutItem.CommandLine);
          lvwitm.Data := Pointer(ShortCutItem.Freq);
          lvwitm.ImageIndex := Ord(siItem);
        end;

      scBlank:
        begin
          lvwitm := lvw.Items.Add;
          lvwitm.Caption := '';
          lvwitm.SubItems.Add('');
          lvwitm.SubItems.Add('');
          lvwitm.SubItems.Add('');
          lvwitm.ImageIndex := Ord(siInfo);
        end;

      scRemark, scOther:
        ;
    else
      ;
    end;
  end;
end;

function TShortCutMan.FilterKeyWord(KeyWord: string; var StringList: TStringList): Boolean;
var
  i: Cardinal;
  Item: TShortCutItem;
  CostTick: Cardinal;
begin
  Result := False;

  CostTick := GetTickCount;

  TraceMsg('FilterKeyWord(%s)', [KeyWord]);

  //��ս���б�
  StringList.Clear;

  //���û�ж������˳�
  if m_SortedShortCutList.Count = 0 then
    Exit;

  //���KeyWordΪ' '�����˳�
  if KeyWord = ' ' then
    Exit;

  //���KeyWordΪ�գ�����ʹ��Ƶ����ʾȫ�����ݣ�����ֻ��ʾ��������
  if KeyWord = '' then
    StringList.Assign(m_SortedShortCutList)
  else
  begin
    KeyWord := LowerCase(KeyWord);

    TraceMsg('FilterKeyWord - 10');

    //���֧��Regex����KeyWord����Ԥ�����Ե�����*���滻Ϊ.*, �Ե�����?���滻Ϊ.?
    if EnableRegex then
    begin
      //----- ����*
      //�Ȱ�.*��ʱ��Ϊ~��@#
      KeyWord := StringReplace(KeyWord, '.*', '~!@#', [rfReplaceAll]);

      //�ٰ�*����Ϊ.*
      KeyWord := StringReplace(KeyWord, '*', '.*', [rfReplaceAll]);

      //����~!@#���.*
      KeyWord := StringReplace(KeyWord, '~!@#', '.*', [rfReplaceAll]);

      //----- ����?
      KeyWord := StringReplace(KeyWord, '?', '.', [rfReplaceAll]);

      //�Ȱ�.?��ʱ��Ϊ~��@#
      //KeyWord:=StringReplace(KeyWord,'.?','~!@#',[rfReplaceAll]);

      //�ٰ�?����Ϊ.?
      //KeyWord:=StringReplace(KeyWord,'?','.?',[rfReplaceAll]);

      //����~!@#���.?
      //KeyWord:=StringReplace(KeyWord,'~!@#','.?',[rfReplaceAll]);
    end;

    TraceMsg('FilterKeyWord - 20, m_SortedShortCutList.Count = %d', [m_SortedShortCutList.Count]);

    for i := 0 to m_SortedShortCutList.Count - 1 do
    begin
      Item := TShortCutItem(m_SortedShortCutList.Objects[i]);

      //���ǿ�������
      if Item.ShortCutType <> scItem then
        Continue;

      //�������̫С������
      if Length(KeyWord) > Length(Item.ShortCut) then
        Continue;

      if EnableRegex then
      begin
        m_Regex.Expression := KeyWord;
        try
          if not m_Regex.Exec(LowerCase(Item.ShortCut)) then
            Continue;
        except
          on E: Exception do
            Continue; // ֱ��������һ��ѭ������
//            Result := False;
        end;

        //��������ͷƥ��
        if (not MatchAnywhere) and (m_Regex.MatchPos[0] > 1) then
          Continue
        else
          Item.Rank := m_Regex.MatchPos[0];
      end
      else
      begin
        Item.Rank := Pos(LowerCase(KeyWord), LowerCase(Item.ShortCut));

        //��������ͷƥ��
        if (not MatchAnywhere) and (Item.Rank > 1) then
          Continue;
      end;

      TraceMsg('FilterKeyWord - 30');

      if Item.Rank > 0 then
      begin
        //��Ȩϵ����Ϊ����ֵ
        //Item.Rank := Item.Rank * 10000 + (Length(Item.ShortCut) - Length(KeyWord));
        //Item.Rank := Item.Rank * 100 + (Length(Item.ShortCut) - Length(KeyWord)) * 2 - Item.Freq * 5;
        Item.Rank := 1024 + Item.Freq * 4 - Item.Rank * 128 - (Length(Item.ShortCut) - Length(KeyWord)) * 16;

        TraceMsg('FilterKeyWord - 40');

        StringList.AddObject(Format(ListFormat, [Item.ShortCut, Item.Name]), TObject(Item));
        //StringList.AddObject(Format('%s - %d/%d (%s)', [Item.ShortCut, Item.Rank, Item.Freq, Item.Name]), TObject(Item));

        TraceMsg('FilterKeyWord - 50');
      end;
    end;

    TraceMsg('FilterKeyWord - 60');

    //��StringList���п�������
    QuickSort(StringList, 0, StringList.Count - 1);
  end;

  TraceMsg('FilterKeyWord - 70');

  //���KeyWord������FavoriteList�ڣ��ҵ�ǰ�б���Ҳ������Ӧ�����ƣ������Ƶ���һ��
  if RememberFavouratMatch then
    if StringList.Count > 0 then
      if m_FavoriteList.IndexOfName(KeyWord) >= 0 then
        for i := 0 to StringList.Count - 1 do
          if m_FavoriteList.Values[KeyWord] = TShortCutItem(StringList.Objects[i]).Name then
          begin
            StringList.Move(i, 0);
            Break;
          end;

  TraceMsg('FilterKeyWord - 80');

  if EnableNumberKey then
    if StringList.Count > 0 then
      for i := 0 to StringList.Count - 1 do
      begin
        if i < 10 then
        begin
          if IndexFrom0to9 then
          begin
            if TShortCutItem(StringList.Objects[i]).ParamType = ptNone then
              StringList.Strings[i] := Format(' %d|%s', [i, StringList.Strings[i]])
            else
              StringList.Strings[i] := Format('*%d|%s', [i, StringList.Strings[i]]);
          end
          else
          begin
            if TShortCutItem(StringList.Objects[i]).ParamType = ptNone then
              StringList.Strings[i] := Format(' %d|%s', [(i + 1) mod 10, StringList.Strings[i]])
            else
              StringList.Strings[i] := Format('*%d|%s', [(i + 1) mod 10, StringList.Strings[i]]);
          end;
        end
        else
          StringList.Strings[i] := Format('  |%s', [StringList.Strings[i]]);
      end;

  CostTick := GetTickCount - CostTick;
  TraceMsg('FilterKeyWord(%s) = %d', [KeyWord, CostTick]);

  TraceMsg('FilterKeyWord - Exit');

  Result := StringList.Count > 0;
end;

function TShortCutMan.GetLatestShortCutIndexList: string;
var
  i: integer;
begin
  Result := '';

  //���û�ж������˳�
  if m_LatestList.Count = 0 then
    Exit;

  //ȡ����Ӧ�Ŀ�ݷ�ʽ
  for i := 0 to m_LatestList.Count - 1 do
  begin
    if m_ShortCutList.IndexOf(m_LatestList.Objects[i]) < 0 then
      Continue;

    Result := Result + IntToStr(m_ShortCutList.IndexOf(m_LatestList.Objects[i]));

    if i < m_LatestList.Count - 1 then
      Result := Result + ', ';
  end;
end;

function TShortCutMan.GetLatestShortCutItemList(var StringList: TStringList): Boolean;
var
  i: Cardinal;
  Item: TShortCutItem;
begin
  Result := False;

  //��ս���б�
  StringList.Clear;

  //���û�ж������˳�
  if m_LatestList.Count = 0 then
    Exit;

  //ȡ����Ӧ�Ŀ�ݷ�ʽ
  for i := 0 to m_LatestList.Count - 1 do
  begin
    if m_LatestList.Objects[i] <> nil then
    begin
      try
        Item := TShortCutItem(m_LatestList.Objects[i]);
        StringList.AddObject(Format(ListFormat, [Item.ShortCut, Item.Name]), TObject(Item));
      except
        TraceErr('StringList.AddObject Error = %d', [i]);
      end;
    end;
  end;

  if EnableNumberKey and (StringList.Count > 0) then
    for i := 0 to StringList.Count - 1 do
    begin
      if i < 10 then
      begin
        if IndexFrom0to9 then
        begin
          if TShortCutItem(StringList.Objects[i]).ParamType = ptNone then
            StringList.Strings[i] := Format(' %d|%s', [i, StringList.Strings[i]])
          else
            StringList.Strings[i] := Format('*%d|%s', [i, StringList.Strings[i]]);
        end
        else
        begin
          if TShortCutItem(StringList.Objects[i]).ParamType = ptNone then
            StringList.Strings[i] := Format(' %d|%s', [(i + 1) mod 10, StringList.Strings[i]])
          else
            StringList.Strings[i] := Format('*%d|%s', [(i + 1) mod 10, StringList.Strings[i]]);
        end;
      end
      else
        StringList.Strings[i] := Format('  |%s', [StringList.Strings[i]]);
    end;
end;

function TShortCutMan.GetParam(Index: Integer): string;
begin
  Result := m_Param[Index];
end;

function TShortCutMan.GetShortCutItemByShortCut(ShortCut: string; var ShortCutItem: TShortCutItem): Boolean;
var
  i: Cardinal;
begin
  Result := False;

  for i := 0 to m_ShortCutList.Count - 1 do
  begin
    ShortCutItem := TShortCutItem(m_ShortCutList.Items[i]);

    if (ShortCutItem.ShortCut = ShortCut) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function TShortCutMan.GetShortCutItemIndex(ShortCutItem: TShortCutItem): Integer;
var
  i: Cardinal;
  Item: TShortCutItem;
begin
  Result := -1;

  for i := 0 to m_ShortCutList.Count - 1 do
  begin
    Item := TShortCutItem(m_ShortCutList.Items[i]);

    if (ShortCutItem.ShortCut = Item.ShortCut) and (ShortCutItem.Name = Item.Name) and (ShortCutItem.CommandLine = Item.CommandLine) then
    begin
      Result := i;
      Break;
    end;
  end;
end;

function TShortCutMan.InsertShortCutItem(ShortCutType: TShortCutType; ParamType: TParamType; ShortCut, Name, CommandLine: string; Index: Integer): Boolean;
var
  Item: TShortCutItem;
begin
  Result := False;

  if (Index < 0) or (Index >= m_ShortCutList.Count) then
    Exit;

  Item := TShortCutItem.Create;
  Item.ShortCutType := ShortCutType;
  Item.ShortCut := ShortCut;
  Item.Name := Name;
  Item.CommandLine := CommandLine;

  m_ShortCutList.Insert(Index, Item);

  Result := True;
end;

procedure TShortCutMan.BubbleSort(var StringList: TStringList; p, r: integer);
var
  i, j: Integer;
  Flag: Boolean;
begin
  PrintStringList(Format('Before BubbleSort(%d, %d)', [p, r]), StringList, p, r);

  if (r - p) < 1 then
    Exit;

  if (r - p) = 1 then
    if TShortCutItem(StringList.Objects[p]).Rank < TShortCutItem(StringList.Objects[r]).Rank then
      StringList.Exchange(p, r);

  if (r - p) > 1 then
    for i := p to r - 1 do
    begin
      Flag := True;
      for j := r - 1 downto i do
        if TShortCutItem(StringList.Objects[j + 1]).Rank > TShortCutItem(StringList.Objects[j]).Rank then
        begin
          StringList.Exchange(j, j + 1);
          Flag := False;
        end;

      if Flag then
        Exit;
    end;

  PrintStringList(Format('After BubbleSort(%d, %d)', [p, r]), StringList, p, r);
end;

function TShortCutMan.InsertShortCutItem(ShortCutItem: TShortCutItem; Index: Integer): Boolean;
begin
  Result := False;

  if (Index < 0) or (Index >= m_ShortCutList.Count) then
    Exit;

  m_ShortCutList.Insert(Index, ShortCutItem);

  Result := True;
end;

function TShortCutMan.LoadFavoriteList: Boolean;
var
  MyFile: TextFile;
  strLine: string;
  ParamItem: TStringList;
begin
  Result := False;

  //���ļ������ڣ���д��ȱʡ����
  if not FileExists(m_FavoriteListFileName) then
  begin
    try
      try
        AssignFile(MyFile, m_FavoriteListFileName);
        ReWrite(MyFile);
      except
        Exit;
      end;
    finally
      CloseFile(MyFile);
    end;
  end;

  //��ȡ������б��ļ�
  try
    try
      AssignFile(MyFile, m_FavoriteListFileName);
      Reset(MyFile);
      ParamItem := TStringList.Create;

      //�����ʷ�б�
      m_FavoriteList.Clear;

      while not Eof(MyFile) do
      begin
        Readln(MyFile, strLine);
        strLine := Trim(strLine);

        SplitString(Trim(strLine), '|', ParamItem);

        m_FavoriteList.Values[Trim(ParamItem[0])] := Trim(ParamItem[1]);
      end;
    except
      Exit;
    end;
  finally
    ParamItem.Free;
    CloseFile(MyFile);
  end;

  Result := True;
end;

procedure TShortCutMan.LoadFromListView(lvw: TListView);
var
  i: Cardinal;
  Item: TShortCutItem;
begin
  m_ShortCutList.Clear;

  if lvw.Items.Count = 0 then
    Exit;

  for i := 0 to lvw.Items.Count - 1 do
  begin
    Item := TShortCutItem.Create;
    StringToParamType(lvw.Items.Item[i].SubItems[1], Item.ParamType);
    Item.ShortCut := lvw.Items.Item[i].Caption;
    Item.Name := lvw.Items.Item[i].SubItems[0];
    Item.CommandLine := lvw.Items.Item[i].SubItems[2];
    Item.Freq := Integer(lvw.Items.Item[i].Data);

    if lvw.Items.Item[i].ImageIndex = Ord(siItem) then
      Item.ShortCutType := scItem
    else
      Item.ShortCutType := scBlank;

    m_ShortCutList.Add(Item);
  end;
end;

function TShortCutMan.LoadShortCutList(FileName: string = ''): Boolean;
var
  MyFile: TextFile;
  strLine: string;
  Item: TShortCutItem;
  NewFileModifyTime: string;
begin
  Result := False;

  //���������գ����滻�ļ���
  if FileName <> '' then
    m_ShortCutFileName := FileName;

  //���ļ���Ϊ�գ��򷵻�
  if Trim(m_ShortCutFileName) = '' then
    Exit;

  //��ʵû��Ҫ���һ���Զ��������Ŀ¼
  {
  //�Զ���������λ��
  CmdDir := ExtractFilePath(Application.ExeName) + CMD_DIR;
  if not DirectoryExists(CmdDir) then CreateDir(CmdDir);
  }

  //���ļ������ڣ���д��ȱʡ����
  if not FileExists(m_ShortCutFileName) then
  begin
    try
      try
        AssignFile(MyFile, m_ShortCutFileName);
        ReWrite(MyFile);

        //д���ļ�ͷ����Ϊ̫�鷳����Ҫ����ļ�ͷ�ˣ�
        //WriteLn(MyFile, '%------------------------------------------------------------------------------%');
        //WriteLn(MyFile, '%Please follow [ShortCut, Name, Command Line], DO NOT rename or delete me      %');
        //WriteLn(MyFile, '%------------------------------------------------------------------------------%');

        //����Ҫд��ʾ��
        if m_WriteDefaultShortCutList then
        begin
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'Computer', resDefault_ShortCut_Name_0, '::{20D04FE0-3AEA-1069-A2D8-08002B30309D}', 100));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'Explorer', resDefault_ShortCut_Name_1, 'explorer.exe /e,::{20D04FE0-3AEA-1069-A2D8-08002B30309D}'));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'MyDocument', resDefault_ShortCut_Name_2, 'explorer.exe'));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'ie', resDefault_ShortCut_Name_3, 'iexplore.exe', 8));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'notepad', resDefault_ShortCut_Name_4, 'notepad', 7));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'mspaint', resDefault_ShortCut_Name_5, 'mspaint'));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNoEncoding, 'cmd', resDefault_ShortCut_Name_6, 'cmd /k %p', 6));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'Calc', resDefault_ShortCut_Name_7, 'calc', 5));

          //��Ϊ������д��WinCtl.exe�����Բ���Ҫ����������¶���
          {
          //���İ�Windows���ǡ���ʾ����.scf����Ӣ�İ���"Show Desktop.scf"��������Բ�֪�������Ըɴ�浽�Լ�Ŀ¼��
          CmdFile := CmdDir + '\Desktop.scf';
          if not FileExists(CmdFile) then
          try
            CmdList := TStringList.Create;
            CmdList.Add('[Shell]');
            CmdList.Add('Command=2');
            CmdList.Add('IconFile=explorer.exe,3');
            CmdList.Add('[Taskbar]');
            CmdList.Add('Command=ToggleDesktop');
            CmdList.SaveToFile(CmdFile);
          finally
            CmdList.Free;
          end;
          }

          //�������ı�Ϊ WinCtl.exe MinAll
          //WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'Desktop', resDefault_ShortCut_Name_8, '.\' + CMD_DIR + '\Desktop.scf'));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'Desktop', resDefault_ShortCut_Name_8, '@.\WinCtl.exe MinAll'));

          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'msconfig', resDefault_ShortCut_Name_9, 'msconfig'));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'Reg', resDefault_ShortCut_Name_10, 'regedt32', 4));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'myip', resDefault_ShortCut_Name_11, 'nslookup'));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'dev', resDefault_ShortCut_Name_12, 'devmgmt.msc'));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'Taskmgr', resDefault_ShortCut_Name_13, 'taskmgr'));
          //WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'ShutDown', resDefault_ShortCut_Name_14, 'tsshutdn 3 /delay:0'));
          //WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'Reboot', resDefault_ShortCut_Name_15, 'tsshutdn 3 /delay:0 /reboot'));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'ShutDown', resDefault_ShortCut_Name_14, 'shutdown /s /t 5'));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'Reboot', resDefault_ShortCut_Name_15, 'shutdown /r /t 5'));
          WriteLn(MyFile, ShortCutItemToString(scBlank));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'Windows', resDefault_ShortCut_Name_16, '%WINDIR%'));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'System32', resDefault_ShortCut_Name_17, '%WINDIR%\System32'));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'ProgramFiles', resDefault_ShortCut_Name_18, '%PROGRAMFILES%'));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'Recent', resDefault_ShortCut_Name_19, '%USERPROFILE%\Recent', 10));
          WriteLn(MyFile, ShortCutItemToString(scBlank));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptURLQuery, 'b', resDefault_ShortCut_Name_20, 'http://www.baidu.com/s?wd=', 12));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptUTF8Query, 'g', resDefault_ShortCut_Name_21, 'http://www.google.com/search?q=', 14));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptURLQuery, 's', resDefault_ShortCut_Name_22, 'http://mp3.sogou.com/music.so?query='));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptURLQuery, 'zd', resDefault_ShortCut_Name_23, 'http://zhidao.baidu.com/q?ct=17&pn=0&tn=ikaslist&rn=10&word=', 9));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptUTF8Query, 'v', resDefault_ShortCut_Name_24, 'http://www.verycd.com/search/folders?kw='));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptUTF8Query, 'y', resDefault_ShortCut_Name_25, 'http://search.yahoo.com/search?p='));
          WriteLn(MyFile, ShortCutItemToString(scBlank));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'Upgrade', resDefault_ShortCut_Name_26, UPGRADE_URL, 15));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'Config', resDefault_ShortCut_Name_27, '.\ALTRun.ini'));
          WriteLn(MyFile, ShortCutItemToString(scBlank));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'AddRemoveProgram', resDefault_ShortCut_Name_28, 'appwiz.cpl', 0));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'ControlPanel', resDefault_ShortCut_Name_29, 'control.exe', 0));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'InternetConnection', resDefault_ShortCut_Name_30, 'control.exe Inetcpl.cpl ,4', 0));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'SystemProperty', resDefault_ShortCut_Name_31, 'Sysdm.cpl', 0));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNoEncoding, 'r', resDefault_ShortCut_Name_32, NEW_PARAM_FLAG, 100));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptURLQuery, 'cb', resDefault_ShortCut_Name_33, 'http://www.baidu.com/s?wd=' + CLIPBOARD_FLAG, 12));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptUTF8Query, 'cg', resDefault_ShortCut_Name_34, 'http://www.google.com/search?q=' + CLIPBOARD_FLAG, 24));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNoEncoding, 'ShowOnly', resDefault_ShortCut_Name_35, '@.\WinCtl.exe ShowOnly ' + FOREGROUND_WINDOW_ID_FLAG, 15));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNoEncoding, 'Hide', resDefault_ShortCut_Name_36, '@.\WinCtl.exe Hide ' + FOREGROUND_WINDOW_ID_FLAG, 20));
          WriteLn(MyFile, ShortCutItemToString(scItem, ptNone, 'UnHide', resDefault_ShortCut_Name_37, '@.\WinCtl.exe UnHide', 20));
        end;
      except
        Exit;
      end;
    finally
      CloseFile(MyFile);
    end;
  end;

  //����ļ�����Ϊ0����ʹ�ñ��ݵ��ļ�
  if GetFileSize(m_ShortCutFileName) = 0 then
  begin
    TraceErr('Size of ShortCutFileName = 0, restore the backup file');

    CopyFile(PChar(m_ShortCutFileName + '.bak'), PChar(m_ShortCutFileName), False);
  end;


  //ȡ���ļ��޸�ʱ��
  NewFileModifyTime := GetFileModifyTime(m_ShortCutFileName);

  //����ļ��޸�ʱ��û�иı䣬�Ͳ���ˢ����
  if m_FileModifyTime = NewFileModifyTime then
    Exit
  else
  begin
    m_FileModifyTime := NewFileModifyTime;
    m_NeedRefresh := True;
  end;


  //��ȡ������б��ļ�
  try
    try
      AssignFile(MyFile, m_ShortCutFileName);
      Reset(MyFile);

      //��տ�����б�
      m_ShortCutList.Clear;

      while not Eof(MyFile) do
      begin
        Readln(MyFile, strLine);
        strLine := Trim(strLine);

        //������һ����˵
        Item := TShortCutItem.Create;

        //������ǰ��
        StringToShortCutItem(strLine, Item);

        case Item.ShortCutType of
          scItem, scBlank:
            m_ShortCutList.Add(TObject(Item));

          scRemark, scOther:
            Item.Free;
        end;
      end;
    except
      Exit;
    end;
  finally
    CloseFile(MyFile);
  end;

  Sort;

  Result := True;
end;

procedure TShortCutMan.ModifyShortCutItem(ShortCutType: TShortCutType; ShortCut, Name, CommandLine: string; Index: Integer);
var
  Item: TShortCutItem;
begin
  Item := TShortCutItem(m_ShortCutList.Items[Index]);

  Item.ShortCutType := ShortCutType;
  Item.ShortCut := ShortCut;
  Item.Name := Name;
  Item.CommandLine := CommandLine;

  SaveShortCutList(m_ShortCutFileName);
  LoadShortCutList(m_ShortCutFileName);
end;

procedure TShortCutMan.ModifyShortCutItem(ShortCutItem: TShortCutItem; Index: Integer);
begin
  with ShortCutItem do
    ModifyShortCutItem(ShortCutType, ShortCut, Name, CommandLine, Index);
end;

function TShortCutMan.ParamTypeToString(ParamType: TParamType): string;
begin
  case ParamType of
    ptNone:
      Result := '';
    ptNoEncoding:
      Result := 'No_Encoding';
    ptURLQuery:
      Result := 'URL_Query';
    ptUTF8Query:
      Result := 'UTF8_Query';
  end;
end;

function TShortCutMan.Partition(var StringList: TObjectList; p, r: Integer): Integer;
var
  PivotIndex, PivotValue: Integer;
  i, j: Integer;
begin
  PrintStringList(Format('Before Partition(%d, %d)', [p, r]), StringList, p, r);

  PivotIndex := SelectPivot(p, r);                     //��L[p..r]��ѡ��һ��֧��Ԫ��pivot
  PivotValue := TShortCutItem(StringList.Items[PivotIndex]).Rank;

  i := p - 1;
  j := r + 1;

  while True do
  begin
    //�ƶ���ָ�룬ע�����ﲻ����whileѭ��
    repeat
      j := j - 1
    until TShortCutItem(StringList.Items[j]).Rank >= PivotValue;

    //�ƶ���ָ�룬ע�����ﲻ����whileѭ��
    repeat
      i := i + 1
    until TShortCutItem(StringList.Items[i]).Rank <= PivotValue;

    if i < j then
      StringList.Exchange(i, j)                        //����L[i]��L[j]
    else if j <> r then
    begin
      Result := j;                                   //����j��ֵ��Ϊ�ָ��
      Break;
    end
    else
    begin
      Result := j - 1;                               //����jǰһλ����Ϊ�ָ��
      Break;
    end;
  end;

  PrintStringList(Format('After Partition(%d, %d) = %d', [p, r, Result]), StringList, p, r);
end;

procedure TShortCutMan.PrintStringList(Title: string; StringList: TObjectList; p, q: Integer);
var
  i: Cardinal;
  Item: TShortCutItem;
begin
  {$ifndef DEBUG_SORT}
  Exit;
  {$endif}

  TraceMsg('  - %s', [Title]);

  for i := p to q do
  begin
    Item := TShortCutItem(StringList.Items[i]);
    with Item do
      TraceMsg('  - [%d] = %d', [i, Freq]);
  end;
end;

function TShortCutMan.Partition(var StringList: TStringList; p, r: Integer): Integer;
var
  PivotIndex, PivotValue: Integer;
  i, j: Integer;
begin
  //Bug
  //3,0,8,2,8,6,1,3,0,8����� PivotIndex = 1������ 3,8,8,2,8,6,1,3,0,0

  PrintStringList(Format('Before Partition(%d, %d)', [p, r]), StringList, p, r);

  PivotIndex := SelectPivot(p, r);                     //��L[p..r]��ѡ��һ��֧��Ԫ��pivot
  PivotValue := TShortCutItem(StringList.Objects[PivotIndex]).Rank;

  i := p - 1;
  j := r + 1;

  while True do
  begin
    //�ƶ���ָ�룬ע�����ﲻ����whileѭ��
    repeat
      j := j - 1
    until TShortCutItem(StringList.Objects[j]).Rank >= PivotValue;

    //�ƶ���ָ�룬ע�����ﲻ����whileѭ��
    repeat
      i := i + 1
    until TShortCutItem(StringList.Objects[i]).Rank <= PivotValue;

    if i < j then
      StringList.Exchange(i, j)                        //����L[i]��L[j]
    else if j <> r then
    begin
      Result := j;                                   //����j��ֵ��Ϊ�ָ��
      Break;
    end
    else
    begin
      Result := j - 1;                               //����jǰһλ����Ϊ�ָ��
      Break;
    end;
  end;

  PrintStringList(Format('After Partition(%d, %d) = %d', [p, r, Result]), StringList, p, r);
end;

procedure TShortCutMan.PrintStringList(Title: string; StringList: TStringList; p, q: Integer);
var
  i: Cardinal;
  Item: TShortCutItem;
begin
  {$ifndef DEBUG_SORT}
  Exit;
  {$endif}

  TraceMsg('  - %s', [Title]);

  for i := p to q do
  begin
    Item := TShortCutItem(StringList.Objects[i]);
    with Item do
      TraceMsg('  - [%d] = %d', [i, Freq]);
  end;
end;

procedure TShortCutMan.QuickSort(var StringList: TObjectList; p, r: integer);
const
  Q_MIN = 12;
var
  q: Integer;
begin
  PrintStringList(Format('Before QuickSort(%d, %d)', [p, r]), StringList, p, r);

  //��L[p..r]�㹻С��ֱ�Ӷ�L[p..r]���в�������
  if r - p <= Q_MIN then
    BubbleSort(StringList, p, r)
  else
  begin
    q := Partition(StringList, p, r);

    //��L[p..r]�ֽ�ΪL[p..q]��L[q+1..r]������
    QuickSort(StringList, p, q);                       //�ݹ�����L[p..q]
    QuickSort(StringList, q + 1, r);                   //�ݹ�����L[q+1..r]
  end;

  PrintStringList(Format('After QuickSort(%d, %d)', [p, r]), StringList, p, r);
end;

procedure TShortCutMan.QuickSort(var StringList: TStringList; p, r: integer);
const
  Q_MIN = 12;
var
  q: Integer;
begin
  PrintStringList(Format('Before QuickSort(%d, %d)', [p, r]), StringList, p, r);

  //��L[p..r]�㹻С��ֱ�Ӷ�L[p..r]���в�������
  if r - p <= Q_MIN then
    BubbleSort(StringList, p, r)
  else
  begin
    q := Partition(StringList, p, r);

    //��L[p..r]�ֽ�ΪL[p..q]��L[q+1..r]������
    QuickSort(StringList, p, q);                       //�ݹ�����L[p..q]
    QuickSort(StringList, q + 1, r);                   //�ݹ�����L[q+1..r]
  end;

  PrintStringList(Format('After QuickSort(%d, %d)', [p, r]), StringList, p, r);
end;

function TShortCutMan.ReplaceEnvStr(str: string): string;
begin
  Result := str;

  m_Regex.Expression := '(%)(.*?)(%)';

  if m_Regex.Exec(str) then
    if GetEnvironmentVariable(m_Regex.Match[2]) <> '' then
      //Result := m_Regex.Replace(str, GetEnvironmentVariable(m_Regex.Match[2]), True);
      Result := StringReplace(str, '%' + m_Regex.Match[2] + '%', GetEnvironmentVariable(m_Regex.Match[2]), [rfReplaceAll]);
end;

function TShortCutMan.SaveFavoriteList: Boolean;
var
  i: Cardinal;
  MyFile: TextFile;
begin
  Result := False;

  //���ļ������ڣ���д��ȱʡ����
  try
    try
      AssignFile(MyFile, m_FavoriteListFileName);
      ReWrite(MyFile);

      if m_FavoriteList.Count > 0 then
        for i := 0 to m_FavoriteList.Count - 1 do
        begin
          WriteLn(MyFile, Format('%-30s|%-30s%', [LowerCase(m_FavoriteList.Names[i]), m_FavoriteList.Values[m_FavoriteList.Names[i]]]));
        end;
    except
      Exit;
    end;
  finally
    CloseFile(MyFile);
  end;
end;

function TShortCutMan.SaveShortCutList(FileName: string = ''): Boolean;
var
  i: Cardinal;
  MyFile: TextFile;
begin
  TraceMsg('SaveShortCutList');

  Result := False;

  //���������գ����滻�ļ���
  if FileName <> '' then
    m_ShortCutFileName := FileName;

  //���ļ���Ϊ�գ��򷵻�
  if Trim(m_ShortCutFileName) = '' then
    Exit;

  //���ļ������ڣ���д��ȱʡ����
  try
    try
      AssignFile(MyFile, m_ShortCutFileName);
      ReWrite(MyFile);

      if m_ShortCutList.Count > 0 then
        for i := 0 to m_ShortCutList.Count - 1 do
        begin
          WriteLn(MyFile, ShortCutItemToString(TShortCutItem(m_ShortCutList.Items[i])));
        end;
    except
      Exit;
    end;
  finally
    CloseFile(MyFile);
  end;
end;

function TShortCutMan.SelectPivot(p, r: Integer): Integer;
begin
  Randomize;
  Result := p + Random(r - p + 1);

  {$ifdef DEBUG_SORT }
  TraceMsg('SelectPivot(%d, %d) = %d', [p, r, Result]);
  {$endif}
end;

function TShortCutMan.SetLatestShortCutIndexList(IndexList: string): Boolean;
var
  i: Cardinal;
  Index: Integer;
  ShortCutIndex: Integer;
begin
  Result := False;

  if Trim(IndexList) = '' then
    Exit;

  SplitString(IndexList, ',', m_LatestList);
  if m_LatestList.Count = 0 then
    Exit;

  //��Ϊ��ʱ��������һ���ַ���','�����±���
  for i := m_LatestList.Count - 1 downto 0 do
    if Trim(m_LatestList.Strings[i]) = '' then
      m_LatestList.Delete(i);

  Index := 0;
  for i := 0 to m_LatestList.Count - 1 do
  begin
    ShortCutIndex := StrToInt(m_LatestList.Strings[i]);
    if (ShortCutIndex >= 0) and (ShortCutIndex <= m_ShortCutList.Count) then
    begin
      m_LatestList.Objects[Index] := m_ShortCutList.Items[ShortCutIndex];
      Inc(Index);
    end;
  end;
end;

procedure TShortCutMan.SetParam(Index: Integer; const Value: string);
begin
  m_Param[Index] := Value;
end;

function TShortCutMan.ShortCutItemToString(ShortCutType: TShortCutType; ParamType: TParamType; ShortCut, Name, CommandLine: string; Freq: Integer): string;
begin
  case ShortCutType of
    scItem:
      Result := Format('F%-8d|%-20s|%-30s|%-30s|%s', [Freq, ParamTypeToString(ParamType), ShortCut, Name, CommandLine]);
    scBlank:
      Result := '';
    scRemark, scOther:
      Result := Name;
  end;
end;

function TShortCutMan.ShortCutItemToString(ShortCutItem: TShortCutItem): string;
begin
  with ShortCutItem do
    Result := ShortCutItemToString(ShortCutType, ParamType, ShortCut, Name, CommandLine, Freq);
end;

procedure TShortCutMan.Sort;
var
  i, j, k: Integer;
  Item: TShortCutItem;
begin
  if m_ShortCutList.Count = 0 then
    Exit;

  m_SortedShortCutList.Clear;

  for i := 0 to m_ShortCutList.Count - 1 do
  begin
    Item := TShortCutItem(m_ShortCutList.Items[i]);

    if Item.ShortCutType = scItem then
    begin
      Item.Rank := Item.Freq * 1000;
      k := 8;
      for j := 1 to Length(Item.ShortCut) do
      begin
        k := k div 2;

        if j > 3 then
          Break
        else
          Item.Rank := Item.Rank - k * (Ord(UpCase(Item.ShortCut[j])) - Ord('A'));
      end;

      Item.Rank := Item.Rank - Length(Item.ShortCut);

      m_SortedShortCutList.AddObject(Format(ListFormat, [Item.ShortCut, Item.Name]), TObject(Item));
    end;
  end;

  //��������
  QuickSort(m_SortedShortCutList, 0, m_SortedShortCutList.Count - 1);
end;

function TShortCutMan.StringToParamType(str: string; var ParamType: TParamType): Boolean;
begin
  Result := True;

  if Trim(str) = '' then
    ParamType := ptNone
  else if LowerCase(Trim(str)) = 'no_encoding' then
    ParamType := ptNoEncoding
  else if LowerCase(Trim(str)) = 'url_query' then
    ParamType := ptURLQuery
  else if LowerCase(Trim(str)) = 'utf8_query' then
    ParamType := ptUTF8Query
  else
    Result := False;
end;

function TShortCutMan.StringToShortCutItem(str: string; var ShortCutItem: TShortCutItem): Boolean;
var
  ShortCutSubItemList: TStringList;
  i, offset: Cardinal;
  CmdPos: Integer;
  strTemp: string;
begin
  //��ȫ�Ƕ����滻Ϊ��Ƕ���
  str := StringReplace(Trim(str), '��', ',', [rfReplaceAll]);

  with ShortCutItem do
  begin
    //Ĭ����Other��Name = strLine
    ShortCutType := scOther;
    ShortCut := '';
    Name := str;
    CommandLine := '';
    Freq := 0;

    //���ǿհ��У���Ӵ���
    if str = '' then
    begin
      ShortCutType := scBlank;
      Result := True;
      Exit;
    end;

    //����ע����
    //if str[1] = '%' then
    //begin
    //  ShortCutType := scRemark;
    //  Result := True;
    //  Exit;
    //end;

    //�����ǲ���Item
    try
      ShortCutSubItemList := TStringList.Create;

      //��ʱ��İ汾��","���ָ�����, �°汾��"|"���ָ�����
      SplitString(str, ',', ShortCutSubItemList);

      //�� explorer.exe /e,::{20D04FE0-3AEA-1069-A2D8-08002B30309D}
      if (ShortCutSubItemList.Count < 3) or (Pos('F', str) = 1) then
        SplitString(str, '|', ShortCutSubItemList);

      if ShortCutSubItemList.Count >= 3 then
      begin
        ShortCutType := scItem;

        //Ϊ�˼̳��ϵ�List�ļ�����Ҫ�жϵ�һ��
        //�����һ����"F"��ͷ��������֣�˵�������°汾���ļ�
        //�����һ��Ϊ�գ�˵��������汾���ļ�
        //�����һ��ǿգ���Ϊ�������ͣ�Ҳ˵��������汾���ļ�
        //��������ϰ汾�ļ�
        //offset��ƫ��

        offset := 0;

        ShortCutSubItemList.Strings[0] := Trim(ShortCutSubItemList.Strings[0]);
        if Length(ShortCutSubItemList.Strings[0]) >= 1 then
          if ShortCutSubItemList.Strings[0][1] = 'F' then
          begin
            //ȥ����ǰ���"F"
            ShortCutSubItemList.Strings[0] := Copy(ShortCutSubItemList.Strings[0], 2, Length(ShortCutSubItemList.Strings[0]) - 1);
            if IsNumericStr(ShortCutSubItemList.Strings[0]) then
            begin
              //��ȡ�99999999����Ҫ�������޷�������
              if Length(ShortCutSubItemList.Strings[0]) > 8 then
                Freq := 10000
              else
                Freq := StrToInt(ShortCutSubItemList.Strings[0]);
            end
            else
              Freq := 0;

            Inc(offset);
          end;

        ParamType := ptNone;
        if StringToParamType(Trim(ShortCutSubItemList.Strings[offset]), ParamType) then
          Inc(offset);

        ShortCut := Trim(ShortCutSubItemList.Strings[offset]);
        Name := Trim(ShortCutSubItemList.Strings[offset + 1]);

        //��ʣ�µĶ�ƴ��һ�����
        //ע�⣬ƴ��һ�𣬲��簴��ԭ��������
        //��http://translate.google.cn/translate_t?hl=zh-CN#en|zh-CN|��������|��

        strTemp := str;
        for i := 0 to offset + 1 do
          strTemp := StringReplace(strTemp, ShortCutSubItemList.Strings[i], '', [rfIgnoreCase]);

        CmdPos := Pos(ShortCutSubItemList.Strings[offset + 2], strTemp);
        CommandLine := Copy(strTemp, CmdPos, Length(strTemp) - CmdPos + 1);

        //CommandLine := '';
        //for i := offset + 2 to ShortCutSubItemList.Count - 1 do
        //  if i = ShortCutSubItemList.Count - 1 then
        //    CommandLine := CommandLine + Trim(ShortCutSubItemList.Strings[i])
        //  else
        //    CommandLine := CommandLine + Trim(ShortCutSubItemList.Strings[i]) + ', ';
      end;
    finally
      ShortCutSubItemList.Free;
    end;
  end;

  Result := True;
end;

function TShortCutMan.Test: Boolean;
begin

  Result := True;
end;

function TShortCutMan.Execute(ShortCutItem: TShortCutItem; KeyWord: string): Boolean;
begin
  m_FavoriteList.Values[LowerCase(KeyWord)] := ShortCutItem.Name;
  AddLatestShortCutItem(ShortCutItem);
  Inc(ShortCutItem.Freq);
  Result := Execute(ShortCutItem);
end;

function TShortCutMan.Execute(cmdobj: TCmdObject): Boolean;
var
  hThread: THandle;
  ThreadID: DWORD;
begin
  Result := False;

  if cmdobj.Command = '' then
    Exit;

  hThread := CreateThread(nil, 0, @ExecuteCmd, Pointer(cmdobj), 0, ThreadID);

  //Count ++
  Inc(ShortCutRunCount);

  if (ShortCutRunCount mod 10000) = 0 then
    Application.MessageBox(PChar(Format(resCongratulations, [ShortCutRunCount])), PChar(resInfo), MB_OK + MB_ICONINFORMATION + MB_TOPMOST);

  Result := hThread > 0;
end;

end.

