unit frmShortCutMan;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ActnList, StdCtrls, ComCtrls, Buttons, ImgList, Menus, ShellAPI,
  untShortCutMan, untUtilities, untALTRunOption, ToolWin, System.ImageList,
  System.Actions;

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
    btnCancel0: TBitBtn;
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
    procedure lvShortCutKeyPress(Sender: TObject; var Key: Char);
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
    procedure lvShortCutColumnClick(Sender: TObject; Column: TListColumn);
  private
    //m_ShortCutList: TShortCutList;
    m_SrcItem: TListItem;

    function ExistListItem(itm: TListItem): Boolean;
    procedure LoadShortCutList;
    function IsValidCommandLine(strCommandLine: string): Boolean;
  public
    { Public declarations }
  end;

var
  ShortCutManForm: TShortCutManForm;

implementation
{$R *.dfm}

uses
  frmShortCut, frmInvalid;

procedure TShortCutManForm.actAddExecute(Sender: TObject);
var
  ShortCutForm: TShortCutForm;
  ListItem: TListItem;
begin
  ShortCutForm := nil;
  try
    ShortCutForm := TShortCutForm.Create(Self);
    with ShortCutForm do
    begin
      lbledtShortCut.Clear;
      lbledtName.Clear;
      lbledtCommandLine.Clear;
      rgParam.ItemIndex := 0;

      ShowModal;

      if ModalResult = mrCancel then
        Exit;

      ListItem := TListItem.Create(lvShortCut.Items);

      if (Trim(lbledtShortCut.Text) <> '') and (Trim(lbledtCommandLine.Text) <> '') then
      begin
        ListItem.Caption := lbledtShortCut.Text;
        ListItem.SubItems.Add(lbledtName.Text);
        ListItem.SubItems.Add(ShortCutMan.ParamTypeToString(TParamType(rgParam.ItemIndex)));
        ListItem.SubItems.Add(lbledtCommandLine.Text);
        ListItem.ImageIndex := Ord(siItem);
      end
      else
      begin
        ListItem.Caption := '';
        ListItem.SubItems.Add('');
        ListItem.SubItems.Add('');
        ListItem.SubItems.Add('');
        ListItem.ImageIndex := Ord(siInfo);
      end;

      //�����ظ����򱨴�
      if ExistListItem(ListItem) then
      begin
        Application.MessageBox('This ShortCut has already existed!', PChar(resInfo), MB_OK + MB_ICONINFORMATION + MB_TOPMOST);

        ListItem.Free;
        Exit;
      end;

      //���û��ѡ�У��ͼӵ����һ�У�����Ͳ���ѡ�е�λ��
      if lvShortCut.ItemIndex < 0 then
        ListItem := lvShortCut.Items.AddItem(ListItem)
      else
        ListItem := lvShortCut.Items.AddItem(ListItem, lvShortCut.ItemIndex);

      //ʹ��ɼ�
      lvShortCut.SetFocus;
      ListItem.Selected := True;
      ListItem.MakeVisible(True);

      //���Captionֻ��һ����ĸ����"a"����ʱ����ʾ��ֻ�ô���һ�²���ˢ����ʾ
      ListItem.Caption := lbledtShortCut.Text + ' ';
      ListItem.Caption := lbledtShortCut.Text;
    end;
  finally
    freeAndNil(ShortCutForm);
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

procedure TShortCutManForm.actEditExecute(Sender: TObject);
var
  ShortCutForm: TShortCutForm;
  itm: TListItem;
  ParamType: TParamType;
begin
  if lvShortCut.ItemIndex < 0 then
    Exit;
  if lvShortCut.Selected.ImageIndex <> Ord(siItem) then
    Exit;

  try
    ShortCutForm := TShortCutForm.Create(Self);
