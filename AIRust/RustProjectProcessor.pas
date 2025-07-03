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
    // 获取子目录，并忽略以 '.' 开头的文件夹
    for var Dir in TDirectory.GetDirectories(APath) do
    begin
      // [CHANGED] Add a check to ignore directories starting with a dot.
      if not TPath.GetFileName(Dir).StartsWith('.') then
        SubDirs.Add(Dir);
    end;

    // 获取符合条件的文件
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
    // 1. 查找文件 (逻辑不变)
    for var FileExt in ['*.toml', '*.rs'] do
      for FilePath in TDirectory.GetFiles(ACurrentPath, FileExt) do
        LocalFiles.Add(FilePath);

    // 2. 排序 (逻辑不变)
    LocalFiles.CustomSort(CompareRustFiles);

    // 3. 写入内容 (逻辑不变)
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

  // 4. 递归处理子目录
  SubDirs := TDirectory.GetDirectories(ACurrentPath);
  TArray.Sort<string>(SubDirs); // 先排序，方便处理
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
    raise EInOutError.CreateFmt('Rust项目根目录 "%s" 不存在。', [RootPath]);

  if not TDirectory.Exists(AOutputPath) then
    TDirectory.CreateDirectory(AOutputPath);

  ProjectFolderName := TPath.GetFileName(RootPath);
  OutputFilePath := TPath.Combine(AOutputPath, ProjectFolderName + '.txt');

  LWriter := TStreamWriter.Create(OutputFilePath, False, TEncoding.UTF8);
  try
    LWriter.WriteLine('项目: ' + ProjectFolderName);
    LWriter.WriteLine('--- 项目结构树 (仅 .toml, .rs 文件, 忽略 .* 目录) ---');
    LWriter.WriteLine(ProjectFolderName);
    GenerateTreeRecursive(RootPath, '', LWriter);
    LWriter.WriteLine;

    LWriter.WriteLine('--- 文件内容聚合 ---');
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
项目源代码聚合工具 - 功能规格说明 (Functional Specification)
1. 概述 (Overview)
本文档旨在定义一个命令行工具或函数库的功能需求，该工具用于处理 Rust 项目。其核心目标是扫描一个指定的 Rust 项目目录，并将其所有关键的源代码文件（.rs 和 .toml）聚合成一个单一、可读的文本文件。
该输出文件旨在作为一个项目的完整、扁平化的快照，便于代码审查、离线阅读、归档或在限制性环境中进行分析。其结构设计应确保理论上可以从该文件逆向还原出原始的项目结构和内容。
2. 系统输入 (System Inputs)
该工具应接受以下两个参数：
ProjectRootPath (字符串): Rust 项目的根目录的绝对或相对路径。该目录应包含项目的 Cargo.toml 文件。
OutputPath (字符串): 用于存放最终生成的聚合文件的目标目录路径。
3. 核心功能与处理逻辑 (Core Functionality & Processing Logic)
3.1. 目录遍历 (Directory Traversal)
工具必须以 ProjectRootPath 为起点，递归地遍历其所有子目录。
过滤规则: 在遍历过程中，任何名称以点（.）开头的目录都必须被完全忽略。例如，.git, .vscode, .idea, .cargo 等目录及其所有内容都应被跳过。
3.2. 文件筛选 (File Selection)
在未被忽略的目录中，工具只应关心并处理以下两种扩展名的文件：
.rs (Rust 源代码文件)
.toml (TOML 配置文件, 主要是 Cargo.toml 和 .cargo/config.toml)
3.3. 文件处理与聚合顺序 (File Processing and Aggregation Order)
为了保证输出的确定性和可读性，文件内容的聚合必须遵循以下顺序：
目录间顺序: 目录应按其名称的字典序（lexicographical order）进行处理。
目录内文件顺序: 在单个目录内，文件的处理顺序由以下优先级决定（优先级从高到低）：
所有 .toml 文件（若有多个，按文件名升序排列）。
main.rs 文件（如果存在）。
lib.rs 文件（如果存在）。
mod.rs 文件（如果存在）。
所有其他 .rs 文件，按其文件名升序排列。
4. 输出文件规格 (Output File Specification)
4.1. 文件命名与位置 (File Naming and Location)
输出文件应被创建在指定的 OutputPath 目录中。
文件名应基于项目根目录的名称，格式为 [ProjectFolderName].txt。例如，如果 ProjectRootPath 是 /path/to/my_rust_app，则输出文件名为 my_rust_app.txt。
4.2. 文件编码 (File Encoding)
输出文件必须使用 UTF-8 编码，以确保对所有字符的正确支持。
4.3. 文件内容结构 (File Content Structure)
输出文件由两个主要部分构成，顺序如下：
Part 1: 项目结构树 (Project Structure Tree)
此部分作为文件的开头。
它提供了一个可视化的、类似 tree /a 命令输出的 ASCII 文本树。
该树状图应只包含符合 3.1 和 3.2 筛选规则的目录和文件。
结构应清晰地展示项目的目录层次和文件布局。
Part 2: 文件内容聚合 (Aggregated File Content)
此部分紧随项目结构树之后。
它包含了所有被选定文件的完整内容，并遵循 3.3 中定义的处理顺序。
每个文件的内容块前都必须有一个明确的标识头，格式如下：
Generated code
--- File: [RelativePath]
---
[... File Content ...]
Use code with caution.
[RelativePath] 是文件相对于项目根目录的路径，且应包含项目根目录名本身。例如: my_rust_app/src/main.rs。
[... File Content ...] 是该文件的完整、未经修改的原始文本内容。
每个文件内容块之间应用空行或分隔符隔开，以提高可读性。
}


