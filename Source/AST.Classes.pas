unit AST.Classes;

interface

uses
  System.SysUtils,
  AVL,
  AST.Lexer,
  AST.Intf,
  AST.JsonSchema,
  AST.Parser.Utils,
  AST.Parser.ProcessStatuses;

type
  TASTItemTypeID = Integer;
  TASTTokenId = Integer;

  TASTItem = class;
  TASTProject = class;
  TASTModule = class;
  TASTDeclaration = class;

  TASTExpression = class;

  TASTExpressionArray = array of TASTExpression;

  TASTUnitClass = class of TASTModule;

  TASTItem = class(TPooledObject)
  private
    fParent: TASTItem;
    fNext: TASTItem;
    //function GetItemTypeID: TASTItemTypeID; virtual; abstract;
  protected
    function GetDisplayName: string; virtual;
  public
    constructor Create(Parent: TASTItem); overload; virtual;
//    property TypeID: TASTItemTypeID read GetItemTypeID;
    property Next: TASTItem read fNext write fNext;
    property DisplayName: string read GetDisplayName;
    property Parent: TASTItem read fParent;
  end;

  TASTItemClass = class of TASTItem;


  TASTProjectSettings = class(TInterfacedObject, IASTProjectSettings)
  end;

  TASTProject = class(TInterfacedObject, IASTProject)
  private
    fName: string;
    fOnProgress: TASTProgressEvent;
    fOnConsoleProc: TASTProjectConsoleWriteEvent;
    fStopIfErrors: Boolean;
    procedure SetName(const Value: string);
    procedure SetOnProgress(const Value: TASTProgressEvent);
    procedure SetOnConsoleWrite(const Value: TASTProjectConsoleWriteEvent);
    procedure SetStopCompileIfError(const Value: Boolean);
    function GetOnProgress: TASTProgressEvent;
    function GetOnConsoleWrite: TASTProjectConsoleWriteEvent;
  protected
    function GetName: string;
    function GetUnitClass: TASTUnitClass; virtual; abstract;
    function GetPointerSize: Integer; virtual; abstract;
    function GetNativeIntSize: Integer; virtual; abstract;
    function GetVariantSize: Integer; virtual; abstract;
    function GetTotalLinesParsed: Integer; virtual;
    function GetTotalUnitsParsed: Integer; virtual;
    function GetTotalUnitsIntfOnlyParsed: Integer; virtual;
    function GetStopCompileIfError: Boolean;
    function InPogress: Boolean; virtual; abstract;
    procedure PutMessage(const AMessage: IASTParserMessage); overload; virtual;
    procedure PutMessage(const AModule: IASTModule; AMsgType: TCompilerMessageType; const AMessage: string;
                         const ATextPostition: TTextPosition; ACritical: Boolean); overload; virtual;
  public
    procedure ClearEvents;
    constructor Create(const AName: string); virtual;
    property Name: string read GetName write SetName;
    property OnProgress: TASTProgressEvent read GetOnProgress write SetOnProgress;
    property StopCompileIfError: Boolean read GetStopCompileIfError write SetStopCompileIfError;
    procedure CosoleWrite(const Module: IASTModule; Line: Integer; const Message: string);
    function ToJson: TJsonASTDeclaration; virtual;
  end;

  TASTParentItem = class(TASTItem)
  private
    fFirstChild: TASTItem;
    fLastChild: TASTItem;
  protected
    function GetDisplayName: string; override;
  public
    procedure AddChild(Item: TASTItem);
    property FirstChild: TASTItem read fFirstChild;
    property LastChild: TASTItem read fLastChild;
  end;

  TASTBlock = class(TASTParentItem)
  private
    function GetIsLoopBody: Boolean;
    function GetIsTryBlock: Boolean;
  public
    property IsLoopBody: Boolean read GetIsLoopBody;
    property IsTryBlock: Boolean read GetIsTryBlock;
  end;

  TASTModule = class(TInterfacedObject, IASTModule)
  private
    fFileName: string;
    function GetFileName: string;
  protected
    fProject: IASTProject;
    fTotalLinesParsed: Integer;
    function GetModuleName: string; virtual;
    function GetModulePath: string;
    function GetSource: string; virtual; abstract;
    function GetCurrentFileName: string; virtual; abstract;
    procedure SetFileName(const Value: string);
    procedure Progress(StatusClass: TASTProcessStatusClass; AElapsedTime: Int64); virtual;
    procedure PutError(const AMessage: string; const ATextPosition: TTextPosition; ACritical: Boolean = False); overload;
    procedure PutError(const AMessage: string; const AParams: array of const; const ATextPosition: TTextPosition; ACritical: Boolean = False); overload;
    function Lexer_Line: Integer; virtual; abstract;
    function Lexer_Position: TTextPosition; virtual; abstract;
    function Lexer_TokenName(AToken: Integer): string; virtual; abstract;
    function Lexer_TokenText(AToken: Integer): string; virtual; abstract;
  public
    property Name: string read GetModuleName;
    property FileName: string read GetFileName write SetFileName;
    property CurrentFileName: string read GetCurrentFileName;
    property Project: IASTProject read fProject;
    function GetTotalLinesParsed: Integer;
    constructor Create(const AProject: IASTProject; const AFileName: string; const ASource: string = ''); virtual;
    constructor CreateFromFile(const Project: IASTProject; const FileName: string); virtual;
    procedure EnumDeclarations(const AEnumProc: TEnumASTDeclProc; AUnitScope: TUnitScopeKind); virtual; abstract;
    property TotalLinesParsed: Integer read GetTotalLinesParsed;
    function ToJson: TJsonASTDeclaration; virtual;
    function Compile(ACompileIntfOnly: Boolean; RunPostCompile: Boolean = True): TCompilerResult; virtual; abstract;
  end;

  TASTDeclaration = class(TASTItem, IASTDeclaration)
  protected
    fID: TIdentifier;
    fModule: TASTModule;
    fHandle: Integer;
    function GetID: TIdentifier;
    function GetName: string;
    function GetSrcPos: TTextPosition;
    function GetModule: IASTModule;
    function GetDisplayName: string; override;
    function Get_Obj: TObject;
    function GetASTKind: string; virtual;
    function GetASTHandle: TASTHandle; virtual;

    procedure SetID(const AValue: TIdentifier);
    procedure SetName(const AValue: string);
    procedure SetSrcPos(const AValue: TTextPosition);
  public
    property ID: TIdentifier read fID write fID;
    property Name: string read fID.Name write FID.Name;
    property TextPosition: TTextPosition read FID.TextPosition write FID.TextPosition;
    property SourcePosition: TTextPosition read FID.TextPosition;
    property Module: TASTModule read fModule;
    property DisplayName: string read GetDisplayName;
    function ToJson: TJsonASTDeclaration; virtual;
    function Decl2Str(AFullName: Boolean = False): string; overload;

    procedure Decl2Str(ABuilder: TStringBuilder;
                       ANestedLevel: Integer = 0;
                       AAppendName: Boolean = True); overload; virtual;

    property ASTKind: string read GetASTKind;
    property ASTHandle: TASTHandle read GetASTHandle;
    function ASTJsonDeclClass: TASTJsonDeclClass; virtual;
  end;

  TASTIDList = class(TAVLTree<string, TASTDeclaration>)
  public
    function InsertID(ADecl: TASTDeclaration): Boolean; inline; // true - ok, false - already exist
    function InsertIDAndReturnIfExist(ADecl: TASTDeclaration): TASTDeclaration; inline;
    function FindID(const AName: string): TASTDeclaration; virtual; //inline;
  end;

  TASTDeclarations = array of TASTDeclaration;

  TASTOperation = class(TASTItem)
  end;

  TASTOperationClass = class of TASTOperation;

  TASTOpOpenRound = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpCloseRound = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpPlus = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpMinus = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpEqual = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpNotEqual = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpGrater = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpGraterEqual = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpLess = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpLessEqual = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpMul = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpDiv = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpIntDiv = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpMod = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpBinAnd = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpBinOr = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpBinXor = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpBinNot = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpLogicalAnd = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpLogicalOr = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpLogicalNot = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpShr = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpShl = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpRawCast = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpDynCast = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpCastCheck = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTOpCallProc = class(TASTOperation)
  private
    fProc: TASTDeclaration;
    fArgs: TASTExpressionArray;
  protected
    function GetDisplayName: string; override;
  public
    property Proc: TASTDeclaration read fProc write fProc;
    procedure AddArg(const Expr: TASTExpression);
  end;

  TASTOpArrayAccess = class(TASTOperation)
  private
    fIndexes: TASTExpressionArray;
  protected
    function GetDisplayName: string; override;
  public
    property Indexes: TASTExpressionArray read fIndexes write fIndexes;
    procedure AddIndex(Expr: TASTExpression);
  end;

  TASTOpMemberAccess = class(TASTOperation)
  protected
    function GetDisplayName: string; override;
  end;

  TASTEIDecl = class(TASTOperation)
  private
    fDecl: TASTDeclaration;
    fSPos: TTextPosition;
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Decl: TASTDeclaration; const SrcPos: TTextPosition); reintroduce;
  end;

  TASTExpression = class(TASTParentItem)
  protected
    function GetDisplayName: string; override;
  public
    procedure AddSubItem(ItemClass: TASTOperationClass);
    procedure AddDeclItem(Decl: TASTDeclaration; const SrcPos: TTextPosition);
    function AddOperation<TASTClass: TASTOperation>: TASTClass;
  end;

  TASTKeyword = class(TASTItem)

  end;

  TASTOpAssign = class(TASTItem)
  private
    fDst: TASTExpression;
    fSrc: TASTExpression;
  protected
    function GetDisplayName: string; override;
  public
    property Dst: TASTExpression read fDst write fDst;
    property Src: TASTExpression read fSrc write fSrc;
  end;

  TASTKWGoTo = class(TASTKeyword)
  private
    fLabel: TASTDeclaration;
  protected
    function GetDisplayName: string; override;
  public
    property LabelDecl: TASTDeclaration read fLabel write fLabel;
  end;

  TASTKWLabel = class(TASTKeyword)
  private
    fLabel: TASTDeclaration;
  protected
    function GetDisplayName: string; override;
  public
    property LabelDecl: TASTDeclaration read fLabel write fLabel;
  end;

  TASTCall = class(TASTExpression)
  end;

  TASTVariable = class(TASTDeclaration)

  end;

  TASTKWExit = class(TASTKeyword)
  private
    fExpression: TASTExpression;
  protected
    function GetDisplayName: string; override;
  public
    property Expression: TASTExpression read fExpression write fExpression;
  end;



  TASTKWIF = class(TASTKeyword)
  type
    TASTKWIfThenBlock = class(TASTBlock) end;
    TASTKWIfElseBlock = class(TASTBlock) end;
  private
    fExpression: TASTExpression;
    fThenBody: TASTBlock;
    fElseBody: TASTBlock;
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Parent: TASTItem = nil); override;
    property Expression: TASTExpression read fExpression write fExpression;
    property ThenBody: TASTBlock read fThenBody write fThenBody;
    property ElseBody: TASTBlock read fElseBody write fElseBody;
  end;

  TASTKWLoop = class(TASTKeyword)
  private
    fBody: TASTBlock;
  public
    constructor Create(Parent: TASTItem = nil); override;
    property Body: TASTBlock read fBody;
  end;

  TASTKWWhile = class(TASTKWLoop)
  private
    fExpression: TASTExpression;
  protected
    function GetDisplayName: string; override;
  public
    property Expression: TASTExpression read fExpression write fExpression;
  end;

  TASTKWRepeat = class(TASTKWLoop)
  private
    fExpression: TASTExpression;
  protected
    function GetDisplayName: string; override;
  public
    property Expression: TASTExpression read fExpression write fExpression;
  end;

  TDirection = (dForward, dBackward);

  TASTKWFor = class(TASTKWLoop)
  private
    fExprInit: TASTExpression;
    fExprTo: TASTExpression;
    fDirection: TDirection;
  protected
    function GetDisplayName: string; override;
  public
    property ExprInit: TASTExpression read fExprInit write fExprInit;
    property ExprTo: TASTExpression read fExprTo write fExprTo;
    property Direction: TDirection read fDirection write fDirection;
  end;

  TASTKWForIn = class(TASTKWLoop)
  private
    fVar: TASTExpression;
    fList: TASTExpression;
  protected
    function GetDisplayName: string; override;
  public
    property VarExpr: TASTExpression read fVar write fVar;
    property ListExpr: TASTExpression read fList write fList;
  end;

  TASTKWBreak = class(TASTKeyword)
  protected
    function GetDisplayName: string; override;
  end;

  TASTKWContinue = class(TASTKeyword)
  protected
    function GetDisplayName: string; override;
  end;

  TASTKWRaise = class(TASTKeyword)
  private
    fExpr: TASTExpression;
  protected
    function GetDisplayName: string; override;
  public
    property Expression: TASTExpression read fExpr write fExpr;
  end;

  TASTKWInherited = class(TASTKeyword)
  private
    fExpr: TASTExpression;
  protected
    function GetDisplayName: string; override;
  public
    property Expression: TASTExpression read fExpr write fExpr;
  end;

  TASTKWWith = class(TASTKeyword)
  private
    fExpressions: TASTExpressionArray;
    fBody: TASTBlock;
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Parent: TASTItem); override;
    property Expressions: TASTExpressionArray read fExpressions;
    property Body: TASTBlock read fBody;
    procedure AddExpression(const Expr: TASTExpression);
  end;

  TASTExpBlockItem = class(TASTItem)
  private
    fExpression: TASTExpression;
    fBody: TASTBlock;
  public
    constructor Create(Parent: TASTItem); override;
    property Expression: TASTExpression read fExpression;
    property Body: TASTBlock read fBody;
  end;

  TASTKWTryExceptItem = class(TASTExpBlockItem)
  protected
    function GetDisplayName: string; override;
  end;

  TASTKWInheritedCall = class(TASTKeyword)
  private
    fProc: TASTExpression;
  protected
    function GetDisplayName: string; override;
  end;


  TASTKWCase = class(TASTKeyword)
  private
    fExpression: TASTExpression;
    fFirstItem: TASTExpBlockItem;
    fLastItem: TASTExpBlockItem;
    fElseBody: TASTBlock;
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Parent: TASTItem); override;
    function AddItem(Expression: TASTExpression): TASTExpBlockItem;
    property Expression: TASTExpression read fExpression write fExpression;
    property FirstItem: TASTExpBlockItem read fFirstItem;
    property ElseBody: TASTBlock read fElseBody;
  end;

  TASTKWTryBlock = class(TASTKeyword)
  private
    fBody: TASTBlock;
    fFinallyBody: TASTBlock;
    fFirstExceptBlock: TASTKWTryExceptItem;
    fLastExceptBlock: TASTKWTryExceptItem;
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Parent: TASTItem); override;
    property Body: TASTBlock read fBody;
    property FinallyBody: TASTBlock read fFinallyBody write fFinallyBody;
    property FirstExceptBlock: TASTKWTryExceptItem read fFirstExceptBlock;
    property LastExceptBlock: TASTKWTryExceptItem read fLastExceptBlock;
    function AddExceptBlock(Expression: TASTExpression): TASTKWTryExceptItem;
  end;

  TASTKWDeclSection = class(TASTKeyword)
  private
    fDecls: TASTDeclarations;
  public
    procedure AddDecl(const Decl: TASTDeclaration);
    property Decls: TASTDeclarations read fDecls;
  end;

  TASTKWInlineVarDecl = class(TASTKWDeclSection)
  private
    fExpression: TASTExpression;
  protected
    function GetDisplayName: string; override;
  public
    property Expression: TASTExpression read fExpression write fExpression;
  end;

  TASTKWInlineConstDecl = class(TASTKeyword)
  protected
    function GetDisplayName: string; override;
  end;

  TASTKWAsm = class(TASTKeyword)
  protected
    function GetDisplayName: string; override;
  end;

  TASTFunc = class(TASTDeclaration)
  private
    fBody: TASTBlock;
  protected
    property Body: TASTBlock read fBody;
  end;

  TASTType = class(TASTDeclaration)

  end;


