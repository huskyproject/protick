Unit PTProcs;
InterFace

Uses
{$IfDef UNIX}
  linux,
{$EndIf}
  DOS, Strings,
  Types, GeneralP, Log,
  TickType, TickCons, PTVar;


Procedure WriteTime;
Function Pack(Packer: Byte; Arc: String; fn: String): Boolean;
Function UnPack(UnPacker: Byte; Arc: String; Dir: String): Boolean;
Procedure ReplaceFiles(FSpec: String);
Function RandName: String8;
Function TicErrorStr(ErrNum: Byte): String;
Procedure GetFileDesc(FName: String; Desc: PChar2);
Procedure SetFileDesc(FName: String; Desc: PChar2);
Procedure SetLongName(Path: DirStr; SName: String12; LName: String40);
Function Match(s1, s2: String): Boolean;
Procedure AddAutoArea(Name: String);
Procedure AddTossArea(Name, BBSArea: String);
Procedure WriteAutoArea;
Procedure WriteTossArea;
Procedure WriteBBSArea;
Procedure DelPT;
Procedure PurgeDupes;
Function GetMsgID : String;

Implementation

Procedure WriteTime;
Var
  Date: TimeTyp;

  Begin
  Now(Date);
  With Date do WriteLn('Time: ', Hour, ':', Min, ':', Sec, '.', Sec100);
  End;

Function RandName: String8;
  Begin
  RandName := WordToHex(word(Random($FFFF)))+WordToHex(word(Random($FFFF)));
  End;

Function UnPack(UnPacker: Byte; Arc: String; Dir: String): Boolean;
Var
  CurUnPacker : TUnPacker;
  i: LongInt;
  UPNum: Byte;
  s: String;
  Error: Integer;
  DidUnpack: Boolean;
  Found: LongInt;

  Begin
  UPNum := 0;
  CurUnPacker.Index := 255;
  DidUnpack := False;
  Found := 0;
  For i := 1 to Cfg^.NumUnPacker do If (Cfg^.UnPacker[i].Index = UnPacker) then
    Begin
    CurUnPacker := Cfg^.UnPacker[i];
    Found := i;
    i := Cfg^.NumUnPacker + 1;
    End;
  If ((Found = 0) and (UnPacker <> 0)) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Unknown UnPacker: #'+IntToStr(UnPacker));
    Exit;
    End;
    Repeat
    If ((UnPacker = 0) and (CurUnPacker.Index <> 0)) then
      Begin
      Inc(UPNum);
      CurUnPacker := Cfg^.UnPacker[UPNum];
      End;
    s := CurUnPacker.Cmd;
    i := Pos('%A', s);
    While (i <> 0) do
      Begin
      Delete(s, i, 2);
      Insert(Arc, s, i);
      i := Pos('%A', s);
      End;
    i := Pos('%s', s);
    While (i <> 0) do
      Begin
      Delete(s, i, 2);
      Insert(Arc, s, i);
      i := Pos('%s', s);
      End;
    i := Pos('%D', s);
    While (i <> 0) do
      Begin
      Delete(s, i, 2);
      Insert(Dir, s, i);
      i := Pos('%D', s);
      End;
    ChDir(Dir);
{$IfDef OS2}
 {$IfDef VIRTUALPASCAL}
    Exec(GetEnv('COMSPEC'), '/C '+s);
    Error := DOSExitCode;
 {$Else}
  {$IfDef FPC}
    Exec(GetEnv('COMSPEC'), '/C '+s);
    Error := DOSExitCode;
  {$Else}
    Error := DOSExitCode(Exec(GetEnv('COMSPEC'), '/C '+s));
  {$EndIf}
 {$EndIf}
{$Else}
 {$IfDef UNIX}
    Shell(s);
    Error := DOSExitCode;
 {$Else}
    SwapVectors;
    Exec(GetEnv('COMSPEC'), '/C '+s);
    Error := DOSExitCode;
    SwapVectors;
 {$EndIf}
{$EndIf}
    WriteLn('Exitcode ', Error);
    DidUnPack := DidUnPack or (Error = 0);
    If (Unpacker <> 0) and (Error > 0) then If (Error = 1) then
     Begin
     LogSetCurLevel(LogHandle, 3);
     LogWriteLn(LogHandle, 'Called "'+s+'"');
     LogWriteLn(LogHandle, 'UnPacker returned warning (errorlevel 1)');
     End
    Else
     Begin
     LogSetCurLevel(LogHandle, 2);
     LogWriteLn(LogHandle, 'Called "'+s+'"');
     LogWriteLn(LogHandle, 'UnPacker returned error (errorlevel '+IntToStr(Error)+')');
     End;
    Until ((UnPacker <> 0) or (CurUnPacker.Index = 0) or (UPNum = Cfg^.NumUnPacker));
  UnPack := DidUnPack;
  End;

