unit X2m.Parser;

interface

uses
  System.Classes, System.SysUtils, System.StrUtils, System.Variants,
  System.Generics.Collections,
  Xml.xmldom,
  Xml.XMLDoc,
  Xml.XMLIntf;

type
  TNodeHandlerProc = function (Node: IXMLNode): string of object;

  TNodeHandler = record
  public
    Template: string;
    Proc: TNodeHandlerProc;
    function IsDefault: Boolean;
    class function Default: TNodeHandler; static;
  end;

  TTemplates = class(TDictionary<string, TNodeHandler>)
  public
    procedure AddString(const AName, ATemplate: string);
    procedure AddProc(const AName: string; AProc: TNodeHandlerProc);
  end;

  TParser = class(TObject)
  private
    FLevel: Integer;
    FTemplates: TTemplates;
    function ProcessTemplate(const ATemplate: string; Node: IXMLNode): string;
    function ProcessTextNode(Node: IXMLNode): string;
    function ProcessNode(Node: IXMLNode): string;
    function ProcessNodes(Node: IXMLNodeList): string;
    function ProcessParameters(Node: IXMLNode): string;

    function FunctionHandler(Node: IXMLNode): string;
    function ParseRetVar(Node: IXMLNode): string;
    function ProcedureHandler(Node: IXMLNode): string;
    function PropertyHandler(Node: IXMLNode): string;
    function ConstructorHandler(Node: IXMLNode): string;
    function DestructorHandler(Node: IXMLNode): string;
    function FieldHandler(Node: IXMLNode): string;
    function MethodHandler(const AMethodKind: string; Node: IXMLNode): string;
    function EnumHandler(Node: IXMLNode): string;

    function ShowElement(Node: IXMLNode): Boolean;
    function ConstHandler(Node: IXMLNode): string;
    function ClassHandler(Node: IXMLNode): string;
    function InterfaceHandler(Node: IXMLNode): string;
    function ArrayHandler(Node: IXMLNode): string;
  public
    function ConvertToMarkdown(const XMLContent: string): string;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

function QuoteMD(const AValue: string): string;
begin
  Result := AValue;
  Result := StringReplace(Result, '<', '\<', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '\>', [rfReplaceAll]);
end;

function Coalesce(const AValue, ADefault: string): string;
begin
  if AValue <> '' then
    Result := AValue
  else
    Result := ADefault;
end;