implementation

uses
  System.StrUtils,
  AST.Parser.Errors;

procedure TASTParentItem.AddChild(Item: TASTItem);
begin
  if Assigned(fLastChild) then
    fLastChild.Next := Item
  else
    fFirstChild := Item;

  fLastChild := Item;
end;

{ TASTExpression }

procedure TASTExpression.AddDeclItem(Decl: TASTDeclaration; const SrcPos: TTextPosition);
var
  Item: TASTEIDecl;
begin
  Item := TASTEIDecl.Create(Decl, SrcPos);
  AddChild(Item);
end;

function TASTExpression.AddOperation<TASTClass>: TASTClass;
begin
  Result := TASTClass.Create(Self);
  AddChild(Result);
end;

procedure TASTExpression.AddSubItem(ItemClass: TASTOperationClass);
var
  Item: TASTOperation;
begin
  Item := ItemClass.Create(Self);
  AddChild(Item);
end;

{ TASTUnit }

constructor TASTModule.Create(const AProject: IASTProject; const AFileName: string; const ASource: string);
begin
  fProject := AProject;
  fFileName := AFileName;
end;

function TASTExpression.GetDisplayName: string;
var
  Item: TASTItem;
begin
  Result := '';
  Item := FirstChild;
  while Assigned(Item) do
  begin
    Result := AddStringSegment(Result, Item.DisplayName, ' ');
    Item := Item.Next;
  end;
