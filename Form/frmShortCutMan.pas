unit frmShortCutMan;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ActnList, StdCtrls, ComCtrls, Buttons, ImgList, Menus, ShellAPI,
  untShortCutMan, untUtilities, untALTRunOption, ToolWin, System.ImageList,
  System.Actions, frmShortCut, System.IOUtils;

type
  TShortCutManForm = class(TForm)
    lvShortCut: TListView;
    actlstShortCut: TActionList;
    actAdd: TAction;
    actEdit: TAction;
    actDelete: TAction;
    actClose: TAction;
    btnOK: TBitBtn;
    ilShortCutMan: TImageList;
    pmShortCutMan: TPopupMenu;
    mniCut: TMenuItem;
    mniInsert: TMenuItem;
    mniDelete: TMenuItem;
    tlbShortCutMan: TToolBar;
    btnAdd: TToolButton;
    btnEdit: TToolButton;
    btnDelete: TToolButton;
    btn1: TToolButton;
    btnHelp: TToolButton;
    actHelp: TAction;
    btnClose: TToolButton;
    actCancel: TAction;
    btnCancel: TToolButton;
    actValidate: TAction;
    btnValidate: TToolButton;
    statShortCutMan: TStatusBar;
    btnPathConvert: TToolButton;
    actPathConvert: TAction;
    procedure FormCreate(Sender: TObject);
    procedure MyDrag(var Msg: TWMDropFiles); message WM_DropFiles;
    procedure actAddExecute(Sender: TObject);
    procedure lvShortCutMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure lvShortCutDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure lvShortCutDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure actEditExecute(Sender: TObject);
    procedure actDeleteExecute(Sender: TObject);
    procedure lvShortCutKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure actHelpExecute(Sender: TObject);
    procedure actCloseExecute(Sender: TObject);
    procedure actCancelExecute(Sender: TObject);
    procedure actValidateExecute(Sender: TObject);
    procedure lvShortCutEdited(Sender: TObject; Item: TListItem; var S: string);
    procedure lvShortCutEditing(Sender: TObject; Item: TListItem; var AllowEdit: Boolean);
    procedure actPathConvertExecute(Sender: TObject);
    procedure lvShortCutClick(Sender: TObject);
  private
    //m_ShortCutList: TShortCutList;
    m_SrcItem: TListItem;

    function ExistListItem(itm: TListItem): Boolean;
    procedure LoadShortCutList;
    function IsValidCommandLine(strCommandLine: string): Boolean;
  public
    function ProcessShortCutForm(AForm: TShortCutForm; AMode: string; AShortCutItem: TShortCutItem = nil): Boolean;
    procedure AddOrUpdateListItem(AForm: TShortCutForm; AMode: string; AInsertIndex: Integer = -1);
    //
    function NormalizePath(const ACommandLine: string; AResolveRelative: Boolean = True): string;
    function CheckPathValidity(const APath: string): Boolean;
    function ConvertPath(const ACommandLine: string; AToRelative: Boolean): string;
  private
    function GetDPIScaledWidth(AWidth: Integer; ToPhysical: Boolean): Integer;
  end;

var
  ShortCutManForm: TShortCutManForm;

implementation
{$R *.dfm}

uses
  frmInvalid, untLogger, untStringAlign, math;
{ 新的公共方法：处理 TShortCutForm 的初始化、显示和数据提取 }

function TShortCutManForm.ProcessShortCutForm(AForm: TShortCutForm; AMode: string; AShortCutItem: TShortCutItem = nil): Boolean;
var
  ParamType: TParamType;
