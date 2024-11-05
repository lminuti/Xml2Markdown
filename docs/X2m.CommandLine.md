# Unit X2m.CommandLine

## 🟦 ECommandLineError (class)

`ECommandLineError = class(Exception)`

Exception class for command line errors (parse errors) 

## 🟦 TCommandLine (class)

`TCommandLine = class(TObject)`

This class is responsible for parsing the command line and converting the XMLDOC files to markdown 

Members:

• **FInputPath** (field)

`Field FInputPath: TArray<System.string>`

• **FOutputDir** (field)

`Field FOutputDir: string`

• **FRecursive** (field)

`Field FRecursive: Boolean`

• **FForce** (field)

`Field FForce: Boolean`

• **FHelp** (field)

`Field FHelp: Boolean`

• **FShowPrivate** (field)

`Field FShowPrivate: Boolean`

• **FSearchPattern** (field)

`Field FSearchPattern: string`

• **ShowHelp**

`procedure ShowHelp();`

Shows the help information 

• **ConvertToMarkdown**

`function ConvertToMarkdown(const XMLContent: string): string;`


• **ConvertFilesToMarkdown**

`procedure ConvertFilesToMarkdown(FileNames: TArray<System.string>);`

Converts a list of files or directories to markdown 

• **ConvertFileToMarkdown**

`procedure ConvertFileToMarkdown(const FileName: string);`

Converts a file to markdown 

• **ConvertDirectoryToMarkdown**

`procedure ConvertDirectoryToMarkdown(const DirName: string);`

Converts a directory to markdown 

• **Convert**

`procedure Convert();`

Converts all files to markdown 

• **Create**

`constructor Create();`

The constructor 

• **ParseCommandLine**

`procedure ParseCommandLine();`

Parses the command line 

• **Run**

`procedure Run();`

Run the command line tool 