end;

{ TASTItem }

constructor TASTItem.Create(Parent: TASTItem);
begin
  CreateFromPool;
  fParent := Parent;
end;

function TASTItem.GetDisplayName: string;
begin
  Result := '<unknown>';
end;

{ TASTKWExit }

function TASTKWExit.GetDisplayName: string;
var
  ExprStr: string;
begin
  if Assigned(fExpression) then
    ExprStr := fExpression.DisplayName;
  Result := 'return ' + ExprStr;
end;

function TASTParentItem.GetDisplayName: string;
begin
end;

{ TASTEIOpenRound }

function TASTOpOpenRound.GetDisplayName: string;
begin
  Result := '(';
end;

{ TASTEICloseRound }

function TASTOpCloseRound.GetDisplayName: string;
begin
  Result := ')';
end;

{ TASTEIPlus }

function TASTOpPlus.GetDisplayName: string;
begin
  Result := '+';
end;

{ TASTEIMinus }

function TASTOpMinus.GetDisplayName: string;
begin
  Result := '-';
end;

{ TASTEIMul }

function TASTOpMul.GetDisplayName: string;
begin
  Result := '*';
end;

{ TASTEIDiv }

function TASTOpDiv.GetDisplayName: string;
begin
  Result := '/';
end;

{ TASTEIIntDiv }

