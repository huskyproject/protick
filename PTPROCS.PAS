Unit PTProcs;
InterFace

Uses
{$IfDef Linux}
  Linux,
{$EndIf}
  DOS, Strings,
  Types, GeneralP, Log,
  TickType, TickCons, PTVar;


Procedure WriteTime;
Function Pack(Packer: Byte; Arc: String; fn: String): Boolean;
Function UnPack(UnPacker: Byte; Arc: String; Dir: String): Boolean;
Procedure ReplaceFiles(FSpec: String);
{Function FloName(Usr: PUser): DirStr;}
{Procedure SendFile(usr: PUser; fn: String; Act: Byte);}
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
{Procedure DelPacked(Dir: String);}
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
  RandName := WordToHex(Random($FFFF))+WordToHex(Random($FFFF));
  End;

(*
Function FloName(Usr: PUser): DirStr;
Var
 s, s1: String;
 FlowName: String;
 Dir: String;
 Addr: TNetAddr;
 i: Byte;

 Begin
 If CompAddr(Usr^.ArcAddr, EmptyAddr) then Addr := Usr^.Addr Else Addr := Usr^.ArcAddr;
 If ((Addr.Domain = Cfg^.Addrs[1].Domain) or (Addr.Domain = '') or (Cfg^.Addrs[1].Domain = '')) then
   Begin
   If (Addr.Zone <> Cfg^.Addrs[1].Zone) then FlowName := Cfg^.OutBound + '.'+Copy(WordToHex(Addr.Zone), 2, 3)+DirSep
   Else FlowName := Cfg^.OutBound + DirSep;
   End
 Else
   Begin
   s := Cfg^.OutBound;
   While (s[Length(s)] <> DirSep) do Delete(s, Length(s), 1);
   s1 := Addr.Domain;
   If (Cfg^.NumDomains > 0) then
    Begin
    For i := 1 to Cfg^.NumDomains do
     If (UpStr(Addr.Domain) = UpStr(Cfg^.Domains[i].Domain)) then
      s1 := Cfg^.Domains[i].Abbrev;
    End;
   FlowName := s + s1 + '.'+Copy(WordToHex(Addr.Zone), 2, 3)+DirSep;
   End;
 Dir := Copy(FlowName, 1, Length(FlowName) - 1);
 FlowName := FlowName + WordToHex(Addr.Net) + WordToHex(Addr.Node);
 If (Addr.Point <> 0) then
   Begin
   Dir := FlowName + '.pnt';
   FlowName := FlowName + '.pnt'+DirSep+'0000' + WordToHex(Addr.Point);
   End;
 Case Usr^.MailFlags of
   ml_Normal : FlowName := FlowName + '.flo';
   ml_Direct : FlowName := FlowName + '.dlo';
   ml_Hold : FlowName := FlowName + '.hlo';
   ml_Crash : FlowName := FlowName + '.clo';
   end;
 If not DirExist(Dir) then If not MakeDir(Dir) then
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Couldn''t create directory "'+Dir+'"!');
   End
 Else
   Begin
   LogSetCurLevel(LogHandle, 2);
   LogWriteLn(LogHandle, 'Created directory "'+Dir+'"');
   End;
 FloName := FlowName;
 End;

Procedure SendFile(usr: PUser; fn: String; Act: Byte);
Var
  f: Text;
  FlowName : String;
  Error1, Error2: Integer;

  Begin
  FlowName := FloName(Usr);
  Assign(f, FlowName);
  {$I-} Append(f); {$I+}
  Error1 := IOResult;
  If (Error1 <> 0) then
    Begin
    Assign(f, FlowName);
    {$I-} ReWrite(f); {$I+}
    Error2 := IOResult;
    If (Error2 <> 0) then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Couldn''t open "'+FlowName+'": Error '+
       IntToStr(Error1)+', '+IntToStr(Error2)+'!');
      Exit;
      End;
    End;
  {$I-}
  Case Act of
    ac_Nothing : WriteLn(f, fn);
    ac_Del     : WriteLn(f, '^'+fn);
    ac_Trunc   : WriteLn(f, '#'+fn);
    else
      WriteLn(f, fn);
    end;
  If (IOResult <> 0) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Error writing "'+FlowName+'"!');
    End;
  Close(f); {$I+}
  If (IOResult <> 0) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Couldn''t close "'+FlowName+'"!');
    End;
  End;