Function Pack(Packer: Byte; Arc: String; fn: String): Boolean;
Var
  CurPacker : TPacker;
  i: LongInt;
  s: String;
  s1: String;
  Error: Integer;
  Found: LongInt;

  Begin
  Found := 0;
  For i := 1 to Cfg^.NumPacker do If (Cfg^.Packer[i].Index = Packer) then
    Begin
    CurPacker := Cfg^.Packer[i];
    Found := i;
    End;
  If (Found = 0) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Unknown Packer: #'+IntToStr(Packer));
    Exit;
    End;
  s := CurPacker.Cmd;
  i := Pos('%A', s);
  While (i <> 0) do
    Begin
    Delete(s, i, 2);
    Insert(Arc, s, i);
    i := Pos('%A', s);
    End;
  i := Pos('%F', s);
  While (i <> 0) do
    Begin
    Delete(s, i, 2);
    Insert(fn, s, i);
    i := Pos('%F', s);
    End;
  i := Pos('$a', s);
  While (i <> 0) do
    Begin
    Delete(s, i, 2);
    Insert(Arc, s, i);
    i := Pos('$a', s);
    End;
  i := Pos('$f', s);
  While (i <> 0) do
    Begin
    Delete(s, i, 2);
    Insert(fn, s, i);
    i := Pos('$f', s);
    End;
  i := Pos('%', s);
  While (i <> 0) do
    Begin
    Delete(s, i, 1);
    s1 := Copy(s, i, Pos('%', s) - i);
    Delete(s, i, (Pos('%', s) - i)+1);
    Insert(GetEnv(UpStr(s1)), s, i);
    i := Pos('%', s);
    End;
{$IfDef OS2}
 {$IfDef VIRTUALPASCAL}
  Exec(GetEnv('COMSPEC'), '/C '+s);
  Error := DosExitCode;
 {$Else}
  {$IfDef FPC}
    Exec(GetEnv('COMSPEC'), '/C '+s);
    Error := DOSExitCode;
  {$Else}
  Error := DosExitCode(Exec(GetEnv('COMSPEC'), '/C '+s));
  {$EndIf}
 {$EndIf}
{$Else}
 {$IfDef UNIX}
  Shell(s);
  Error := DOSExitCode;
 {$Else}
  SwapVectors;
  Exec(GetEnv('COMSPEC'), '/C '+s);
  Error := DosExitCode;
  SwapVectors;
 {$EndIf}
{$EndIf}
  If (Error > 0) then If (Error = 1) then
   Begin
   LogSetCurLevel(LogHandle, 3);
   LogWriteLn(LogHandle, 'Called "'+s+'"');
   LogWriteLn(LogHandle, 'Packer returned warning (errorlevel 1)');
   End
  Else
   Begin
   LogSetCurLevel(LogHandle, 2);
   LogWriteLn(LogHandle, 'Called "'+s+'"');
   LogWriteLn(LogHandle, 'Packer returned error (errorlevel '+IntToStr(Error)+')');
   End;
  Pack := (Error < 1);
  End;

Procedure ReplaceFiles(FSpec: String);
Var
{$IfDef SPEED}
  SRec: TSearchRec;
{$Else}
  SRec: SearchRec;
{$EndIf}
  f: File;
  Dir: String;
  Name: String;
  Ext: String;

  Begin
  If (Pos('.', FSpec) = 0) then SRec.Name := FSpec + '.*'
  Else SRec.Name := FSpec;
  FindFirst(FSpec, AnyFile, SRec);
  While (DosError = 0) Do
    Begin
    FSplit(FSpec, Dir, Name, Ext);
    If (CurArea^.MoveTo <> '') then
      Begin
      DelFile(CurArea^.MoveTo + DirSep + SRec.Name);
      If not MoveFile(Dir + SRec.Name, CurArea^.MoveTo + DirSep + SRec.Name) then
        Begin
        LogSetCurLevel(LogHandle, 1);
        LogWriteLn(LogHandle, 'Couldn''t move "'+Dir + SRec.Name+'" to "'+CurArea^.MoveTo + DirSep+ SRec.Name +'"!');
        End;
      End
    Else
      Begin
      If not DelFile(Dir + SRec.Name) then
        Begin
        LogSetCurLevel(LogHandle, 1);
        LogWriteLn(LogHandle, 'Couldn''t delete "'+Dir + SRec.Name+'"!');
        End;
      End;
    FindNext(SRec);
    End;
{$IfDef OS2}
  FindClose(SRec);
{$EndIf}
  End;

Function TicErrorStr(ErrNum: Byte): String;
  Begin
  Case ErrNum of
    bt_NoFile: TicErrorStr := 'File locked or not in InBound';
    bt_CRC: TicErrorStr := 'CRC-Error';
    bt_UnKnownArea: TicErrorStr := 'Unknown area';
    bt_NotConnected: TicErrorStr := 'Sender not connected to area';
    bt_NoSend: TicErrorStr := 'Sender not SEND-connected to area';
    bt_WrongPwd: TicErrorStr := 'Wrong password';
    bt_CouldntMove: TicErrorStr := 'Couldn''t move file';
    bt_Dupe: TicErrorStr := 'Dupe';
    bt_NotForUs: TicErrorStr := 'Not for us';
    bt_Unlisted: TicErrorStr := 'Unlisted sender';
    Else TicErrorStr := 'Unknown error';
    End;
  End;

