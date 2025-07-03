unit RustProjectProcessor;

interface

uses
  System.SysUtils;

procedure ProcessRustProject(const ARustProjectPath, AOutputPath: string);

implementation

uses
  System.Classes, System.IOUtils, System.Character, System.Generics.Defaults,
  types, system.Generics.Collections, ShellAPI, windows;

procedure select_out_file(OutputFilePath: string);
var
  commandStr, ParamStr, WorkingDir: string;
begin
  commandStr := 'explorer.exe';
  ParamStr := format('/n,/select,%s', [OutputFilePath]);
  WorkingDir := './';
  ShellExecute(0, nil, Pchar(commandStr), pchar(ParamStr), nil, SW_SHOW);
//  ShellExecute(nil, nil, _T("explorer.exe"), _T("/n,/select,") + FullcmdName.c_str(), NULL, SW_SHOW);

end;

// -----------------------------------------------------------------------------
// Helper functions (no changes here)
// -----------------------------------------------------------------------------

function GetFilePriority(const AFileName: string): Integer;
begin
  var LFileNameLower := AFileName.ToLower;
  var LExt := TPath.GetExtension(LFileNameLower);

  if LExt = '.toml' then
    Exit(0);
  if LFileNameLower = 'main.rs' then
    Exit(1);
  if LFileNameLower = 'lib.rs' then
    Exit(2);
  if LFileNameLower = 'mod.rs' then
    Exit(3);
  if LExt = '.rs' then
    Exit(4);

  Result := 99;
end;

function CompareRustFiles(List: TStringList; Index1, Index2: Integer): Integer;
var
  P1, P2: Integer;
  FileName1, FileName2: string;
begin
  FileName1 := TPath.GetFileName(List[Index1]);
  FileName2 := TPath.GetFileName(List[Index2]);

  P1 := GetFilePriority(FileName1);
  P2 := GetFilePriority(FileName2);

  Result := P1 - P2;
  if Result = 0 then
    Result := CompareText(FileName1, FileName2);
end;

// -----------------------------------------------------------------------------
// Recursive functions with optimization
// -----------------------------------------------------------------------------

procedure GenerateTreeRecursive(const APath, APrefix: string; AWriter: TStreamWriter);
var
  Entries: TStringDynArray;
  SubDirs, Files: TStringList;
  I: Integer;
  EntryName, NewPrefix: string;
begin
  SubDirs := TStringList.Create;
  Files := TStringList.Create;
  try
    // ��ȡ��Ŀ¼���������� '.' ��ͷ���ļ���
    for var Dir in TDirectory.GetDirectories(APath) do
    begin
      // [CHANGED] Add a check to ignore directories starting with a dot.
      if not TPath.GetFileName(Dir).StartsWith('.') then
        SubDirs.Add(Dir);
    end;

    // ��ȡ�����������ļ�
    for var FileExt in ['*.toml', '*.rs'] do
      for var F in TDirectory.GetFiles(APath, FileExt) do
        Files.Add(F);

    SubDirs.Sort;
    Files.Sort;

    var AllItems := TStringList.Create;
    try
      AllItems.AddStrings(SubDirs);
      AllItems.AddStrings(Files);

      for I := 0 to AllItems.Count - 1 do
      begin
        EntryName := TPath.GetFileName(AllItems[I]);
        if I = AllItems.Count - 1 then
        begin
          AWriter.WriteLine(APrefix + '\-- ' + EntryName);
          NewPrefix := APrefix + '    ';
        end
        else
        begin
          AWriter.WriteLine(APrefix + '+-- ' + EntryName);
          NewPrefix := APrefix + '|   ';
        end;

        if TDirectory.Exists(AllItems[I]) then
          GenerateTreeRecursive(AllItems[I], NewPrefix, AWriter);
      end;
    finally
      AllItems.Free;
    end;
  finally
    SubDirs.Free;
    Files.Free;
  end;
end;

procedure AggregateContentRecursive(const ACurrentPath, ARootPath: string; AWriter: TStreamWriter);
var
  LocalFiles: TStringList;
  SubDirs: TStringDynArray;
  FilePath, RelativePath, RootParentPath: string;