begin
  Result := False;
  try
    // 初始化表单
    if AMode = 'Add' then
    begin
      AForm.lbledtShortCut.Clear;
      AForm.lbledtName.Clear;
      AForm.lbledtCommandLine.Clear;
      AForm.rgParam.ItemIndex := 0;
      AForm.cb_RunAsAdmin.Checked := False;
    end
    else if AMode = 'Edit' then
    begin
      AForm.lbledtShortCut.Text := lvShortCut.Selected.Caption;
      AForm.lbledtName.Text := lvShortCut.Selected.SubItems[0];
      AForm.cb_RunAsAdmin.Checked := ShortCutMan.StringToRunAs(lvShortCut.Selected.SubItems[2]);
      AForm.lbledtCommandLine.Text := lvShortCut.Selected.SubItems[3];
      ShortCutMan.StringToParamType(lvShortCut.Selected.SubItems[1], ParamType);
      AForm.rgParam.ItemIndex := Ord(ParamType);
    end
    else if AMode = 'Drag' then
    begin
      if AShortCutItem = nil then
        Exit;
      AForm.lbledtShortCut.Text := AShortCutItem.ShortCut;
      AForm.lbledtName.Text := AShortCutItem.Name;
      AForm.lbledtCommandLine.Text := AShortCutItem.CommandLine;
      AForm.rgParam.ItemIndex := 0;
      AForm.cb_RunAsAdmin.Checked := AShortCutItem.RunAsAdmin;
    end;

    // 显示表单
    AForm.ShowModal;
    Result := AForm.ModalResult = mrOk;
  finally
    // 调用者负责释放 AForm
  end;
end;

{ 新的公共方法：处理 TListItem 的创建、更新、重复检查和显示 }
procedure TShortCutManForm.AddOrUpdateListItem(AForm: TShortCutForm; AMode: string; AInsertIndex: Integer = -1);
var
  ListItem: TListItem;
  Success: Boolean;
  MinColumnWidth: Integer;
begin
  Success := False;
  ListItem := TListItem.Create(lvShortCut.Items);
  try
    // 设置 ListItem 属性
    if (Trim(AForm.lbledtShortCut.Text) <> '') and (Trim(AForm.lbledtCommandLine.Text) <> '') then
    begin
      ListItem.Caption := AForm.lbledtShortCut.Text;
      ListItem.SubItems.Add(AForm.lbledtName.Text);
      ListItem.SubItems.Add(ShortCutMan.ParamTypeToString(TParamType(AForm.rgParam.ItemIndex)));
      ListItem.SubItems.Add(ShortCutMan.RunAsToString(AForm.cb_RunAsAdmin.Checked));
      ListItem.SubItems.Add(AForm.lbledtCommandLine.Text);
      ListItem.ImageIndex := Ord(siItem);
    end
    else
    begin
      ListItem.Caption := '';
      ListItem.SubItems.Add('');
      ListItem.SubItems.Add('');
      ListItem.SubItems.Add('');
      ListItem.SubItems.Add('');
      ListItem.ImageIndex := Ord(siInfo);
    end;


    // 检查重复
    if ExistListItem(ListItem) then
    begin
      Application.MessageBox('This ShortCut has already existed!', PChar(resInfo), MB_OK + MB_ICONINFORMATION + MB_TOPMOST);
      Exit;
    end;

    // 添加或更新
    if AMode = 'Edit' then
    begin
      lvShortCut.Selected.Caption := ListItem.Caption;
      lvShortCut.Selected.SubItems[0] := ListItem.SubItems[0];
      lvShortCut.Selected.SubItems[1] := ListItem.SubItems[1];
      lvShortCut.Selected.SubItems[2] := ListItem.SubItems[2];
      lvShortCut.Selected.SubItems[3] := ListItem.SubItems[3];
      lvShortCut.Selected.ImageIndex := ListItem.ImageIndex;
    end
    else
    begin
      //如果没有选中，就加到最后一行，否则就插入选中的位置
      if AInsertIndex < 0 then
        lvShortCut.Items.AddItem(ListItem)
      else
        lvShortCut.Items.AddItem(ListItem, AInsertIndex);
    end;

    // 更新显示
    lvShortCut.SetFocus;
    ListItem.Selected := True;
    ListItem.MakeVisible(True);

    //如果Caption只是一个字母，如"a"，则当时不显示，只好处理一下才能刷新显示
    // 恢复原始 Caption workaround
    ListItem.Caption := ListItem.Caption + ' ';
    ListItem.Caption := AForm.lbledtShortCut.Text;

    // 确保第一列宽度足够（可选，保留以防万一）
    lvShortCut.Canvas.Font.Assign(lvShortCut.Font); // 确保使用 TListView 的字体
    // 213  设置最大宽度限制
    MinColumnWidth := min(lvShortCut.Canvas.TextWidth(ListItem.Caption + '    ') + 20, 213);
    if lvShortCut.Columns[0].Width < MinColumnWidth then
      lvShortCut.Columns[0].Width := MinColumnWidth;

    // 简化刷新，模拟原始代码行为
    lvShortCut.Update; // 仅调用 Update，匹配原始代码的隐式刷新
    Success := True;
  finally
    // 仅在未成功添加或更新时释放 ListItem
    if not Success then
      FreeAndNil(ListItem);
  end;