Procedure GetFileDesc(FName: String; Desc: PChar2);
Var
  s: String;
  f: Text;
  Dir, Name, Ext: String;
  ppos: word;
  i: word;

  Begin
  PPos := 0;
  Desc^[0] := #0;
  FSplit(FName, Dir, Name, Ext);
{$IfNDef UNIX}
  Name := UpStr(Name);
  Ext := UpStr(Ext);
{$EndIf}
  Assign(f, Dir + 'files.bbs');
  {$I-} ReSet(f); {$I+}
  If (IOResult = 0) then
    Begin
    While (not EOF(f)) do
      Begin
      ReadLn(f, s);
      If (s[Byte(s[0])] = #13) then s[0] := Char(Byte(s[0])-1);
{$IfDef UNIX}
      If (Pos(Name+Ext, s) = 1) then Break;
{$Else}
      If (Pos(Name+Ext, UpStr(s)) = 1) then Break;
{$EndIf}
      End;
{$IfDef UNIX}
    If (Pos(Name+Ext, s) = 1) then
{$Else}
    If (Pos(Name+Ext, UpStr(s)) = 1) then
{$EndIf}
      Begin
      Delete(s, 1, Length(Name)+Length(Ext));
      s := KillSpcs(s);
      If ((s[1] = '[') and (s[2] in Digits)) then
       Begin
       While (s[1] <> ']') do Delete(s, 1, 1);
       Delete(s, 1, 1);
       End;
      s := KillSpcs(s);
      For i := 1 to Byte(s[0]) do Desc^[PPos + i - 1] := s[i];
      PPos := Byte(s[0]) + 3;
      Desc^[PPos-2] := #13;
      Desc^[PPos-1] := #10;
      While (not EOF(f)) do
        Begin
        ReadLn(f, s);
        If (s[Byte(s[0])] = #13) then s[0] := Char(Byte(s[0])-1);
        If (s[2] = ' ') then
          Begin
          KillLeadingSpcs(s);
          For i := 1 to Byte(s[0]) do Desc^[PPos + i - 1] := s[i];
          PPos := Byte(s[0]) + 3;
          Desc^[PPos-2] := #13;
          Desc^[PPos-1] := #10;
          End
        Else Break;
        End;
      Desc^[PPos] := #0;
      End;
    {$I-} Close(f); {$I+}
    If (IOResult <> 0) then
     Begin
     LogSetCurLevel(LogHandle, 1);
     LogWriteLn(LogHandle, 'Couldn''t close "'+Dir+'files.bbs"!');
     End;
    End;
  End;

Procedure SetFileDesc(FName: String; Desc: PChar2);
Var
 FilesBBS: Text;
 FilesTMP: Text;
 Dir: DirStr;
 Name: NameStr;
 Ext: ExtStr;
 Error: Integer;
 NewFilesBBS: Boolean;
 Line: String;
 FoundOldDesc: Boolean;
 i: Byte;
 CRLF: PChar2;
 FirstLine: Boolean;
 CurDesc: PChar2;
 CRLFPos: Pointer;

 Begin
 {init vars}
 FoundOldDesc := False;

 {get names of files.bbs and files.tmp, open them}
 FSplit(FName, Dir, Name, Ext);
{$IfNDef UNIX}
 Name := UpStr(Name) + UpStr(Ext);
{$Else}
 Name := Name + Ext;
{$EndIf}
 Assign(FilesBBS, Dir + 'files.bbs');
 Assign(FilesTMP, Dir + 'files.tmp');
 {$I-} ReSet(FilesBBS); {$I+}
 NewFilesBBS := (IOResult <> 0);
 {$I-} ReWrite(FilesTMP); {$I+}
 Error := IOResult;
 If (Error <> 0) then
  Begin
  LogSetCurLevel(LogHandle, 1);
  LogWriteLn(LogHandle, 'Could not open "'+Dir+'files.tmp" for writing!');
  If (not NewFilesBBS) then Close(FilesBBS);
  Exit;
  End;

 {if files.bbs existed, copy it to files.tmp and look for the filename}
 If not NewFilesBBS then
  Begin
  While not EOF(FilesBBS) do
   Begin
   ReadLn(FilesBBS, Line);
   {filenames begin at first char of line}
{$IfDef UNIX}
   If (Pos(Name, Line) = 1) then
{$Else}
   If (Pos(Name, UpStr(Line)) = 1) then
{$EndIf}
    Begin
    FoundOldDesc := True;
    {skip old description}
    If (not EOF(FilesBBS)) then ReadLn(FilesBBS, Line)
    Else Line := '';
    While (Line[2] = ' ') and (not EOF(FilesBBS)) do
     Begin
     ReadLn(FilesBBS, Line);
     {descriptions have a space at the second char of line}
     End;
    If (Line[2] = ' ') then Line := '';
    Break;
    End;
   WriteLn(FilesTMP, Line);
   End;
  End;

 {write (new) entry}
 Write(FilesTMP, Name+' ');
 {add DownLoadCounter}
 If (Cfg^.AddDLC) then
  Begin
  Write(FilesTMP, '['+Copy('0000000000', 1, Cfg^.DLCDig)+'] ');
  End;
 {write description}
 If (Desc <> NIL) and (Desc^[0] > #0) then
  Begin
  GetMem(CRLF, 3); CRLF^[0] := #13; CRLF^[1] := #10; CRLF^[2] := #0;
  FirstLine := True;
  CurDesc := Desc;

  While (StrPos(Pointer(CurDesc), Pointer(CRLF)) <> NIL) do
   Begin
   CRLFPos := StrPos(Pointer(CurDesc), Pointer(CRLF));
   If FirstLine then
    Begin
    FirstLine := False;

    While (CurDesc <> CRLFPos) do
     Begin
     Write(filesTMP, CurDesc^[0]);
     CurDesc := @CurDesc^[1];
     End;
    If not Cfg^.SingleDescLine then WriteLn(FilesTMP);
    End
   Else
    Begin
    {add LongDescChar + Spaces}
    If not Cfg^.SingleDescLine then
     Begin
     Write(FilesTMP, Cfg^.LDescString);
     If (Cfg^.DescPos > 2) then Write(FilesTMP, Copy(Leer, 1, Cfg^.DescPos-1));
     End
    Else Write(FilesTMP, ' ');

    While (CurDesc <> CRLFPos) do
     Begin
     Write(filesTMP, CurDesc^[0]);
     CurDesc := @CurDesc^[1];
     End;
    If not Cfg^.SingleDescLine then WriteLn(FilesTMP);
    End;
   CurDesc := @CurDesc^[2]; {skip CR/LF}
   End;

  {add last line}
  If (CurDesc^[0] <> #0) then
   Begin
   If FirstLine then
    Begin
    FirstLine := False;

    While (CurDesc^[0] <> #0) do
     Begin
     Write(filesTMP, CurDesc^[0]);
     CurDesc := @CurDesc^[1];
     End;
    If not Cfg^.SingleDescLine then WriteLn(FilesTMP);
    End
   Else
    Begin
    {add LongDescChar + Spaces}
    If not Cfg^.SingleDescLine then
     Begin
     Write(FilesTMP, Cfg^.LDescString);
     If (Cfg^.DescPos > 2) then Write(FilesTMP, Copy(Leer, 1, Cfg^.DescPos-1));
     End
    Else Write(FilesTMP, ' ');

    While (CurDesc^[0] <> #0) do
     Begin
     Write(filesTMP, CurDesc^[0]);
     CurDesc := @CurDesc^[1];
     End;
    If not Cfg^.SingleDescLine then WriteLn(FilesTMP);
    End;
   End;

  FreeMem(CRLF, 3);
  End
 Else
  Begin
  WriteLn(FilesTMP, '<no description available>');
  End;

 {copy remaining entries of files.bbs if any}
 If (not NewFilesBBS) and (FoundOldDesc) then
  Begin
  {check if EOF occured while skipping old description}
  If (Line <> '') then
   Begin
   WriteLn(FilesTMP, Line);

   While not EOF(FilesBBS) do
    Begin
    ReadLn(FilesBBS, Line);
    WriteLn(FilesTMP, Line);
    End;
   End;
  End;

 {close files, replace files.bbs by files.tmp}
 If not NewFilesBBS then Close(FilesBBS);
 Close(FilesTMP);
{$IfDef UNIX}
 ChMod(Dir+'files.tmp', FilePerm);
{$EndIf}
 If not RepFile(Dir+'files.tmp', Dir+'files.bbs') then
  Begin
  LogSetCurLevel(LogHandle, 1);
  LogWriteLn(LogHandle, 'Couldn''t replace "'+Dir+'files.bbs"!');
  End;
 End;


Procedure SetLongName(Path: DirStr; SName: String12; LName: String40);
Var
 f1, f2: Text;
 Found: Boolean;
 s, SNameU: String;

 Begin
{$IfNDef UNIX}
 SNameU := UpStr(SName);
{$EndIf}
 Found := False;
 Assign(f1, Path+DirSep+'files.lng');
 Assign(f2, Path+DirSep+'files.tmp');
 {$I-} ReWrite(f2); {$I+}
 If (IOResult <> 0) then
  Begin
  LogSetCurLevel(LogHandle, 1);
  LogWriteLn(LogHandle, 'Could not open "'+Path+DirSep+'files.tmp"!');
  Exit;
  End;
 {$I-} ReSet(f1); {$I+}
 If (IOResult = 0) then {copy file}
  Begin
  While not EOF(f1) do
   Begin
   ReadLn(f1, s);
   If (s[Byte(s[0])] = #13) then s[0] := Char(Byte(s[0])-1);
{$IfDef UNIX}
   If (copy(s, 1, Pos(' ', s)-1) = SName) then {replace entry}
{$Else}
   If (UpStr(copy(s, 1, Pos(' ', s)-1)) = SNameU) then {replace entry}
{$EndIf}
    Begin
    Found := True;
{$IfDef UNIX}
    WriteLn(f2, SName + ' ' + LName);
{$Else}
    WriteLn(f2, SNameU + ' ' + LName);
{$EndIf}
    End
   Else WriteLn(f2, s);
   End;
  {$I-} Close(f1); {$I+}
  If (IOResult <> 0) then
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Could not close "'+Path+DirSep+'files.lng"!');
   End;
  {$I-} Erase(f1); {$I+}
  If (IOResult <> 0) then
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Could not delete "'+Path+DirSep+'files.lng"!');
   End;
  End;
{$IfDef UNIX}
 If not Found then WriteLn(f2, SName + ' ' + LName); {append entry}
{$Else}
 If not Found then WriteLn(f2, SNameU + ' ' + LName); {append entry}
{$EndIf}
 {$I-} Close(f2); {$I+}
 If (IOResult <> 0) then
  Begin
  LogSetCurLevel(LogHandle, 1);
  LogWriteLn(LogHandle, 'Could not close "'+Path+DirSep+'files.tmp"!');
  End
 Else
  Begin
{$IfDef UNIX}
  ChMod(Path+DirSep+'files.tmp', FilePerm);
{$EndIf}
  End;
 {$I-} Rename(f2, Path+DirSep+'files.lng'); {$I+}
 If (IOResult <> 0) then
  Begin
  LogSetCurLevel(LogHandle, 1);
  LogWriteLn(LogHandle, 'Could not rename "'+Path+DirSep+'files.tmp" to "'+Path+DirSep+'files.lng"!');
  End;
 End;

Function Match(s1, s2: String): Boolean;
Var
  i: Byte;

  Begin
  If (s2 = '') or (s1 = '') then
    Begin
    Match := False;
    Exit;
    End;
  If (Pos('*', s2) = 0) and (Pos('?', s2) = 0) then Match := (s1 = s2)
  Else
    Begin
    For i := 1 to Length(s2) do
      Begin
      If (s2[i] = '*') then
        Begin
        Match := True;
        Exit;
        End
      Else If (s2[i] = '?') then Continue
      Else If (s1[i] <> s2[i]) then
        Begin
        Match := False;
        Exit;
        End;
      End;
    Match := True;
    End;
  End;

Procedure WriteAutoArea;
Var
  f: Text;

  Begin
  If (AutoAddList = NIL) then exit;
  If (Cfg^.NewAreasLst = '') then exit;
  WriteLn('writing newareas.pt');
  Assign(f, Cfg^.NewAreasLst);
  {$I-} Append(f); {$I+}
  If (IOResult <> 0) then
    Begin
    Assign(f, Cfg^.NewAreasLst);
    {$I-} ReWrite(f); {$I+}
    If (IOResult <> 0) then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Couldn''t open "'+ Cfg^.NewAreasLst+'"!');
      Exit;
      End;
    End;
  CurAutoAddList := AutoAddList;
  While (CurAutoAddList <> NIL) do
    Begin
    WriteLn(f, CurAutoAddList^.Name);
    CurAutoAddList := CurAutoAddList^.Next;
    End;
  Close(f);
  If (IOResult <> 0) then
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Couldn''t close "'+ Cfg^.NewAreasLst+'"!');
   End
  Else
   Begin
{$IfDef UNIX}
   ChMod(Cfg^.NewAreasLst, FilePerm);
{$EndIf}
   End;
  End;

Procedure WriteTossArea;
Var
  f: Text;
  Error1, Error2: Integer;

  Begin
  If (TossList = NIL) then exit;
  If (Cfg^.AreasLog = '') then exit;
  Assign(f, Cfg^.AreasLog);
  {$I-} Append(f); {$I+}
  Error1 := IOResult;
  If (Error1 <> 0) then
    Begin
    Assign(f, Cfg^.AreasLog);
    {$I-} ReWrite(f); {$I+}
    Error2 := IOResult;
    If (Error2 <> 0) then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Couldn''t open '+ Cfg^.AreasLog +
      ': Error '+IntToStr(Error1)+', '+IntToStr(Error2)+'!');
      Exit;
      End;
    End;
  CurTossList := TossList;
  While (CurTossList <> NIL) do
    Begin
    WriteLn(f, CurTossList^.Name);
    CurTossList := CurTossList^.Next;
    End;
  Close(f);
  If (IOResult <> 0) then
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Couldn''t close '+ Cfg^.AreasLog+ '!');
   End
  Else
   Begin
{$IfDef UNIX}
   ChMod(Cfg^.AreasLog, FilePerm);
{$EndIf}
   End;
  End;

Procedure WriteBBSArea;
Var
  f: Text;
  Error1, Error2: Integer;

  Begin
  If (TossList = NIL) then exit;
  If (Cfg^.BBSAreaLog = '') then exit;
  Assign(f, Cfg^.BBSAreaLog);
  {$I-} Append(f); {$I+}
  Error1 := IOResult;
  If (Error1 <> 0) then
    Begin
    Assign(f, Cfg^.BBSAreaLog);
    {$I-} ReWrite(f); {$I+}
    Error2 := IOResult;
    If (Error2 <> 0) then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Couldn''t open '+ Cfg^.BBSAreaLog +
        ': Error '+IntToStr(Error1)+', '+IntToStr(Error2)+'!');
      Exit;
      End;
    End;
  CurTossList := TossList;
  While (CurTossList <> NIL) do
    Begin
    If (CurTossList^.BBSArea = '') then WriteLn(f, CurTossList^.Name)
    Else WriteLn(f, CurTossList^.BBSArea);
    CurTossList := CurTossList^.Next;
    End;
  Close(f);
  If (IOResult <> 0) then
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Couldn''t close '+ Cfg^.BBSAreaLog + '!');
   End
  Else
   Begin
{$IfDef UNIX}
   ChMod(Cfg^.BBSAreaLog, FilePerm);
{$EndIf}
   End;
  End;

Procedure AddAutoArea(Name: String);
  Begin
  If (AutoAddList = NIL) then
    Begin
    New(AutoAddList);
    CurAutoAddList := AutoAddList;
    CurAutoAddList^.Next := NIL;
    CurAutoAddList^.Prev := NIL;
    CurAutoAddList^.Name := Name;
    End
  Else
    Begin
    CurAutoAddList := AutoAddList;
      Repeat
      If CurAutoAddList^.Name = Name then Break;
      If CurAutoAddList^.Next <> NIL then CurAutoAddList := CurAutoAddList^.Next
      Else Break;
      Until False;
    If (CurAutoAddList^.Name <> Name) then
      Begin
      New(CurAutoAddList^.Next);
      CurAutoAddList^.Next^.Prev := CurAutoAddList;
      CurAutoAddList := CurAutoAddList^.Next;
      CurAutoAddList^.Next := NIL;
      CurAutoAddList^.Name := Name;
      End;
    End;
  End;

Procedure AddTossArea(Name, BBSArea: String);
  Begin
  If (TossList = NIL) then
    Begin
    New(TossList);
    CurTossList := TossList;
    CurTossList^.Next := NIL;
    CurTossList^.Prev := NIL;
    CurTossList^.Name := Name;
    CurTossList^.BBSArea := BBSArea;
    End
  Else
    Begin
    CurTossList := TossList;
      Repeat
      If CurTossList^.Name = Name then Break;
      If CurTossList^.Next <> NIL then CurTossList := CurTossList^.Next
      Else Break;
      Until False;
    If (CurTossList^.Name <> Name) then
      Begin
      New(CurTossList^.Next);
      CurTossList^.Next^.Prev := CurTossList;
      CurTossList := CurTossList^.Next;
      CurTossList^.Next := NIL;
      CurTossList^.Name := Name;
      CurTossList^.BBSArea := BBSArea;
      End;
    End;
  End;

Procedure DelAll(Dir: String);
Var
 f: File;
{$IfDef SPEED}
 SRec: TSearchRec;
{$Else}
 SRec: SearchRec;
{$EndIf}

 Begin
{$IfDef VER70}
 FindFirst(Dir + DirSep + '*.*', AnyFile - Directory, SRec);
{$Else}
 FindFirst(Dir + DirSep + '*', AnyFile - Directory, SRec);
{$EndIf}
 While (DOSError = 0) do
  Begin
  WriteLn('deleting "'+Dir+DirSep+SRec.Name+'"');
  Assign(f, Dir+DirSep+SRec.Name);
  {$I-} Erase(f); {$I+}
  If (IOResult <> 0) then
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Could not delete "'+Dir+DirSep+SRec.Name+'"!');
   End;
  FindNext(SRec);
  End;
{$IfDef OS2}
 FindClose(SRec);
{$EndIf}
 End;

Procedure DelPT;
Var
 f: File;
 Error: Integer;
 DoEnd: Boolean;
 PTC, PTCC: PPTList;
{$IfDef SPEED}
 SRec: TSearchRec;
{$Else}
 SRec: SearchRec;
{$EndIf}

  Procedure ReadList;
    Begin
    New(PTC);
    PTCC := PTC;
    PTCC^.Prev := NIL;
    PTCC^.Next := NIL;
    Read(PTList, PTCC^.a);
    While not EOF(PTList) Do
      Begin
      New(PTCC^.Next);
      PTCC^.Next^.Prev := PTCC;
      PTCC := PTCC^.Next;
      PTCC^.Next := NIL;
      Read(PTList, PTCC^.a);
      End;
    {$I-} Close(PTList); {$I+}
    If (IOResult <> 0) then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Couldn''t close PTList!');
      End;
    End;

  Procedure Sort; {Bubblesort}
  Var
    Swapped: Boolean;

    Procedure Swap(var a, b: TPTListEntry);
    Var
      c: TPTListEntry;

      Begin
      c := a;
      a := b;
      b := c;
      End;

    Begin
      Repeat
      PTCC := PTC;
      Swapped := False;
      While (PTCC^.Next <> NIL) do With PTCC^ do
        Begin
        If a.FileName > PTCC^.Next^.a.FileName then
          Begin
          Swap(PTCC^.a, PTCC^.Next^.a);
          Swapped := True;
          End;
        PTCC := PTCC^.Next;
        End;
      Until not Swapped;
    End;

  Procedure DispList;
    Begin
    If PTC = NIL then Exit;
    PTCC := PTC;
      Repeat
      If PTCC^.Next <> Nil then PTCC := PTCC^.Next
      Else If PTCC^.Prev <> Nil then
        Begin
        PTCC := PTCC^.Prev;
        Dispose(PTCC^.Next);
        PTCC^.Next := Nil;
        End;
      Until (PTCC = PTC);
    Dispose(PTC);
    PTC := NIL;
    PTCC := NIL;
    End;

 Function Search(fn: String):Boolean;
 Var
  p: Pointer;
  a1: TNetAddr;

  Begin
  Search := False;
  PTCC := PTC;
  While (PTCC <> NIL) and (PTCC^.Next <> NIL) do
   Begin
{$IfDef UNIX}
   If (PTCC^.a.FileName = fn) then
{$Else}
   If (UpStr(PTCC^.a.FileName) = UpStr(fn)) then
{$EndIf}
    Begin
    If (PTCC^.a.TICName[1] = '!') then
     Begin
     CurUser := Cfg^.Users;
     Str2Addr(Copy(PTCC^.a.TICName, 2, Length(PTCC^.a.TICName)-1), a1);
     While ((CurUser^.Next <> NIL) and (not CompAddr(CurUser^.Addr, a1))) do
      CurUser := CurUser^.Next;
     If (not CompAddr(CurUser^.Addr, a1)) then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Could not find user with address "'+
       Copy(PTCC^.a.TICName, 2, Length(PTCC^.a.TICName)-1)+'" used in PTList!');
      PTCC := PTCC^.Next;
      Continue;
      End;
     If not Outbound^.CheckFileSent(CurUser, fn) then
      Begin
      Search := True;
      Exit;
      End
     Else
      Begin
      If (PTCC^.Prev <> NIL) then
       Begin
       PTCC^.Prev^.Next := PTCC^.Next;
       If (PTCC^.Next <> NIL) then PTCC^.Next^.Prev := PTCC^.Prev;
       End
      Else
       Begin
       PTC := PTCC^.Next;
       If (PTCC^.Next <> NIL) then PTCC^.Next^.Prev := NIL;
       End;
      Dispose(PTCC);
      PTCC := PTCC^.Next;
      End;
     End
    Else
     Begin
     If FileExist(PTCC^.a.TICName) then
      Begin
      Search := True;
      Exit;
      End
     Else
      Begin
      If (PTCC^.Prev <> NIL) then
       Begin
       PTCC^.Prev^.Next := PTCC^.Next;
       If (PTCC^.Next <> NIL) then PTCC^.Next^.Prev := PTCC^.Prev;
       End
      Else
       Begin
       PTC := PTCC^.Next;
       If (PTCC^.Next <> NIL) then PTCC^.Next^.Prev := NIL;
       End;
      Dispose(PTCC);
      PTCC := PTCC^.Next;
      End;
     End
    End
   Else PTCC := PTCC^.Next;
   End;
  End;

 Procedure WriteList;
  Begin
  Assign(PTList, Cfg^.PTLst);
  {$I-} ReWrite(PTList); {$I+}
  If (IOResult <> 0) then
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Could not open "'+Cfg^.PTLst+'"!');
   Exit;
   End;
  If (PTCC <> NIL) then
   Begin
   While (PTCC^.Next <> NIL) do
    Begin
    Write(PTList, PTCC^.a);
    PTCC := PTCC^.Next;
    End;
   Write(PTList, PTCC^.a);
   End;
  {$I-} Close(PTList); {$I+}
  If (IOResult <> 0) then
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Could not close "'+Cfg^.PTLst+'"!');
   Exit;
   End;
{$IfDef UNIX}
  ChMod(Cfg^.PTLst, FilePerm);
{$EndIf}
  PTCC := PTC;
  End;


 Begin
 If (Cfg^.PT = '') then
  Begin
  LogSetCurLevel(LogHandle, 3);
  LogWriteLn(LogHandle, 'No passthrough path set, won''t delete passthrough files');
  Exit;
  End;
 Assign(PTList, Cfg^.PTLst);
 {$I-} ReSet(PTList); {$I+}
 If (IOResult <> 0) or EOF(PTList) then
  Begin
  DelAll(Cfg^.PT);
  Exit;
  End;
 ReadList;
 Sort;
 {search for files to be deleted}
{$IfDef VER70}
 FindFirst(Cfg^.PT+DirSep+'*.*', AnyFile-Directory-VolumeID, SRec);
{$Else}
 FindFirst(Cfg^.PT+DirSep+'*', AnyFile-Directory-VolumeID, SRec);
{$EndIf}
 While (DOSError = 0) do
  Begin
  If not Search(SRec.Name) then
   Begin
   Assign(f, Cfg^.PT+DirSep+SRec.Name);
   WriteLn('deleting "'+Cfg^.PT+DirSep+SRec.Name+'"');
   {$I-} Erase(f); {$I+}
   If (IOResult <> 0) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Could not delete "'+Cfg^.PT+DirSep+SRec.Name+'"!');
    End;
   End;
  FindNext(SRec);
  End;
{$IfDef OS2}
 FindClose(SRec);
{$EndIf}
 WriteList;
 DispList;
 End;

Procedure PurgeDupes;
Var
  f1,f2: File of TDupeEntry;
  CurEntry: TDupeEntry;
  i: LongInt;
  DidPurge: Boolean;
  MaxDate: LongInt;
  DT: TimeTyp;
  TmpName: String;

  Begin
  Assign(f1, Cfg^.DupeFile);
  TmpName := Cfg^.DupeFile;
  TmpName[Byte(TmpName[0])] := '$';
  Assign(f2, TmpName);
  {$I-} ReSet(f1); {$I+}
  If (IOResult <> 0) then Exit;
  {$I-} ReWrite(f2); {$I+}
  If (IOResult <> 0) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Error opening "'+TmpName+'"!');
    Close(f1);
    Exit;
    End;
  DidPurge := False;
  Today(DT); Now(DT);
  MaxDate := DTToUnixDate(DT) + (Cfg^.MaxDupeAge * 86400);
  While not EOF(f1) do
    Begin
    Read(f1, CurEntry);
    If (CurEntry.Date < MaxDate) then Write(f2, CurEntry)
    Else DidPurge := True;
    End;
  If DidPurge then
    Begin
    LogSetCurLevel(LogHandle, 3);
    LogWriteLn(LogHandle, 'Purged DupeBase');
    End;
  {$I-} Close(f1); {$I+}
  If (IOResult <> 0) then
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Couldn''t close "'+Cfg^.DupeFile+'"!');
   End;
  {$I-} Close(f2); {$I+}
  If (IOResult <> 0) then
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Couldn''t close "'+TmpName+'"!');
   End
  Else
   Begin
{$IfDef UNIX}
   ChMod(TmpName, FilePerm);
{$EndIf}
   End;
  {$I-} Erase(f1); {$I+}
  If (IOResult <> 0) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Couldn''t delete "'+Cfg^.DupeFile+'"!');
    End;
  {$I-} Rename(f2, Cfg^.DupeFile); {$I+}
  If (IOResult <> 0) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Couldn''t rename "'+TmpName+
     '" to "'+Cfg^.DupeFile+'"!');
    End;
 End;


Function GetMsgID : String;
Var
 MsgIDFile: Text;
 CurMsgID: ULong;
 Dir: String;
 s: String;
{$IfDef VIRTUALPASCAL}
 Error: LongInt;
{$Else}
 Error: Integer;
{$EndIf}

 begin
 Assign(MsgIDFile, Cfg^.MsgIDFile);
 {$I-} ReSet(MsgIDFile); {$I+}
 If (IOResult = 0) then
  begin
  ReadLn(MsgIDFile, s);
  While (s[Byte(s[0])] = #10) or (s[Byte(s[0])] = #13) do Dec(s[0]);
  Val(s, CurMsgID, Error);
  If (Error <> 0) or (CurMsgID = 0) then CurMsgID := 1;
  Close(MsgIDFile);
  end
 Else CurMsgID := 1; {Reset MsgID if no MSGID.DAT is found}
 GetMsgID := WordToHex(word(CurMsgID SHR 16)) + WordToHex(word(CurMsgID));
 Inc(CurMsgID);
 {$I-} ReWrite(MsgIDFile); {$I+}
 If (IOResult = 0) then
  Begin
  Write(MsgIDFile, CurMsgID, #13#10);
  Close(MsgIDFile);
{$IfDef UNIX}
  ChMod(Cfg^.MsgIDFile, FilePerm);
{$EndIf}
  End;
 end;


Begin
End.