begin
  LocalFiles := TStringList.Create;
  try
    // 1. �����ļ� (�߼�����)
    for var FileExt in ['*.toml', '*.rs'] do
      for FilePath in TDirectory.GetFiles(ACurrentPath, FileExt) do
        LocalFiles.Add(FilePath);

    // 2. ���� (�߼�����)
    LocalFiles.CustomSort(CompareRustFiles);

    // 3. д������ (�߼�����)
    RootParentPath := TPath.GetDirectoryName(ARootPath) + TPath.DirectorySeparatorChar;
    for FilePath in LocalFiles do
    begin
      RelativePath := FilePath.Replace(RootParentPath, '', [rfReplaceAll, rfIgnoreCase]);
      AWriter.WriteLine;
      AWriter.WriteLine('--- File: ' + RelativePath);
      AWriter.WriteLine('---');
      AWriter.Write(TFile.ReadAllText(FilePath, TEncoding.UTF8));
      AWriter.WriteLine;
    end;
  finally
    LocalFiles.Free;
  end;

  // 4. �ݹ鴦����Ŀ¼
  SubDirs := TDirectory.GetDirectories(ACurrentPath);
  TArray.Sort<string>(SubDirs); // �����򣬷��㴦��
  for var SubDir in SubDirs do
  begin
    // [CHANGED] Add a check to ignore directories starting with a dot.
    if not TPath.GetFileName(SubDir).StartsWith('.') then
    begin
      AggregateContentRecursive(SubDir, ARootPath, AWriter);
    end;
  end;
end;


// -----------------------------------------------------------------------------
// Main public procedure (no changes here)
// -----------------------------------------------------------------------------
procedure ProcessRustProject(const ARustProjectPath, AOutputPath: string);
var
  LWriter: TStreamWriter;
  OutputFilePath, ProjectFolderName, RootPath: string;
begin
  RootPath := ExcludeTrailingPathDelimiter(ARustProjectPath);
  if not TDirectory.Exists(RootPath) then
    raise EInOutError.CreateFmt('Rust��Ŀ��Ŀ¼ "%s" �����ڡ�', [RootPath]);

  if not TDirectory.Exists(AOutputPath) then
    TDirectory.CreateDirectory(AOutputPath);

  ProjectFolderName := TPath.GetFileName(RootPath);
  OutputFilePath := TPath.Combine(AOutputPath, ProjectFolderName + '.txt');

  LWriter := TStreamWriter.Create(OutputFilePath, False, TEncoding.UTF8);
  try
    LWriter.WriteLine('��Ŀ: ' + ProjectFolderName);
    LWriter.WriteLine('--- ��Ŀ�ṹ�� (�� .toml, .rs �ļ�, ���� .* Ŀ¼) ---');
    LWriter.WriteLine(ProjectFolderName);
    GenerateTreeRecursive(RootPath, '', LWriter);
    LWriter.WriteLine;

    LWriter.WriteLine('--- �ļ����ݾۺ� ---');
    AggregateContentRecursive(RootPath, RootPath, LWriter);
    LWriter.WriteLine;
    LWriter.WriteLine('--- END OF FILE ---');
  finally
    LWriter.Free;
  end;
  select_out_file(OutputFilePath);
end;

end.