function StripBlanks(const Text: string): string;
begin
  Result := '';
  var LSpace := True;
  var LNewLine := False;
  var LUnixNewLine := False;
  var I := 1;
  while I <= Length(Text) do
  begin
    if CharInSet(Text[I], [#13, #10, #9, ' '])  then
    begin
      if Copy(Text, I, 2) = sLineBreak then
      begin
        if LNewLine then
        begin
          Result := Result + sLineBreak + sLineBreak;
          Inc(I, 2);
          Continue;
        end;
        LNewLine := True;
      end;
      if Copy(Text, I, 1) = #10 then
      begin
        if LUnixNewLine then
        begin
          Result := Result + sLineBreak + sLineBreak;
          Inc(I, 1);
          Continue;
        end;
        LUnixNewLine := True;
      end;

      if not LSpace then
        Result := Result + ' ';
      LSpace := True;
    end
    else
    begin
      LSpace := False;
      LNewLine := False;
      LUnixNewLine := False;
      Result := Result + Text[I];
    end;
    Inc(I);
  end;
end;

{ TParser }

function QuoteAttributeValue(const AValue: string): string;
begin
  Result := AValue;
end;

function QuoteTextValue(const AValue: string): string;
begin
  Result := AValue;
end;

constructor TParser.Create;
begin
  inherited;
  FLevel := 0;

  FTemplates := TTemplates.Create;

  FTemplates.AddString('interfaces', '');
  FTemplates.AddString('attributes', '');
  FTemplates.AddString('ancestor', '');
  FTemplates.AddString('namespace', '# Unit %name%' + sLineBreak + sLineBreak + '%children%');
  //FTemplates.AddString('class', sLineBreak + '## %name% (class)' + sLineBreak + sLineBreak + '%children%');
  FTemplates.AddString('struct', sLineBreak + '## %name% (record)' + sLineBreak + sLineBreak + '%children%');
  FTemplates.AddProc('class', ClassHandler);
  FTemplates.AddProc('interface', InterfaceHandler);
  FTemplates.AddString('helper', sLineBreak + '## %name% helper for %for%' + sLineBreak + sLineBreak + '%children%');
  FTemplates.AddString('members', 'Members:' + sLineBreak + sLineBreak + '%children%');
  FTemplates.AddProc('function', FunctionHandler);
  FTemplates.AddProc('procedure', ProcedureHandler);
  FTemplates.AddProc('constructor', ConstructorHandler);
  FTemplates.AddProc('destructor', DestructorHandler);
  FTemplates.AddProc('property', PropertyHandler);
  FTemplates.AddProc('field', FieldHandler);
  FTemplates.AddProc('const', ConstHandler);
  FTemplates.AddProc('enum', EnumHandler);
  FTemplates.AddString('set', sLineBreak + '## %name% (set)' + sLineBreak + sLineBreak + '`%name% = set of %type%`' + sLineBreak + sLineBreak);
  FTemplates.AddString('pointer', sLineBreak + '## %name% (pointer)' + sLineBreak + sLineBreak + '`%name% = Pointer`' + sLineBreak + sLineBreak);
  FTemplates.AddString('anonMethod', sLineBreak + '## %name% (reference)' + sLineBreak + sLineBreak + '`%name% = reference to procedure`' + sLineBreak + sLineBreak);
  FTemplates.AddProc('array', ArrayHandler);
  FTemplates.AddString('b', '**%children%** ');
  FTemplates.AddString('i', '*%children%* ');
  FTemplates.AddString('summary', '%children%');
  FTemplates.AddString('remarks', sLineBreak + '**Remarks**: %children%' + sLineBreak);
  FTemplates.AddString('returns', '*Returns*: %children%' + sLineBreak);
  FTemplates.AddString('param', sLineBreak + '`%name%`: %children%' + sLineBreak);
  FTemplates.AddString('seealso', 'See also: [%children%](%href%)');
  //FTemplates.AddString('devnotes', '<div class="devnotes">' + sLineBreak + '%children%' + sLineBreak + '</div>' + sLineBreak);
  FTemplates.AddString('devnotes', '%children%' + sLineBreak);
end;

destructor TParser.Destroy;
begin
  FTemplates.Free;
  inherited;
end;

function TParser.DestructorHandler(Node: IXMLNode): string;
begin
  Result := MethodHandler('destructor', Node);
end;

function TParser.EnumHandler(Node: IXMLNode): string;
begin
  if not ShowElement(Node) then
    Exit('');

  Result := '## ' + Node.Attributes['name'] + ' (enum)' + sLineBreak + sLineBreak;
  var LValues: TArray<string> := [];
  for var I := 0 to Node.ChildNodes.Count - 1 do
  begin
    if Node.ChildNodes[I].NodeName = 'element' then
      LValues := LValues + [VarToStr(Node.ChildNodes[I].Attributes['name'])];
  end;

  Result := Result + '`' + Node.Attributes['name'] + ' = (' + string.Join(', ', LValues) + ');`' + sLineBreak;
  var LNode := Node.ChildNodes.FindNode('devnotes');
  if Assigned(LNode) then
  begin
    Result := Result + ProcessNode(LNode);
  end;
  Result := Result + sLineBreak;

end;

function TParser.FieldHandler(Node: IXMLNode): string;
begin
  if not ShowElement(Node) then
    Exit('');

  Result := '**' + Node.Attributes['name'] + '** (field)' + sLineBreak + sLineBreak;
  Result := Result + '`Field ' + Node.Attributes['name'] + ': ' + Coalesce(VarToStr(Node.Attributes['type']), '?') + '`' + sLineBreak;
  var LNode := Node.ChildNodes.FindNode('devnotes');
  if Assigned(LNode) then
  begin
    Result := Result + ProcessNode(LNode);
  end;
  Result := Result + sLineBreak;
end;

function TParser.ArrayHandler(Node: IXMLNode): string;
begin
  var LType: string := '?';
  if Assigned(Node.ChildNodes.FindNode('element')) then
    LType := Coalesce(VarToStr(Node.ChildNodes.FindNode('element').Attributes['type']), '?');

  Result := '## ' + VarToStr(Node.Attributes['name']) + ' (array)' + sLineBreak + sLineBreak;
  Result := Result + '`' + VarToStr(Node.Attributes['name']) + ' = array of ' + LType + '`' + sLineBreak + sLineBreak;
  Result := Result + ProcessNodes(Node.ChildNodes) + sLineBreak;
end;

function TParser.ClassHandler(Node: IXMLNode): string;
begin
  var LAnchestor := 'TObject';
  var LAnchestorNode := Node.ChildNodes.FindNode('ancestor');
  if Assigned(LAnchestorNode) then
  begin
    LAnchestor := QuoteMD(Coalesce(VarToStr(LAnchestorNode.Attributes['name']), 'TObject'));
  end;
  var LImplements: TArray<string> := [];
  var LImplementsStr := '';
  if Assigned(Node.ChildNodes.FindNode('interfaces')) then
  begin
    var Interfaces := Node.ChildNodes.FindNode('interfaces');
    for var I := 0 to Interfaces.ChildNodes.Count - 1 do
    begin
      if Interfaces.ChildNodes[I].NodeName = 'implements' then
        LImplements := LImplements + [Coalesce(VarToStr(Interfaces.ChildNodes[I].Attributes['name']), '?')];
    end;
    if Length(LImplements) > 0 then
      LImplementsStr := ', ' + string.Join(', ', LImplements);
  end;

  Result := '## ' + VarToStr(Node.Attributes['name']) + ' (class)' + sLineBreak + sLineBreak;
  Result := Result + '`' + VarToStr(Node.Attributes['name']) + ' = class(' + LAnchestor + LImplementsStr + ')`' + sLineBreak + sLineBreak;
  Result := Result + ProcessNodes(Node.ChildNodes) + sLineBreak;
end;

function TParser.ConstHandler(Node: IXMLNode): string;
begin
  if not ShowElement(Node) then
    Exit('');

  Result := '**' + Node.Attributes['name'] + '** (const)' + sLineBreak + sLineBreak;
  Result := Result + '`const ' + Node.Attributes['name'] + ': ' + Coalesce(VarToStr(Node.Attributes['type']), '?') + '`' + sLineBreak;
  var LNode := Node.ChildNodes.FindNode('devnotes');
  if Assigned(LNode) then
  begin
    Result := Result + ProcessNode(LNode);
  end;
  Result := Result + sLineBreak;
end;

function TParser.FunctionHandler(Node: IXMLNode): string;
begin
  Result := '**' + Node.Attributes['name'] + '**' + sLineBreak + sLineBreak;
  var LParamsNode := Node.ChildNodes.FindNode('parameters');
  Result := Result + '`function ' + Node.Attributes['name'] + '(' + ProcessParameters(LParamsNode) + '): ' + ParseRetVar(LParamsNode) + ';`' + sLineBreak;
  var LNode := Node.ChildNodes.FindNode('devnotes');
  if Assigned(LNode) then
  begin
    Result := Result + ProcessNode(LNode);
  end;
  Result := Result + sLineBreak;
end;

function TParser.InterfaceHandler(Node: IXMLNode): string;
begin
  var LAnchestor := VarToStr(Node.Attributes['ancestor']);

  Result := '## ' + VarToStr(Node.Attributes['name']) + ' (interface)' + sLineBreak + sLineBreak;
  Result := Result + '`' + VarToStr(Node.Attributes['name']) + ' = interface(' + LAnchestor + ')`' + sLineBreak + sLineBreak;
  Result := Result + ProcessNodes(Node.ChildNodes) + sLineBreak;
end;

function TParser.ProcedureHandler(Node: IXMLNode): string;
begin
  Result := MethodHandler('procedure', Node);
end;

function TParser.MethodHandler(const AMethodKind: string; Node: IXMLNode): string;
begin
  if not ShowElement(Node) then
    Exit('');

  Result := '**' + Node.Attributes['name'] + '**' + sLineBreak + sLineBreak;
  var LParamsNode := Node.ChildNodes.FindNode('parameters');
  Result := Result + '`' + AMethodKind + ' ' + Node.Attributes['name'] + '(' + ProcessParameters(LParamsNode) + ');`' + sLineBreak + sLineBreak;
  var LNode := Node.ChildNodes.FindNode('devnotes');
  if Assigned(LNode) then
  begin
    Result := Result + ProcessNode(LNode);
  end;
  Result := Result + sLineBreak;
end;

function TParser.ProcessParameters(Node: IXMLNode): string;
var
  LParameters: TArray<string>;
begin
  Result := '';
  SetLength(LParameters, 0);
  if Assigned(Node) and Assigned(Node.ChildNodes) then
  begin
    for var I := 0 to Node.ChildNodes.Count - 1 do
    begin
      if Node.ChildNodes[I].NodeName = 'parameter' then
      begin
        var LParamFlags := VarToStr(Node.ChildNodes[I].Attributes['paramflags']);
        if LParamFlags <> '' then
          LParamFlags := LParamFlags + ' ';

        LParameters := LParameters + [
          LParamFlags + Node.ChildNodes[I].Attributes['name'] + ': ' + Coalesce(VarToStr(Node.ChildNodes[I].Attributes['type']), '?')
        ];
      end;
    end;
  end;
  Result := string.Join(', ', LParameters);
end;

function TParser.ParseRetVar(Node: IXMLNode): string;
begin
  Result := '?';
  if Assigned(Node) and Assigned(Node.ChildNodes) then
  begin
    for var I := 0 to Node.ChildNodes.Count - 1 do
    begin
      if Node.ChildNodes[I].NodeName = 'retval' then
      begin
        Result := Coalesce(VarToStr(Node.ChildNodes[I].Attributes['type']), '?');
      end;
    end;
  end;
end;

function TParser.ProcessNode(Node: IXMLNode): string;
var
  LHandler: TNodeHandler;
begin
  Result := '';
//  Writeln(StringOfChar(' ', FLevel) + '[S] ' + Node.NodeName);
  Inc(FLevel);
  if not FTemplates.TryGetValue(Node.NodeName, LHandler) then
    LHandler := TNodeHandler.Default;

  if LHandler.Template <> '' then
    Result := ProcessTemplate(LHandler.Template, Node)
  else if Assigned(LHandler.Proc) then
    Result := LHandler.Proc(Node);

//  Writeln(Result);
  Dec(FLevel);
//  Writeln(StringOfChar(' ', FLevel) + '[E] ' + Node.NodeName);
end;

function TParser.ProcessNodes(Node: IXMLNodeList): string;
begin
  Result := '';
  for var I := 0 to Node.Count - 1 do
  begin
    Result := Result + ProcessNode(Node[I]);
  end;
end;

function TParser.ProcessTemplate(const ATemplate: string;
  Node: IXMLNode): string;
begin
  Result := '';
  if ATemplate = '' then
    Exit;

  if ATemplate = '*' then
  begin
    if Node.NodeType in [ntText, ntCData] then
    begin
      Exit(ProcessTextNode(Node));
    end;

    Result := '<' + Node.NodeName;
    for var I := 0 to Node.AttributeNodes.Count - 1 do
    begin
      Result := Result + ' ' + Node.AttributeNodes[I].NodeName + '="' + QuoteAttributeValue(Node.AttributeNodes[I].NodeValue) + '"';
    end;
    Result := Result + '>';
    if Node.ChildNodes.Count > 0 then
    begin
      Result := Result + ProcessNodes(Node.ChildNodes);
    end;

    Result := Result + '</' + Node.NodeName +  '>';
    Exit;
  end;

  Result := ATemplate;
  for var I := 0 to Node.AttributeNodes.Count - 1 do
  begin
    Result := StringReplace(Result, '%' + Node.AttributeNodes[I].NodeName + '%', Node.AttributeNodes[I].NodeValue, [rfReplaceAll, rfIgnoreCase]);
  end;
  if Pos('%children%', Result) > 0 then
  begin
    var LValue := ProcessNodes(Node.ChildNodes);
    Result := StringReplace(Result, '%children%', LValue, [rfReplaceAll, rfIgnoreCase]);
  end;
end;

function TParser.ProcessTextNode(Node: IXMLNode): string;
begin
  Result := StripBlanks(Node.NodeValue);
end;

function TParser.PropertyHandler(Node: IXMLNode): string;
begin
  if not ShowElement(Node) then
    Exit('');

  Result := '**' + Node.Attributes['name'] + '**' + sLineBreak + sLineBreak;
  Result := Result + '`property ' + Node.Attributes['name'] + ': ' + Node.Attributes['type'] + '`' + sLineBreak;
  var LNode := Node.ChildNodes.FindNode('devnotes');
  if Assigned(LNode) then
  begin
    Result := Result + ProcessNode(LNode);
  end;
  Result := Result + sLineBreak;
end;

function TParser.ShowElement(Node: IXMLNode): Boolean;
begin
  var LVisibility := VarToStr(Node.Attributes['visibility']);
  Result := LVisibility <> 'private';
end;

function TParser.ConstructorHandler(Node: IXMLNode): string;
begin
  Result := MethodHandler('constructor', Node);
end;

function TParser.ConvertToMarkdown(const XMLContent: string): string;
var
  XMLDoc: IXMLDocument;
begin
  XMLDoc := TXMLDocument.Create(nil);
  XMLDoc.LoadFromXML(XMLContent);
  Result := ProcessNode(XMLDoc.DocumentElement);
end;

{ TNodeHandler }

class function TNodeHandler.Default: TNodeHandler;
begin
  Result.Template := '*';
  Result.Proc := nil;
end;

function TNodeHandler.IsDefault: Boolean;
begin
  Result := Template = '*';
end;

{ TTemplates }

procedure TTemplates.AddProc(const AName: string; AProc: TNodeHandlerProc);
var
  LNodeHandler: TNodeHandler;
begin
  LNodeHandler.Template := '';
  LNodeHandler.Proc := AProc;
  Add(AName, LNodeHandler);
end;

procedure TTemplates.AddString(const AName, ATemplate: string);
var
  LNodeHandler: TNodeHandler;
begin
  LNodeHandler.Template := ATemplate;
  LNodeHandler.Proc := nil;
  Add(AName, LNodeHandler);
end;

end.
