unit X2m.CommandLine;

interface

uses
  System.Classes, System.SysUtils, System.IOUtils;

type
  /// <summary>
  /// Exception class for command line errors (parse errors)
  /// </summary>
  ECommandLineError = class(Exception);

  /// <summary>
  /// This class is responsible for parsing the command line and converting the XMLDOC files to markdown
  /// </summary>
  TCommandLine = class(TObject)
  private
    FInputPath: TArray<string>;
    FOutputDir: string;
    FRecursive: Boolean;
    FForce: Boolean;
    FHelp: Boolean;
    FShowPrivate: Boolean;
    FSearchPattern: string;
    /// <summary>
    /// Shows the help information
    /// </summary>
    procedure ShowHelp;
    /// <summary>
    /// </summary>
    // Converts a XMLDOC string to markdown
    function ConvertToMarkdown(const XMLContent: string): string;
    /// <summary>
    /// Converts a list of files or directories to markdown
    /// </summary>
    procedure ConvertFilesToMarkdown(FileNames: TArray<string>);
    /// <summary>
    /// Converts a file to markdown
    /// </summary>
    procedure ConvertFileToMarkdown(const FileName: string);
    /// <summary>
    /// Converts a directory to markdown
    /// </summary>
    procedure ConvertDirectoryToMarkdown(const DirName: string);
    /// <summary>
    /// Converts all files to markdown
    /// </summary>
    procedure Convert;
    /// <summary>
    /// The constructor
    /// </summary>
    constructor Create;
    /// <summary>
    /// Parses the command line
    /// </summary>
    procedure ParseCommandLine;
  public
    /// <summary>
    /// Run the command line tool
    /// </summary>
    class procedure Run; static;
  end;

implementation

{ TCommandLine }

uses
  X2m.Parser;

procedure TCommandLine.Convert;
begin
  if FHelp then
  begin
    ShowHelp;
    Exit;
  end;

  if Length(FInputPath) = 0 then
    raise ECommandLineError.Create('Input file name missing');

  ConvertFilesToMarkdown(FInputPath);
end;

procedure TCommandLine.ConvertDirectoryToMarkdown(const DirName: string);
begin
  var FileNames := TDirectory.GetFiles(DirName, FSearchPattern);
  ConvertFilesToMarkdown(FileNames);
  if FRecursive then
  begin
    var DirNames := TDirectory.GetDirectories(DirName);
    ConvertFilesToMarkdown(DirNames);
  end;
end;

procedure TCommandLine.ConvertFilesToMarkdown(FileNames: TArray<string>);
begin
  for var LFileName in FileNames do
  begin
    if TFile.Exists(LFileName) then
      ConvertFileToMarkdown(LFileName)
    else if TDirectory.Exists(LFileName) then
      ConvertDirectoryToMarkdown(LFileName)
    else
      raise ECommandLineError.CreateFmt('File or directory "%s" not found', [LFileName]);
  end;
end;

procedure TCommandLine.ConvertFileToMarkdown(const FileName: string);
begin
  try
    Writeln(FileName);
    var XMLContent := TFile.ReadAllText(FileName);
    var Markdown := ConvertToMarkdown(XMLContent);
    var OutputFileName := ChangeFileExt(FileName, '.md');
    if FOutputDir <> '' then
    begin
      OutputFileName := ExtractFileName(OutputFileName);
      OutputFileName := TPath.Combine(FOutputDir, OutputFileName);
    end;

    if (not FForce) and FileExists(OutputFileName) then
      raise ECommandLineError.CreateFmt('File "%s" already exists', [OutputFileName]);
    TFile.WriteAllText(OutputFileName, Markdown);
  except
    on E: Exception do
      Writeln(E.Message);
  end;
end;

function TCommandLine.ConvertToMarkdown(const XMLContent: string): string;
begin
  var Parser := TParser.Create;
  try
    Parser.ShowPrivate := FShowPrivate;
    Result := Parser.ConvertToMarkdown(XMLContent);
  finally
    Parser.Free;
  end;
end;

constructor TCommandLine.Create;
begin
  ParseCommandLine;
end;

procedure TCommandLine.ParseCommandLine;
begin
  FSearchPattern := '*.xml';
  FOutputDir := '';
  FRecursive := False;
  FForce := False;
  FHelp := False;
  FShowPrivate := False;
  FInputPath := [];

  var I := 1;
  while I <= ParamCount do
  begin
    if SameText(ParamStr(I), '/O') then
    begin
      FOutputDir := ParamStr(I + 1);
      Inc(I);
    end
    else if SameText(ParamStr(I), '/P') then
    begin
      FSearchPattern := ParamStr(I + 1);
      Inc(I);
    end
    else if SameText(ParamStr(I), '/R') then
    begin
      FRecursive := True;
    end
    else if SameText(ParamStr(I), '/S') then
    begin
      FShowPrivate := True;
    end
    else if SameText(ParamStr(I), '/F') then
    begin
      FForce := True;
    end
    else if SameText(ParamStr(I), '/H') then
    begin
      FHelp := True;
    end
    else if ParamStr(I).StartsWith('/') then
      raise ECommandLineError.Create('Option not available. Type /H for help')
    else
      FInputPath := FInputPath + [ParamStr(I)];
    Inc(I);
  end;
end;

class procedure TCommandLine.Run;
begin
  var CommandLine := TCommandLine.Create;
  try
    CommandLine.Convert;
  finally
    CommandLine.Free;
  end;
end;

procedure TCommandLine.ShowHelp;
var
  AppName: string;
begin
  AppName := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
  Writeln('Converts XMLDOC files in markdown');
  Writeln;
  Writeln(AppName + ' [/R] [/F] [/O output] [/P pattern] [/H] pathname...');
  Writeln;
  Writeln('  /R           Recursively convert files in the current directory and all subdirectories');
  Writeln('  /F           Force overwrite if output files already exist');
  Writeln('  /O output    Specify the output directory for the generated Markdown files');
  Writeln('  /P parrern   Specify a search pattern (default *.xml)');
  Writeln('  /H           Display help information');
  Writeln('  pathname     One or more files or directories to convert. If a directory is specified, ');
  Writeln('               the tool will process all XML files within it');
  Writeln('  /S           Show private elements');
end;

end.