//    with ShortCutForm do
    begin
      ShortCutForm.lbledtShortCut.Text := lvShortCut.Selected.Caption;
      ShortCutForm.lbledtName.Text := lvShortCut.Selected.SubItems[0];
      ShortCutForm.lbledtCommandLine.Text := lvShortCut.Selected.SubItems[3];
      ShortCutMan.StringToParamType(lvShortCut.Selected.SubItems[1], ParamType);
      ShortCutForm.rgParam.ItemIndex := Ord(ParamType);

      ShowModal;

      if ModalResult = mrCancel then
        Exit;

      itm := nil;
      try
        itm := TListItem.Create(lvShortCut.Items);

        if (Trim(ShortCutForm.lbledtShortCut.Text) <> '') and (Trim(ShortCutForm.lbledtCommandLine.Text) <> '') then
        begin
          itm.Caption := ShortCutForm.lbledtShortCut.Text;
          itm.SubItems.Add(ShortCutForm.lbledtName.Text);
          itm.SubItems.Add(ShortCutMan.ParamTypeToString(TParamType(ShortCutForm.rgParam.ItemIndex)));
          itm.SubItems.Add(ShortCutForm.lbledtCommandLine.Text);
          itm.ImageIndex := Ord(siItem);
        end
        else
        begin
          itm.Caption := '';
          itm.SubItems.Add('');
          itm.SubItems.Add('');
          itm.SubItems.Add('');
          itm.ImageIndex := Ord(siInfo);
        end;

        //�����ظ����򱨴�
        if ExistListItem(itm) then
        begin
          Application.MessageBox('This ShortCut has already existed!', PChar(resInfo), MB_OK + MB_ICONINFORMATION + MB_TOPMOST);

          Exit;
        end;

        lvShortCut.Selected.Caption := itm.Caption;
        lvShortCut.Selected.SubItems[0] := itm.SubItems[0];
        lvShortCut.Selected.SubItems[1] := itm.SubItems[1];
        lvShortCut.Selected.SubItems[2] := itm.SubItems[2];
        lvShortCut.Selected.SubItems[3] := itm.SubItems[3];
        lvShortCut.Selected.ImageIndex := itm.ImageIndex;

        //ʹ��ɼ�
        lvShortCut.Selected.MakeVisible(True);
      finally
        FreeAndNil(itm);
      end;
    end;
  finally
    freeandNil(ShortCutForm);
  end;
end;

procedure TShortCutManForm.actHelpExecute(Sender: TObject);
begin
  if IsValidCommandLine('"C:\Program Files\ChromePlus\chrome.exe" ".\Shit.txt"') then
    ShowMessage('Good');
end;

procedure TShortCutManForm.actPathConvertExecute(Sender: TObject);
var
  i, Count: Cardinal;
  CommandLine: string;
  IsAbsoluteToRelative: Boolean;