function TASTOpIntDiv.GetDisplayName: string;
begin
  Result := 'div';
end;

{ TASTEIMod }

function TASTOpMod.GetDisplayName: string;
begin
  Result := 'mod';
end;

{ TASTEIEqual }

function TASTOpEqual.GetDisplayName: string;
begin
  Result := '=';
end;

{ TASTEINotEqual }

function TASTOpNotEqual.GetDisplayName: string;
begin
  Result := '<>';
end;

{ TASTEIGrater }

function TASTOpGrater.GetDisplayName: string;
begin
  Result := '>';
end;

{ TASTEIGraterEqual }

function TASTOpGraterEqual.GetDisplayName: string;
begin
  Result := '>=';
end;

{ TASTEILess }

function TASTOpLess.GetDisplayName: string;
begin
  Result := '<';
end;

{ TASTEILessEqual }

function TASTOpLessEqual.GetDisplayName: string;
begin
  Result := '<=';
end;

{ TASTEIVariable }

constructor TASTEIDecl.Create(Decl: TASTDeclaration; const SrcPos: TTextPosition);
begin
  CreateFromPool;
  fDecl := Decl;
  fSPos := SrcPos;
end;

function TASTEIDecl.GetDisplayName: string;
begin
  Result := fDecl.DisplayName;
