program AIRust;

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  Winapi.ShellAPI,
  System.SysUtils,
  System.Win.ComObj,
  Winapi.ActiveX,
  Winapi.ShlObj,
  System.IOUtils,
  System.Classes,
  SHDocVw,
  RustProjectProcessor in 'RustProjectProcessor.pas';

const
  // 手动定义 IID_IServiceProvider
  IID_IServiceProvider: TGUID = '{6D5140C1-7436-11CE-8034-00AA006009FA}';
  // 手动定义 IID_IFolderView
  IID_IFolderView: TGUID = '{CDE725B0-CCC9-4519-917E-325D72FAB4CE}';
  // 手动定义 IID_IPersistFolder2
  IID_IPersistFolder2: TGUID = '{1AC3D9F0-175C-11D1-95BE-00609797EA4F}';

type
  TWindowInfo = record
    Handle: HWND;
    ZOrder: Integer;
    Path: string;
  end;

function GetWindowZOrder(hWnd: DWord): Integer;
var
  CurrentWnd: DWord;
  ZOrder: Integer;
begin
  Result := -1;
  ZOrder := 0;
  CurrentWnd := GetTopWindow(0); // 从最顶层窗口开始
  while CurrentWnd <> 0 do
  begin
    if CurrentWnd = hWnd then
    begin
      Result := ZOrder;
      Exit;
    end;
    Inc(ZOrder);
    CurrentWnd := GetWindow(CurrentWnd, GW_HWNDNEXT); // 获取下一个窗口
  end;
end;

function GetExplorerPath: string;
var
  ShellWindows: IShellWindows;
  Window: IWebBrowser2;
  ServiceProvider: IServiceProvider;
  ShellBrowser: IShellBrowser;
  ShellView: IShellView;
  FolderView: IFolderView;
  ShellFolder: IShellFolder;
  PersistFolder: IPersistFolder2;
  ItemIDList: PItemIDList;
  Path: array[0..MAX_PATH] of Char;
  DisplayName: PWideChar;
  i: Integer;
  WindowHandle: OleVariant;
  ClassName: array[0..255] of Char;
  CurrentProcessId: DWORD;
  WindowProcessId: DWORD;
  Windows: array of TWindowInfo;
  WindowCount: Integer;
  MinZOrder: Integer;
  TopWindowIndex: Integer;