*)

Function UnPack(UnPacker: Byte; Arc: String; Dir: String): Boolean;
Var
  CurUnPacker : TUnPacker;
  i: LongInt;
  UPNum: Byte;
  s: String;
  Error: Integer;
  DidUnpack: Boolean;

  Begin
  UPNum := 0;
  CurUnPacker.Index := 255;
  DidUnpack := False;
  For i := 1 to Cfg^.NumUnPacker do If (Cfg^.UnPacker[i].Index = UnPacker) then
    Begin
    CurUnPacker := Cfg^.UnPacker[i];
    i := Cfg^.NumUnPacker + 1;
    End;
  If ((i <= Cfg^.NumUnPacker) and (UnPacker <> 0)) then
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
    i := Pos('%D', s);
    While (i <> 0) do
      Begin
      Delete(s, i, 2);
      Insert(Dir, s, i);
      i := Pos('%D', s);
      End;
{$IfDef OS2}
 {$IfDef VIRTUALPASCAL}
    Exec(GetEnv('COMSPEC'), '/C '+s);
    Error := DOSExitCode;
 {$Else}
    Error := DOSExitCode(Exec(GetEnv('COMSPEC'), '/C '+s));
 {$EndIF}
{$Else}
 {$IfDef Linux}
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

  Begin
  For i := 1 to Cfg^.NumPacker do If (Cfg^.Packer[i].Index = Packer) then
    Begin
    CurPacker := Cfg^.Packer[i];
    i := Cfg^.NumPacker + 1;
    End;
  If (i <= Cfg^.NumPacker) then
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
  Error := DosExitCode(Exec(GetEnv('COMSPEC'), '/C '+s));
 {$EndIf}
{$Else}
 {$IfDef Linux}
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
{$IfNDef Linux}
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
{$IfDef Linux}
      If (Pos(Name+Ext, s) = 1) then Break;
{$Else}
      If (Pos(Name+Ext, UpStr(s)) = 1) then Break;
{$EndIf}
      End;
{$IfDef Linux}
    If (Pos(Name+Ext, s) = 1) then
{$Else}
    If (Pos(Name+Ext, UpStr(s)) = 1) then
{$EndIf}
      Begin
      s := KillLeadingSpcs(s);
      For i := 1 to Byte(s[0]) do Desc^[PPos + i - 1] := s[i];
      PPos := i + 3;
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
          PPos := i + 3;
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

