Unit NLS;

Interface

{
- National Language Support
- formats like "argument 1: %1, argument 3: %3, argument 2: %2\n"
}

Type
{private}
 PNLS_Msg = ^TNLS_Msg;
 TNLS_Msg =
  record
  Next: PNLS_Msg;
  MsgNum: Word;
  MsgStr: PChar;
  End;

 {public}
 PNLS_Args = ^TNLS_Args;
 TNLS_Args =
  record
  Next: PNLS_Args;
  Arg: PChar;
  End;

 PNLS = ^TNLS;
 TNLS =
  object
  Constructor Init(Language: String; LangPath: String);
  Destructor Done;

  Function GetMsg(Args: PNLS_Args; MsgNum: Word);

  Private
  Msgs: PNLS_Msg;

  Debug: Boolean;
  End;

Const
{$IfDef Linux}
 DirSep = '/';
{$Else}
 DirSep = '\';
{$EndIf}

Implementation

Constructor TNLS.Init(Language: String; LangPath: String);
Var
 F: Text;
 FName: String;

 Begin
 Debug := False;
 If (LangPath[Length(LangPath)] = DirSep) then FName := LangPath
 Else FName := LangPath + DirSep;
 FName := FName + 'pt_'+Language+'.nls';
 
 If (Debug) then WriteLn('Reading NLS database "'+FName+'"');
 End;

Begin
End.

