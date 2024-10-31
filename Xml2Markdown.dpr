program Xml2Markdown;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Winapi.ActiveX,
  X2m.CommandLine in 'Source\X2m.CommandLine.pas',
  X2m.Parser in 'Source\X2m.Parser.pas';

begin
  CoInitialize(nil);
  try
    try
      TCommandLine.Run;
    except
      on E: Exception do
        Writeln(E.ClassName, ': ', E.Message);
    end;
  finally
    CoUninitialize;
  end;
end.