(*
Procedure SetFileDesc(FName: String; Desc: PChar2);
Var
  s: String;
  f1, f2: Text;
  Dir, Name, Ext: String;
  i: word;
  DoAppend: Boolean;
  b: Boolean;
  crlf: PChar2;

  Begin
  GetMem(crlf, 3);
  crlf^[0] := #13; crlf^[1] := #10; crlf^[3] := #0;
  FSplit(FName, Dir, Name, Ext);
{$IfNDef Linux}
  Name := UpStr(Name);
  Ext := UpStr(Ext);
{$EndIf}
  Assign(f1, Dir + 'files.bbs');
  Assign(f2, Dir + 'files.tmp');
  {$I-} ReSet(f1); {$I+}
  DoAppend := (IOResult = 0);
  {$I-} ReWrite(f2); {$I+}
  If (IOResult <> 0) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Couldn''t open "'+Dir+'files.tmp"!');
    {$I-} Close(f1); {$I+}
    If (IOResult <> 0) then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Couldn''t close "'+Dir+'files.bbs"!');
      End;
    Exit;
    End;
  If DoAppend then While (not EOF(f1)) do
    Begin
    ReadLn(f1, s);
    If (s[Byte(s[0])] = #13) then s[0] := Char(Byte(s[0])-1);
{$IfDef Linux}
    If (Pos(Name+Ext, s) = 1) then Break;
{$Else}
    If (Pos(Name+Ext, UpStr(s)) = 1) then Break;
{$EndIf}
    WriteLn(f2, s);
    End;

  {add entry to FILES.BBS}
  Write(f2, Name+Ext+' ');

  {add DLC}
  If (Cfg^.AddDLC) then
   Begin
   Write(f2, '[');
   For i := 1 to Cfg^.DLCDig do Write(f2, '0');
   Write(f2, '] ');
   End;

  {write description}
  If (Desc <> NIL) and (Desc^[0] > #0) then
    Begin
    b := False;
    While (StrPos(Pointer(Desc), Pointer(crlf)) <> NIL) do
      Begin
      {check if first line}
      If not b then b := True
      Else
       Begin
       Write(f2, Cfg^.LDescChar);
       If (Cfg^.DescPos > 1) then Write(f2, Copy(Leer, 1, Cfg^.DescPos-1));
       End;
      i := 0;
       Repeat
       Write(f2, Desc^[i]);
       Inc(i);
       Until (Desc^[i] = #13) and (Desc^[i+1] = #10);
      WriteLn(f2);
{$IfDef OS2}
      Desc := Pointer(StrPos(Pointer(Desc), Pointer(crlf))+2);
{$Else}
 {$IfDef FPC}
      Desc := Pointer(StrPos(Pointer(Desc), Pointer(crlf))+2);
 {$Else}
      Desc := Pointer(StrPos(Pointer(Desc), Pointer(crlf)));
      MemW[Seg(Desc):Ofs(Desc)+2] := MemW[Seg(Desc):Ofs(Desc)+2] + 2;
 {$EndIf}
{$EndIf}
      End;
    i := 0;
    If (Desc^[i] > #0) then
     Begin
     If b then
      Begin
      Write(f2, Cfg^.LDescChar);
      If (Cfg^.DescPos > 1) then Write(f2, Copy(Leer, 1, Cfg^.DescPos-1));
      End;

      Repeat
      Write(f2, Desc^[i]);
      Inc(i);
      Until (Desc^[i] = #0);
     End;
    End
  Else WriteLn(f2, '<no description available>');
{$IfDef Linux}
  If DoAppend then If (Pos(Name+Ext, s) = 1) then
{$Else}
  If DoAppend then If (Pos(Name+Ext, UpStr(s)) = 1) then
{$EndIf}
    Begin
      Repeat
      ReadLn(f1, s);
      If (s[Byte(s[0])] = #13) then s[0] := Char(Byte(s[0])-1);
      Until EOF(f1) or (s[2] <> ' ');
    End;
  If DoAppend then If (not EOF(f1)) then
    Begin
      Repeat
      ReadLn(f1, s);
      If (s[Byte(s[0])] = #13) then s[0] := Char(Byte(s[0])-1);
      WriteLn(f2, s);
      Until EOF(f1);
    End;
  If DoAppend then
    Begin
    {$I-} Close(f1); {$I+}
    If (IOResult <> 0) then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Couldn''t close "'+Dir+'files.bbs"!');
      End;
    End;
  {$I-} Close(f2); {$I+}
  If (IOResult <> 0) then
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Couldn''t close "'+Dir+'files.tmp"!');
   End
  Else
   Begin
{$IfDef Linux}
   ChMod(Dir+'files.tmp', FilePerm);
{$EndIf}
   End;
  If not RepFile(Dir + 'files.tmp', Dir+'files.bbs') then
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Couldn''t replace "'+Dir+'files.bbs"!');
   End;
  FreeMem(crlf, 3);
  End;
*)

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
{$IfNDef Linux}
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
{$IfDef Linux}
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
  Write(FilesTMP, '['+Copy('0000000000', 1, Cfg^.DLCDig)+']');
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

     Repeat
     Write(filesTMP, CurDesc^[0]);
     Inc(CurDesc);
     Until (CurDesc = CRLFPos);
    WriteLn(FilesTMP);
    End
   Else
    Begin
    {add LongDescChar + Spaces}
    Write(FilesTMP, Cfg^.LDescChar);
    If (Cfg^.DescPos > 2) then Write(FilesTMP, Copy(Leer, 1, Cfg^.DescPos-1));

     Repeat
     Write(filesTMP, CurDesc^[0]);
     Inc(CurDesc);
     Until (CurDesc = CRLFPos);
    WriteLn(FilesTMP);
    End;
   CurDesc := @CurDesc^[2]; {skip CR/LF}
   End;

  {add last line}
  If FirstLine then
   Begin
   FirstLine := False;

    Repeat
    Write(filesTMP, CurDesc^[0]);
    Inc(CurDesc);
    Until (CurDesc^[0] = #0);
   WriteLn(FilesTMP);
   End
  Else
   Begin
   {add LongDescChar + Spaces}
   Write(FilesTMP, Cfg^.LDescChar);
   If (Cfg^.DescPos > 2) then Write(FilesTMP, Copy(Leer, 1, Cfg^.DescPos-1));

    Repeat
    Write(filesTMP, CurDesc^[0]);
    Inc(CurDesc);
    Until (CurDesc^[0] = #0);
   WriteLn(FilesTMP);
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
{$IfDef Linux}
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
{$IfNDef Linux}
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
{$IfDef Linux}
   If (copy(s, 1, Pos(' ', s)-1) = SName) then {replace entry}
{$Else}
   If (UpStr(copy(s, 1, Pos(' ', s)-1)) = SNameU) then {replace entry}
{$EndIf}
    Begin
    Found := True;
{$IfDef Linux}
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
 If not Found then WriteLn(f2, SNameU + ' ' + LName); {append entry}
 {$I-} Close(f2); {$I+}
 If (IOResult <> 0) then
  Begin
  LogSetCurLevel(LogHandle, 1);
  LogWriteLn(LogHandle, 'Could not close "'+Path+DirSep+'files.tmp"!');
  End
 Else
  Begin
{$IfDef Linux}
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
{$IfDef Linux}
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
  WriteLn('writing areas.log');
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
{$IfDef Linux}
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
  WriteLn('writing bbsarea.log');
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
{$IfDef Linux}
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

(*
Procedure DelPacked(Dir: String);
Var
{$IfDef SPEED}
  SRec: TSearchRec;
{$Else}
  SRec: SearchRec;
{$EndIf}
  l: Byte;

 Begin
{$IfDef VER70}
 SRec.Name := Dir + DirSep+'*.*';
{$Else}
 SRec.Name := Dir + DirSep+'*';
{$EndIf}
 FindFirst(SRec.Name, AnyFile, SRec);
 While (DosError = 0) do
  Begin
  l := Length(SRec.Name);
  If (SRec.Attr and Directory) = 0 then
   Begin
   If (SRec.Name[l-3] = '.') and (SRec.Name[l-2] = 'c') then
    Begin
    If not ((SRec.Name[l-1] < '0') or (SRec.Name[l-1] > '9')
     or (SRec.Name[l] < '0') or (SRec.Name[l] > '9')) then
     Begin
     If (GetFSize(Dir + DirSep + SRec.Name) = 0) then
      Begin
      Write('Deleting '+Dir + DirSep + SRec.Name+'...');
      If Not DelFile(Dir + DirSep + SRec.Name) then
       Begin
       WriteLn;
       LogSetCurLevel(LogHandle, 1);
       LogWriteLn(LogHandle, 'Couldn''t delete '+Dir+DirSep+SRec.Name+'!');
       End
      Else WriteLn(' Done');
      End;
     End;
    End;
   End
  Else If (SRec.Name[1] <> '.') then DelPacked(Dir + DirSep + SRec.Name);
  FindNext(SRec);
  End;
 End;
*)

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
{$IfDef Linux}
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
{$IfDef Linux}
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
{$IfDef Linux}
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
{$IfDef Linux}
  ChMod(Cfg^.MsgIDFile, FilePerm);
{$EndIf}
  End;
 end;


Begin
End.