end;

{ TASTDeclaration }

function TASTDeclaration.ASTJsonDeclClass: TASTJsonDeclClass;
begin
  Result := TJsonASTDeclaration;
end;

procedure TASTDeclaration.Decl2Str(ABuilder: TStringBuilder; ANestedLevel: Integer; AAppendName: Boolean);
begin
  ABuilder.Append(format('<unknown %s>', [ClassName]));
end;

function TASTDeclaration.Decl2Str(AFullName: Boolean): string;
begin
  var LBuilder := TStringBuilder.Create;
  try
    if AFullName then
      LBuilder.Append(fModule.Name);
    Decl2Str(LBuilder);
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

function TASTDeclaration.GetASTKind: string;
begin
  Result := '<unknown>';
end;

function TASTDeclaration.GetASTHandle: TASTHandle;
begin
  Result := TASTHandle(Self);
end;

function TASTDeclaration.GetDisplayName: string;
begin
  Result := fID.Name;
end;

function TASTDeclaration.GetID: TIdentifier;
begin
  Result := fID;
end;

function TASTDeclaration.GetModule: IASTModule;
begin
  Result := fModule;
end;

function TASTDeclaration.GetName: string;
begin
  Result := fID.Name;
end;

function TASTDeclaration.GetSrcPos: TTextPosition;
begin
  Result := fID.TextPosition;
end;

function TASTDeclaration.Get_Obj: TObject;
begin
  Result := Self;
end;

procedure TASTDeclaration.SetID(const AValue: TIdentifier);
begin
   fID := AValue;
end;

procedure TASTDeclaration.SetName(const AValue: string);
begin
  fID.Name := AValue;
end;

procedure TASTDeclaration.SetSrcPos(const AValue: TTextPosition);
begin
  fID.TextPosition := AValue;
