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
  // �ֶ����� IID_IServiceProvider
  IID_IServiceProvider: TGUID = '{6D5140C1-7436-11CE-8034-00AA006009FA}';
  // �ֶ����� IID_IFolderView
  IID_IFolderView: TGUID = '{CDE725B0-CCC9-4519-917E-325D72FAB4CE}';
  // �ֶ����� IID_IPersistFolder2
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
  CurrentWnd := GetTopWindow(0); // ����㴰�ڿ�ʼ
  while CurrentWnd <> 0 do
  begin
    if CurrentWnd = hWnd then
    begin
      Result := ZOrder;
      Exit;
    end;
    Inc(ZOrder);
    CurrentWnd := GetWindow(CurrentWnd, GW_HWNDNEXT); // ��ȡ��һ������
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
  // ��ȡ��ǰ���� ID
  CurrentProcessId := GetCurrentProcessId;

  // ��ȡ ShellWindows �ӿ�
  try
    ShellWindows := CoShellWindows.Create;
  except
    on E: Exception do
    begin
      Writeln('����: ���� ShellWindows ʧ�� - ', E.Message);
      Exit;
    end;
  end;

  if ShellWindows = nil then
  begin
    Writeln('����: �޷����� ShellWindows ����');
    Exit;
  end;

  Writeln('����: �ҵ� ', ShellWindows.Count, ' �� Shell ����');

  // ��ʼ��������Ϣ����
  WindowCount := ShellWindows.Count;
  SetLength(Windows, WindowCount);
  for i := 0 to WindowCount - 1 do
    Windows[i].ZOrder := MaxInt; // ��ʼ��Ϊ���ֵ����ʾδ�ҵ�

  // ����������Դ����������
  for i := 0 to ShellWindows.Count - 1 do
  begin
    try
      Window := ShellWindows.Item(i) as IWebBrowser2;
      if Window = nil then
      begin
        Writeln('����: �� ', i, ' ��������Ч������');
        Continue;
      end;

      // ��ȡ���ھ��
      WindowHandle := Window.HWND;
      if WindowHandle = 0 then
      begin
        Writeln('����: �� ', i, ' �����ھ��Ϊ 0������');
        Continue;
      end;

      // ��ȡ��������
      GetClassName(WindowHandle, ClassName, SizeOf(ClassName));
      Writeln('����: �� ', i, ' ����������: ', ClassName);

      // ����Ƿ�Ϊ��Դ���������� (CabinetWClass �� ExplorerBrowser)
      if not (SameText(ClassName, 'CabinetWClass') or SameText(ClassName, 'ExplorerBrowser')) then
      begin
        Writeln('����: �� ', i, ' �����ڲ�����Դ���������ڣ�����');
        Continue;
      end;

      // ��ȡ���ڵĽ��� ID
      GetWindowThreadProcessId(WindowHandle, @WindowProcessId);
      Writeln('����: �� ', i, ' �����ڽ��� ID: ', WindowProcessId, '����ǰ���� ID: ', CurrentProcessId);

      // ��ȡ Z ˳��
      Windows[i].Handle := WindowHandle;
      Windows[i].ZOrder := GetWindowZOrder(WindowHandle);
      Writeln('����: �� ', i, ' ������ Z ˳��: ', Windows[i].ZOrder);

      // ͨ�� IServiceProvider ��ȡ IShellBrowser
      if Succeeded(Window.QueryInterface(IID_IServiceProvider, ServiceProvider)) and (ServiceProvider <> nil) then
      begin
        Writeln('����: �� ', i, ' �����ڳɹ���ȡ IServiceProvider');
        if Succeeded(ServiceProvider.QueryService(IID_IShellBrowser, IID_IShellBrowser, ShellBrowser)) and (ShellBrowser <> nil) then
        begin
          Writeln('����: �� ', i, ' �����ڳɹ���ȡ IShellBrowser');
          // ��ȡ IShellView �ӿ�
          if Succeeded(ShellBrowser.QueryActiveShellView(ShellView)) and (ShellView <> nil) then
          begin
            Writeln('����: �� ', i, ' �����ڳɹ���ȡ IShellView');
            // ��ȡ IFolderView �ӿ�
            if Succeeded(ShellView.QueryInterface(IID_IFolderView, FolderView)) and (FolderView <> nil) then
            begin
              Writeln('����: �� ', i, ' �����ڳɹ���ȡ IFolderView');
              // ��ȡ IShellFolder �ӿ�
              if Succeeded(FolderView.GetFolder(IID_IShellFolder, ShellFolder)) and (ShellFolder <> nil) then
              begin
                Writeln('����: �� ', i, ' �����ڳɹ���ȡ IShellFolder');
                // ��ȡ IPersistFolder2 �ӿ�
                if Succeeded(ShellFolder.QueryInterface(IID_IPersistFolder2, PersistFolder)) and (PersistFolder <> nil) then
                begin
                  Writeln('����: �� ', i, ' �����ڳɹ���ȡ IPersistFolder2');
                  // ��ȡ��ǰ�ļ��е� PIDL
                  if Succeeded(PersistFolder.GetCurFolder(ItemIDList)) and (ItemIDList <> nil) then
                  begin
                    // �� PIDL ת��Ϊ·��
                    if SHGetPathFromIDList(ItemIDList, Path) then
                    begin
                      Windows[i].Path := Path;
                      Writeln('����: �� ', i, ' �����ڳɹ���ȡ·��: ', Windows[i].Path);
                    end
                    else
                    begin
                      // ���Ի�ȡ��ʾ���ƣ����������ļ��У��硰�˵��ԡ���
                      if Succeeded(SHGetNameFromIDList(ItemIDList, SIGDN_NORMALDISPLAY, DisplayName)) then
                      begin
                        Windows[i].Path := DisplayName;
                        Writeln('����: �� ', i, ' �����ڳɹ���ȡ��ʾ����: ', Windows[i].Path);
                        CoTaskMemFree(DisplayName);
                      end;
                    end;
                    CoTaskMemFree(ItemIDList);
                  end
                  else
                    Writeln('����: �� ', i, ' �������޷���ȡ PIDL');
                end
                else
                  Writeln('����: �� ', i, ' �������޷���ȡ IPersistFolder2');
              end
              else
                Writeln('����: �� ', i, ' �������޷���ȡ IShellFolder');
            end
            else
              Writeln('����: �� ', i, ' �������޷���ȡ IFolderView');
          end
          else
            Writeln('����: �� ', i, ' �������޷���ȡ IShellView');
        end
        else
          Writeln('����: �� ', i, ' �������޷�ͨ�� IServiceProvider ��ȡ IShellBrowser');
      end
      else
        Writeln('����: �� ', i, ' �������޷���ȡ IServiceProvider');
    except
      on E: Exception do
        Writeln('����: ����� ', i, ' ������ʱ����: ', E.Message);
    end;
  end;

  // �ҵ� Z ˳����͵Ĵ��ڣ�������Ĵ��ڣ�
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
    Writeln('����: ������Ĵ����ǵ� ', TopWindowIndex, ' ����·��: ', Result);
  end
  else
    Writeln('����: δ�ҵ���Ч����Դ���������ڣ�');
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

    // 1. ��֤����·����Ч��
    if not TDirectory.Exists(SourcePath) then
      raise Exception.Create('Դ·��������: ' + SourcePath);

    // 2. ��ȡ���һ���ļ�������
    str := SourcePath;
    delete(str, length(str), 1);
    LastFolderName := TPath.GetFileName(TrimRight(str));
    if LastFolderName.IsEmpty then
      raise Exception.Create('�޷���ȡ�ļ�������');

    // 3. �������ļ���·����Z�̸�Ŀ¼��
    NewFolderPath := TPath.Combine('Z:\', LastFolderName);
    if not TDirectory.Exists(NewFolderPath) then
      TDirectory.CreateDirectory(NewFolderPath);
    result := NewFolderPath;

    // 4. ��ȡ�����ļ���������Ŀ¼��
//    Files := TDirectory.GetFiles(SourcePath + 'src\', '*.*', TSearchOption.soAllDirectories);
    Files := TDirectory.GetFiles(SourcePath, '*.*', TSearchOption.soAllDirectories);
    len := Length(Files);
    SetLength(Files, len + 1);
    Files[len] := SourcePath + 'Cargo.toml';

    // 5. ��������ÿ���ļ�
    for FileName in Files do
    try
      if FileName.EndsWith('.rs') or FileName.EndsWith('.toml') then
      begin
      // 6. �������ļ�����·��+�ļ���+.txt
        PathPrefix := StringReplace(FileName, SourcePath, '', [rfReplaceAll]);
//      NewFileName := TPath.ChangeExtension(FileName, '.txt');
        NewFileName := FileName + '.txt';
        NewFileName := StringReplace(NewFileName, SourcePath, '', [rfReplaceAll]);
        NewFileName := StringReplace(NewFileName, PathDelim, '��', [rfReplaceAll]);
        NewFileName := TPath.Combine(NewFolderPath, NewFileName);

        writeln(NewFileName);
      // 7. ��ȡ�ļ����ݲ�������
        Content := TStringList.Create;
        try
          FileStream := TFileStream.Create(FileName, fmOpenRead);
          try
            Reader := TStreamReader.Create(FileStream, TEncoding.UTF8, True);
            try
            // ��������Ա����ͷź����
              FileEncoding := Reader.CurrentEncoding;
            // ������λ����ȷ����ȷ��ȡ
              FileStream.Position := 0;
              Content.LoadFromStream(FileStream, FileEncoding);
            finally
              Reader.Free;
            end;
          finally
            FileStream.Free;
          end;

        // 8. ����� .rs �ļ�������ע��
          if SameText(TPath.GetExtension(FileName), '.rs') then
            Content.Insert(0, '// ' + PathPrefix);

        // 9. д�����ļ�������ԭʼ����
          Content.SaveToFile(NewFileName, FileEncoding);
        finally
          Content.Free;
        end;
      end;
    except
      on E: Exception do
      begin
        // ��¼���󵫼������������ļ�
        Writeln('�����ļ�ʧ��: ' + FileName + ' ����: ' + E.Message);
        Continue;
      end;
    end;

    Result := result;
  except
    on E: Exception do
    begin
      Writeln('����ʧ��: ' + E.Message);
      Exit;
    end;
  end;
end;

var
  curr_path: string;

begin
  try
    // ��ʼ�� COM
    CoInitialize(nil);
    try
      // ��ȡ�������Դ���������ڵ�·��
      curr_path := GetExplorerPath();
//      curr_path := CopyAndRenameFiles(curr_path);
      ProcessRustProject(curr_path,'z:\');
      Writeln('��Դ������·��: ', curr_path);
      ShellExecute(GetDesktopWindow, nil, pchar(curr_path), nil, pchar(curr_path), sw_show);
    finally
      // �ͷ� COM
      CoUninitialize;
    end;
  except
    on E: Exception do
      Writeln('����: ', E.Message);
  end;
  // ��ֹ���������ر�
  Writeln('5s�� �˳�...');
  sleep(5000);
end.