end;

procedure TShortCutManForm.actAddExecute(Sender: TObject);
var
  ShortCutForm: TShortCutForm;
begin
  ShortCutForm := TShortCutForm.Create(Self);
  try
    if not ProcessShortCutForm(ShortCutForm, 'Add') then
      Exit;
    AddOrUpdateListItem(ShortCutForm, 'Add', lvShortCut.Items.Count);
  finally
    FreeAndNil(ShortCutForm);
  end;
end;

procedure TShortCutManForm.actEditExecute(Sender: TObject);
var
  ShortCutForm: TShortCutForm;
begin
  if (lvShortCut.ItemIndex < 0) or (lvShortCut.Selected.ImageIndex <> Ord(siItem)) then
    Exit;

  ShortCutForm := TShortCutForm.Create(Self);
  try
    if not ProcessShortCutForm(ShortCutForm, 'Edit') then
      Exit;
    AddOrUpdateListItem(ShortCutForm, 'Edit');
  finally
    FreeAndNil(ShortCutForm);
  end;
end;


{ 新增：规范化路径，处理前导标志、环境变量和相对路径 }
function TShortCutManForm.NormalizePath(const ACommandLine: string; AResolveRelative: Boolean = True): string;
var
  ResultPath: string;
begin
  ResultPath := ACommandLine;

  // 移除前导标志（如 @, @+, @-）
  if Pos(SHOW_MAX_FLAG, ResultPath) = 1 then
    ResultPath := Copy(ResultPath, Length(SHOW_MAX_FLAG) + 1, MaxInt)
  else if Pos(SHOW_MIN_FLAG, ResultPath) = 1 then
    ResultPath := Copy(ResultPath, Length(SHOW_MIN_FLAG) + 1, MaxInt)
  else if Pos(SHOW_HIDE_FLAG, ResultPath) = 1 then
    ResultPath := Copy(ResultPath, Length(SHOW_HIDE_FLAG) + 1, MaxInt);

  // 替换环境变量
  ResultPath := ShortCutMan.ReplaceEnvStr(ResultPath);

  // 处理相对路径（.\ 开头）
  if AResolveRelative and (Pos('.\', ResultPath) = 1) then
    ResultPath := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(Application.ExeName), Copy(ResultPath, 3, MaxInt)));

  Result := ResultPath;
end;

{ 新增：检查路径有效性（文件或文件夹是否存在） }
function TShortCutManForm.CheckPathValidity(const APath: string): Boolean;
var
  CleanPath: string;