begin
  Result := '';
  // 获取当前进程 ID
  CurrentProcessId := GetCurrentProcessId;

  // 获取 ShellWindows 接口
  try
    ShellWindows := CoShellWindows.Create;
  except
    on E: Exception do
    begin
      Writeln('错误: 创建 ShellWindows 失败 - ', E.Message);
      Exit;
    end;
  end;

  if ShellWindows = nil then
  begin
    Writeln('错误: 无法创建 ShellWindows 对象！');
    Exit;
  end;

  Writeln('调试: 找到 ', ShellWindows.Count, ' 个 Shell 窗口');

  // 初始化窗口信息数组
  WindowCount := ShellWindows.Count;
  SetLength(Windows, WindowCount);
  for i := 0 to WindowCount - 1 do
    Windows[i].ZOrder := MaxInt; // 初始化为最大值，表示未找到

  // 遍历所有资源管理器窗口
  for i := 0 to ShellWindows.Count - 1 do
  begin
    try
      Window := ShellWindows.Item(i) as IWebBrowser2;
      if Window = nil then
      begin
        Writeln('调试: 第 ', i, ' 个窗口无效，跳过');
        Continue;
      end;

      // 获取窗口句柄
      WindowHandle := Window.HWND;
      if WindowHandle = 0 then
      begin
        Writeln('调试: 第 ', i, ' 个窗口句柄为 0，跳过');
        Continue;
      end;

      // 获取窗口类名
      GetClassName(WindowHandle, ClassName, SizeOf(ClassName));
      Writeln('调试: 第 ', i, ' 个窗口类名: ', ClassName);

      // 检查是否为资源管理器窗口 (CabinetWClass 或 ExplorerBrowser)
      if not (SameText(ClassName, 'CabinetWClass') or SameText(ClassName, 'ExplorerBrowser')) then
      begin
        Writeln('调试: 第 ', i, ' 个窗口不是资源管理器窗口，跳过');
        Continue;
      end;

      // 获取窗口的进程 ID
      GetWindowThreadProcessId(WindowHandle, @WindowProcessId);
      Writeln('调试: 第 ', i, ' 个窗口进程 ID: ', WindowProcessId, '，当前进程 ID: ', CurrentProcessId);

      // 获取 Z 顺序
      Windows[i].Handle := WindowHandle;
      Windows[i].ZOrder := GetWindowZOrder(WindowHandle);
      Writeln('调试: 第 ', i, ' 个窗口 Z 顺序: ', Windows[i].ZOrder);

      // 通过 IServiceProvider 获取 IShellBrowser
      if Succeeded(Window.QueryInterface(IID_IServiceProvider, ServiceProvider)) and (ServiceProvider <> nil) then
      begin
        Writeln('调试: 第 ', i, ' 个窗口成功获取 IServiceProvider');
        if Succeeded(ServiceProvider.QueryService(IID_IShellBrowser, IID_IShellBrowser, ShellBrowser)) and (ShellBrowser <> nil) then
        begin
          Writeln('调试: 第 ', i, ' 个窗口成功获取 IShellBrowser');
          // 获取 IShellView 接口
          if Succeeded(ShellBrowser.QueryActiveShellView(ShellView)) and (ShellView <> nil) then
          begin
            Writeln('调试: 第 ', i, ' 个窗口成功获取 IShellView');
            // 获取 IFolderView 接口
            if Succeeded(ShellView.QueryInterface(IID_IFolderView, FolderView)) and (FolderView <> nil) then
            begin
              Writeln('调试: 第 ', i, ' 个窗口成功获取 IFolderView');
              // 获取 IShellFolder 接口
              if Succeeded(FolderView.GetFolder(IID_IShellFolder, ShellFolder)) and (ShellFolder <> nil) then
              begin
                Writeln('调试: 第 ', i, ' 个窗口成功获取 IShellFolder');
                // 获取 IPersistFolder2 接口
                if Succeeded(ShellFolder.QueryInterface(IID_IPersistFolder2, PersistFolder)) and (PersistFolder <> nil) then
                begin
                  Writeln('调试: 第 ', i, ' 个窗口成功获取 IPersistFolder2');
                  // 获取当前文件夹的 PIDL
                  if Succeeded(PersistFolder.GetCurFolder(ItemIDList)) and (ItemIDList <> nil) then
                  begin
                    // 将 PIDL 转换为路径
                    if SHGetPathFromIDList(ItemIDList, Path) then
                    begin
                      Windows[i].Path := Path;
                      Writeln('调试: 第 ', i, ' 个窗口成功获取路径: ', Windows[i].Path);
                    end
                    else
                    begin
                      // 尝试获取显示名称（处理特殊文件夹，如“此电脑”）
                      if Succeeded(SHGetNameFromIDList(ItemIDList, SIGDN_NORMALDISPLAY, DisplayName)) then
                      begin
                        Windows[i].Path := DisplayName;
                        Writeln('调试: 第 ', i, ' 个窗口成功获取显示名称: ', Windows[i].Path);
                        CoTaskMemFree(DisplayName);
                      end;
                    end;
                    CoTaskMemFree(ItemIDList);
                  end
                  else
                    Writeln('调试: 第 ', i, ' 个窗口无法获取 PIDL');
                end
                else
                  Writeln('调试: 第 ', i, ' 个窗口无法获取 IPersistFolder2');
              end
              else
                Writeln('调试: 第 ', i, ' 个窗口无法获取 IShellFolder');
            end
            else
              Writeln('调试: 第 ', i, ' 个窗口无法获取 IFolderView');
          end
          else
            Writeln('调试: 第 ', i, ' 个窗口无法获取 IShellView');
        end
        else
          Writeln('调试: 第 ', i, ' 个窗口无法通过 IServiceProvider 获取 IShellBrowser');
      end
      else
        Writeln('调试: 第 ', i, ' 个窗口无法获取 IServiceProvider');
    except
      on E: Exception do
        Writeln('调试: 处理第 ', i, ' 个窗口时出错: ', E.Message);
    end;
  end;

  // 找到 Z 顺序最低的窗口（最上面的窗口）
  MinZOrder := MaxInt;
  TopWindowIndex := -1;
  for i := 0 to WindowCount - 1 do
  begin
    if (Windows[i].ZOrder < MinZOrder) and (Windows[i].Path <> '') then
    begin
      MinZOrder := Windows[i].ZOrder;
      TopWindowIndex := i;
    end;
  end;

  if TopWindowIndex >= 0 then
  begin
    Result := Windows[TopWindowIndex].Path;
    Writeln('调试: 最上面的窗口是第 ', TopWindowIndex, ' 个，路径: ', Result);
  end
  else
    Writeln('错误: 未找到有效的资源管理器窗口！');