end;

function TASTDeclaration.ToJson: TJsonASTDeclaration;
begin
  Result := nil;
end;

{ TASTKWAssign }

function TASTOpAssign.GetDisplayName: string;
begin
  Result := fDst.DisplayName + ' := ' + fSrc.DisplayName;
end;

{ TASTKWIF }

constructor TASTKWIF.Create(Parent: TASTItem);
begin
  inherited;
  fThenBody := TASTKWIfThenBlock.Create(Self);
end;

function TASTKWIF.GetDisplayName: string;
begin
  Result := 'IF ' + fExpression.DisplayName;
end;

{ TASTKWhile }

function TASTKWWhile.GetDisplayName: string;
begin
  Result := 'while ' + fExpression.DisplayName;
end;

{ TASTRepeat }

function TASTKWRepeat.GetDisplayName: string;
begin
  Result := 'repeat ' + fExpression.DisplayName;
end;

{ TASTKWWith }

procedure TASTKWWith.AddExpression(const Expr: TASTExpression);
begin
  fExpressions := fExpressions + [Expr];
end;

constructor TASTKWWith.Create(Parent: TASTItem);
begin
  inherited;
  fBody := TASTBlock.Create(Self);
end;

function TASTKWWith.GetDisplayName: string;
begin
  Result := 'with ';
end;

{ TASTKWFor }

function TASTKWFor.GetDisplayName: string;
begin
  Result := 'for ' + fExprInit.DisplayName + ' ' + ifthen(fDirection = dForward, 'to', 'downto') + ' ' + fExprTo.DisplayName;
end;


{ TASTKWLoop }

constructor TASTKWLoop.Create(Parent: TASTItem = nil);
begin
  inherited;
  fBody := TASTBlock.Create(Self);
end;

{ TASTKWSwitch }

function TASTKWCase.AddItem(Expression: TASTExpression): TASTExpBlockItem;
begin
  Result := TASTExpBlockItem.Create(Self);
  Result.fExpression := Expression;

  if Assigned(fLastItem) then
    fLastItem.Next := Result
  else
    fFirstItem := Result;

  fLastItem := Result;
end;

constructor TASTKWCase.Create(Parent: TASTItem);
begin
  inherited;
  fElseBody := TASTBlock.Create(Self);
end;

function TASTKWCase.GetDisplayName: string;
begin
  Result := 'case ' + fExpression.DisplayName;
end;

{ TASTKWSwitchItem }

constructor TASTExpBlockItem.Create(Parent: TASTItem);
begin
  inherited;
  fBody := TASTBlock.Create(Self);
end;

{ TASTBody }

function TASTBlock.GetIsLoopBody: Boolean;
var
  Item: TASTItem;
begin
  Result := fParent is TASTKWLoop;
  if not Result then
  begin
    Item := fParent;
    while Assigned(Item) do
    begin
       if (Item is TASTBlock) and TASTBlock(Item).IsLoopBody then
         Exit(True);
       Item := Item.Parent;
    end;
  end;
end;

function TASTBlock.GetIsTryBlock: Boolean;
begin
  Result := fParent.ClassType = TASTKWTryBlock;
end;

{ TASTKWBreak }

function TASTKWBreak.GetDisplayName: string;
begin
  Result := 'break';
end;

{ TASTKContinue }

function TASTKWContinue.GetDisplayName: string;
begin
  Result := 'continue';
end;

{ TASTKWTryBlock }

function TASTKWTryBlock.AddExceptBlock(Expression: TASTExpression): TASTKWTryExceptItem;
begin
  Result := TASTKWTryExceptItem.Create(Self);
  Result.fExpression := Expression;

  if Assigned(fLastExceptBlock) then
    fLastExceptBlock.Next := Result
  else
    fFirstExceptBlock := Result;

  fLastExceptBlock := Result;
end;

constructor TASTKWTryBlock.Create(Parent: TASTItem);
begin
  inherited;
  fBody := TASTBlock.Create(Self);
end;

function TASTKWTryBlock.GetDisplayName: string;
begin
  Result := 'try';
end;

{ TASTKWInherited }

function TASTKWInherited.GetDisplayName: string;
begin
  Result := 'inherited call';
  if Assigned(Expression) then
    Result := Result + ' ' + Expression.DisplayName;
end;

{ TASTKWRaise }

function TASTKWRaise.GetDisplayName: string;
begin
  Result := 'raise';
  if Assigned(Expression) then
    Result := Result + ' ' + Expression.DisplayName;