begin
  // 跳过网络路径
  if Pos('\\', APath) > 0 then
    Exit(True);

  // 没有反斜杠，认为是命令而非路径，跳过检查
  if Pos('\', APath) = 0 then
    Exit(True);

  // 移除引号
  CleanPath := RemoveQuotationMark(APath, '"');

  // 检查文件或文件夹是否存在
  Result := TPath.IsPathRooted(CleanPath) and (TFile.Exists(CleanPath) or TDirectory.Exists(CleanPath));
end;

{ 新增：转换路径（绝对 <-> 相对） }
function TShortCutManForm.ConvertPath(const ACommandLine: string; AToRelative: Boolean): string;
var
  AppDir: string;
begin
  Result := ACommandLine;
  AppDir := TPath.GetDirectoryName(Application.ExeName);

  if AToRelative then
  begin
    // 绝对路径 -> 相对路径
    if Pos(LowerCase(AppDir), LowerCase(ACommandLine)) > 1 then
      Result := StringReplace(ACommandLine, AppDir, '.', [rfReplaceAll, rfIgnoreCase]);
  end
  else
  begin
    // 相对路径 -> 绝对路径
    if Pos('.\', LowerCase(ACommandLine)) > 0 then
      Result := StringReplace(ACommandLine, '.\', AppDir + '\', [rfReplaceAll, rfIgnoreCase]);
  end;
end;

procedure TShortCutManForm.actCancelExecute(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TShortCutManForm.actCloseExecute(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TShortCutManForm.actDeleteExecute(Sender: TObject);
begin
  if lvShortCut.ItemIndex < 0 then
    Exit;

  if lvShortCut.Selected.Caption = '' then
  begin
    if Application.MessageBox(PChar(resDeleteBlankLine), PChar(resInfo), MB_OKCANCEL + MB_ICONQUESTION + MB_TOPMOST) = IDOK then
      lvShortCut.DeleteSelected;
  end
  else
  begin
    if Application.MessageBox(PChar(Format(PChar(resDeleteConfirm), [lvShortCut.Selected.Caption, lvShortCut.Selected.SubItems[0]])), PChar(resInfo), MB_OKCANCEL + MB_ICONQUESTION + MB_TOPMOST) = IDOK then
      lvShortCut.DeleteSelected;
  end;
end;

procedure TShortCutManForm.actHelpExecute(Sender: TObject);
begin
  if IsValidCommandLine('"C:\Program Files\ChromePlus\chrome.exe" ".\Shit.txt"') then
    ShowMessage('Good');
end;

procedure TShortCutManForm.actValidateExecute(Sender: TObject);
var
  i: Cardinal;
  InvalidForm: TInvalidForm;
  lvwitm: TListItem;
  CommandLine: string;
begin
  if lvShortCut.Items.Count = 0 then
    Exit;

  //看看是否真的需要
  if Application.MessageBox(PChar(resValidateConfirm), PChar(resInfo), MB_YESNO + MB_ICONQUESTION + MB_TOPMOST) = IDNO then
  begin
    Exit;
  end;

  try
    InvalidForm := TInvalidForm.Create(Self);

    Screen.Cursor := crHourGlass;

    for i := 0 to lvShortCut.Items.Count - 1 do
    begin
      //解析出快捷项
      CommandLine := lvShortCut.Items.Item[i].SubItems[2];

      if not IsValidCommandLine(CommandLine) then
      begin
        lvwitm := InvalidForm.lvShortCut.Items.Add;

        lvwitm.Caption := lvShortCut.Items.Item[i].Caption;
        lvwitm.SubItems.Add(lvShortCut.Items.Item[i].SubItems[0]);
        lvwitm.SubItems.Add(lvShortCut.Items.Item[i].SubItems[1]);
        lvwitm.SubItems.Add(lvShortCut.Items.Item[i].SubItems[2]);
        lvwitm.SubItems.Add(lvShortCut.Items.Item[i].SubItems[3]);
        lvwitm.ImageIndex := Ord(siItem);
        lvwitm.Checked := True;

        //保存Index
        lvwitm.Data := Pointer(i);
      end;
    end;

    Screen.Cursor := crDefault;

    //若没有找到有问题的项目，则退出
    if InvalidForm.lvShortCut.Items.Count = 0 then
    begin
      Application.MessageBox(PChar(resNoInvalidShortCut), PChar(resInfo), MB_OK + MB_ICONINFORMATION + MB_TOPMOST);
      Exit;
    end;

    InvalidForm.ShowModal;

    if InvalidForm.ModalResult = mrCancel then
      Exit;

    //将选中的都删除
    for i := InvalidForm.lvShortCut.Items.Count - 1 downto 0 do
    begin
      if not InvalidForm.lvShortCut.Items[i].Checked then
        Continue;

      lvShortCut.Items.Delete(Integer(InvalidForm.lvShortCut.Items[i].Data));
    end;
  finally
    FreeAndNil(InvalidForm);
  end;
end;

function TShortCutManForm.IsValidCommandLine(strCommandLine: string): Boolean;
var
  CleanPath: string;
  SlashPos: Integer;
  i: Integer;
begin
  // 默认有效
  Result := True;

  // 规范化路径（移除标志、替换环境变量、处理相对路径）
  strCommandLine := NormalizePath(strCommandLine);

  // 检查路径有效性
  if not CheckPathValidity(strCommandLine) then
  begin
    // 尝试解析带参数的路径
    CleanPath := RemoveQuotationMark(strCommandLine, '"');
    if CleanPath <> strCommandLine then
    begin
      // 带引号路径，重新检查
      Result := TFile.Exists(CleanPath) or TDirectory.Exists(CleanPath);
      if Result then
        Exit;
    end;

    // 查找最后一个反斜杠，检查目录
    SlashPos := 0;
    for i := Length(strCommandLine) downto 1 do
      if strCommandLine[i] = '\' then
      begin
        SlashPos := i;
        Break;
      end;

    if SlashPos > 0 then
    begin
      CleanPath := Copy(strCommandLine, 1, SlashPos);
      if strCommandLine[1] = '"' then
        CleanPath := Copy(CleanPath, 2, SlashPos - 1);
      Result := TDirectory.Exists(CleanPath);
    end;

    // 最后尝试解析带引号的路径
    if not Result and (strCommandLine[1] = '"') then
    begin
      CleanPath := Copy(strCommandLine, 2, Pos('"', Copy(strCommandLine, 2, MaxInt)) - 1);
      Result := TFile.Exists(CleanPath) or TDirectory.Exists(CleanPath);
    end;
  end;
end;

procedure TShortCutManForm.actPathConvertExecute(Sender: TObject);
var
  i, Count: Cardinal;
  CommandLine: string;
  IsAbsoluteToRelative: Boolean;
begin
  IsAbsoluteToRelative := False;
  // 用户确认
  case Application.MessageBox(PChar(Format(resPathConvertConfirm, [#13#10, #13#10])), PChar(resInfo), MB_YESNOCANCEL + MB_ICONQUESTION + MB_TOPMOST) of
    IDCANCEL:
      Exit;
    IDYES:
      IsAbsoluteToRelative := True;
    IDNO:
      IsAbsoluteToRelative := False;
  end;

  Screen.Cursor := crHourGlass;
  try
    Count := 0;
    for i := 0 to lvShortCut.Items.Count - 1 do
    begin
      CommandLine := lvShortCut.Items.Item[i].SubItems[3];
      CommandLine := ConvertPath(CommandLine, IsAbsoluteToRelative);
      if CommandLine <> lvShortCut.Items.Item[i].SubItems[3] then
      begin
        Inc(Count);
        lvShortCut.Items.Item[i].SubItems[3] := CommandLine;
      end;
    end;

    Application.MessageBox(PChar(Format(resConvertFinished, [Count])), PChar(resInfo), MB_OK + MB_ICONINFORMATION + MB_TOPMOST);
  finally
    Screen.Cursor := crDefault;
  end;
end;

function TShortCutManForm.ExistListItem(itm: TListItem): Boolean;
var
  i: Cardinal;
begin
  Result := False;

  if lvShortCut.Items.Count = 0 then
    Exit;

  //若是空行
  if itm.Caption = '' then
    Exit;

  for i := 0 to lvShortCut.Items.Count - 1 do
    with lvShortCut.Items.Item[i] do
      if (itm.Caption = Caption) and (itm.SubItems[0] = SubItems[0]) and (itm.SubItems[1] = SubItems[1]) and (itm.SubItems[2] = SubItems[2]) then
      begin
        Result := True;
        Exit;
      end;
end;

function TShortCutManForm.GetDPIScaledWidth(AWidth: Integer; ToPhysical: Boolean): Integer;
var
  ScaleFactor: Double;
begin
  ScaleFactor := Screen.PixelsPerInch / 96; // 125% DPI 时，ScaleFactor = 120 / 96 = 1.25
  if ToPhysical then
    Result := Round(AWidth * ScaleFactor) // 逻辑像素 -> 物理像素
  else
    Result := Round(AWidth / ScaleFactor); // 物理像素 -> 逻辑像素
end;

procedure TShortCutManForm.FormCreate(Sender: TObject);
begin

  tlbShortCutMan.DoubleBuffered := false;
  tlbShortCutMan.ParentDoubleBuffered := false;
  tlbShortCutMan.Transparent := False;
  tlbShortCutMan.Flat := True;
  tlbShortCutMan.ShowCaptions := True;
  tlbShortCutMan.List := False; // 关闭List模式，避免兼容性问题

  // Disable Close Button
  EnableMenuItem(GetSystemMenu(Self.Handle, False), SC_CLOSE, MF_GRAYED);

  Self.DoubleBuffered := false;
  Self.Caption := resShortCutManFormCaption;
  btnAdd.Caption := resBtnAdd;
  btnEdit.Caption := resBtnEdit;
  btnDelete.Caption := resBtnDelete;
  btnPathConvert.Caption := resBtnPathConvert;
  btnValidate.Caption := resBtnValidate;
  btnHelp.Caption := resBtnHelp;
  btnClose.Caption := resBtnClose;
  btnCancel.Caption := resBtnCancel;

  btnAdd.Hint := resBtnAddHint;
  btnEdit.Hint := resBtnEditHint;
  btnDelete.Hint := resBtnDeleteHint;
  btnValidate.Hint := resBtnValidateHint;
  btnHelp.Hint := resBtnHelpHint;
  btnClose.Hint := resBtnCloseHint;
  btnCancel.Hint := resBtnCancelHint;

  lvShortCut.Columns.Items[0].Caption := resShortCut;
  lvShortCut.Columns.Items[1].Caption := resName;
  lvShortCut.Columns.Items[2].Caption := resParamType;
  lvShortCut.Columns.Items[3].Caption := resRunAsAdmin;
  lvShortCut.Columns.Items[4].Caption := resCommandLine;

  actAdd.Caption := resBtnAdd;
  actEdit.Caption := resBtnEdit;
  actDelete.Caption := resBtnDelete;

  DragAcceptFiles(Handle, True);
  LoadShortCutList;
end;

procedure TShortCutManForm.FormShow(Sender: TObject);
var
  i: Cardinal;
begin
  begin
    ManColWidth[0] := 213; // 默认宽度
    ManColWidth[1] := 172;
    ManColWidth[2] := 105;
    ManColWidth[3] := 125;
    ManColWidth[4] := 973;
  end;


  //设置窗体位置
  LoadSettings;

  if (ManWinTop = 0) and (ManWinLeft = 0) then
  begin
    try
      Self.Position := poScreenCenter;
    except
      //不用Except，就会蹦出来“Cannot change Visible in OnShow or OnHide”的报错
    end;
  end
  else
  begin
    Self.Top := ManWinTop;
    Self.Left := ManWinLeft;
    Self.Width := ManWinWidth;
    Self.Height := ManWinHeight;
  end;


   // 加载列宽（逻辑像素 -> 物理像素）
  for i := 0 to lvShortCut.Columns.Count - 1 do
    lvShortCut.Columns.Items[i].Width := ManColWidth[i];

end;

procedure TShortCutManForm.FormDestroy(Sender: TObject);
var
  i: Cardinal;
begin

  ManWinTop := Self.Top;
  ManWinLeft := Self.Left;
  ManWinWidth := Self.Width;
  ManWinHeight := Self.Height;


  // 保存列宽（物理像素 -> 逻辑像素）
  for i := 0 to lvShortCut.Columns.Count - 1 do
    ManColWidth[i] := GetDPIScaledWidth(lvShortCut.Columns.Items[i].Width, false);

  SaveSettings;
end;

procedure TShortCutManForm.LoadShortCutList;
begin
  ShortCutMan.FillListView(lvShortCut);
end;

procedure TShortCutManForm.lvShortCutClick(Sender: TObject);
var
  item: TListItem;
begin
  item := lvshortCut.Selected;
  if item <> nil then
  begin
    statShortCutMan.simpleText := FormatAligned(item.SubItems[0], 60) + '   ' + item.SubItems[3];
  end;
end;

procedure TShortCutManForm.lvShortCutDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  tempItem1, tempItem2: TListItem;
begin
  begin
    //如果拖到不是列表项的地方，就退出
    if lvShortCut.GetItemAt(X, Y) = nil then
      Exit;

    tempItem1 := lvShortCut.GetItemAt(X, Y);
    tempItem2 := lvShortCut.Items.Insert(tempItem1.index);
    tempItem2.Caption := m_SrcItem.Caption;
    tempItem2.SubItems.Add(m_SrcItem.SubItems[0]);
    tempItem2.SubItems.Add(m_SrcItem.SubItems[1]);
    tempItem2.SubItems.Add(m_SrcItem.SubItems[2]);
    tempItem2.SubItems.Add(m_SrcItem.SubItems[3]);
    tempItem2.ImageIndex := m_SrcItem.ImageIndex;

    m_SrcItem.Delete;
    lvShortCut.Refresh;
  end;
end;

procedure TShortCutManForm.lvShortCutDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
begin
  Accept := True;
end;

procedure TShortCutManForm.lvShortCutEdited(Sender: TObject; Item: TListItem; var S: string);
begin
  btnOK.Default := True;
end;

procedure TShortCutManForm.lvShortCutEditing(Sender: TObject; Item: TListItem; var AllowEdit: Boolean);
begin
  btnOK.Default := False;
end;

procedure TShortCutManForm.lvShortCutKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_F2:
      actEditExecute(Sender);

    VK_INSERT:
      actAddExecute(Sender);

    VK_DELETE:
      actDeleteExecute(Sender);
  end;
end;

procedure TShortCutManForm.lvShortCutMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  m_SrcItem := lvShortCut.GetItemAt(X, Y);
end;

procedure TShortCutManForm.MyDrag(var Msg: TWMDropFiles);
var
  hDrop: Cardinal;
  FileName: string;
  ShortCutForm: TShortCutForm;
  ShortCutItem: TShortCutItem;
begin
  hDrop := Msg.Drop;
  FileName := GetDragFileName(hDrop);
  ShortCutForm := TShortCutForm.Create(Self);
  ShortCutItem := TShortCutItem.Create;
  try
    if not ShortCutMan.ExtractShortCutItemFromFileName(ShortCutItem, FileName) then
    begin
      Application.MessageBox('Can not get file name!', 'Info', MB_OK + MB_ICONINFORMATION + MB_TOPMOST);
      Exit;
    end;

    if not ProcessShortCutForm(ShortCutForm, 'Drag', ShortCutItem) then
      Exit;
    AddOrUpdateListItem(ShortCutForm, 'Add', lvShortCut.ItemIndex);
  finally
    FreeAndNil(ShortCutItem);
    FreeAndNil(ShortCutForm);
    DragFinish(hDrop);
  end;
  Msg.Result := 0;
end;

end.

