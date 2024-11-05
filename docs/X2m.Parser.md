# Unit X2m.Parser


## 🟧 TNodeHandlerProc (type)

This event is used to handle the processing of a node with a custom procedure 

## 🟦 TNodeHandler (record)

This record is used to store the template OR the procedure to handle XML transformations 
• **Template** (field)

`Field Template: string`

• **Proc** (field)

`Field Proc: TNodeHandlerProc`

• **IsDefault**

`function IsDefault(): Boolean;`

• **Default**

`function Default(): TNodeHandler;`

## 🟦 TTemplates (class)

`TTemplates = class({System.Generics.Collections}TDictionary\<System.string,X2m.Parser.TNodeHandler\>)`

This class is used to store all the templates and procedures to handle XML transformations. The key is the name of the XML node. 

Members:

• **AddString**

`procedure AddString(const AName: string, const ATemplate: string);`

Add a string template to the dictionary 

• **AddProc**

`procedure AddProc(const AName: string, AProc: TNodeHandlerProc);`

Add a procedure to the dictionary 


## 🟦 TParser (class)

`TParser = class(TObject)`

This class is responsible for parsing the XMLDOC and converting it to markdown 

Members:

• **FLevel** (field)

`Field FLevel: Integer`

• **FTemplates** (field)

`Field FTemplates: TTemplates`

• **FShowPrivate** (field)

`Field FShowPrivate: Boolean`

• **ProcessTemplate**

`function ProcessTemplate(const ATemplate: string, Node: IXMLNode): string;`
This method processes a template and replaces the placeholders with the values from the XML node 

• **ProcessTextNode**

`function ProcessTextNode(Node: IXMLNode): string;`
This method processes a text node and returns the text value 

• **ProcessNode**

`function ProcessNode(Node: IXMLNode): string;`
This method processes a node with the templates or procedures found in the TTemplates class 

• **ProcessNodes**

`function ProcessNodes(Node: IXMLNodeList): string;`
This method processes a list of nodes 

• **ProcessParameters**

`function ProcessParameters(Node: IXMLNode): string;`
This method processes the parameters of a function or procedure 

• **FunctionHandler**

`function FunctionHandler(Node: IXMLNode): string;`
Custom procedure to handle a **function** node 

• **ProcedureHandler**

`function ProcedureHandler(Node: IXMLNode): string;`
Custom procedure to handle a **procedure** node 

• **PropertyHandler**

`function PropertyHandler(Node: IXMLNode): string;`
Custom procedure to handle a **property** node 

• **ConstructorHandler**

`function ConstructorHandler(Node: IXMLNode): string;`
Custom procedure to handle a **constructor** node 

• **DestructorHandler**

`function DestructorHandler(Node: IXMLNode): string;`
Custom procedure to handle a **destructor** node 

• **FieldHandler**

`function FieldHandler(Node: IXMLNode): string;`
Custom procedure to handle a **field** node 

• **MethodHandler**

`function MethodHandler(const AMethodKind: string, Node: IXMLNode): string;`
Custom procedure to handle a **method** node (procedure, function, constructor, destructor) 

• **EnumHandler**

`function EnumHandler(Node: IXMLNode): string;`
Custom procedure to handle a **enum** node 

• **ConstHandler**

`function ConstHandler(Node: IXMLNode): string;`
Custom procedure to handle a **const** node 

• **ClassHandler**

`function ClassHandler(Node: IXMLNode): string;`
Custom procedure to handle a **class** node 

• **InterfaceHandler**

`function InterfaceHandler(Node: IXMLNode): string;`
Custom procedure to handle a **interface** node 

• **ArrayHandler**

`function ArrayHandler(Node: IXMLNode): string;`
Custom procedure to handle a **array** node 

• **VarHandler**

`function VarHandler(Node: IXMLNode): string;`
Custom procedure to handle a **var** node 

• **ParseRetVar**

`function ParseRetVar(Node: IXMLNode): string;`
Extracts the return variable from the parameters node 

• **ShowElement**

`function ShowElement(Node: IXMLNode): Boolean;`
Determines if the element should be shown (default is true for non-private elements) 

• **ConvertToMarkdown**

`function ConvertToMarkdown(const XMLContent: string): string;`
Converts a XMLDOC string to markdown 

• **ShowPrivate**

`property ShowPrivate: Boolean`
This property determines if private elements should be shown in the markdown (default is false) 

• **Create**

`constructor Create();`


• **Destroy**

`destructor Destroy();`



