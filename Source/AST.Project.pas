unit AST.Project;

interface

uses AST.Parser.ProcessStatuses;

type

  IASTModule = interface
    ['{1E3A5748-1671-41E8-BAAD-4BBB2B363BF4}']
    function GetModuleName: string;
    property Name: string read GetModuleName;
  end;

  TASTProgressEvent = reference to procedure (const Module: IASTModule; Status: TASTProcessStatusClass);

  IASTProject = interface
    ['{AE77D75A-4F7F-445B-ADF9-47CF5C2F0A14}']
    procedure SetOnProgress(const Value: TASTProgressEvent);
    function GetOnProgress: TASTProgressEvent;
    property OnProgress: TASTProgressEvent read GetOnProgress write SetOnProgress;
  end;

implementation

end.