begin
  IsAbsoluteToRelative := False;
  //�����Ƿ������Ҫ
  case Application.MessageBox(PChar(Format(resPathConvertConfirm, [#13#10, #13#10])), PChar(resInfo), MB_YESNOCANCEL + MB_ICONQUESTION + MB_TOPMOST) of
    IDCANCEL:
      begin
        Exit;
      end;
    IDYES:
      begin
        //����·�� -> ���·��
        IsAbsoluteToRelative := True;
      end;
    IDNO:
      begin
        //���·�� -> ����·��
        IsAbsoluteToRelative := False;
      end;
  end;

  Screen.Cursor := crHourGlass;

  Count := 0;
  for i := 0 to lvShortCut.Items.Count - 1 do
  begin
    //�����������
    CommandLine := lvShortCut.Items.Item[i].SubItems[3];

    if IsAbsoluteToRelative and (Pos(LowerCase(ExtractFileDir(Application.ExeName)), LowerCase(CommandLine)) > 1) then
    begin
      Inc(Count);
      lvShortCut.Items.Item[i].SubItems[3] := StringReplace(CommandLine, ExtractFileDir(Application.ExeName), '.', [rfReplaceAll, rfIgnoreCase]);
    end
    else if (not IsAbsoluteToRelative) and (Pos('.\', LowerCase(CommandLine)) > 0) then
    begin
      Inc(Count);
      lvShortCut.Items.Item[i].SubItems[3] := StringReplace(CommandLine, '.\', ExtractFilePath(Application.ExeName), [rfReplaceAll, rfIgnoreCase]);
    end;
  end;

  Screen.Cursor := crDefault;

  Application.MessageBox(PChar(Format(resConvertFinished, [Count])), PChar(resInfo), MB_OK + MB_ICONINFORMATION + MB_TOPMOST);
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

  //�����Ƿ������Ҫ
  if Application.MessageBox(PChar(resValidateConfirm), PChar(resInfo), MB_YESNO + MB_ICONQUESTION + MB_TOPMOST) = IDNO then
  begin
    Exit;
  end;

  try
    InvalidForm := TInvalidForm.Create(Self);

    Screen.Cursor := crHourGlass;

    for i := 0 to lvShortCut.Items.Count - 1 do
    begin
      //�����������
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

        //����Index
        lvwitm.Data := Pointer(i);
      end;
    end;

    Screen.Cursor := crDefault;

    //��û���ҵ����������Ŀ�����˳�
    if InvalidForm.lvShortCut.Items.Count = 0 then
    begin
      Application.MessageBox(PChar(resNoInvalidShortCut), PChar(resInfo), MB_OK + MB_ICONINFORMATION + MB_TOPMOST);
      Exit;
    end;

    InvalidForm.ShowModal;

    if InvalidForm.ModalResult = mrCancel then
      Exit;

    //��ѡ�еĶ�ɾ��
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
  SlashPos: Integer;
  i: Cardinal;
  strTemp: string;
  FlagPos: Integer;
begin
  Result := True;

  //去除前导的@/@+/@-
  if Pos(SHOW_MAX_FLAG, strCommandLine) = 1 then
    strCommandLine := CutLeftString(strCommandLine, Length(SHOW_MAX_FLAG))
  else if Pos(SHOW_MIN_FLAG, strCommandLine) = 1 then
    strCommandLine := CutLeftString(strCommandLine, Length(SHOW_MIN_FLAG))
  else if Pos(SHOW_HIDE_FLAG, strCommandLine) = 1 then
    strCommandLine := CutLeftString(strCommandLine, Length(SHOW_HIDE_FLAG));

  //出现'\\'认为是网络相关，别做检查
  if Pos('\\', strCommandLine) > 0 then
    Exit;

  //出现'\'才认为是文件或文件夹，才去做检查
  if Pos('\', strCommandLine) = 0 then
    Exit;

  //替换环境变量
  strCommandLine := ShortCutMan.ReplaceEnvStr(strCommandLine);

  //如果被""包围，就认为是文件，或者文件夹
  if strCommandLine <> RemoveQuotationMark(strCommandLine, '"') then
    strCommandLine := RemoveQuotationMark(strCommandLine, '"');

  //如果是.\开头，替换出当前路径
  if Pos('.\', strCommandLine) = 1 then
    strCommandLine := ExtractFilePath(Application.ExeName) + Copy(strCommandLine, 3, Length(strCommandLine) - 2);

  //有这个文件，当然没问题
  if FileExists(strCommandLine) then
    Exit;

  //有这个文件夹，当然没问题
  if DirectoryExists(strCommandLine) then
    Exit;

  //如果被""包围，就认为是文件，或者文件夹，要么有它，要么没有
  if strCommandLine <> RemoveQuotationMark(strCommandLine, '"') then
  begin
    strCommandLine := RemoveQuotationMark(strCommandLine, '"');

    if FileExists(strCommandLine) then
      Exit;
    if DirectoryExists(strCommandLine) then
      Exit;

    Result := False;
    Exit;
  end;

  // 剩下的可能是带参数的，找最后一个\
  SlashPos := 0;
  for i := Length(strCommandLine) downto 1 do
    if strCommandLine[i] = '\' then
    begin
      SlashPos := i;
      Break;
    end;

  if SlashPos > 0 then
  begin
    // 如果第一个字符是"
    if strCommandLine[1] = '"' then
      Result := DirectoryExists(Copy(strCommandLine, 2, SlashPos - 1))
    else
      Result := DirectoryExists(Copy(strCommandLine, 1, SlashPos));
  end;

  // 还不行就从开头进行寻找
  if not Result then
  begin
    // "C:\Program Files\ChromePlus\chrome.exe" ".\Shit.txt"
    // C:\Program Files\IDM Computer Solutions\UltraEdit-32\uedit32.exe .\HandleList.txt
    // C:\Program Files\IDM Computer Solutions\UltraEdit-32\uedit32.exe C:\Documents and Settings\to qqq\我需要干的事儿.txt

    // 如果第一个字符是"
    if strCommandLine[1] = '"' then
    begin
      //找下一个"
      strTemp := Copy(strCommandLine, 2, Length(strCommandLine) - 1);
      FlagPos := Pos('"', strTemp);
      if FlagPos > 0 then
        strTemp := Copy(strTemp, 1, FlagPos - 1);

      Result := DirectoryExists(strTemp) or FileExists(strTemp);
    end
    else
    begin
      // C:\Program Files\IDM Computer Solutions\UltraEdit-32\uedit32.exe .\HandleList.txt
      // 这种路径很难识别，如果有个exe是 C:\Program Files\IDM.exe 呢？

      Result := False;
    end;
  end;

  //Result := False;

  {
  //"C:\Program Files\D-Tools\daemon.exe" -lang 1033
  if Pos('"', strCommandLine) = 1 then Exit;

  //带参数的，都不检查
  //D:\Philips\Lenovo\Lenovo Status.xls 这种带有空格的残废路径，会在此逃掉
  if Pos(' ', strCommandLine) > 1 then Exit;


  //TODO: 其他的，都认为比较可疑，是否运行一下看看？
  Result := False;
  }
end;

function TShortCutManForm.ExistListItem(itm: TListItem): Boolean;
var
  i: Cardinal;
begin
  Result := False;

  if lvShortCut.Items.Count = 0 then
    Exit;

  //���ǿ���
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

procedure TShortCutManForm.FormCreate(Sender: TObject);
begin
  tlbShortCutMan.DoubleBuffered := True;
  tlbShortCutMan.ParentDoubleBuffered := True;
  tlbShortCutMan.Transparent := False;
  tlbShortCutMan.Flat := True;
  tlbShortCutMan.ShowCaptions := True;
  tlbShortCutMan.List := False; // 关闭List模式，避免兼容性问题

  // Disable Close Button
  EnableMenuItem(GetSystemMenu(Self.Handle, False), SC_CLOSE, MF_GRAYED);

  //mniCut.Enabled := False;
  //mniInsert.Enabled := False;
  //m_Cutted := False;

  Self.DoubleBuffered := True;
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

procedure TShortCutManForm.FormDestroy(Sender: TObject);
var
  i: Cardinal;
begin
  ManWinTop := Self.Top;
  ManWinLeft := Self.Left;
  ManWinWidth := Self.Width;
  ManWinHeight := Self.Height;

  for i := 0 to lvShortCut.Columns.Count - 1 do
    ManColWidth[i] := lvShortCut.Columns.Items[i].Width;

  SaveSettings;
end;

procedure TShortCutManForm.FormShow(Sender: TObject);
var
  i: Cardinal;
begin
  //���ô���λ��
  LoadSettings;

  if (ManWinTop = 0) and (ManWinLeft = 0) then
  begin
    try
      Self.Position := poScreenCenter;
    except
      //����Except���ͻ�ĳ�����Cannot change Visible in OnShow or OnHide���ı���
    end;
  end
  else
  begin
    Self.Top := ManWinTop;
    Self.Left := ManWinLeft;
    Self.Width := ManWinWidth;
    Self.Height := ManWinHeight;
  end;

  for i := 0 to lvShortCut.Columns.Count - 1 do
    lvShortCut.Columns.Items[i].Width := ManColWidth[i];
end;

procedure TShortCutManForm.LoadShortCutList;
begin
  ShortCutMan.FillListView(lvShortCut);
end;

procedure TShortCutManForm.lvShortCutColumnClick(Sender: TObject; Column: TListColumn);
begin
  //ShowMessage(Column.Caption);
end;

procedure TShortCutManForm.lvShortCutDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  tempItem1, tempItem2: TListItem;
begin
  begin
    //����ϵ������б���ĵط������˳�
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

procedure TShortCutManForm.lvShortCutKeyPress(Sender: TObject; var Key: Char);
begin
  //�س�
  //if Key = #13 then actEditExecute(Sender);
end;

procedure TShortCutManForm.lvShortCutMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  m_SrcItem := lvShortCut.GetItemAt(X, Y);
  //mniCut.Enabled := True;
end;

procedure TShortCutManForm.MyDrag(var Msg: TWMDropFiles);
var
  hDrop: Cardinal;
  FileName: string;
  ListItem: TListItem;
  ShortCutItem: TShortCutItem;
begin
  hDrop := Msg.Drop;
  FileName := GetDragFileName(hDrop);

  ShortCutForm := TShortCutForm.Create(Self);
  ShortCutItem := TShortCutItem.Create;
  try
    with ShortCutForm do
    begin
      if not ShortCutMan.ExtractShortCutItemFromFileName(ShortCutItem, FileName) then
      begin
        Application.MessageBox('Can not get file name!', 'Info', MB_OK + MB_ICONINFORMATION + MB_TOPMOST);

        Exit;
      end;

      lbledtShortCut.Text := ShortCutItem.ShortCut;
      lbledtName.Text := ShortCutItem.Name;
      lbledtCommandLine.Text := ShortCutItem.CommandLine;
      rgParam.ItemIndex := 0;

      ShowModal;

      if ModalResult = mrCancel then
      begin
        ShortCutItem.Free;
        Exit;
      end;

      ListItem := TListItem.Create(lvShortCut.Items);

      if (Trim(lbledtShortCut.Text) <> '') and (Trim(lbledtCommandLine.Text) <> '') then
      begin
        ListItem.Caption := lbledtShortCut.Text;
        ListItem.SubItems.Add(lbledtName.Text);
        ListItem.SubItems.Add(ShortCutMan.ParamTypeToString(TParamType(rgParam.ItemIndex)));
        ListItem.SubItems.Add(ShortCutMan.RunAsToString(ShortCutItem.RunAsAdmin));
        ListItem.SubItems.Add(lbledtCommandLine.Text);
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

      //�����ظ����򱨴�
      if ExistListItem(ListItem) then
      begin
        Application.MessageBox('This ShortCut has already existed!', PChar(resInfo), MB_OK + MB_ICONINFORMATION + MB_TOPMOST);

        ListItem.Free;
        Exit;
      end;

      //���û��ѡ�У��ͼӵ����һ�У�����Ͳ���ѡ�е�λ��
      if lvShortCut.ItemIndex < 0 then
        ListItem := lvShortCut.Items.AddItem(ListItem)
      else
        ListItem := lvShortCut.Items.AddItem(ListItem, lvShortCut.ItemIndex);

      //ʹ��ɼ�
      lvShortCut.SetFocus;
      ListItem.Selected := True;
      ListItem.MakeVisible(True);

      //���Captionֻ��һ����ĸ����"a"����ʱ����ʾ��ֻ�ô���һ�²���ˢ����ʾ
      ListItem.Caption := lbledtShortCut.Text + ' ';
      ListItem.Caption := lbledtShortCut.Text;
    end;
  finally
    ShortCutForm.Free;
  end;

  DragFinish(hDrop);
  Msg.Result := 0;

end;

end.

