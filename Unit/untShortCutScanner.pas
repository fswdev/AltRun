unit untShortCutScanner;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections, untshortCutMan;

function ScanShortCutItems: TList<TShortCutItem>;

implementation

uses
  Winapi.Windows, Winapi.ShlObj, System.IOUtils, untPinYin, Winapi.ActiveX;

const
  SLGP_RAWPATHNAME = 4; // �ֶ����壬IShellLink.GetPath�ı�־

function ExtractLnkInfo(const LnkPath: string; out TargetPath, WorkingDirectory: string): Boolean;
var
  ShellLink: IShellLink;
  PersistFile: IPersistFile;
  Buffer: array[0..MAX_PATH] of Char;
  FindData: TWin32FindData;
begin
  Result := False;
  TargetPath := '';
  WorkingDirectory := '';

  // ��ʼ��COM
  if Failed(CoInitialize(nil)) then
    Exit;

  try
    // ����IShellLinkʵ��
    if Failed(CoCreateInstance(CLSID_ShellLink, nil, CLSCTX_INPROC_SERVER, IID_IShellLink, ShellLink)) then
      Exit;

    // ��ȡIPersistFile�ӿ�
    if Failed(ShellLink.QueryInterface(IPersistFile, PersistFile)) then
      Exit;

    // ����.lnk�ļ�
    if Failed(PersistFile.Load(PWideChar(LnkPath), STGM_READ)) then
      Exit;

    // ��ȡĿ��·��
    if Succeeded(ShellLink.GetPath(Buffer, MAX_PATH, FindData, SLGP_RAWPATHNAME)) then
      TargetPath := Buffer;

    // ��ȡ����Ŀ¼
    if Succeeded(ShellLink.GetWorkingDirectory(Buffer, MAX_PATH)) then
      WorkingDirectory := Buffer;

    // ���Ŀ��·���ǿգ���Ϊ�����ɹ�
    Result := TargetPath <> '';
  finally
    CoUninitialize;
  end;
end;

function GetSpecialFolderPath(CSIDL: Integer): string;
var
  Path: array[0..MAX_PATH] of Char;
begin
  if SHGetSpecialFolderPath(0, Path, CSIDL, False) then
    Result := IncludeTrailingPathDelimiter(Path)
  else
    Result := '';
end;

procedure ScanDirectoryForShortcuts(const Directory: string; ShortCutList: TList<TShortCutItem>);
var
  Files: TArray<string>;
  FileName, FilePath, s_name, Pinyin: string;
  Item: TShortCutItem;
  TargetPath, WorkingDirectory: string;
begin
  if not TDirectory.Exists(Directory) then
    Exit;

  try
    // ɨ�� .lnk �ļ�
    Files := TDirectory.GetFiles(Directory, '*.lnk', TSearchOption.soAllDirectories);
    for FilePath in Files do
    begin
      FileName := TPath.GetFileName(FilePath);

      // �������� "Uninstall" �� "ж��" ���ļ������Դ�Сд��
      if (Pos('UNINSTALL', UpperCase(FileName)) = 0) and (Pos('ж��', FileName) = 0) then
      begin
        Item := TShortCutItem.Create;
        try
          s_name := TPath.ChangeExtension(FileName, ''); // ȥ�� .lnk ��չ��
          ExtractLnkInfo(FilePath, TargetPath, WorkingDirectory);
          Item.ShortCutType := scItem;
          Item.ParamType := ptNone;
          Item.ShortCut := s_name;
          Item.Name := s_name;
          Item.CommandLine := format('"%s"', [TargetPath]); // ����·��
          Item.WorkingDir := format('"%s"', [WorkingDirectory]);
          Item.Rank := 0;
          Item.Freq := 0;
          Item.RunAsAdmin := False;
          ShortCutList.Add(Item);
        except
          Item.Free;
          raise;
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      // ��ѡ����¼������־
      // ������������Ŀ¼
    end;
  end;
end;

function ScanShortCutItems: TList<TShortCutItem>;
var
  ShortCutList: TList<TShortCutItem>;
  DesktopPath, CommonProgramsPath, ProgramsPath: string;
begin
  ShortCutList := TList<TShortCutItem>.Create;

  try
    // ��ȡ�����ļ���·��
    DesktopPath := GetSpecialFolderPath(CSIDL_DESKTOP);
    CommonProgramsPath := GetSpecialFolderPath(CSIDL_COMMON_PROGRAMS);
    ProgramsPath := GetSpecialFolderPath(CSIDL_PROGRAMS);

    // ɨ��ÿ��Ŀ¼
    if DesktopPath <> '' then
      ScanDirectoryForShortcuts(DesktopPath, ShortCutList);
    if CommonProgramsPath <> '' then
      ScanDirectoryForShortcuts(CommonProgramsPath, ShortCutList);
    if ProgramsPath <> '' then
      ScanDirectoryForShortcuts(ProgramsPath, ShortCutList);
  except
    on E: Exception do
    begin
      // �ͷ��Ѵ�������
      for var Item in ShortCutList do
        Item.Free;
      ShortCutList.Free;
      raise;
    end;
  end;

  Result := ShortCutList;
end;

end.