end;

{ TASTKWImmVarDecl }

function TASTKWInlineVarDecl.GetDisplayName: string;
begin
  Result := 'var';
  if Assigned(fExpression) then
    Result := Result + ' = ' + fExpression.DisplayName;
end;

{ TASTKWImmConstDecl }

function TASTKWInlineConstDecl.GetDisplayName: string;
begin
  Result := 'const';
end;

{ TASTKWDeclSection }

procedure TASTKWDeclSection.AddDecl(const Decl: TASTDeclaration);
begin
  fDecls := fDecls + [Decl];
end;

{ TASTKWGoTo }

function TASTKWGoTo.GetDisplayName: string;
begin
  Result := 'goto ' + fLabel.DisplayName;
end;

{ TASTKWLabel }

function TASTKWLabel.GetDisplayName: string;
begin
  Result := 'label ' + fLabel.DisplayName + ':';
end;

{ TASTKWTryExceptItem }

function TASTKWTryExceptItem.GetDisplayName: string;
begin
  if Assigned(fExpression) then
    Result := fExpression.DisplayName + ': '
  else
    Result := '';
end;

{ TASTKWAsm }

function TASTKWAsm.GetDisplayName: string;
begin
  Result := 'asm';
end;

{ TASTKWInheritedCall }

function TASTKWInheritedCall.GetDisplayName: string;
begin
  Result := 'inherited ' + fProc.DisplayName;
end;

{ TASTEICallProc }

procedure TASTOpCallProc.AddArg(const Expr: TASTExpression);
begin
  fArgs := fArgs + [Expr];
end;

function TASTOpCallProc.GetDisplayName: string;
var
  SArgs: string;
begin
  for var Arg in fArgs do
    SArgs := AddStringSegment(SArgs, Arg.DisplayName, ', ');
  Result := 'call ' + fProc.DisplayName + '(' + SArgs + ')';
end;

{ TASTKWForIn }

function TASTKWForIn.GetDisplayName: string;
begin
  Result := 'for ' + fVar.DisplayName + ' in ' + fList.DisplayName;
end;

{ TASTOpArrayAccess }

procedure TASTOpArrayAccess.AddIndex(Expr: TASTExpression);
begin
  fIndexes := fIndexes + [Expr];
end;

function TASTOpArrayAccess.GetDisplayName: string;
var
  SIndexes: string;
begin
  for var Expr in fIndexes do
    SIndexes := AddStringSegment(SIndexes, Expr.DisplayName, ', ');
  Result := '[' + SIndexes + ']';
end;

{ TASTOpMemberAccess }

function TASTOpMemberAccess.GetDisplayName: string;
begin
  Result := '.';
end;

{ TASTOpShr }

function TASTOpShr.GetDisplayName: string;
begin
  Result := 'shr';
end;

{ TASTOpShl }

function TASTOpShl.GetDisplayName: string;
begin
  Result := 'shl';
end;

{ TASTOpRawCast }

function TASTOpRawCast.GetDisplayName: string;
begin
  Result := 'rawcast';
end;

{ TASTOpDynCast }

function TASTOpDynCast.GetDisplayName: string;
begin
  Result := 'dyncast';
end;

{ TASTOpCastCheck }

function TASTOpCastCheck.GetDisplayName: string;
begin
  Result := 'castcheck';
end;

{ TASTOpBinAnd }

function TASTOpBinAnd.GetDisplayName: string;
begin
  Result := 'band';
end;

{ TASTOpBinOr }

function TASTOpBinOr.GetDisplayName: string;
begin
  Result := 'bor';
end;

{ TASTOpBinXor }

function TASTOpBinXor.GetDisplayName: string;
begin
  Result := 'bxor';
end;

{ TASTOpBinNot }

function TASTOpBinNot.GetDisplayName: string;
begin
  Result := 'bnot';
end;

{ TASTOpLogicalAnd }

function TASTOpLogicalAnd.GetDisplayName: string;
begin
  Result := 'land';
end;

{ TASTOpLogicalOr }

function TASTOpLogicalOr.GetDisplayName: string;
begin
  Result := 'lor';
end;

{ TASTOpLogicalNot }

function TASTOpLogicalNot.GetDisplayName: string;
begin
  Result := 'lnot';
end;

constructor TASTModule.CreateFromFile(const Project: IASTProject; const FileName: string);
begin
  fFileName := FileName;
end;

function TASTModule.GetFileName: string;
begin
  Result := fFileName;
