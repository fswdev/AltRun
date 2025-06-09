unit untShortCutScanner;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections, untshortCutMan;

function ScanShortCutItems: TList<TShortCutItem>;

implementation

uses
  Winapi.Windows, Winapi.ShlObj, System.IOUtils, untPinYin, Winapi.ActiveX;

const
  SLGP_RAWPATHNAME = 4; // 手动定义，IShellLink.GetPath的标志

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

  // 初始化COM
  if Failed(CoInitialize(nil)) then
    Exit;

  try
    // 创建IShellLink实例
    if Failed(CoCreateInstance(CLSID_ShellLink, nil, CLSCTX_INPROC_SERVER, IID_IShellLink, ShellLink)) then
      Exit;

    // 获取IPersistFile接口
    if Failed(ShellLink.QueryInterface(IPersistFile, PersistFile)) then
      Exit;

    // 加载.lnk文件
    if Failed(PersistFile.Load(PWideChar(LnkPath), STGM_READ)) then
      Exit;

    // 获取目标路径
    if Succeeded(ShellLink.GetPath(Buffer, MAX_PATH, FindData, SLGP_RAWPATHNAME)) then
      TargetPath := Buffer;

    // 获取工作目录
    if Succeeded(ShellLink.GetWorkingDirectory(Buffer, MAX_PATH)) then
      WorkingDirectory := Buffer;

    // 如果目标路径非空，认为解析成功
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
    // 扫描 .lnk 文件
    Files := TDirectory.GetFiles(Directory, '*.lnk', TSearchOption.soAllDirectories);
    for FilePath in Files do
    begin
      FileName := TPath.GetFileName(FilePath);

      // 跳过包含 "Uninstall" 或 "卸载" 的文件（忽略大小写）
      if (Pos('UNINSTALL', UpperCase(FileName)) = 0) and (Pos('卸载', FileName) = 0) then
      begin
        Item := TShortCutItem.Create;
        try
          s_name := TPath.ChangeExtension(FileName, ''); // 去掉 .lnk 扩展名
          ExtractLnkInfo(FilePath, TargetPath, WorkingDirectory);
          Item.ShortCutType := scItem;
          Item.ParamType := ptNone;
          Item.ShortCut := s_name;
          Item.Name := s_name;
          Item.CommandLine := format('"%s"', [TargetPath]); // 绝对路径
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
      // 可选：记录错误日志
      // 继续处理其他目录
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
    // 获取特殊文件夹路径
    DesktopPath := GetSpecialFolderPath(CSIDL_DESKTOP);
    CommonProgramsPath := GetSpecialFolderPath(CSIDL_COMMON_PROGRAMS);
    ProgramsPath := GetSpecialFolderPath(CSIDL_PROGRAMS);

    // 扫描每个目录
    if DesktopPath <> '' then
      ScanDirectoryForShortcuts(DesktopPath, ShortCutList);
    if CommonProgramsPath <> '' then
      ScanDirectoryForShortcuts(CommonProgramsPath, ShortCutList);
    if ProgramsPath <> '' then
      ScanDirectoryForShortcuts(ProgramsPath, ShortCutList);
  except
    on E: Exception do
    begin
      // 释放已创建的项
      for var Item in ShortCutList do
        Item.Free;
      ShortCutList.Free;
      raise;
    end;
  end;

  Result := ShortCutList;
end;

end.

