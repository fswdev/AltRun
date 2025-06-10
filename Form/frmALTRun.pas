unit frmALTRun;

interface
 {$I Defines.inc} // 包含宏定义

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, AppEvnts, CoolTrayIcon, ActnList, Menus, HotKeyManager,
  ExtCtrls, Buttons, ImgList, ShellAPI, MMSystem, frmParam, frmAutoHide,
  untShortCutMan, untClipboard, untALTRunOption, untUtilities, jpeg,
  System.ImageList, System.Actions, system.Generics.Collections;

const
  WM_ALTRUN_ADD_SHORTCUT = WM_USER + 2000;
  WM_ALTRUN_SHOW_WINDOW = WM_USER + 2001;

type
  TALTRunForm = class(TForm)
    lblShortCut: TLabel;
    edtShortCut: TEdit;
    lstShortCut: TListBox;
    evtMain: TApplicationEvents;
    pmMain: TPopupMenu;
    actlstMain: TActionList;
    actShow: TAction;
    actShortCut: TAction;
    actConfig: TAction;
    actClose: TAction;
    actAbout: TAction;
    Show1: TMenuItem;
    ShortCut1: TMenuItem;
    Config1: TMenuItem;
    About1: TMenuItem;
    Close1: TMenuItem;
    actExecute: TAction;
    actSelectChange: TAction;
    imgBackground: TImage;
    actHide: TAction;
    pmList: TPopupMenu;
    actAddItem: TAction;
    actEditItem: TAction;
    actDeleteItem: TAction;
    mniAddItem: TMenuItem;
    mniEditItem: TMenuItem;
    mniDeleteItem: TMenuItem;
    tmrHide: TTimer;
    ilHotRun: TImageList;
    btnShortCut: TSpeedButton;
    btnClose: TSpeedButton;
    edtHint: TEdit;
    edtCommandLine: TEdit;
    mniN1: TMenuItem;
    actOpenDir: TAction;
    mniOpenDir: TMenuItem;
    tmrExit: TTimer;
    edtCopy: TEdit;
    tmrCopy: TTimer;
    btnConfig: TSpeedButton;
    tmrFocus: TTimer;
    actUp: TAction;
    actDown: TAction;
    pmCommandLine: TPopupMenu;
    actCopyCommandLine: TAction;
    OpenSelfDir: TMenuItem;
    actOpenAltRunDir: TAction;
    tmrScanner: TTimer;

    procedure WndProc(var Msg: TMessage); override;
    procedure edtShortCutChange(Sender: TObject);
    procedure edtShortCutKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure evtMainIdle(Sender: TObject; var Done: Boolean);
    procedure evtMainMinimize(Sender: TObject);
    procedure actShowExecute(Sender: TObject);
    procedure actConfigExecute(Sender: TObject);
    procedure actCloseExecute(Sender: TObject);
    procedure actAboutExecute(Sender: TObject);
    procedure hkmHotkeyHotKeyPressed(HotKey: Cardinal; Index: Word);
    procedure FormDestroy(Sender: TObject);
    procedure actExecuteExecute(Sender: TObject);
    procedure edtShortCutKeyPress(Sender: TObject; var Key: Char);
    procedure actSelectChangeExecute(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure lstShortCutKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure actHideExecute(Sender: TObject);
    procedure actShortCutExecute(Sender: TObject);
    procedure btnShortCutClick(Sender: TObject);
    procedure actAddItemExecute(Sender: TObject);
    procedure actEditItemExecute(Sender: TObject);
    procedure actDeleteItemExecute(Sender: TObject);
    procedure lblShortCutMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure imgBackgroundMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure tmrHideTimer(Sender: TObject);
    procedure evtMainDeactivate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure ntfMainDblClick(Sender: TObject);
    procedure lstShortCutMouseActivate(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate);
    procedure edtShortCutMouseActivate(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate);
    procedure lblShortCutMouseActivate(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate);
    procedure edtCommandLineKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure actOpenDirExecute(Sender: TObject);
    procedure lstShortCutMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure pmListPopup(Sender: TObject);
    procedure tmrExitTimer(Sender: TObject);
    procedure tmrCopyTimer(Sender: TObject);
    procedure tmrFocusTimer(Sender: TObject);
    procedure evtMainActivate(Sender: TObject);
    procedure evtMainMessage(var Msg: tagMSG; var Handled: Boolean);
    procedure evtMainShortCut(var Msg: TWMKey; var Handled: Boolean);
    procedure actUpExecute(Sender: TObject);
    procedure actDownExecute(Sender: TObject);
    procedure MiddleMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure actCopyCommandLineExecute(Sender: TObject);
    procedure hkmHotkey3HotKeyPressed(HotKey: Cardinal; Index: Word);
    procedure actOpenAltRunDirExecute(Sender: TObject);
    procedure tmrScannerTimer(Sender: TObject);
  private
    ntfMain: TCoolTrayIcon;
    hkmHotkey1: THotKeyManager;
    hkmHotkey2: THotKeyManager;
    hkmHotkey3: THotKeyManager;
    procedure Receive_SendTo_Filename(var Msg: TWMCopyData); message WM_COPYDATA;
  private
    m_IsShow: Boolean;
    m_IsFirstShow: Boolean;
    m_IsFirstDblClickIcon: Boolean;
    m_LastShortCutPointerList: array[0..9] of Pointer;
    m_LastShortCutCmdIndex: Integer;
    m_LastShortCutListCount: Integer;
    m_LastKeyIsNumKey: Boolean;
    m_LastActiveTime: Cardinal;
    m_IsExited: Boolean;
    m_NeedRefresh: Boolean;

    function ApplyHotKey1: Boolean;
    function ApplyHotKey2: Boolean;
    function GetHotKeyString: string;
    procedure GetLastCmdList;
    procedure RestartHideTimer(Delay: Integer);
    procedure StopTimer;
    function DirAvailable: Boolean;
    procedure RefreshOperationHint;
    function GetLangList(List: TStringList): Boolean;
    procedure RestartMe;
    procedure DisplayShortCutItem(Item: TShortCutItem);
    procedure ShowLatestShortCutList;
  private
    function readIsTop: Boolean;
    procedure writeTop(b: Boolean);
  public
    property IsExited: Boolean read m_IsExited write m_IsExited;

  public
    FNeedLayoutRefresh: Boolean; // 新增：是否需要刷新布局
    procedure UpdateFormLayout();
    property IsTop: boolean read readIsTop write writeTop;
  end;

var
  ALTRunForm: TALTRunForm;

implementation
{$R *.dfm}

uses
  untLogger, frmConfig, frmAbout, frmShortCut, frmShortCutMan, frmLang, math,
  untShortCutScanner, dateutils;

procedure TALTRunForm.UpdateFormLayout;
const
  MARGIN = 8; // 控件间距
  BUTTON_SIZE = 25; // 按钮宽高
  LABEL_HEIGHT = 33; // 标签高度（固定值）
  MIN_HEIGHT = 14; // 最小控件高度
  PADDING = 4; // 控件内边距
  VERTICAL_CENTER_OFFSET = 6; // 命令行文字垂直居中调整
var
  CurrentTop: Integer;
  LabelWidth: Integer;
  EditHeight, HintHeight, CommandHeight: Integer;
  lg: Longint;
  SkinFilePath: string;
begin
  // 应用字体
  StrToFont(TitleFontStr, lblShortCut.Font);
  StrToFont(KeywordFontStr, edtShortCut.Font);
  StrToFont(ListFontStr, lstShortCut.Font);

  // 计算控件高度（基于字体高度）
  EditHeight := Max(Abs(edtShortCut.Font.Height) + 2 * PADDING, MIN_HEIGHT);
  HintHeight := Max(Abs(edtHint.Font.Height) + 2 * PADDING, MIN_HEIGHT);
  CommandHeight := Max(Abs(edtCommandLine.Font.Height) + 2 * PADDING + VERTICAL_CENTER_OFFSET, MIN_HEIGHT);

  // 初始化顶部位置
  CurrentTop := MARGIN;

  // 1. 背景图片
  SkinFilePath := ExtractFilePath(Application.ExeName) + BGFileName;
  imgBackground.Picture := nil; // 先清空图片
  if ShowSkin and FileExists(SkinFilePath) then
  begin
    try
      imgBackground.Picture.LoadFromFile(SkinFilePath);
    except
      on E: Exception do
        TraceMsg('Failed to load background image: ' + E.Message);
    end;
  end;
  imgBackground.Left := 0;
  imgBackground.Top := 0;
  imgBackground.Width := Self.ClientWidth;
  imgBackground.Height := Self.ClientHeight;

  // 2. 按钮和标签（顶部）
  btnShortCut.Visible := ShowShortCutButton;
  btnConfig.Visible := ShowConfigButton;
  btnClose.Visible := ShowCloseButton;

  // 按钮位置
  btnShortCut.Left := MARGIN;
  btnShortCut.Top := CurrentTop;
  btnShortCut.Width := BUTTON_SIZE;
  btnShortCut.Height := BUTTON_SIZE;

  btnClose.Left := Self.ClientWidth - BUTTON_SIZE - MARGIN;
  btnClose.Top := CurrentTop;
  btnClose.Width := BUTTON_SIZE;
  btnClose.Height := BUTTON_SIZE;

  btnConfig.Left := btnClose.Left - BUTTON_SIZE - MARGIN;
  btnConfig.Top := CurrentTop;
  btnConfig.Width := BUTTON_SIZE;
  btnConfig.Height := BUTTON_SIZE;

  // 标签位置
  if ShowShortCutButton then
    lblShortCut.Left := btnShortCut.Left + btnShortCut.Width + MARGIN
  else
    lblShortCut.Left := MARGIN;
  lblShortCut.Top := CurrentTop;
  if ShowConfigButton then
    LabelWidth := btnConfig.Left - lblShortCut.Left
  else if ShowCloseButton then
    LabelWidth := btnClose.Left - lblShortCut.Left
  else
    LabelWidth := Self.ClientWidth - lblShortCut.Left - MARGIN;
  lblShortCut.Width := LabelWidth;
  lblShortCut.Height := LABEL_HEIGHT;

  // 更新顶部位置
  CurrentTop := CurrentTop + LABEL_HEIGHT + MARGIN;

  // 3. 输入框 (edtShortCut)
  edtShortCut.Left := MARGIN;
  edtShortCut.Top := CurrentTop;
  edtShortCut.Width := Self.ClientWidth - 2 * MARGIN;
  edtShortCut.Height := EditHeight;
  SendMessage(edtShortCut.Handle, EM_SETMARGINS, EC_LEFTMARGIN, MakeLong(26, 0));

  // 提示框 (edtHint，与edtShortCut部分重叠)
  edtHint.Left := MARGIN + 74; // 与原DFM中Left=82对齐
  edtHint.Top := CurrentTop + 3; // 略微偏移
  edtHint.Width := Self.ClientWidth - 2 * MARGIN - 74;
  edtHint.Height := HintHeight;
  edtHint.Visible := ShowOperationHint;

  // 更新顶部位置
  CurrentTop := CurrentTop + EditHeight + MARGIN;

  // 4. 列表框 (lstShortCut)
  lstShortCut.Left := MARGIN;
  lstShortCut.Top := CurrentTop;
  lstShortCut.Width := Self.ClientWidth - 2 * MARGIN;
  lstShortCut.Height := 10 * lstShortCut.ItemHeight; // 8项高度

  // 更新顶部位置
  CurrentTop := CurrentTop + lstShortCut.Height + MARGIN;

  // 5. 命令行输入框 (edtCommandLine)
  edtCommandLine.Left := MARGIN;
  edtCommandLine.Top := CurrentTop;
  edtCommandLine.Width := Self.ClientWidth - 2 * MARGIN;
  edtCommandLine.Height := CommandHeight;
  edtCommandLine.Visible := ShowCommandLine;

  // 6. 调整窗体高度
  if ShowCommandLine then
    Self.ClientHeight := CurrentTop + CommandHeight + MARGIN
  else
    Self.ClientHeight := CurrentTop; // 精确到lstShortCut底部，避免空白

  // 7. 复制提示框 (edtCopy)
  edtCopy.Left := Self.ClientWidth - 16 - MARGIN;
  edtCopy.Top := Self.ClientHeight - 16 - MARGIN;
  edtCopy.Width := 16;
  edtCopy.Height := 16;

  // 8. 应用窗体样式（透明度和圆角）
  lg := GetWindowLong(Handle, GWL_EXSTYLE);
  lg := lg or WS_EX_LAYERED;
  SetWindowLong(Handle, GWL_EXSTYLE, lg);
  SetLayeredWindowAttributes(Handle, AlphaColor, Alpha, LWA_ALPHA or LWA_COLORKEY);
  SetWindowRgn(Handle, CreateRoundRectRgn(0, 0, Width, Height, RoundBorderRadius, RoundBorderRadius), True);

  // 强制刷新窗体
  Self.Invalidate;
  Self.Refresh;
end;

procedure TALTRunForm.actShowExecute(Sender: TObject);
var
  PopupFileName: string;
begin
  TraceMsg('actShowExecute()');
  Self.Caption := TITLE;

  if ParamForm <> nil then
    ParamForm.ModalResult := mrCancel;

  // 仅在初次显示或需要刷新时加载快捷方式列表
  if m_IsFirstShow or ShortCutMan.NeedRefresh then
    ShortCutMan.LoadShortCutList;

  if (edtShortCut.Text <> '') then
  begin
    edtShortCut.Text := '';
  end
  else
  begin
    if m_IsFirstShow or m_NeedRefresh or ShortCutMan.NeedRefresh then
    begin
      m_NeedRefresh := False;
      ShortCutMan.NeedRefresh := False; // 加载后重置标志
      edtShortCutChange(Sender);
    end
    else
    begin
      RefreshOperationHint;
      if lstShortCut.Items.Count > 0 then
      begin
        lstShortCut.ItemIndex := 0;
        lblShortCut.Caption := TShortCutItem(lstShortCut.Items.Objects[0]).Name;
        if DirAvailable then
          lblShortCut.Caption := '[' + lblShortCut.Caption + ']';
      end;
    end;
  end;

  // 设置窗体位置
  if m_IsFirstShow then
  begin
    m_IsFirstShow := False;
    if (WinTop <= 0) or (WinLeft <= 0) then
      Self.Position := poScreenCenter
    else
    begin
      Self.Top := WinTop;
      Self.Left := WinLeft;
      Self.Width := FormWidth;
    end;
    // 获得最近使用快捷方式的列表
    ShortCutMan.SetLatestShortCutIndexList(LatestList);
    FNeedLayoutRefresh := True; // 初次显示需要刷新布局
  end;

  // 仅在需要时更新布局
  if FNeedLayoutRefresh then
    UpdateFormLayout;

  Self.Show;
  Application.Restore;
  SetForegroundWindow(Application.Handle);
  m_IsShow := True;
  edtShortCut.SetFocus;
  GetLastCmdList;
  RestartHideTimer(HideDelay);
  tmrFocus.Enabled := True;

  WinTop := Self.Top;
  WinLeft := Self.Left;
  m_LastActiveTime := GetTickCount;
  self.IsTop := True;

  if PlayPopupNotify then
  begin
    PopupFileName := ExtractFilePath(Application.ExeName) + 'Popup.wav';
    if not FileExists(PopupFileName) then
      ExtractRes('WAVE', 'PopupWav', 'Popup.wav');
    if FileExists(PopupFileName) then
      PlaySound(PChar(PopupFileName), 0, snd_ASYNC)
    else
      PlaySound(PChar('PopupWav'), HInstance, snd_ASYNC or SND_RESOURCE);
  end;
end;

procedure TALTRunForm.actConfigExecute(Sender: TObject);
var
  ConfigForm: TConfigForm;
  i: Cardinal;
  LangList: TStringList;
  IsNeedRestart: Boolean;
begin
  TraceMsg('actConfigExecute()');
  //取消HotKey以免冲突
  hkmHotkey1.ClearHotKeys;
  hkmHotkey2.ClearHotKeys;

  ConfigForm := TConfigForm.Create(Self);
  IsNeedRestart := False;

  try
  	//调用当前配置
    with ConfigForm do
    begin
      DisplayHotKey1(HotKeyStr1);
      DisplayHotKey2(HotKeyStr2);
      chklstConfig.Checked[0] := AutoRun;
      chklstConfig.Checked[1] := AddToSendTo;
      chklstConfig.Checked[2] := EnableRegex;
      chklstConfig.Checked[3] := MatchAnywhere;
      chklstConfig.Checked[4] := EnableNumberKey;
      chklstConfig.Checked[5] := IndexFrom0to9;
      chklstConfig.Checked[6] := RememberFavouratMatch;
      chklstConfig.Checked[7] := ShowOperationHint;
      chklstConfig.Checked[8] := ShowCommandLine;
      chklstConfig.Checked[9] := ShowStartNotification;
      chklstConfig.Checked[10] := ShowTopTen;
      chklstConfig.Checked[11] := PlayPopupNotify;
      chklstConfig.Checked[12] := ExitWhenExecute;
      chklstConfig.Checked[13] := ShowSkin;
      chklstConfig.Checked[14] := ShowMeWhenStart;
      chklstConfig.Checked[15] := ShowTrayIcon;
      chklstConfig.Checked[16] := ShowShortCutButton;
      chklstConfig.Checked[17] := ShowConfigButton;
      chklstConfig.Checked[18] := ShowCloseButton;
      chklstConfig.Checked[19] := ExecuteIfOnlyOne;
      StrToFont(TitleFontStr, lblTitleSample.Font);
      StrToFont(KeywordFontStr, lblKeywordSample.Font);
      StrToFont(ListFontStr, lblListSample.Font);

      for i := Low(ListFormatList) to High(ListFormatList) do
        cbbListFormat.Items.Add(ListFormatList[i]);
      if cbbListFormat.Items.IndexOf(ListFormat) < 0 then
        cbbListFormat.Items.Add(ListFormat);
      cbbListFormat.ItemIndex := cbbListFormat.Items.IndexOf(ListFormat);
      cbbListFormatChange(Sender);
      lstAlphaColor.Selected := AlphaColor;
      seAlpha.Value := Alpha;
      seRoundBorderRadius.Value := RoundBorderRadius;
      seFormWidth.Value := FormWidth;

      LangList := TStringList.Create;
      try
        cbbLang.Items.Add(DEFAULT_LANG);
        cbbLang.ItemIndex := 0;
        if not GetLangList(LangList) then
          Exit;
        if LangList.Count > 0 then
        begin
          for i := 0 to LangList.Count - 1 do
            if cbbLang.Items.IndexOf(LangList.Strings[i]) < 0 then
              cbbLang.Items.Add(LangList.Strings[i]);
          for i := 0 to cbbLang.Items.Count - 1 do
            if cbbLang.Items[i] = Lang then
            begin
              cbbLang.ItemIndex := i;
              Break;
            end;
        end;
      finally
        LangList.Free;
      end;

      self.IsTop := false;
      ShowModal;
      self.IsTop := True;

      case ModalResult of
        mrOk:
          begin
            HotKeyStr1 := GetHotKey1;
            HotKeyStr2 := GetHotKey2;
            AutoRun := chklstConfig.Checked[0];
            AddToSendTo := chklstConfig.Checked[1];
            EnableRegex := chklstConfig.Checked[2];
            MatchAnywhere := chklstConfig.Checked[3];
            EnableNumberKey := chklstConfig.Checked[4];
            IndexFrom0to9 := chklstConfig.Checked[5];
            RememberFavouratMatch := chklstConfig.Checked[6];
            ShowOperationHint := chklstConfig.Checked[7];
            ShowCommandLine := chklstConfig.Checked[8];
            ShowStartNotification := chklstConfig.Checked[9];
            ShowTopTen := chklstConfig.Checked[10];
            PlayPopupNotify := chklstConfig.Checked[11];
            ExitWhenExecute := chklstConfig.Checked[12];
            ShowSkin := chklstConfig.Checked[13];
            ShowMeWhenStart := chklstConfig.Checked[14];
            ShowTrayIcon := chklstConfig.Checked[15];
            ShowShortCutButton := chklstConfig.Checked[16];
            ShowConfigButton := chklstConfig.Checked[17];
            ShowCloseButton := chklstConfig.Checked[18];
            ExecuteIfOnlyOne := chklstConfig.Checked[19];
            TitleFontStr := FontToStr(lblTitleSample.Font);
            KeywordFontStr := FontToStr(lblKeywordSample.Font);
            ListFontStr := FontToStr(lblListSample.Font);
            ListFormat := cbbListFormat.Text;
            if not IsNeedRestart then
              IsNeedRestart := (AlphaColor <> lstAlphaColor.Selected);
            AlphaColor := lstAlphaColor.Selected;
            if not IsNeedRestart then
              IsNeedRestart := (Alpha <> seAlpha.Value);
            Alpha := Round(seAlpha.Value);
            if not IsNeedRestart then
              IsNeedRestart := (RoundBorderRadius <> seRoundBorderRadius.Value);
            RoundBorderRadius := Round(seRoundBorderRadius.Value);
            if not IsNeedRestart then
              IsNeedRestart := (FormWidth <> seFormWidth.Value);
            FormWidth := Round(seFormWidth.Value);
            if not IsNeedRestart then
              IsNeedRestart := (Lang <> cbbLang.Text);
            Lang := cbbLang.Text;

            ShortCutMan.SaveShortCutList;
            ShortCutMan.LoadShortCutList;
            ShortCutMan.NeedRefresh := True;
            FNeedLayoutRefresh := True; // 设置更新后需要刷新布局
            // 重新注册热键
            ApplyHotKey1;
            ApplyHotKey2;
          end;
        mrRetry:
          begin
            DeleteFile(ExtractFilePath(Application.ExeName) + TITLE + '.ini');
            LoadSettings;
            IsNeedRestart := True;
            FNeedLayoutRefresh := True; // 重置设置需要刷新布局
            // 重新注册热键
            ApplyHotKey1;
            ApplyHotKey2;
          end;
      else
        ApplyHotKey1;
        ApplyHotKey2;
        Exit;
      end;

      SetAutoRunInStartUp(TITLE, Application.ExeName, AutoRun);
      AddMeToSendTo(TITLE, AddToSendTo);
      ntfMain.IconVisible := ShowTrayIcon;

      // 更新布局和样式
      UpdateFormLayout;

      SetActiveLanguage;
      edtShortCutChange(Sender);

      SaveSettings;
      if IsNeedRestart then
      begin
        Application.MessageBox(PChar(resRestartMeInfo), PChar(resInfo), MB_OK + MB_ICONINFORMATION + MB_TOPMOST);
        RestartMe;
      end;
    end;
  finally
    FreeAndNil(ConfigForm);
  end;
end;

procedure TALTRunForm.actAboutExecute(Sender: TObject);
var
  AboutForm: TAboutForm;
begin
  TraceMsg('actAboutExecute()');
  try
    AboutForm := TAboutForm.Create(Self);
    AboutForm.Caption := Format('%s %s %s', [resAbout, TITLE, ALTRUN_VERSION]);
    AboutForm.ShowModal;
  finally
    freeandnil(AboutForm);
  end;
end;

procedure TALTRunForm.actAddItemExecute(Sender: TObject);
begin
  TraceMsg('actAddItemExecute()');

  self.IsTop := False;
  ShortCutMan.AddFileShortCut(edtShortCut.Text);
  self.IsTop := True;
  if m_IsShow then
    edtShortCutChange(Self);
end;

procedure TALTRunForm.actCloseExecute(Sender: TObject);
begin
  TraceMsg('actCloseExecute()');

  //保存窗体位置
  if m_IsShow then
  begin
    WinTop := Self.Top;
    WinLeft := Self.Left;
  end;

  //保存最近使用快捷方式的列表
  LatestList := ShortCutMan.GetLatestShortCutIndexList;

  HandleID := 0;
  SaveSettings;

  //若保留此行，在右键添加后，直接退出本程序，此新添快捷项将丢失
  ShortCutMan.SaveShortCutList;

  Application.Terminate;
end;

procedure TALTRunForm.actCopyCommandLineExecute(Sender: TObject);
begin
  if lstShortCut.ItemIndex >= 0 then
  begin
    //SetClipboardText(TShortCutItem(lstShortCut.Items.Objects[lstShortCut.ItemIndex]).CommandLine);
    Clipboard.AsUnicodeText := TShortCutItem(lstShortCut.Items.Objects[lstShortCut.ItemIndex]).CommandLine;
    edtCopy.Show;
    tmrCopy.Enabled := True;
  end;
end;

procedure TALTRunForm.actDeleteItemExecute(Sender: TObject);
var
  itm: TShortCutItem;
  Index: Integer;
begin
  TraceMsg('actDeleteItemExecute(%d)', [lstShortCut.ItemIndex]);

  if lstShortCut.ItemIndex < 0 then
    Exit;

  itm := TShortCutItem(lstShortCut.Items.Objects[lstShortCut.ItemIndex]);

  if Application.MessageBox(PChar(Format('%s %s(%s)?', [resDelete, itm.ShortCut, itm.Name])), PChar(resInfo), MB_OKCANCEL + MB_ICONQUESTION + MB_TOPMOST) = IDOK then
  begin
    Index := ShortCutMan.GetShortCutItemIndex(itm);
    ShortCutMan.DeleteShortCutItem(Index);

    //不加这一句，一旦添加“1111”，再删除“1111”，会报错
    m_LastShortCutListCount := 0;

    //刷新
    edtShortCutChange(Sender);
  end;
end;

procedure TALTRunForm.actDownExecute(Sender: TObject);
begin
  TraceMsg('actDownExecute');

  with lstShortCut do
    if Visible then
    begin
      if Count = 0 then
        Exit;

      //列表上下走
      if ItemIndex = -1 then
        ItemIndex := 0
      else if ItemIndex = Count - 1 then
        ItemIndex := 0
      else
        ItemIndex := ItemIndex + 1;

      DisplayShortCutItem(TShortCutItem(Items.Objects[ItemIndex]));
      m_LastShortCutCmdIndex := ItemIndex;

      if ShowOperationHint and (lstShortCut.ItemIndex >= 0) and (Length(edtShortCut.Text) < 10) and CharInSet(lstShortCut.Items[lstShortCut.ItemIndex][2], ['0'..'9']) then
        edtHint.Text := Format(resRunNum, [lstShortCut.Items[lstShortCut.ItemIndex][2], lstShortCut.Items[lstShortCut.ItemIndex][2]]);
    end;
end;

procedure TALTRunForm.actEditItemExecute(Sender: TObject);
var
  ShortCutForm: TShortCutForm;
  itm: TShortCutItem;
begin
  TraceMsg('actEditItemExecute(%d)', [lstShortCut.ItemIndex]);

  if lstShortCut.ItemIndex < 0 then
    Exit;

  itm := TShortCutItem(lstShortCut.Items.Objects[lstShortCut.ItemIndex]);

  ShortCutForm := nil;
  try
    ShortCutForm := TShortCutForm.Create(Self);
    with ShortCutForm do
    begin
      lbledtShortCut.Text := itm.ShortCut;
      lbledtName.Text := itm.Name;
      cb_RunAsAdmin.Checked := itm.RunAsAdmin;
      lbledtCommandLine.Text := itm.CommandLine;
      rgParam.ItemIndex := Ord(itm.ParamType);

      self.IsTop := False;
      ShowModal;
      self.IsTop := True;

      if ModalResult = mrCancel then
        Exit;

      //取得新的项目
      itm.ShortCutType := scItem;
      itm.ShortCut := lbledtShortCut.Text;
      itm.Name := lbledtName.Text;
      itm.RunAsAdmin := cb_runasadmin.Checked;
      itm.CommandLine := lbledtCommandLine.Text;
      itm.ParamType := TParamType(rgParam.ItemIndex);

      //保存新的项目
      ShortCutMan.SaveShortCutList;
      ShortCutMan.LoadShortCutList;

      //刷新
      edtShortCutChange(Sender);
    end;
  finally
    freeandnil(ShortCutForm);
  end;
end;

procedure TALTRunForm.actExecuteExecute(Sender: TObject);
begin
  TraceMsg('actExecuteExecute(%d)', [lstShortCut.ItemIndex]);

  //若下面有选中某项
  if lstShortCut.Count > 0 then
  begin
    evtMainMinimize(Self);
    //Self.Hide;

    //WINEXEC//调用可执行文件
    //winexec('command.com /c copy *.* c:\',SW_Normal);
    //winexec('start abc.txt');
    //ShellExecute或ShellExecuteEx//启动文件关联程序
    //function executefile(const filename,params,defaultDir:string;showCmd:integer):THandle;
    //ExecuteFile('C:\abc\a.txt','x.abc','c:\abc\',0);
    //ExecuteFile('http://tingweb.yeah.net','','',0);
    //ExecuteFile('mailto:tingweb@wx88.net','','',0);
    //如果WinExec返回值小于32，就是失败，那就使用ShellExecute来搞

    //这种发送键盘的方法并不太好，所以屏蔽掉
    //    for i := 1 to Length(cmd) do
    //    begin
    //      ch := UpCase(cmd[i]);
    //      case ch of
    //        'A'..'Z': PostKeyEx32(ORD(ch), [], FALSE);
    //        '0'..'9': PostKeyEx32(ORD(ch), [], FALSE);                  R
    //        '.': PostKeyEx32(VK_DECIMAL, [], FALSE);
    //        '+': PostKeyEx32(VK_ADD, [], FALSE);
    //        '-': PostKeyEx32(VK_SUBTRACT, [], FALSE);
    //        '*': PostKeyEx32(VK_MULTIPLY, [], FALSE);
    //        '/': PostKeyEx32(VK_DIVIDE, [], FALSE);
    //        ' ': PostKeyEx32(VK_SPACE, [], FALSE);
    //        ';': PostKeyEx32(186, [], FALSE);
    //        '=': PostKeyEx32(187, [], FALSE);
    //        ',': PostKeyEx32(188, [], FALSE);
    //        '[': PostKeyEx32(219, [], FALSE);
    //        '\': PostKeyEx32(220, [], FALSE);
    //        ']': PostKeyEx32(221, [], FALSE);
    //      else
    //        ShowMessage(ch);
    //      end;
    //      //sleep(50);
    //    end;
    //
    //    PostKeyEx32(VK_RETURN, [], FALSE);

    //下面这种方法也不好
    //如果一种方式无法运行，就换一种
    //if WinExec(PChar(cmd), SW_SHOWNORMAL) < 33 then
    //begin
    //  if ShellExecute(0, 'open', PChar(cmd), nil, nil, SW_SHOWNORMAL) < 33 then
    //  begin
    //    //写批处理的这招，先不用
    //    //WriteLineToFile('D:\My\Code\Delphi\HotRun\Bin\shit.bat', cmd);
    //    //if ShellExecute(0, 'open', 'D:\My\Code\Delphi\HotRun\Bin\shit.bat', nil, nil, SW_HIDE) < 33 then
    //    Application.MessageBox(PChar(Format('Can not execute "%s"', [cmd])), 'Warning', MB_OK + MB_ICONWARNING);
    //  end;
    //end;

    //执行快捷项
    ShortCutMan.Execute(TShortCutItem(lstShortCut.Items.Objects[lstShortCut.ItemIndex]), edtShortCut.Text);

    //清空输入框
    edtShortCut.Text := '';

    //下面的方法，有时候键盘序列会发到其他窗口
    //打开“开始/运行”对话框，发送键盘序列
    //ShellApplication := CreateOleObject('Shell.Application');
    //ShellApplication.FileRun;
    //sleep(500);
    //SendKeys(PChar(cmd), False, True);
    //SendKeys('~', True, True);                         //回车

    //如果需要执行完就退出
    if ExitWhenExecute then
      tmrExit.Enabled := True;
  end
  else
    //如果没有合适项目，则提示是否添加之
    if Application.MessageBox(PChar(Format(resNoItemAndAdd, [edtShortCut.Text])), PChar(resInfo), MB_OKCANCEL + MB_ICONQUESTION) = IDOK then
    actAddItemExecute(Sender);
end;

procedure TALTRunForm.actHideExecute(Sender: TObject);
begin
  TraceMsg('actHideExecute()');

  evtMainMinimize(Sender);

  edtShortCut.Text := '';
end;

procedure TALTRunForm.actOpenAltRunDirExecute(Sender: TObject);
begin
  ShellExecute(GetDesktopWindow, nil, pchar(extractFilePath(ParamStr(0))), nil, nil, SW_SHOW);
end;

procedure TALTRunForm.actOpenDirExecute(Sender: TObject);
var
  itm: TShortCutItem;
  cmdobj: TCmdObject;
  CommandLine: string;
  SlashPos: Integer;
  i: Cardinal;
begin
  TraceMsg('actOpenDirExecute(%d)', [lstShortCut.ItemIndex]);

  if lstShortCut.ItemIndex < 0 then
    Exit;

  itm := TShortCutItem(lstShortCut.Items.Objects[lstShortCut.ItemIndex]);

  //if not (FileExists(itm.CommandLine) or DirectoryExists(itm.CommandLine)) then Exit;

  cmdobj := TCmdObject.Create;
  cmdobj.Param := '';
  //cmdobj.Command := ExtractFileDir(RemoveQuotationMark(itm.CommandLine, '"'));

  //去除前导的@/@+/@-
  CommandLine := itm.CommandLine;
  if Pos(SHOW_MAX_FLAG, CommandLine) = 1 then
    CommandLine := CutLeftString(CommandLine, Length(SHOW_MAX_FLAG))
  else if Pos(SHOW_MIN_FLAG, CommandLine) = 1 then
    CommandLine := CutLeftString(CommandLine, Length(SHOW_MIN_FLAG))
  else if Pos(SHOW_HIDE_FLAG, CommandLine) = 1 then
    CommandLine := CutLeftString(CommandLine, Length(SHOW_HIDE_FLAG));

  cmdobj.Command := RemoveQuotationMark(CommandLine, '"');

  if (Pos('.\', itm.CommandLine) > 0) or (Pos('..\', itm.CommandLine) > 0) then
  begin
    TraceMsg('CommandLine = %s', [itm.CommandLine]);
    TraceMsg('Application.ExeName = %s', [Application.ExeName]);
    TraceMsg('WorkingDir = %s', [ExtractFilePath(Application.ExeName)]);

    cmdobj.Command := ExtractFileDir(CommandLine);
    cmdobj.WorkingDir := ExtractFilePath(Application.ExeName);
  end
  else if FileExists(ExtractFileDir(itm.CommandLine)) then
  begin
    cmdobj.Command := ExtractFileDir(CommandLine);
    cmdobj.WorkingDir := ExtractFileDir(itm.CommandLine);
  end
  else
  begin
    SlashPos := 0;
    if Length(cmdobj.Command) > 1 then
      for i := Length(cmdobj.Command) - 1 downto 1 do
        if cmdobj.Command[i] = '\' then
        begin
          SlashPos := i;
          Break;
        end;

    if SlashPos > 0 then
    begin
      // 如果第一个字符是"
      if cmdobj.Command[1] = '"' then
        cmdobj.Command := (Copy(cmdobj.Command, 2, SlashPos - 1))
      else
        cmdobj.Command := (Copy(cmdobj.Command, 1, SlashPos));

      cmdobj.WorkingDir := cmdobj.Command;
    end
    else
    begin
      cmdobj.Command := ExtractFileDir(cmdobj.Command);
      cmdobj.WorkingDir := '';
    end;

  end;

  ShortCutMan.Execute(cmdobj);
end;

procedure TALTRunForm.actSelectChangeExecute(Sender: TObject);
begin
  TraceMsg('actSelectChangeExecute(%d)', [lstShortCut.ItemIndex]);

  if lstShortCut.ItemIndex = -1 then
    Exit;

  lblShortCut.Caption := TShortCutItem(lstShortCut.Items.Objects[lstShortCut.ItemIndex]).Name;
  lblShortCut.Hint := TShortCutItem(lstShortCut.Items.Objects[lstShortCut.ItemIndex]).CommandLine;
  //edtCommandLine.Hint := lblShortCut.Hint;
  edtCommandLine.Text := resCMDLine + lblShortCut.Hint;

  if DirAvailable then
    lblShortCut.Caption := '[' + lblShortCut.Caption + ']';
end;

procedure TALTRunForm.actShortCutExecute(Sender: TObject);
const
  TEST_ITEM_COUNT = 10;
  Test_Array: array[0..TEST_ITEM_COUNT - 1] of Integer = (3, 0, 8, 2, 8, 6, 1, 3, 0, 8);
var
  ShortCutManForm: TShortCutManForm;
begin
  TraceMsg('actShortCutExecute()');

  {$ifdef DEBUG_MODE}
  begin
    SetEnvironmentVariable(PChar('MyTool'), PChar('C:\'));
    Exit;
  end;
  {$endif}

  try
    ShortCutManForm := TShortCutManForm.Create(Self);
    with ShortCutManForm do
    begin
      self.IsTop := False;
      StopTimer;
      ShowModal;
      self.IsTop := True;

      if ModalResult = mrOk then
      begin
        //刷新快捷项列表
        ShortCutMan.LoadFromListView(lvShortCut);
        ShortCutMan.SaveShortCutList;
        ShortCutMan.LoadShortCutList;

        if m_IsShow then
        begin
          edtShortCutChange(Sender);

          try
            edtShortCut.SetFocus;
          except
            TraceMsg('edtShortCut.SetFocus failed');
          end;
        end;
      end;

      RestartHideTimer(HideDelay);
    end;
  finally
    freeandnil(ShortCutManForm);
  end;
end;

procedure TALTRunForm.actUpExecute(Sender: TObject);
begin
  TraceMsg('actUpExecute');

  with lstShortCut do
    if Visible then
    begin
      if Count = 0 then
        Exit;

      //列表上下走
      if ItemIndex = -1 then
        ItemIndex := Count - 1
      else if ItemIndex = 0 then
        ItemIndex := Count - 1
      else
        ItemIndex := ItemIndex - 1;

      DisplayShortCutItem(TShortCutItem(Items.Objects[ItemIndex]));
      m_LastShortCutCmdIndex := ItemIndex;

      if ShowOperationHint and (lstShortCut.ItemIndex >= 0) and (Length(edtShortCut.Text) < 10) and CharInSet(lstShortCut.Items[lstShortCut.ItemIndex][2], ['0'..'9']) then
        edtHint.Text := Format(resRunNum, [lstShortCut.Items[lstShortCut.ItemIndex][2], lstShortCut.Items[lstShortCut.ItemIndex][2]]);
    end;
end;

function TALTRunForm.ApplyHotKey1: Boolean;
var
  HotKeyVar: Cardinal;
begin
  Result := False;
  TraceMsg('ApplyHotKey1(%s)', [HotKeyStr1]);
  HotKeyVar := TextToHotKey(HotKeyStr1, LOCALIZED_KEYNAMES);
  if (HotKeyVar = 0) or (hkmHotkey1.AddHotKey(HotKeyVar) = 0) then
  begin
    Application.MessageBox(PChar(Format(resHotKeyError, [HotKeyStr1])), PChar(resWarning), MB_OK + MB_ICONWARNING);
    Exit;
  end;

  Result := True;
end;

function TALTRunForm.ApplyHotKey2: Boolean;
var
  HotKeyVar: Cardinal;
begin
  Result := False;
  TraceMsg('ApplyHotKey2(%s)', [HotKeyStr2]);
  HotKeyVar := TextToHotKey(HotKeyStr2, LOCALIZED_KEYNAMES);
  if (HotKeyVar = 0) or (hkmHotkey2.AddHotKey(HotKeyVar) = 0) then
  begin
    if (HotKeyStr2 <> '') and (HotKeyStr2 <> resVoidHotKey) then
    begin
      Application.MessageBox(PChar(Format(resHotKeyError, [HotKeyStr2])), PChar(resWarning), MB_OK + MB_ICONWARNING);
      HotKeyStr2 := '';
    end;
    Exit;
  end;
  Result := True;
end;

procedure TALTRunForm.btnShortCutClick(Sender: TObject);
begin
  TraceMsg('btnShortCutClick()');

  {$ifdef DEBUG_MODE}
  begin
    if ShortCutMan.Test then
      ShowMessage('True')
    else
      ShowMessage('False');
  end;
  {$else}
  begin
    actShortCutExecute(Sender);
    if m_IsShow then
    try
      edtShortCut.SetFocus;
    except
      TraceMsg('edtShortCut.SetFocus failed');
    end;
  end;
  {$endif}
end;

function TALTRunForm.DirAvailable: Boolean;
var
  itm: TShortCutItem;
  CommandLine: string;
  SlashPos: Integer;
  i: Cardinal;
begin
  Result := False;

  if lstShortCut.ItemIndex < 0 then
    Exit;

  itm := TShortCutItem(lstShortCut.Items.Objects[lstShortCut.ItemIndex]);

  //去除前导的@/@+/@-
  CommandLine := itm.CommandLine;
  if Pos(SHOW_MAX_FLAG, CommandLine) = 1 then
    CommandLine := CutLeftString(CommandLine, Length(SHOW_MAX_FLAG))
  else if Pos(SHOW_MIN_FLAG, CommandLine) = 1 then
    CommandLine := CutLeftString(CommandLine, Length(SHOW_MIN_FLAG))
  else if Pos(SHOW_HIDE_FLAG, CommandLine) = 1 then
    CommandLine := CutLeftString(CommandLine, Length(SHOW_HIDE_FLAG));

  CommandLine := RemoveQuotationMark(CommandLine, '"');

  if Pos('\\', CommandLine) > 0 then
    Exit;

  if (FileExists(CommandLine) {or DirectoryExists(CommandLine)}) then
    Result := True
  else
  begin
    if Pos('.\', CommandLine) = 1 then
      Result := True
    else
    begin
      // 查找最后一个"\"，以此来定路径
      SlashPos := 0;
      if Length(CommandLine) > 1 then
        for i := Length(CommandLine) - 1 downto 1 do
          if CommandLine[i] = '\' then
          begin
            SlashPos := i;
            Break;
          end;

      if SlashPos > 0 then
      begin
        // 如果第一个字符是"
        if CommandLine[1] = '"' then
          Result := DirectoryExists(Copy(CommandLine, 2, SlashPos - 1))
        else
          Result := DirectoryExists(Copy(CommandLine, 1, SlashPos));
      end
      else
        Result := False;
    end;
  end;

  if Result then
    TraceMsg('DirAvailable(%s) = True', [itm.CommandLine])
  else
    TraceMsg('DirAvailable(%s) = False', [itm.CommandLine]);
end;

procedure TALTRunForm.DisplayShortCutItem(Item: TShortCutItem);
begin
  TraceMsg('DisplayShortCutItem()');

  lblShortCut.Caption := Item.Name;
  lblShortCut.Hint := Item.CommandLine;
  edtCommandLine.Text := resCMDLine + Item.CommandLine;
  if DirAvailable then
    lblShortCut.Caption := '[' + Item.Name + ']';
end;

procedure TALTRunForm.edtCommandLineKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  TraceMsg('edtCommandLineKeyDown( #%d = %s )', [Key, Chr(Key)]);

  if not ((ssShift in Shift) or (ssAlt in Shift) or (ssCtrl in Shift)) then
    case Key of
      //回车
      13:
        ;

      VK_PRIOR, VK_NEXT:
        ;
    else
      if m_IsShow then
      begin
        //传到这里的键，都转发给edtShortCut
        PostMessage(edtShortCut.Handle, WM_KEYDOWN, Key, 0);

        try
          edtShortCut.SetFocus;
        except
          TraceMsg('edtShortCut.SetFocus failed');
        end;
      end;
    end;
end;

procedure TALTRunForm.MiddleMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbMiddle then
  begin
    actExecuteExecute(Sender);
  end;
end;

procedure TALTRunForm.edtShortCutChange(Sender: TObject);
var
  i, k: integer;
  StringList: TStringList;
begin
  // 有时候内容没有变化，却触发这个消息，那是因为有人主动调用它了
  //if edtShortCut.Text = m_LastShortCutText then Exit;
  //m_LastShortCutText := edtShortCut.Text;

  TraceMsg('edtShortCutChange(%s)', [edtShortCut.Text]);
  lblShortCut.Caption := '';
  lblShortCut.Hint := '';
  lstShortCut.Hint := '';
  edtCommandLine.Text := '';

  lstShortCut.Clear;

  //更新列表
  try
    StringList := TStringList.Create;
    //lstShortCut.Hide;
    if ShortCutMan.FilterKeyWord(edtShortCut.Text, StringList) then
    begin
      if ShowTopTen then
      begin
        for i := 0 to 9 do
          if i >= StringList.Count then
            Break
          else
            lstShortCut.Items.AddObject(StringList[i], StringList.Objects[i])
      end
      else
        lstShortCut.Items.Assign(StringList);
    end;

  finally
    StringList.Free;
  end;

  //显示第一项
  if lstShortCut.Count = 0 then
  begin
    lblShortCut.Caption := '';
    lblShortCut.Hint := '';
    lstShortCut.Hint := '';
    edtCommandLine.Text := '';

    //看最后一个字符是否是数字0-9
    if EnableNumberKey and m_LastKeyIsNumKey then
      if CharInSet(edtShortCut.Text[Length(edtShortCut.Text)], ['0'..'9']) then
      begin
        k := StrToInt(edtShortCut.Text[Length(edtShortCut.Text)]);

        if IndexFrom0to9 then
        begin
          if k <= m_LastShortCutListCount - 1 then
          begin
            evtMainMinimize(Self);

            ShortCutMan.Execute(TShortCutItem(m_LastShortCutPointerList[k]), Copy(edtShortCut.Text, 1, Length(edtShortCut.Text) - 1));

            edtShortCut.Text := '';
          end;
        end
        else
        begin
          if k = 0 then
            k := 10;

          if k <= m_LastShortCutListCount then
          begin
            evtMainMinimize(Self);

            ShortCutMan.Execute(TShortCutItem(m_LastShortCutPointerList[k - 1]), Copy(edtShortCut.Text, 1, Length(edtShortCut.Text) - 1));

            edtShortCut.Text := '';
          end;
        end;
      end;

    //最后一个如果是空格
    if (edtShortCut.Text <> '') and CharInSet(edtShortCut.Text[Length(edtShortCut.Text)], [' ']) then
    begin
      if (m_LastShortCutListCount > 0) and (m_LastShortCutCmdIndex >= 0) and (m_LastShortCutCmdIndex < m_LastShortCutListCount) then
      begin
        evtMainMinimize(Self);

        ShortCutMan.Execute(TShortCutItem(m_LastShortCutPointerList[m_LastShortCutCmdIndex]), Copy(edtShortCut.Text, 1, Length(edtShortCut.Text) - 1));

        edtShortCut.Text := '';

        //如果需要执行完就退出
        if ExitWhenExecute then
          tmrExit.Enabled := True;

      end;
    end;
  end
  else
  begin
    lstShortCut.ItemIndex := 0;
    lblShortCut.Caption := TShortCutItem(lstShortCut.Items.Objects[0]).Name;
    lblShortCut.Hint := TShortCutItem(lstShortCut.Items.Objects[0]).CommandLine;
    edtCommandLine.Text := resCMDLine + lblShortCut.Hint;

    //如果只有一项就立即执行
    if ExecuteIfOnlyOne and (lstShortCut.Count = 1) then
    begin
      actExecuteExecute(Sender);
    end;

  end;

  //如果可以打开文件夹，标记下
  if DirAvailable then
    lblShortCut.Caption := '[' + lblShortCut.Caption + ']';

  //刷新上一次的列表
  GetLastCmdList;

  //刷新提示
  RefreshOperationHint;
end;

procedure TALTRunForm.edtShortCutKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  Index: Integer;
begin
  TraceMsg('edtShortCutKeyDown( #%d = %s )', [Key, Chr(Key)]);

  m_LastKeyIsNumKey := False;

  //关闭tmrFocus
  tmrFocus.Enabled := False;

  case Key of
{    VK_UP:
      with lstShortCut do
        if Visible then
        begin
          //为了防止向上键导致光标位置移动，故吞掉之
          Key := VK_NONAME;

          //列表上下走
          if ItemIndex = -1 then
            ItemIndex := Count - 1
          else
            if ItemIndex = 0 then
              ItemIndex := Count - 1
            else
              ItemIndex := ItemIndex - 1;

          DisplayShortCutItem(TShortCutItem(Items.Objects[ItemIndex]));
        end;

    VK_DOWN:
      with lstShortCut do
        if Visible then
        begin
          //为了防止向下键导致光标位置移动，故吞掉之
          Key := VK_NONAME;

          //列表上下走
          if ItemIndex = -1 then
            ItemIndex := 0
          else
            if ItemIndex = Count - 1 then
              ItemIndex := 0
            else
              ItemIndex := ItemIndex + 1;

          DisplayShortCutItem(TShortCutItem(Items.Objects[ItemIndex]));
        end;
 }
    VK_PRIOR:
      with lstShortCut do
      begin
        Key := VK_NONAME;
        PostMessage(lstShortCut.Handle, WM_KEYDOWN, VK_PRIOR, 0);
      end;

    VK_NEXT:
      with lstShortCut do
      begin
        Key := VK_NONAME;
        PostMessage(lstShortCut.Handle, WM_KEYDOWN, VK_NEXT, 0);
      end;

    //数字键0-9，和小键盘数字键. ALT+Num 或 CTRL+Num 都可以执行
      48..57, 96..105:
      begin
        m_LastKeyIsNumKey := True;

        if (ssCtrl in Shift) or (ssAlt in Shift) then
        begin
          if Key >= 96 then
            Index := Key - 96
          else
            Index := Key - 48;

          //看看数字是否超出已有总数
          if IndexFrom0to9 and (Index > lstShortCut.Count - 1) then
            Exit;
          if (not IndexFrom0to9) and (Index > lstShortCut.Count) then
            Exit;

          evtMainMinimize(Self);

          if IndexFrom0to9 then
            ShortCutMan.Execute(TShortCutItem(lstShortCut.Items.Objects[Index]), edtShortCut.Text)
          else
            ShortCutMan.Execute(TShortCutItem(lstShortCut.Items.Objects[(Index + 9) mod 10]), edtShortCut.Text);

          edtShortCut.Text := '';
        end;
      end;

    //分号键 = No.2 , '号键 = No.3
      186, 222:
      begin
        if Key = 186 then
          Index := 2
        else
          Index := 3;

        //看看数字是否超出已有总数
        if IndexFrom0to9 and (Index > lstShortCut.Count - 1) then
          Exit;
        if (not IndexFrom0to9) and (Index > lstShortCut.Count) then
          Exit;

        evtMainMinimize(Self);

        if IndexFrom0to9 then
          ShortCutMan.Execute(TShortCutItem(lstShortCut.Items.Objects[Index]), edtShortCut.Text)
        else
          ShortCutMan.Execute(TShortCutItem(lstShortCut.Items.Objects[(Index + 9) mod 10]), edtShortCut.Text);

        edtShortCut.Text := '';
      end;

    //CTRL+D，打开文件夹
      68:
      begin
        if (ssCtrl in Shift) then
        begin
          KillMessage(Self.Handle, WM_CHAR);

          if not DirAvailable then
            Exit;

          evtMainMinimize(Self);
          actOpenDirExecute(Sender);
          edtShortCut.Text := '';

        end;
      end;

    //CTRL+C，复制CommandLine
      67:
      begin
        if (ssCtrl in Shift) then
        begin
          //这个方法对于中文是乱码，必须用Unicode来搞
          //Clipboard.SetTextBuf(PChar(TShortCutItem(lstShortCut.Items.Objects[lstShortCut.ItemIndex]).CommandLine));

          actCopyCommandLineExecute(Sender);
        end;
      end;

    //CTRL+L，列出最近使用的列表(最多只取10个)
      76:
      begin
        if (ssCtrl in Shift) then
        begin
          ShowLatestShortCutList;
          KillMessage(Self.Handle, WM_CHAR);
        end;
      end;

    VK_ESCAPE:
      begin
        //如果不为空，就清空，否则隐藏
        if edtShortCut.Text = '' then
          evtMainMinimize(Self)
        else
          edtShortCut.Text := '';
      end;
  end;

  if ShowOperationHint and (lstShortCut.ItemIndex >= 0) and (Length(edtShortCut.Text) < 10) and CharInSet(lstShortCut.Items[lstShortCut.ItemIndex][2], ['0'..'9']) then
    edtHint.Text := Format(resRunNum, [lstShortCut.Items[lstShortCut.ItemIndex][2], lstShortCut.Items[lstShortCut.ItemIndex][2]]);
end;

procedure TALTRunForm.edtShortCutKeyPress(Sender: TObject; var Key: Char);
begin
  TraceMsg('edtShortCutKeyPress(%d)', [Key]);

  // 看起来这块儿根本执行不到
  Exit;

  //如果回车，就执行程序
  if Key = #13 then
  begin
    Key := #0;
    actExecuteExecute(Sender);
  end;
end;

procedure TALTRunForm.edtShortCutMouseActivate(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate);
begin
  TraceMsg('edtShortCutMouseActivate()');

  RestartHideTimer(HideDelay);
end;

procedure TALTRunForm.evtMainActivate(Sender: TObject);
begin
  TraceMsg('evtMainActivate()');

  RestartHideTimer(HideDelay);
end;

procedure TALTRunForm.evtMainDeactivate(Sender: TObject);
begin
  TraceMsg('evtMainDeactivate(%d)', [GetTickCount - m_LastActiveTime]);

  // 失去焦点就一律隐藏
  evtMainMinimize(Sender);
  edtShortCut.Text := '';

end;

procedure TALTRunForm.evtMainIdle(Sender: TObject; var Done: Boolean);
begin
  ReduceWorkingSize;
end;

procedure TALTRunForm.evtMainMessage(var Msg: tagMSG; var Handled: Boolean);
begin
  case Msg.message of
    WM_SYSCOMMAND:                                     //点击关闭按钮
      if Msg.WParam = SC_CLOSE then
      begin
        {$ifdef DEBUG_MODE}
        actCloseExecute(Self);                        //如果Debug模式，可以Alt-F4关闭
        {$else}
        begin
          evtMainMinimize(Self);                       //正常模式，仅仅隐藏
          edtShortCut.Text := '';
        end
        {$endif}
      end
      else
        inherited;

    WM_QUERYENDSESSION, WM_ENDSESSION:                 //系统关机
      begin
        TraceMsg('System shutdown');
        actCloseExecute(Self);

        inherited;
      end;

    WM_MOUSEWHEEL:
      begin
        if self.IsTop then
        begin
          if Msg.wParam > 0 then
            PostMessage(lstShortCut.Handle, WM_KEYDOWN, VK_UP, 0)
          else
            PostMessage(lstShortCut.Handle, WM_KEYDOWN, VK_DOWN, 0);
        end;

        Handled := False;
      end;
  end;
end;

procedure TALTRunForm.evtMainMinimize(Sender: TObject);
begin
  inherited;

  TraceMsg('evtMainMinimize()');

  edtCopy.Visible := False;
  m_IsShow := False;
  self.Hide;
  StopTimer;
end;

procedure TALTRunForm.evtMainShortCut(var Msg: TWMKey; var Handled: Boolean);
begin
  // 在ActionList中创建actUp和actDown，分别对应SecondaryShortCuts为Shift+Tab和Tab
end;

procedure TALTRunForm.FormActivate(Sender: TObject);
begin
  TraceMsg('FormActivate()');

  RestartHideTimer(HideDelay);
end;

function SendFileNameToExistingInstance(const FileList: string): Boolean;
var
  hWnd: Cardinal;
  CopyData: TCopyDataStruct;
begin
  Result := False;
  // 查找已运行实例的主窗体
  hWnd := FindWindow('TALTRunForm', nil);
  if hWnd <> 0 then
  begin
    // 准备 WM_COPYDATA 数据
    CopyData.dwData := 0;
    CopyData.cbData := Length(FileList) * SizeOf(Char) + SizeOf(Char); // 包括结束符
    CopyData.lpData := PChar(FileList);
    // 发送消息
    SendMessage(hWnd, WM_COPYDATA, 0, LPARAM(@CopyData));
    Result := True;
  end;
end;

procedure TALTRunForm.FormCreate(Sender: TObject);
var
  LangForm: TLangForm;
  LangList: TStringList;
  i: Cardinal;
begin
  ntfMain := TCoolTrayIcon.Create(self);
  ntfmain.CycleInterval := 0;
  ntfmain.Icon := self.Icon;
  ntfmain.PopupMenu := pmMain;
  ntfmain.MinimizeToTray := true;
  ntfmain.OnClick := self.ntfMainDblClick;
  ntfmain.OnDblClick := self.ntfMainDblClick;
  //
  hkmHotkey1 := THotKeyManager.Create(self);
  hkmHotkey1.Tag := 1;
  hkmHotKey1.OnHotKeyPressed := hkmHotkeyHotKeyPressed;

  hkmHotkey2 := THotKeyManager.Create(self);
  hkmHotkey2.Tag := 2;
  hkmHotkey2.OnHotKeyPressed := hkmHotkeyHotKeyPressed;

  hkmHotkey3 := THotKeyManager.Create(self);
  hkmHotkey3.Tag := 3;
  hkmHotkey3.OnHotKeyPressed := hkmHotkeyHotKeyPressed;
  // ==================================================
  //
  //


  Self.Caption := TITLE;

  //初始化不显示图标
  ntfMain.IconVisible := False;

  //窗体防闪
  Self.DoubleBuffered := True;
  lstShortCut.DoubleBuffered := True;
  edtShortCut.DoubleBuffered := True;
  edtHint.DoubleBuffered := True;
  edtCommandLine.DoubleBuffered := True;
  edtCopy.DoubleBuffered := True;

  //Load 配置
  //LoadSettings;

  m_IsExited := False;

  //如果是第一次使用，提示选择语言
  if IsRunFirstTime then
  begin
    LangList := nil;
    LangForm := nil;
    try
      LangForm := TLangForm.Create(Self);

      LangForm.cbbLang.Items.Add(DEFAULT_LANG);
      LangForm.cbbLang.ItemIndex := 0;

      LangList := TStringList.Create;
      if GetLangList(LangList) then
      begin
        if LangList.Count > 0 then
        begin
          for i := 0 to LangList.Count - 1 do
            if LangForm.cbbLang.Items.IndexOf(LangList.Strings[i]) < 0 then
              LangForm.cbbLang.Items.Add(LangList.Strings[i]);

          for i := 0 to LangForm.cbbLang.Items.Count - 1 do
            if LangForm.cbbLang.Items[i] = Lang then
            begin
              LangForm.cbbLang.ItemIndex := i;
              Break;
            end;
        end;
      end;

      if LangList.Count > 0 then
      begin
        // 专门为了简体中文
        if Lang = '简体中文' then
          LangForm.Caption := '请选择界面语言';

        LangForm.ShowModal;

        if LangForm.ModalResult = mrOk then
        begin
          Lang := LangForm.cbbLang.Text;
          SetActiveLanguage;
        end
        else
        begin
          DeleteFile(ExtractFilePath(Application.ExeName) + TITLE + '.ini');
          Halt(1);
        end;
      end;

    finally
      FreeAndNil(LangList);
      FreeAndNil(LangForm);
    end;
  end
  else
  begin
    SetActiveLanguage;
  end;

  //Load 快捷方式
  ShortCutMan := TShortCutMan.Create;
  ShortCutMan.LoadShortCutList;

  //初始化上次列表
  m_LastShortCutCmdIndex := -1;
  m_LastKeyIsNumKey := False;

  //Trace
  TraceMsg('FormCreate()');

  //判断是否是Vista
  TraceMsg('OS is Vista = %s', [BoolToStr(IsVista)]);

  //干掉老的HotRun的启动项和SendTo
  if LowerCase(ExtractFilePath(GetAutoRunItemPath('HotRun'))) = LowerCase(ExtractFilePath(Application.ExeName)) then
    SetAutoRun('HotRun', '', False);

  if LowerCase(ExtractFilePath(GetAutoRunItemPath('HotRun.exe'))) = LowerCase(ExtractFilePath(Application.ExeName)) then
  begin
    SetAutoRun('HotRun.exe', '', False);
    SetAutoRunInStartUp('HotRun.exe', '', False);
  end;

  if LowerCase(ExtractFilePath(ResolveLink(GetSendToDir + '\HotRun.lnk'))) = LowerCase(ExtractFilePath(Application.ExeName)) then
    AddMeToSendTo('HotRun', False);

  if FileExists(ExtractFilePath(Application.ExeName) + 'HotRun.ini') then
    RenameFile(ExtractFilePath(Application.ExeName) + 'HotRun.ini', ExtractFilePath(Application.ExeName) + TITLE + '.ini');

  if LowerCase(ExtractFilePath(GetAutoRunItemPath('ALTRun.exe'))) = LowerCase(ExtractFilePath(Application.ExeName)) then
  begin
    SetAutoRun('ALTRun.exe', '', False);
    SetAutoRunInStartUp('ALTRun.exe', '', False);
  end;

  //配置设置
  ApplyHotKey1;
  ApplyHotKey2;

  //TODO: 暂时以ALT+L作为调用最近一次快捷项的热键
  hkmHotkey3.AddHotKey(TextToHotKey(LastItemHotKeyStr, LOCALIZED_KEYNAMES));

  //配置菜单语言
  actShow.Caption := resMenuShow;
  actShortCut.Caption := resMenuShortCut;
  actConfig.Caption := resMenuConfig;
  actOpenAltRunDir.Caption := resOpenAltRunDir;
  actAbout.Caption := resMenuAbout;
  actClose.Caption := resMenuClose;

  //配置Hint
  btnShortCut.Hint := resBtnShortCutHint;
  btnConfig.Hint := resBtnConfigHint;
  btnClose.Hint := resBtnFakeCloseHint;
  edtShortCut.Hint := resEdtShortCutHint;

  //先删除后增加，目的是防止有人放到别的目录运行，导致出现多个启动项
  SetAutoRun(TITLE, Application.ExeName, False);
  SetAutoRunInStartUp(TITLE, Application.ExeName, False);

  //如果是第一次使用，提示是否添加到自动启动
  if IsRunFirstTime then
    AutoRun := (Application.MessageBox(PChar(resAutoRunWhenStart), PChar(resInfo), MB_YESNO + MB_ICONQUESTION + MB_TOPMOST) = IDYES);

  //SetAutoRun(TITLE, Application.ExeName, AutoRun);
  SetAutoRunInStartUp(TITLE, Application.ExeName, AutoRun);

  AddMeToSendTo(TITLE, False);

  //如果是第一次使用，提示是否添加到发送到
  if IsRunFirstTime then
    AddToSendTo := (Application.MessageBox(PChar(resAddToSendToMenu), PChar(resInfo), MB_YESNO + MB_ICONQUESTION + MB_TOPMOST) = IDYES);

  //添加到发送到
  AddMeToSendTo(TITLE, AddToSendTo);

  //保存设置
  HandleID := Self.Handle;
  SaveSettings;

  //如果是第一次使用，重启一次以保证右键发送到不受影响
  if IsRunFirstTime then
  begin
    RestartMe;
    Exit;
  end;

  //第一次显示
  m_IsFirstShow := True;

  //第一次双击图标
  m_IsFirstDblClickIcon := True;

  //显示图标
  ntfMain.IconVisible := ShowTrayIcon;

  //显示按钮
  btnShortCut.Visible := ShowShortCutButton;
  btnConfig.Visible := ShowConfigButton;
  btnClose.Visible := ShowCloseButton;

  //提示
  if ShowStartNotification then
    ntfMain.ShowBalloonHint(resInfo, Format(resStarted + #13#10 + resPressKeyToShowMe, [TITLE, ALTRUN_VERSION, GetHotKeyString]), bitInfo, 5);

  //浮动提示
  ntfMain.Hint := ansistring(Format(resMainHint, [TITLE, ALTRUN_VERSION, #13#10, GetHotKeyString]));

  //需要刷新
  m_NeedRefresh := True;

  if ShowMeWhenStart then
    actShowExecute(Sender);
end;

procedure TALTRunForm.FormDestroy(Sender: TObject);
begin
  //如果是右键添加启动的程序，保存文件时，不改变修改时间
  //这样正常运行的主程序不需要
  //if m_IsExited then FileSetDate(ShortCutMan.ShortCutFileName, m_AgeOfFile);

  ShortCutMan.Free;
end;

procedure TALTRunForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  TraceMsg('FormKeyDown( #%d = %s )', [Key, Chr(Key)]);

  //取得最近一次击键时间
  m_LastActiveTime := GetTickCount;

  //关闭tmrFocus
  tmrFocus.Enabled := False;

  //重起Timer
  RestartHideTimer(HideDelay);

  //如果命令行获得焦点，就什么也不管
  if edtCommandLine.Focused then
    Exit;

  case Key of
    VK_UP:
      with lstShortCut do
      begin
        //为了防止向上键导致光标位置移动，故吞掉之
        Key := VK_NONAME;

        if Count = 0 then
          Exit;

        //列表上下走
        if ItemIndex = -1 then
          ItemIndex := Count - 1
        else if ItemIndex = 0 then
          ItemIndex := Count - 1
        else
          ItemIndex := ItemIndex - 1;

        DisplayShortCutItem(TShortCutItem(Items.Objects[ItemIndex]));
        m_LastShortCutCmdIndex := ItemIndex;
      end;

    VK_DOWN:
      with lstShortCut do
      begin
        //为了防止向下键导致光标位置移动，故吞掉之
        Key := VK_NONAME;

        if Count = 0 then
          Exit;

        //列表上下走
        if ItemIndex = -1 then
          ItemIndex := 0
        else if ItemIndex = Count - 1 then
          ItemIndex := 0
        else
          ItemIndex := ItemIndex + 1;

        DisplayShortCutItem(TShortCutItem(Items.Objects[ItemIndex]));
        m_LastShortCutCmdIndex := ItemIndex;
      end;

    VK_F1:
      begin
        Key := VK_NONAME;
        actAboutExecute(Sender);
      end;

    VK_F2:
      begin
        Key := VK_NONAME;
        actEditItemExecute(Sender);
      end;

    VK_INSERT:
      begin
        Key := VK_NONAME;
        actAddItemExecute(Sender);
      end;

    VK_DELETE:
      begin
        if lstShortCut.ItemIndex >= 0 then
        begin
          Key := VK_NONAME;
          actDeleteItemExecute(Sender);
        end;
      end;

    VK_ESCAPE:
      begin
        Key := VK_NONAME;

        //如果不为空，就清空，否则隐藏
        if edtShortCut.Text = '' then
          evtMainMinimize(Self)
        else
          edtShortCut.Text := '';
      end;

    {分别对actConfig和actShortCut分配了快捷键
    //ALT+C，显示配置窗口
    $43:
      begin
        if (ssAlt in Shift) then actConfigExecute(Sender);
      end;

    //ALT+S，显示快捷键列表
    $53:
      begin
        if (ssAlt in Shift) then actShortCutExecute(Sender);
      end;
    }
  else
    begin
      if m_IsShow then
      try
        edtShortCut.SetFocus;
      except
        TraceMsg('edtShortCut.SetFocus failed');
      end;
    end;
  end;
end;

procedure TALTRunForm.FormKeyPress(Sender: TObject; var Key: Char);
begin
  TraceMsg('FormKeyPress(%s)', [Key]);

  //关闭tmrFocus
  tmrFocus.Enabled := False;

  case Key of
    //如果回车，就执行程序
    #13:
      begin
        Key := #0;
        if Self.Visible then
          actExecuteExecute(Sender);
      end;

    //如果ESC，就吞掉
        #27:
      begin
        Key := #0;
      end;
  end;
end;

function TALTRunForm.GetHotKeyString: string;
begin
  if (HotKeyStr2 = '') or (HotKeyStr2 = resVoidHotKey) then
    Result := HotKeyStr1
  else
    Result := Format('%s %s %s', [HotKeyStr1, resWordOr, HotKeyStr2]);
end;

function TALTRunForm.GetLangList(List: TStringList): Boolean;
var
  i: Cardinal;
  FileList: TStringList;
begin
  TraceMsg('GetLangList()');

  try
    FileList := TStringList.Create;
    List.Clear;

    if GetFileListInDir(FileList, ExtractFileDir(Application.ExeName), 'lang', False) then
    begin
      if FileList.Count > 0 then
        for i := 0 to FileList.Count - 1 do
          List.Add(Copy(FileList.Strings[i], 1, Length(FileList.Strings[i]) - 5));

      Result := True;
    end
    else
      Result := False;
  finally
    FileList.Free;
  end;
end;

procedure TALTRunForm.GetLastCmdList;
var
  i, n: Cardinal;
begin
  TraceMsg('GetLastCmdList()');

  m_LastShortCutListCount := 0;
  m_LastShortCutCmdIndex := -1;

  if lstShortCut.Count > 0 then
  begin
    m_LastShortCutCmdIndex := lstShortCut.ItemIndex;

    if lstShortCut.Count > 10 then
      n := 10
    else
      n := lstShortCut.Count;

    for i := 0 to n - 1 do
    begin
      if lstShortCut.Items.Objects[i] <> nil then
      begin
        m_LastShortCutPointerList[m_LastShortCutListCount] := Pointer(lstShortCut.Items.Objects[i]);
        Inc(m_LastShortCutListCount);
      end;
    end;
  end;
end;

procedure TALTRunForm.hkmHotkey3HotKeyPressed(HotKey: Cardinal; Index: Word);
var
  Buf: array[0..254] of Char;
  StringList: TStringList;
begin
  TraceMsg('hkmHotkey3HotKeyPressed(%d)', [HotKey]);

  // 取得当前剪贴板中的文字
  ShortCutMan.Param[0] := Clipboard.AsUnicodeText;

  // 取得当前前台窗体ID及标题
  ShortCutMan.Param[1] := IntToStr(GetForegroundWindow);
  GetWindowText(GetForegroundWindow, Buf, 255);
  if Buf <> '' then
    ShortCutMan.Param[2] := Buf;
  GetClassName(GetForegroundWindow, Buf, 255);
  if Buf <> '' then
    ShortCutMan.Param[3] := Buf;

  TraceMsg('WinID = %s, WinCaption = %s, Class = %s', [ShortCutMan.Param[1], ShortCutMan.Param[2], ShortCutMan.Param[3]]);

  // 取得最近一次的项目
  try
    StringList := TStringList.Create;
    ShortCutMan.GetLatestShortCutItemList(StringList);
    if StringList.Count > 0 then
      ShortCutMan.Execute(TShortCutItem(StringList.Objects[0]));
  finally
    StringList.Free;
  end;
end;

procedure TALTRunForm.hkmHotkeyHotKeyPressed(HotKey: Cardinal; Index: Word);
var
  Buf: array[0..254] of Char;
begin
  TraceMsg('hkmMainHotKeyPressed(%d)', [HotKey]);

  {$ifdef DEBUG_SORT}
  begin
    actShortCutExecute(Self);
    Exit;
  end;
  {$ENDIF}

  // 取得当前剪贴板中的文字
  ShortCutMan.Param[0] := Clipboard.AsUnicodeText;

  // 取得当前前台窗体ID, 标题, Class
  ShortCutMan.Param[1] := IntToStr(GetForegroundWindow);
  GetWindowText(GetForegroundWindow, Buf, 255);
  if Buf <> '' then
    ShortCutMan.Param[2] := Buf;
  GetClassName(GetForegroundWindow, Buf, 255);
  if Buf <> '' then
    ShortCutMan.Param[3] := Buf;

  TraceMsg('WinID = %s, WinCaption = %s, Class = %s', [ShortCutMan.Param[1], ShortCutMan.Param[2], ShortCutMan.Param[3]]);

  if m_IsShow then
    actHideExecute(Self)
  else
    actShowExecute(Self);
end;

procedure TALTRunForm.imgBackgroundMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    ReleaseCapture;
    SendMessage(Handle, WM_SYSCOMMAND, SC_DRAGMOVE, 0);
  end
  else if Button = mbMiddle then
  begin
    actExecuteExecute(Sender);
  end;
end;

procedure TALTRunForm.lblShortCutMouseActivate(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate);
begin
  TraceMsg('lblShortCutMouseActivate()');

  RestartHideTimer(HideDelay);
end;

procedure TALTRunForm.lblShortCutMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    ReleaseCapture;
    SendMessage(Handle, WM_SYSCOMMAND, SC_DRAGMOVE, 0);
  end
  else if Button = mbMiddle then
  begin
    actExecuteExecute(Sender);
  end;
end;

procedure TALTRunForm.lstShortCutKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  TraceMsg('lstShortCutKeyDown( #%d = %s )', [Key, Chr(Key)]);

  //关闭tmrFocus
  tmrFocus.Enabled := False;

  case Key of
    //    VK_F2:
    //      actEditItemExecute(Sender);
    //
    //    VK_INSERT:
    //      actAddItemExecute(Sender);
    //
    //    VK_DELETE:
    //      actDeleteItemExecute(Sender);

    //回车
    13:
      ;

    VK_PRIOR, VK_NEXT:
      ;
  else
    if m_IsShow then
    begin
      //传到这里的键，都转发给edtShortCut
      PostMessage(edtShortCut.Handle, WM_KEYDOWN, Key, 0);

      try
        edtShortCut.SetFocus;
      except
        TraceMsg('edtShortCut.SetFocus failed');
      end;
    end;
  end;
end;

procedure TALTRunForm.lstShortCutMouseActivate(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate);
begin
  TraceMsg('lstShortCutMouseActivate()');

  RestartHideTimer(HideDelay);
end;

procedure TALTRunForm.lstShortCutMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  TraceMsg('lstShortCutMouseDown()');

  //右键点击，就选中该项
  if Button = mbRight then
  begin
    lstShortCut.Perform(WM_LBUTTONDOWN, MK_LBUTTON, (Y shl 16) + X);
    actSelectChangeExecute(Sender);
  end
  else if Button = mbMiddle then
  begin
    //lstShortCut.Perform(WM_LBUTTONDOWN, 0, (y shl 16) + x);
    actExecuteExecute(Sender);
  end;
end;

procedure TALTRunForm.ntfMainDblClick(Sender: TObject);
var
  AutoHideForm: TAutoHideForm;
begin
  TraceMsg('ntfMainDblClick()');

  if m_IsFirstDblClickIcon then
  begin
    m_IsFirstDblClickIcon := False;

    //对话框没法消失，不优秀，换成自动消失的
    //Application.MessageBox(
    //  PChar(Format(resShowMeByHotKey, [HotKeyStr])),
    //  PChar(resInfo), MB_OK + MB_ICONINFORMATION + MB_TOPMOST);


    AutoHideForm := nil;
    try
      AutoHideForm := TAutoHideForm.Create(Self);
      AutoHideForm.Caption := resInfo;
      AutoHideForm.Info := Format(resShowMeByHotKey, [HotKeyStr1]);
      AutoHideForm.Info := Format(resShowMeByHotKey, [GetHotKeyString]);
      AutoHideForm.ShowModal;
    finally
      freeandnil(AutoHideForm);
    end;
  end;

  if m_IsShow then
    actHideExecute(Self)
  else
    actShowExecute(Self);
end;

procedure TALTRunForm.pmListPopup(Sender: TObject);
begin
  mniOpenDir.Visible := DirAvailable;
  mniN1.Visible := mniOpenDir.Visible
end;

procedure TALTRunForm.RefreshOperationHint;
var
  HintIndex: Integer;
begin
  TraceMsg('RefreshOperationHint()');

  //刷新提示
  if not ShowOperationHint then
    edtHint.Hide
  else
  begin
    edtHint.Show;
    if Length(edtShortCut.Text) = 0 then
    begin
      //随机挑选一个提示显示出来
      Randomize;

      repeat
        HintIndex := Random(Length(HintList));
      until Trim(HintList[HintIndex]) <> '';

      edtHint.Text := HintList[HintIndex];
    end
    else if Length(edtShortCut.Text) < 6 then
    begin
      if lstShortCut.Count = 0 then
      begin
        edtHint.Text := resKeyToAdd;
      end
      else if DirAvailable then
        edtHint.Text := resKeyToOpenFolder
      else
        edtHint.Text := resKeyToRun;
    end
    else
      edtHint.Hide;
  end;
end;

procedure TALTRunForm.RestartMe;
begin
  TraceMsg('RestartMe()');

  ShellExecute(0, nil, PChar(Application.ExeName), RESTART_FLAG, nil, SW_SHOWNORMAL);
  actCloseExecute(Self);
end;

procedure TALTRunForm.RestartHideTimer(Delay: Integer);
begin
  TraceMsg('RestartHideTimer()');

  if m_IsShow then
  begin
    tmrHide.Enabled := False;
    tmrHide.Interval := Delay * 1000;
    tmrHide.Enabled := True;
  end;
end;

procedure TALTRunForm.ShowLatestShortCutList;
var
  StringList: TStringList;
begin
  TraceMsg('ShowLatestShortCutList');

  lblShortCut.Caption := '';
  lblShortCut.Hint := '';
  lstShortCut.Hint := '';
  edtCommandLine.Text := '';

  lstShortCut.Clear;

  try
    StringList := TStringList.Create;
    ShortCutMan.GetLatestShortCutItemList(StringList);
    lstShortCut.Items.Assign(StringList);
    m_NeedRefresh := True;
  finally
    StringList.Free;
  end;

  if lstShortCut.Count = 0 then
  begin
    lblShortCut.Caption := '';
    lblShortCut.Hint := '';
    lstShortCut.Hint := '';
    edtCommandLine.Text := '';
  end
  else
  begin
    lstShortCut.ItemIndex := 0;
    lblShortCut.Caption := TShortCutItem(lstShortCut.Items.Objects[0]).Name;
    lblShortCut.Hint := TShortCutItem(lstShortCut.Items.Objects[0]).CommandLine;
    edtCommandLine.Text := resCMDLine + lblShortCut.Hint;
  end;

  //如果可以打开文件夹，标记下
  if DirAvailable then
    lblShortCut.Caption := '[' + lblShortCut.Caption + ']';

  //更新最近的命令列表
  GetLastCmdList;

  //刷新提示
  RefreshOperationHint;
end;

procedure TALTRunForm.StopTimer;
begin
  TraceMsg('StopTimer()');

  tmrHide.Enabled := False;
  tmrFocus.Enabled := False;
end;

procedure TALTRunForm.tmrCopyTimer(Sender: TObject);
begin
  tmrCopy.Enabled := False;
  edtCopy.Hide;
end;

procedure TALTRunForm.tmrExitTimer(Sender: TObject);
begin
  TraceMsg('tmrExitTimer()');

  tmrExit.Enabled := False;
  actCloseExecute(Sender);
end;

procedure TALTRunForm.tmrFocusTimer(Sender: TObject);
begin
  TraceMsg('tmrFocusTimer()');

  tmrFocus.Enabled := False;

  // 因为将窗体重新置于前台经常失败，故放弃这个Timer
  Exit;

  {
  // 如果窗体显示却没有获得焦点，则获得焦点
  if m_IsShow then
  begin
    try
      TraceMsg('Lost Focus, try again');

      SetForegroundWindow(Application.Handle);
      edtShortCut.SetFocus;
    except
      TraceMsg('edtShortCut.SetFocus failed');
      tmrFocus.Enabled := True;
    end;
  end;
  }
end;

procedure TALTRunForm.tmrHideTimer(Sender: TObject);
begin
  TraceMsg('tmrHideTimer()');

  evtMainMinimize(Sender);
  edtShortCut.Text := '';
end;

procedure TALTRunForm.tmrScannerTimer(Sender: TObject);

  function IsTime1205: Boolean;
  var
    CurrentTime: TDateTime;
  begin
    CurrentTime := Now;
    Result := (HourOf(CurrentTime) = 12) and (MinuteOf(CurrentTime) = 5) or true;
  end;

var
  lst: TList<TShortCutItem>;
  item: TShortCutItem;
  bAdded: boolean;
begin   // 50s 一次
  if IsTime1205() then
  begin
    bAdded := false;

    try
      lst := ScanShortCutItems;
      // 遍历并添加未存在的项
      for item in lst do
      begin
        if not ShortCutMan.ContainShortCutItem(item) then
        begin
          ShortCutMan.AppendShortCutItem(item);
          bAdded := TRUE;
        end
        else
        begin
          item.free;
        end;
      end;
      if bAdded then
      begin
        ShortCutMan.SaveShortCutList;
        ShortCutMan.LoadShortCutList;
      end;
    finally
      lst.Free; // 自动释放未被 Append 的 TShortCutItem
    end;
  end;
end;

procedure TALTRunForm.WndProc(var Msg: TMessage);
var
  FileName: string;
begin
  case Msg.Msg of
    WM_ALTRUN_SHOW_WINDOW:
      begin
        TraceMsg('WM_ALTRUN_SHOW_WINDOW');

        actShowExecute(Self);
        SetForegroundWindow(Application.Handle);
      end;

    WM_SETTEXT:
      begin
        //Msg.WParam = 1 表示是自己程序发过来的
        if Msg.WParam = 1 then
        begin
          FileName := StrPas(PChar(Msg.LParam));
          TraceMsg('Received FileName = %s', [FileName]);

          ShortCutMan.AddFileShortCut(FileName);
        end;
      end;

    WM_SETTINGCHANGE:
      begin
      // 用户环境变量发生变化，故强行再次读取，然后设置以生效

      // When the system sends this message as a result of a change in locale settings, this parameter is zero.
      // To effect a change in the environment variables for the system or the user,
      // broadcast this message with lParam set to the string "Environment".
        if (Msg.WParam = 0) and ((PChar(Msg.LParam)) = 'Environment') then
        begin
        // 根据注册表内容，强行刷新自身的环境变量
          RefreshEnvironmentVars;
        end;

        inherited;
      end;

  else
    //TraceMsg('msg.Msg = %d, msg.LParam = %d, ms.WParam = %d', [msg.Msg, msg.LParam, msg.WParam]);
    inherited;
  end;
end;

function TALTRunForm.readIsTop: Boolean;
begin
  result := self.formStyle = fsStayOnTop;
end;

procedure TALTRunForm.writeTop(b: Boolean);
begin
  if b then
    self.formStyle := fsStayOnTop
  else
    self.formStyle := fsNormal;
end;

procedure TALTRunForm.Receive_SendTo_Filename(var Msg: TWMCopyData);
var
  FileList: string;
begin
  TraceMsg('WM_ALTRUN_ADD_SHORTCUT');
  // 接收 WM_COPYDATA 消息中的文件列表
  FileList := PChar(Msg.CopyDataStruct.lpData);

  self.IsTop := False;
  ShortCutMan.AddFileShortCut(FileList);
  self.IsTop := True;
  if m_IsShow then
    edtShortCutChange(Self);

  ShortCutMan.SaveShortCutList;
  ShortCutMan.LoadShortCutList;

  // Msg.Result := 1; 表示消息被成功处理（成功接收并处理数据）。
  // Msg.Result := 0; 表示消息未被处理或处理失败。
  Msg.Result := 1;
end;

end.