end;

function TASTModule.GetModuleName: string;
begin
  Result := ExtractFileName(fFileName);
end;

function TASTModule.GetModulePath: string;
begin
  Result := ExtractFilePath(fFileName);
end;

function TASTModule.GetTotalLinesParsed: Integer;
begin
  Result := fTotalLinesParsed;
end;

procedure TASTModule.Progress(StatusClass: TASTProcessStatusClass; AElapsedTime: Int64);
var
  Event: TASTProgressEvent;
begin
  Event := fProject.OnProgress;
  if Assigned(Event) then
    Event(Self, StatusClass, AElapsedTime);
end;

procedure TASTModule.PutError(const AMessage: string; const AParams: array of const;
  const ATextPosition: TTextPosition; ACritical: Boolean);

  procedure DebugBreak;
  asm
    int 3;
  end;

begin
  if Project.StopCompileIfError or ACritical then
    AbortWork(AMessage, AParams, ATextPosition)
  else begin
    Project.PutMessage(Self, cmtError, Format(AMessage, AParams), ATextPosition);
    if (BreakpointOnError) and (System.DebugHook > 0) then
      DebugBreak;
  end;
end;

procedure TASTModule.PutError(const AMessage: string; const ATextPosition: TTextPosition; ACritical: Boolean);
begin
  PutError(AMessage, {AParams:} [], ATextPosition, ACritical);
end;

procedure TASTModule.SetFileName(const Value: string);
begin
  fFileName := Value;
end;

function TASTModule.ToJson: TJsonASTDeclaration;
begin
  Result := nil;
end;

{ TASTProject }

procedure TASTProject.CosoleWrite(const Module: IASTModule; Line: Integer; const Message: string);
begin
  if Assigned(fOnConsoleProc) then
    fOnConsoleProc(Module, Line, Message);
end;

constructor TASTProject.Create(const AName: string);
begin
  fName := AName;
end;

function TASTProject.GetName: string;
begin
  Result := fName;
end;

procedure TASTProject.ClearEvents;
begin
  fOnConsoleProc := nil;
  fOnProgress := nil;
end;

function TASTProject.GetOnConsoleWrite: TASTProjectConsoleWriteEvent;
begin
  Result := fOnConsoleProc;
end;

function TASTProject.GetOnProgress: TASTProgressEvent;
begin
  Result := fOnProgress;
end;

function TASTProject.GetStopCompileIfError: Boolean;
begin
  Result := fStopIfErrors;
end;

function TASTProject.GetTotalLinesParsed: Integer;
begin
  Result := 0;
end;

function TASTProject.GetTotalUnitsIntfOnlyParsed: Integer;
begin
  Result := 0;
end;

function TASTProject.GetTotalUnitsParsed: Integer;
begin
  Result := 0;
end;

procedure TASTProject.PutMessage(const AMessage: IASTParserMessage);
begin
  // do nothing
end;

procedure TASTProject.PutMessage(const AModule: IASTModule; AMsgType: TCompilerMessageType;
  const AMessage: string; const ATextPostition: TTextPosition; ACritical: Boolean);
begin
  // do nothing
end;

procedure TASTProject.SetName(const Value: string);
begin
  fName := Value;
end;

procedure TASTProject.SetOnConsoleWrite(const Value: TASTProjectConsoleWriteEvent);
begin
  fOnConsoleProc := Value;
end;

procedure TASTProject.SetOnProgress(const Value: TASTProgressEvent);
begin
  fOnProgress := Value;
end;

procedure TASTProject.SetStopCompileIfError(const Value: Boolean);
begin
 fStopIfErrors := Value;
end;

function TASTProject.ToJson: TJsonASTDeclaration;
begin
  Result := nil;
end;

{ TASTIDList }

function TASTIDList.FindID(const AName: string): TASTDeclaration;
var
  LNode: PAVLNode;
begin
  LNode := Find(AName);
  if Assigned(LNode) then
    Result := LNode.Data
  else
    Result := nil;
end;

function TASTIDList.InsertID(ADecl: TASTDeclaration): Boolean;
begin
  Result := InsertNode(ADecl.Name, ADecl) = nil;
end;

function TASTIDList.InsertIDAndReturnIfExist(ADecl: TASTDeclaration): TASTDeclaration;
var
  LNode: PAVLNode;
begin
  LNode := InsertNode(ADecl.Name, ADecl);
  if Assigned(LNode) then
    Result := LNode.Data
  else
    Result := nil;
end;

end.