{
��ĿԴ����ۺϹ��� - ���ܹ��˵�� (Functional Specification)
1. ���� (Overview)
���ĵ�ּ�ڶ���һ�������й��߻�����Ĺ������󣬸ù������ڴ��� Rust ��Ŀ�������Ŀ����ɨ��һ��ָ���� Rust ��ĿĿ¼�����������йؼ���Դ�����ļ���.rs �� .toml���ۺϳ�һ����һ���ɶ����ı��ļ���
������ļ�ּ����Ϊһ����Ŀ����������ƽ���Ŀ��գ����ڴ�����顢�����Ķ����鵵���������Ի����н��з�������ṹ���Ӧȷ�������Ͽ��ԴӸ��ļ�����ԭ��ԭʼ����Ŀ�ṹ�����ݡ�
2. ϵͳ���� (System Inputs)
�ù���Ӧ������������������
ProjectRootPath (�ַ���): Rust ��Ŀ�ĸ�Ŀ¼�ľ��Ի����·������Ŀ¼Ӧ������Ŀ�� Cargo.toml �ļ���
OutputPath (�ַ���): ���ڴ���������ɵľۺ��ļ���Ŀ��Ŀ¼·����
3. ���Ĺ����봦���߼� (Core Functionality & Processing Logic)
3.1. Ŀ¼���� (Directory Traversal)
���߱����� ProjectRootPath Ϊ��㣬�ݹ�ر�����������Ŀ¼��
���˹���: �ڱ��������У��κ������Ե㣨.����ͷ��Ŀ¼�����뱻��ȫ���ԡ����磬.git, .vscode, .idea, .cargo ��Ŀ¼�����������ݶ�Ӧ��������
3.2. �ļ�ɸѡ (File Selection)
��δ�����Ե�Ŀ¼�У�����ֻӦ���Ĳ���������������չ�����ļ���
.rs (Rust Դ�����ļ�)
.toml (TOML �����ļ�, ��Ҫ�� Cargo.toml �� .cargo/config.toml)
3.3. �ļ�������ۺ�˳�� (File Processing and Aggregation Order)
Ϊ�˱�֤�����ȷ���ԺͿɶ��ԣ��ļ����ݵľۺϱ�����ѭ����˳��
Ŀ¼��˳��: Ŀ¼Ӧ�������Ƶ��ֵ���lexicographical order�����д���
Ŀ¼���ļ�˳��: �ڵ���Ŀ¼�ڣ��ļ��Ĵ���˳�����������ȼ����������ȼ��Ӹߵ��ͣ���
���� .toml �ļ������ж�������ļ����������У���
main.rs �ļ���������ڣ���
lib.rs �ļ���������ڣ���
mod.rs �ļ���������ڣ���
�������� .rs �ļ��������ļ����������С�
4. ����ļ���� (Output File Specification)
4.1. �ļ�������λ�� (File Naming and Location)
����ļ�Ӧ��������ָ���� OutputPath Ŀ¼�С�
�ļ���Ӧ������Ŀ��Ŀ¼�����ƣ���ʽΪ [ProjectFolderName].txt�����磬��� ProjectRootPath �� /path/to/my_rust_app��������ļ���Ϊ my_rust_app.txt��
4.2. �ļ����� (File Encoding)
����ļ�����ʹ�� UTF-8 ���룬��ȷ���������ַ�����ȷ֧�֡�
4.3. �ļ����ݽṹ (File Content Structure)
����ļ���������Ҫ���ֹ��ɣ�˳�����£�
Part 1: ��Ŀ�ṹ�� (Project Structure Tree)
�˲�����Ϊ�ļ��Ŀ�ͷ��
���ṩ��һ�����ӻ��ġ����� tree /a ��������� ASCII �ı�����
����״ͼӦֻ�������� 3.1 �� 3.2 ɸѡ�����Ŀ¼���ļ���
�ṹӦ������չʾ��Ŀ��Ŀ¼��κ��ļ����֡�
Part 2: �ļ����ݾۺ� (Aggregated File Content)
�˲��ֽ�����Ŀ�ṹ��֮��
�����������б�ѡ���ļ����������ݣ�����ѭ 3.3 �ж���Ĵ���˳��
ÿ���ļ������ݿ�ǰ��������һ����ȷ�ı�ʶͷ����ʽ���£�
Generated code
--- File: [RelativePath]
---
[... File Content ...]
Use code with caution.
[RelativePath] ���ļ��������Ŀ��Ŀ¼��·������Ӧ������Ŀ��Ŀ¼����������: my_rust_app/src/main.rs��
[... File Content ...] �Ǹ��ļ���������δ���޸ĵ�ԭʼ�ı����ݡ�
ÿ���ļ����ݿ�֮��Ӧ�ÿ��л�ָ�������������߿ɶ��ԡ�
}