end;

function CopyAndRenameFiles(SourcePath: string): string;
var
  LastFolderName, NewFolderPath, FileName, NewFileName: string;
  Files: TArray<string>;
  FileStream: TFileStream;
  FileEncoding: TEncoding;
  Reader: TStreamReader;
  Content: TStringList;
  PathPrefix: string;
  str: string;
  len: integer;
begin
  Result := '';
  try
    SourcePath := trim(SourcePath);
    if not SourcePath.EndsWith(PathDelim) then
      SourcePath := SourcePath + PathDelim;

    // 1. 验证输入路径有效性
    if not TDirectory.Exists(SourcePath) then
      raise Exception.Create('源路径不存在: ' + SourcePath);

    // 2. 提取最后一个文件夹名称
    str := SourcePath;
    delete(str, length(str), 1);
    LastFolderName := TPath.GetFileName(TrimRight(str));
    if LastFolderName.IsEmpty then
      raise Exception.Create('无法提取文件夹名称');

    // 3. 创建新文件夹路径（Z盘根目录）
    NewFolderPath := TPath.Combine('Z:\', LastFolderName);
    if not TDirectory.Exists(NewFolderPath) then
      TDirectory.CreateDirectory(NewFolderPath);
    result := NewFolderPath;

    // 4. 获取所有文件（包括子目录）
//    Files := TDirectory.GetFiles(SourcePath + 'src\', '*.*', TSearchOption.soAllDirectories);
    Files := TDirectory.GetFiles(SourcePath, '*.*', TSearchOption.soAllDirectories);
    len := Length(Files);
    SetLength(Files, len + 1);
    Files[len] := SourcePath + 'Cargo.toml';

    // 5. 遍历处理每个文件
    for FileName in Files do
    try
      if FileName.EndsWith('.rs') or FileName.EndsWith('.toml') then
      begin
      // 6. 生成新文件名：路径+文件名+.txt
        PathPrefix := StringReplace(FileName, SourcePath, '', [rfReplaceAll]);
//      NewFileName := TPath.ChangeExtension(FileName, '.txt');
        NewFileName := FileName + '.txt';
        NewFileName := StringReplace(NewFileName, SourcePath, '', [rfReplaceAll]);
        NewFileName := StringReplace(NewFileName, PathDelim, '、', [rfReplaceAll]);
        NewFileName := TPath.Combine(NewFolderPath, NewFileName);

        writeln(NewFileName);
      // 7. 读取文件内容并检测编码
        Content := TStringList.Create;
        try
          FileStream := TFileStream.Create(FileName, fmOpenRead);
          try
            Reader := TStreamReader.Create(FileStream, TEncoding.UTF8, True);
            try
            // 保存编码以避免释放后访问
              FileEncoding := Reader.CurrentEncoding;
            // 重置流位置以确保正确读取
              FileStream.Position := 0;
              Content.LoadFromStream(FileStream, FileEncoding);
            finally
              Reader.Free;
            end;
          finally
            FileStream.Free;
          end;

        // 8. 如果是 .rs 文件，插入注释
          if SameText(TPath.GetExtension(FileName), '.rs') then
            Content.Insert(0, '// ' + PathPrefix);

        // 9. 写入新文件，保留原始编码
          Content.SaveToFile(NewFileName, FileEncoding);
        finally
          Content.Free;
        end;
      end;
    except
      on E: Exception do
      begin
        // 记录错误但继续处理其他文件
        Writeln('处理文件失败: ' + FileName + ' 错误: ' + E.Message);
        Continue;
      end;
    end;

    Result := result;
  except
    on E: Exception do
    begin
      Writeln('操作失败: ' + E.Message);
      Exit;
    end;
  end;
end;

var
  curr_path: string;

begin
  try
    // 初始化 COM
    CoInitialize(nil);
    try
      // 获取并输出资源管理器窗口的路径
      curr_path := GetExplorerPath();
//      curr_path := CopyAndRenameFiles(curr_path);
      ProcessRustProject(curr_path,'z:\');
      Writeln('资源管理器路径: ', curr_path);
      ShellExecute(GetDesktopWindow, nil, pchar(curr_path), nil, pchar(curr_path), sw_show);
    finally
      // 释放 COM
      CoUninitialize;
    end;
  except
    on E: Exception do
      Writeln('错误: ', E.Message);
  end;
  // 防止窗口立即关闭
  Writeln('5s后 退出...');
  sleep(5000);
end.

