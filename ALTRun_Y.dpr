program ALTRun_Y;

uses
  Forms,
  SysUtils,
  Windows,
  Messages,
  Dialogs,
  frmALTRun in 'Form\frmALTRun.pas' {ALTRunForm},
  frmConfig in 'Form\frmConfig.pas' {ConfigForm},
  frmShortCut in 'Form\frmShortCut.pas' {ShortCutForm},
  untUtilities in 'Unit\untUtilities.pas',
  untALTRunOption in 'Unit\untALTRunOption.pas',
  frmShortCutMan in 'Form\frmShortCutMan.pas' {ShortCutManForm},
  untShortCutMan in 'Unit\untShortCutMan.pas',
  frmAbout in 'Form\frmAbout.pas' {AboutForm},
  frmParam in 'Form\frmParam.pas' {ParamForm},
  frmHelp in 'Form\frmHelp.pas' {HelpForm},
  frmInvalid in 'Form\frmInvalid.pas' {InvalidForm},
  frmLang in 'Form\frmLang.pas' {LangForm},
  frmAutoHide in 'Form\frmAutoHide.pas' {AutoHideForm},
  untLogger in 'Unit\untLogger.pas',
  untClipboard in 'Unit\untClipboard.pas',
  CoolTrayIcon in '3rdUnit\CoolTrayIcon\CoolTrayIcon.pas',
  RegisterTrayIcons in '3rdUnit\CoolTrayIcon\RegisterTrayIcons.pas',
  SimpleTimer in '3rdUnit\CoolTrayIcon\SimpleTimer.pas',
  TextTrayIcon in '3rdUnit\CoolTrayIcon\TextTrayIcon.pas',
  HotKeyManager in '3rdUnit\HotKeyManager\HotKeyManager.pas';

{$R *.res}

function SendFileNameToExistingInstance(const FileList: string): Boolean;
var
  hWnd: Cardinal;
  CopyData: TCopyDataStruct;
begin
  Result := False;
  // ����������ʵ����������
  hWnd := FindWindow('TALTRunForm', nil);
  if hWnd <> 0 then
  begin
    // ׼�� WM_COPYDATA ����
    CopyData.dwData := 0;
    CopyData.cbData := Length(FileList) * SizeOf(Char) + SizeOf(Char); // ����������
    CopyData.lpData := PChar(FileList);
    // ������Ϣ
    SendMessage(hWnd, WM_COPYDATA, 0, LPARAM(@CopyData));
    hWnd := getlasterror();
    if hWnd > 0 then
      showmessage('��AltRun�������ʧ��,����: ' + SysErrorMessage(hWnd));
    Result := True;
  end;
end;

begin
  //----- �ڴ�й©����
  //  mmPopupMsgDlg := DEBUG_MODE;
  //  mmShowObjectInfo := DEBUG_MODE;
  //  mmUseObjectList := DEBUG_MODE;
  //  mmSaveToLogFile := DEBUG_MODE;

  //----- Trace
  //  InitLogger(DEBUG_MODE,DEBUG_MODE, False);

   //���в��������ж�֮
  if ParamStr(1) <> '' then
  begin
    //�Զ��������
    if ParamStr(1) = RESTART_FLAG then
    begin
      Sleep(2000);
    end
    else if ParamStr(1) = CLEAN_FLAG then         //ɾ�����ʱ������
    begin
      if Application.MessageBox(PChar(resCleanConfirm), PChar(resInfo), MB_YESNO + MB_ICONQUESTION + MB_TOPMOST) = IDYES then
      begin
        SetAutoRun(TITLE, '', False);
        SetAutoRunInStartUp(TITLE, '', False);
        AddMeToSendTo(TITLE, False);
      end;
      Application.Terminate;
      Exit;
    end
    else
    begin
      if IsRunningInstance('ALTRUN_MUTEX') then
      begin
        SendFileNameToExistingInstance(ParamStr(1));
        exit;
      end;
    end;
  end
  else
  begin
    if IsRunningInstance('ALTRUN_MUTEX') then
    begin
        // ������Ϣ����ALTRun��ʾ����
      SendMessage(FindWindow('TALTRunForm', nil), WM_ALTRUN_SHOW_WINDOW, 0, 0);
      exit;
    end;
  end;

  //----- ������ʼ
  Application.Initialize;

  IsRunFirstTime := not FileExists(ExtractFilePath(Application.ExeName) + TITLE + '.ini');
  LoadSettings;
  //SaveSettings;

  Application.Title := TITLE;
//  Application.CreateForm(TParamForm, ParamForm);
  Application.CreateForm(TALTRunForm, ALTRunForm);
  Application.ShowMainForm := False;
  Application.OnMinimize := ALTRunForm.evtMainMinimize;

  //����ô���������ڴ�й¶
  if not ALTRunForm.IsExited then
    Application.Run;

  SaveSettings;
end.

