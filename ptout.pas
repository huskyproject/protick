Unit PTOut;
Interface

{$Q-}

Uses
{$IfDef UNIX}
 linux,
{$EndIf}
 DOS,
 Types, GeneralP,
 Log,
 TickCons, TickType;

Type
 pOutbound = ^tOutbound;
 pBTOutbound = ^tBTOutbound;
 pFDOutbound = ^tFDOutbound;

 tOutbound =
  object
  Constructor Init;
  Destructor Done; Virtual;

  {check/set/unset BusyFlags for an user}
  Function IsBusy(User: pUser): Boolean; Virtual;
  Procedure SetBusy(User: pUser); Virtual;
  Procedure UnSetBusy(User: pUser); Virtual;

  {send a file to a user, check if it already was sent}
  Procedure SendFile(User: pUser; FName: String; Action: Byte); Virtual;
  Function CheckFileSent(User: pUser; FName: String): Boolean; Virtual;

  {get a name for an archive, remove zero-length archives}
  Function ArchiveName(User: pUser): String; Virtual;
  Procedure PurgeArchs; Virtual;
  end;

 tBTOutbound =
  object(tOutbound)

  Constructor Init(_Cfg: PTickCfg; _lh: Byte; _BaseDir: String;
   _PrimAKA: tNetAddr);
  Destructor Done; Virtual;

  {check/set/unset BusyFlags for an user}
  Function IsBusy(User: pUser): Boolean; Virtual;
  Procedure SetBusy(User: pUser); Virtual;
  Procedure UnSetBusy(User: pUser); Virtual;

  {send a file to a user, check if it already was sent}
  Procedure SendFile(User: pUser; FName: String; Action: Byte); Virtual;
  Function CheckFileSent(User: pUser; FName: String): Boolean; Virtual;

  {get a name for an archive, remove zero-length archives}
  Function ArchiveName(User: pUser): String; Virtual;
  Procedure PurgeArchs; Virtual;


  private
  BaseDir: String; {directory of primary zone}
  PrimAKA: tNetAddr; {primary AKA}
  lh: Byte;
  Cfg: PTickCfg;

  Function FloName(Usr: pUser): String;
  Procedure PurgeArchsDir(Dir: String);
  end;

 tFDOutbound =
  object (tOutbound)

  Constructor Init(_STQFile: String; _LCKFile: String; _lh: Byte; _TicDir: String; _FlagDir: String);
  Destructor Done; Virtual;

  {check/set/unset BusyFlags for an user}
  Function IsBusy(User: pUser): Boolean; Virtual;
  Procedure SetBusy(User: pUser); Virtual;
  Procedure UnSetBusy(User: pUser); Virtual;

  {send a file to a user, check if it already was sent}
  Procedure SendFile(User: pUser; FName: String; Action: Byte); Virtual;
  Function CheckFileSent(User: pUser; FName: String): Boolean; Virtual;

  {get a name for an archive, remove zero-length archives}
  Function ArchiveName(User: pUser): String; Virtual;
  Procedure PurgeArchs; Virtual;

  private
  STQFile: String;
  LCKFile: String;
  TicDir: String;
  FlagDir: String;
  STQ: file;
  ValidQueue: Boolean;
  Rev: Word;
  lh: Byte;
  {global}
  TimeCreated, TimePacked, ReservedLong, PackRecovery: LongInt;
  {single record}
  EntryTime, Flags, TimeStamp: LongInt;
  Address, FileName, TFA: String;

  Procedure ReadHdr;
  Procedure WriteHdr;
  Procedure ReadEntry;
  Procedure WriteEntry;
  Function OpenSTQ: Boolean;
  Procedure ForceRescan;
  Function FileBusy(FName: String): Boolean;
  Procedure PurgeArchsDir(Dir: String);
  end;


Implementation

Const
{FD}
  FQflgKFS        =$00000001;            {Kill file after sending, w/checking}
  FQflgKFSNoCheck =$00000002;                     {Like KFS, but w/o checking}
  FQflgTFS        =$00000004;            {Trunc file after sending w/checking}
  FQflgTFSNoCheck =$00000008;                     {Like TFS, but w/o checking}
  FQflgIsARCmail  =$00000020;                                 {ARCmail attach}
  FQflgSendStart  =$00000040;               {FD has started to send this file}
  FQflgSendAfter  =$00020000;               {Date contains entry release date}
  FQflgKeepExpired=$00040000;                             {Keep expired entry}
  FQflgSendUntil  =$00080000;            {Date contains entry expiration date}
  FQflgIsHold     =$00100000;                                           {Hold}
  FQflgIsCrash    =$00200000;                                          {Crash}
  FQflgIsIMM      =$00400000;                                      {Immediate}
  FQflgNoPickup   =$00800000;                              {Must be delivered}
  FQflgIsSpool    =$01000000;            {Spool mask (Permanent + KFSNoCheck)}
  FQflgIsFREQ     =$02000000;                                {Is file request}
  FQflgIsFile     =$04000000;                                 {Is file attach}
  FQflgTFA        =$08000000;              {TFA field contains alias filename}
  FQflgHidden     =$20000000;                    {Hidden entry, don't display}
  FQflgLocked     =$40000000;                           {Locked entry, ignore}
  FQflgDeleted    =$80000000;                         {Entry has been deleted}
  FQflgPassword   =$08000000;                         {Used for File Requests}
  FQmacHasFilename=(FQflgIsFREQ or FQflgIsFile);


Procedure Abstract; Begin Halt(211); End;

Constructor tOutbound.Init;
Begin Fail; End;

Destructor tOutbound.Done;
Begin Abstract; End;


Function tOutbound.IsBusy(User: pUser): Boolean;
Begin Abstract; End;

Procedure tOutbound.SetBusy(User: pUser);
Begin Abstract; End;

Procedure tOutbound.UnSetBusy(User: pUser);
Begin Abstract; End;


Procedure tOutbound.SendFile(User: pUser; FName: String; Action: Byte);
Begin Abstract; End;

Function tOutbound.CheckFileSent(User: pUser; FName: String): Boolean;
Begin Abstract; End;

Function tOutbound.ArchiveName(User: pUser): String;
Begin Abstract; End;

Procedure tOutbound.PurgeArchs;
Begin Abstract; End;


Constructor tBTOutbound.Init(_Cfg: PTickCfg; _lh: Byte; _BaseDir: String;
 _PrimAKA: tNetAddr);

 Begin
 Cfg := _Cfg;
 lh := _lh;
 BaseDir := _BaseDir;
 PrimAKA := _PrimAKA;
 LogSetCurLevel(lh, 5);
 LogWriteLn(lh, 'BaseDir = "'+_BaseDir+'"/"'+BaseDir+'"');
 End;

Destructor tBTOutbound.Done;
 Begin

 End;


Function tBTOutbound.IsBusy(User: pUser): Boolean;
Var
 Tmp: String;

 Begin
 Tmp := FLOName(User);
 Tmp[0] := Char(Byte(Tmp[0])-3); {remove 'flo'}
 IsBusy := FileExist(Tmp + 'bsy');
 End;

Procedure tBTOutbound.SetBusy(User: pUser);
Var
 Tmp: String;
 f: File;

 Begin
 Tmp := FLOName(User);
 Tmp[0] := Char(Byte(Tmp[0])-3); {remove 'flo'}
 Assign(f, Tmp + 'bsy');
 {$I-} ReWrite(f); {$I+}
 If (IOResult = 0) then Close(f)
 Else
  Begin
  LogSetCurLevel(lh, 1);
  LogWriteLn(lh, 'Could not create BusyFile "'+Tmp+'bsy"!');
  End;
 End;

Procedure tBTOutbound.UnSetBusy(User: pUser);
Var
 Tmp: String;

 Begin
 Tmp := FLOName(User);
 Tmp[0] := Char(Byte(Tmp[0])-3); {remove 'flo'}
 If not DelFile(Tmp + 'bsy') then
  Begin
  LogSetCurLevel(lh, 1);
  LogWriteLn(lh, 'Could not remove BusyFile "'+Tmp+'bsy"!');
  End;
 End;


Procedure tBTOutbound.SendFile(User: pUser; FName: String; Action: Byte);
Var
 f: Text;
 FlowName: String;
 Error1, Error2: Integer;

 Begin
 FlowName := FloName(User);
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
   LogSetCurLevel(lh, 1);
   LogWriteLn(lh, 'Couldn''t open "'+FlowName+'": Error '+
    IntToStr(Error1)+', '+IntToStr(Error2)+'!');
   Exit;
   End;
  End;
 {$I-}
 Case Action of
  ac_Nothing : WriteLn(f, FName);
  ac_Del     : WriteLn(f, '^'+FName);
  ac_Trunc   : WriteLn(f, '#'+FName);
  else
   WriteLn(f, FName);
  end;
 If (IOResult <> 0) then
  Begin
  LogSetCurLevel(lh, 1);
  LogWriteLn(lh, 'Error writing "'+FlowName+'"!');
  End;
 Close(f); {$I+}
 If (IOResult <> 0) then
  Begin
  LogSetCurLevel(lh, 1);
  LogWriteLn(lh, 'Couldn''t close "'+FlowName+'"!');
  End
 Else
  Begin
{$IfDef UNIX}
  Chmod(FlowName, FilePerm);
{$EndIf}
  End;
 End;

Function tBTOutbound.CheckFileSent(User: pUser; FName: String): Boolean;
Var
 Tmp: String;
 f: Text;
 Line: String;
 Found: Boolean;

 Begin
{$IfNDef UNIX}
 FName := UpStr(FName);
{$EndIf}
 Found := False;
 Tmp := FLOName(User);
 Tmp[Length(Tmp)-2] := 'f'; {flavour normal}
 Assign(f, Tmp);
 {$I-} ReSet(f); {$I+}
 If (IOResult = 0) then While not (EOF(f) or Found) do
  Begin
  ReadLn(f, Line);
  If (Line[1] = '~') then Continue; {skip sent files}
  If (Line[1] in ['#', '^']) then Delete(Line, 1, 1);
{$IfDef UNIX}
  Found := Found or (Line = FName);
{$Else}
  Found := Found or (Upstr(Line) = FName);
{$EndIf}
  End;

 If not Found then
  Begin
  Tmp[Length(Tmp)-2] := 'c'; {flavour crash}
  Assign(f, Tmp);
  {$I-} ReSet(f); {$I+}
  If (IOResult = 0) then While not (EOF(f) or Found) do
   Begin
   ReadLn(f, Line);
   If (Line[1] = '~') then Continue; {skip sent files}
   If (Line[1] in ['#', '^']) then Delete(Line, 1, 1);
{$IfDef UNIX}
   Found := Found or (Line = FName);
{$Else}
   Found := Found or (Upstr(Line) = FName);
{$EndIf}
   End;
  End;

 If not Found then
  Begin
  Tmp[Length(Tmp)-2] := 'd'; {flavour direct}
  Assign(f, Tmp);
  {$I-} ReSet(f); {$I+}
  If (IOResult = 0) then While not (EOF(f) or Found) do
   Begin
   ReadLn(f, Line);
   If (Line[1] = '~') then Continue; {skip sent files}
   If (Line[1] in ['#', '^']) then Delete(Line, 1, 1);
{$IfDef UNIX}
   Found := Found or (Line = FName);
{$Else}
   Found := Found or (Upstr(Line) = FName);
{$EndIf}
   End;
  End;

 If not Found then
  Begin
  Tmp[Length(Tmp)-2] := 'h'; {flavour hold}
  Assign(f, Tmp);
  {$I-} ReSet(f); {$I+}
  If (IOResult = 0) then While not (EOF(f) or Found) do
   Begin
   ReadLn(f, Line);
   If (Line[1] = '~') then Continue; {skip sent files}
   If (Line[1] in ['#', '^']) then Delete(Line, 1, 1);
{$IfDef UNIX}
   Found := Found or (Line = FName);
{$Else}
   Found := Found or (Upstr(Line) = FName);
{$EndIf}
   End;
  End;

 CheckFileSent := not Found;
 End;


Function tBTOutbound.ArchiveName(User: pUser): String;
Var
 CurName: String;

 Begin
 CurName := FLOName(User);
 CurName[0] := Char(Byte(CurName[0])-3); {remove 'flo'}
 CurName := CurName + 'c00';
 While (FileExist(CurName) and (GetFSize(CurName) = 0)) do
  Begin
  If (CurName[Length(CurName)] = '9') then
   Begin
   If (CurName[Length(CurName)-1] = '9') then
    Begin
    LogSetCurLevel(lh, 1);
    LogWriteLn(lh, 'no free archive name for "'+User^.Name+'" ('+
     Addr2Str(User^.Addr)+')!');
    ArchiveName := '';
    Exit;
    End
   Else Inc(CurName[Length(CurName)-1]);
   End
  Else Inc(CurName[Length(CurName)]);
  End;
 ArchiveName := CurName;
 End;

Procedure tBTOutbound.PurgeArchs;
 Begin
{ LogSetCurLevel(lh, 5);
 LogWriteLn(lh, 'BaseDir = "'+BaseDir+'"');
 LogWriteLn(lh, 'Calling PurchArchsDir("'+ Copy(BaseDir, 1, LastPos(DirSep, BaseDir)-1)+ '")');}
 PurgeArchsDir(Copy(BaseDir, 1, LastPos(DirSep, BaseDir)-1));
 End;

Procedure tBTOutbound.PurgeArchsDir(Dir: String);
Var
{$IfDef SPEED}
  SRec: TSearchRec;
{$Else}
  SRec: SearchRec;
{$EndIf}
  l: Byte;

 Begin
{ LogSetCurLevel(lh, 5);
 LogWriteLn(lh, 'tBTOutbound.PurgeArchsDir("'+Dir+'") called');}
 SRec.Name := Dir + DirSep+ '*.*';
{ LogWriteLn(lh, 'Calling FindFirst("'+ SRec.Name+ ', AnyFile, SRec)');}
 FindFirst(SRec.Name, AnyFile, SRec);
 While (DosError = 0) do
  Begin
  LogSetCurLevel(lh, 5);
{  LogWriteLn(lh, 'DosError = 0');}
  l := Length(SRec.Name);
{  LogWriteLn(lh, 'Length(SRec.Name) = '+ IntToStr(l));}
  If (SRec.Attr and Directory) = 0 then
   Begin
   LogSetCurLevel(lh, 5);
{   LogWriteLn(lh, 'not Directory');}
   If (SRec.Name[l-3] = '.') and (UpCase(SRec.Name[l-2]) = 'C') then
    Begin
{    LogWriteLn(lh, '*.[Cc]?? found');}
    If not ((SRec.Name[l-1] < '0') or (SRec.Name[l-1] > '9')
     or (SRec.Name[l] < '0') or (SRec.Name[l] > '9')) then
     Begin
{     LogWriteLn(lh, '*.[Cc][0-9][0-9] found');}
     If (GetFSize(Dir + DirSep + SRec.Name) = 0) then
      Begin
      Write('Deleting '+Dir + DirSep + SRec.Name+'...');
      If Not DelFile(Dir + DirSep + SRec.Name) then
       Begin
       WriteLn;
       LogSetCurLevel(lh, 1);
       LogWriteLn(lh, 'Couldn''t delete '+Dir+DirSep+SRec.Name+'!');
       End
      Else WriteLn(' Done');
      End;
     End;
    End;
   End
  Else
   Begin
{   LogSetCurLevel(lh, 5);
   LogWriteLn(lh, 'Directory');}
   If (SRec.Name[1] <> '.') then PurgeArchsDir(Dir + DirSep + SRec.Name);
   End;
  LogSetCurLevel(lh, 5);
{  LogWriteLn(lh, 'Calling FindNext');}
  FindNext(SRec);
  End;
 End;


Function tBTOutbound.FloName(Usr: pUser): String;
Var
 s, s1: String;
 FlowName: String;
 Dir: String;
 Addr: TNetAddr;
 i: Byte;

 Begin
 If CompAddr(Usr^.ArcAddr, EmptyAddr) then Addr := Usr^.Addr Else Addr := Usr^.ArcAddr;
 If ((Addr.Domain = PrimAKA.Domain) or (Addr.Domain = '') or (PrimAKA.Domain = '')) then
   Begin
   If (Addr.Zone <> PrimAKA.Zone) then 
    Begin
    If (Addr.Zone < 4096) then FlowName := Cfg^.OutBound+'.'+Copy(WordToHex(word(Addr.Zone)), 2, 3)+DirSep
    Else FlowName := Cfg^.OutBound+'.'+WordToHex(Word(Addr.Zone))+DirSep; 
    End
   Else FlowName := Cfg^.OutBound + DirSep;
   End
 Else
   Begin
   s := BaseDir;
   While (s[Length(s)] <> DirSep) do Delete(s, Length(s), 1);
   s1 := Addr.Domain;
   If (Cfg^.NumDomains > 0) then
    Begin
    For i := 1 to Cfg^.NumDomains do
     If (UpStr(Addr.Domain) = UpStr(Cfg^.Domains[i].Domain)) then
      s1 := Cfg^.Domains[i].Abbrev;
    End;
   FlowName := s + s1 + '.'+Copy(WordToHex(word(Addr.Zone)), 2, 3)+DirSep;
   End;
 Dir := Copy(FlowName, 1, Length(FlowName) - 1);
 FlowName := FlowName + WordToHex(word(Addr.Net)) + WordToHex(word(Addr.Node));
 If (Addr.Point <> 0) then
   Begin
   Dir := FlowName + '.pnt';
   FlowName := FlowName + '.pnt'+DirSep+'0000' + WordToHex(word(Addr.Point));
   End;
 Case Usr^.MailFlags of
   ml_Normal : FlowName := FlowName + '.flo';
   ml_Direct : FlowName := FlowName + '.dlo';
   ml_Hold : FlowName := FlowName + '.hlo';
   ml_Crash : FlowName := FlowName + '.clo';
   end;
 If not DirExist(Dir) then If not MakeDir(Dir) then
   Begin
   LogSetCurLevel(lh, 1);
   LogWriteLn(lh, 'Couldn''t create directory "'+Dir+'"!');
   End
 Else
   Begin
   LogSetCurLevel(lh, 2);
   LogWriteLn(lh, 'Created directory "'+Dir+'"');
   End;
 FloName := FlowName;
 End;


Constructor tFDOutbound.Init(_STQFile: String; _LCKFile: String; _lh: Byte; _TicDir: String; _FlagDir: String);
 Begin
 STQFile := _STQFile;
 LCKFile := _LCKFile;
 lh := _lh;
 TicDir := _TicDir;
 FlagDir := _FlagDir;
 End;

Destructor tFDOutbound.Done;
 Begin

 End;


Function tFDOutbound.IsBusy(User: pUser): Boolean;
 Begin
 {does nothing}
 IsBusy := False;
 End;

Procedure tFDOutbound.SetBusy(User: pUser);
 Begin
 {does nothing}
 End;

Procedure tFDOutbound.UnSetBusy(User: pUser);
 Begin
 {does nothing}
 End;


Procedure tFDOutbound.SendFile(User: pUser; FName: String; Action: Byte);
Var
 i: Byte;
 DT: TimeTyp;

 Begin
 If not OpenSTQ then Exit;
 ReadHdr;

 {set entry values}
 Today(DT); Now(DT); EntryTime := DTToUnixDate(DT);
 TimeStamp := EntryTime;
 Address := Addr2StrND(User^.ArcAddr);
 FileName := FName;
 TFA := '';
 Flags := FQflgIsFile;
 If (Action = ac_Del) then Flags := Flags or FQflgKFSNoCheck
 Else if (Action = ac_Trunc) then Flags := Flags or FQflgTFSNoCheck;
 Case User^.MailFlags of
  ml_Crash: Flags := Flags or FQflgIsCrash;
  ml_Direct: Flags := Flags or FQflgIsIMM;
  ml_Hold: Flags := Flags or FQflgIsHold;
{  ml_Normal: do nothing}
  End;

 {check lock}
 i := 1;
 While (FileExist(LCKFile) and (i < 12)) do
  Begin
  Inc(i);
  Delay(1000);
  End;
 If FileExist(LCKFile) then
  Begin
  LogSetCurLevel(lh, 1);
  LogWriteLn(lh, 'tFDOutbound: Could not send file "'+FName+'" to User "'+
  User^.Name+'" ('+Addr2Str(User^.Addr)+'): STQ locked for more than 10 seconds!');

  Close(STQ);
  End
 Else
  Begin
  {set lock}
  CreateSem(LCKFile);

  {append entry}
  Seek(STQ, filesize(STQ));
  WriteEntry;

  {reset lock}
  DelFile(LCKFile);

  Close(STQ);

  {force rescan?}
  If (User^.MailFlags <> ml_Hold) then ForceReScan;
  End;
 End;

Function tFDOutbound.CheckFileSent(User: pUser; FName: String): Boolean;
Var
 Error: Integer;
 DT: TimeTyp;
 Addr: TNetAddr;

 Begin
 If not OpenSTQ then Exit;
 ReadHdr;

 If (not EOF(STQ)) then
  Begin
   Repeat
   ReadEntry;
   Str2Addr(Address, Addr);

   Until (EOF(STQ) or (CompAddr(Addr, User^.ArcAddr) and (FName = FileName)));
  CheckFileSent := not CompAddr(Addr, User^.ArcAddr) or (FName <> FileName)
   or ((Flags and FQflgDeleted) > 0); {no entry or deleted entry => file already sent}
  End
 Else CheckFileSent := True; {no entry in STQ => file already sent}
 Close(STQ);
 End;

Function tFDOutbound.ArchiveName(User: pUser): String;
Var
 CurName: String;

 Begin
 {directory structure:
  Cfg^.TicDir
  |
  +-zone.001            Dir
  |
  +-zone.002            Dir
  | |
  | +-098301a8.pnt      Dir
  | | |
  | | +-00000001.c00    File
  | |
  | +-09830000.c00      File
  |
  +-zone.02c            Dir

 }

 {calculate first name, create necessary dirs}
 CurName := TicDir+DirSep+'zone.';
 If (User^.ArcAddr.Zone < 4096) then CurName := CurName+Copy(WordToHex(Word(User^.ArcAddr.Zone)), 2, 3)
 Else CurName := CurName+WordToHex(Word(User^.ArcAddr.Zone));
 MakeDir(CurName);
 CurName := CurName+DirSep + WordToHex(word(User^.ArcAddr.Net)) +
  WordToHex(word(User^.ArcAddr.Node));
 If (User^.ArcAddr.Point <> 0) then
  Begin
  CurName := CurName + '.pnt' + DirSep + '0000' + WordToHex(word(User^.ArcAddr.Point));
  MakeDir(CurName+'.pnt');
  End;
 CurName := CurName + '.c00';

 {Find unused name}
 While (FileExist(CurName) and ((GetFSize(CurName) = 0) or FileBusy(CurName))) do
  Begin
  If (CurName[Length(CurName)] = '9') then
   Begin
   If (CurName[Length(CurName)-1] = '9') then
    Begin
    LogSetCurLevel(lh, 1);
    LogWriteLn(lh, 'no free archive name for "'+User^.Name+'" ('+
     Addr2Str(User^.Addr)+')!');
    ArchiveName := '';
    Exit;
    End
   Else Inc(CurName[Length(CurName)-1]);
   End
  Else Inc(CurName[Length(CurName)]);
  End;
 ArchiveName := CurName;
 End;

Procedure tFDOutbound.PurgeArchs;
 Begin
 PurgeArchsDir(TicDir);
 End;


Procedure tFDOutbound.ReadHdr;
Var
 Sig: String[22];
 Maj, Min: Byte;
 Long1, Long2, Long3, Long4: Byte;
 DT: TimeTyp;

 Begin
 Sig[0] := Char(22);
 BlockRead(STQ, Sig[1], 22);
 If (Sig = 'FrontDoor File Queue'#26#0) then
  Begin
  BlockRead(STQ, Min, 1);
  BlockRead(STQ, Maj, 1);
  Rev := Min + (Maj * 256);
  If (Rev = $0100) then
   Begin
   BlockRead(STQ, Long1, 1); BlockRead(STQ, Long2, 1);
   BlockRead(STQ, Long3, 1); BlockRead(STQ, Long4, 1);
   TimeCreated := (LongInt(Long1) + (LongInt(Long2) * 256)) + ((LongInt(Long3) + (LongInt(Long4) * 256)) * 65536);
   UnixToDT(TimeCreated, DT);

   BlockRead(STQ, Long1, 1); BlockRead(STQ, Long2, 1);
   BlockRead(STQ, Long3, 1); BlockRead(STQ, Long4, 1);
   TimePacked := (LongInt(Long1) + (LongInt(Long2) * 256)) + ((LongInt(Long3) + (LongInt(Long4) * 256)) * 65536);
   UnixToDT(TimePacked, DT);

   BlockRead(STQ, Long1, 1); BlockRead(STQ, Long2, 1);
   BlockRead(STQ, Long3, 1); BlockRead(STQ, Long4, 1);
   ReservedLong := (LongInt(Long1) + (LongInt(Long2) * 256)) + ((LongInt(Long3) + (LongInt(Long4) * 256)) * 65536);

   BlockRead(STQ, Long1, 1); BlockRead(STQ, Long2, 1);
   BlockRead(STQ, Long3, 1); BlockRead(STQ, Long4, 1);
   PackRecovery := (LongInt(Long1) + (LongInt(Long2) * 256)) + ((LongInt(Long3) + (LongInt(Long4) * 256)) * 65536);

   Seek(STQ, 1024); {0-based => pos = 1025}
   ValidQueue := True;
   End
  Else
   Begin
   LogSetCurLevel(lh, 1);
   LogWriteLn(lh, 'tFDOutbound: Invalid Queue revision!');
   ValidQueue := False;
   End;
  End
 Else
  Begin
  LogSetCurLevel(lh, 1);
  LogWriteLn(lh, 'tFDOutbound: Invalid Queue signature!');
  ValidQueue := False;
  End;
 End;

Procedure tFDOutbound.WriteHdr;
Const Sig: String[22] = 'FrontDoor File Queue'#26#00;
Var
 Maj, Min: Byte;
 Long1, Long2, Long3, Long4: Byte;
 i: Word;
 HdrBuf: Array[0..1023] of Byte;

 Begin
 {Signature}
 for i := 1 to 22 do HdrBuf[i - 1] := Byte(Sig[i]);

 {rev $0100}
 HdrBuf[22] := $00;
 HdrBuf[23] := $01;

 {TimeCreated}
 Long1 := TimeCreated mod 256; Long2 := (TimeCreated div 256) mod 256;
 Long3 := (TimeCreated div 65536) mod 256; Long4 := (TimeCreated div 16777216);
 HdrBuf[24] := Long1; HdrBuf[25] := Long2;
 HdrBuf[26] := Long3; HdrBuf[27] := Long4;

 {TimePacked}
 Long1 := TimePacked mod 256; Long2 := (TimePacked div 256) mod 256;
 Long3 := (TimePacked div 65536) mod 256; Long4 := (TimePacked div 16777216);
 HdrBuf[28] := Long1; HdrBuf[29] := Long2;
 HdrBuf[30] := Long3; HdrBuf[31] := Long4;

 {ReservedLong}
 Long1 := 0; Long2 := 0; Long3 := 0; Long4 := 0;
 HdrBuf[32] := Long1; HdrBuf[33] := Long2;
 HdrBuf[34] := Long3; HdrBuf[35] := Long4;

 {PackRecovery}
 Long1 := 0; Long2 := 0; Long3 := 0; Long4 := 0;
 HdrBuf[36] := Long1; HdrBuf[37] := Long2;
 HdrBuf[38] := Long3; HdrBuf[39] := Long4;

 {fill up to 1024 Bytes}
 For i := 40 to 1023 do HdrBuf[i] := 0;
 
 BlockWrite(STQ, HdrBuf, 1024);

 ValidQueue := True;
 End;

Procedure tFDOutbound.ReadEntry;
Var
 EntryLen: Word;
 Min, Maj: Byte;
 Long1, Long2, Long3, Long4: Byte;
 DT: TimeTyp;

 Begin
 BlockRead(STQ, Min, 1);
 BlockRead(STQ, Maj, 1);
 EntryLen := Word(Min) + (Word(Maj) * 256);

 If (EntryLen >= 15) then
  Begin
  BlockRead(STQ, Long1, 1); BlockRead(STQ, Long2, 1);
  BlockRead(STQ, Long3, 1); BlockRead(STQ, Long4, 1);
  EntryTime := (LongInt(Long1) + (LongInt(Long2) * 256)) + ((LongInt(Long3) + (LongInt(Long4) * 256)) * 65536);
  UnixToDT(EntryTime, DT);

  BlockRead(STQ, Long1, 1); BlockRead(STQ, Long2, 1);
  BlockRead(STQ, Long3, 1); BlockRead(STQ, Long4, 1);
  Flags := (LongInt(Long1) + (LongInt(Long2) * 256)) + ((LongInt(Long3) + (LongInt(Long4) * 256)) * 65536);

  BlockRead(STQ, Long1, 1); BlockRead(STQ, Long2, 1);
  BlockRead(STQ, Long3, 1); BlockRead(STQ, Long4, 1);
  TimeStamp := (LongInt(Long1) + (LongInt(Long2) * 256)) + ((LongInt(Long3) + (LongInt(Long4) * 256)) * 65536);
  UnixToDT(TimeStamp, DT);

  BlockRead(STQ, Address[0], 1);
  If (Byte(Address[0]) > 0) then BlockRead(STQ, Address[1], Byte(Address[0]));

  If (EntryLen > (Byte(Address[0])+14)) then
   Begin
   BlockRead(STQ, Filename[0], 1);
   If (Byte(Filename[0]) > 0) then BlockRead(STQ, Filename[1], Byte(Filename[0]));

   If (EntryLen >= (Byte(Address[0])+Byte(Filename[0])+15)) then
    Begin
    BlockRead(STQ, TFA[0], 1);
    If (EntryLen = (Byte(Address[0])+Byte(Filename[0])+15)) then TFA[0] := Char(0);
    If (Byte(TFA[0]) > 0) then BlockRead(STQ, TFA[1], Byte(TFA[0]));

    {skip last bytes if entry is too long}
    If (EntryLen > (Byte(Address[0])+Byte(Filename[0])+Byte(TFA[0])+15)) then
     Begin
     Seek(STQ, FilePos(STQ)+EntryLen-(Byte(Address[0])+Byte(Filename[0])+Byte(TFA[0])+15));
     LogSetCurLevel(lh, 2);
     LogWriteLn(lh, 'tFDOutbound: skipped '+IntToStr(EntryLen-(Byte(Address[0])+
      Byte(Filename[0])+Byte(TFA[0])+15))+' Bytes of garbage.');
     End;
    End
   Else TFA[0] := Char(0);
   End;
  End
 Else
  Begin
  LogSetCurLevel(lh, 2);
  LogWriteLn(lh, 'tFDOutbound: Entry too small => skipping '+IntToStr(EntryLen)+
   ' Bytes.');
  Seek(STQ, FilePos(STQ)+EntryLen);
  End;
 End;

Procedure tFDOutbound.WriteEntry;
Var
 EntryLen: Word;
 Min, Maj: Byte;
 Long1, Long2, Long3, Long4: Byte;
 EntryBuf: PChar2;
 EntryPos: Word;
 i: Word;

 Begin
 {EntryLen}
 EntryLen := (Byte(Address[0])+Byte(Filename[0])+Byte(TFA[0])+15);
 GetMem(EntryBuf, EntryLen+2);
 Min := EntryLen mod 256; Maj := (EntryLen div 256);
 EntryBuf^[0] := Char(Min); EntryBuf^[1] := Char(Maj);

 Long1 := EntryTime mod 256; Long2 := (EntryTime div 256) mod 256;
 Long3 := (EntryTime div 65536) mod 256; Long4 := (EntryTime div 16777216);
 EntryBuf^[2] := Char(Long1); EntryBuf^[3] := Char(Long2);
 EntryBuf^[4] := Char(Long3); EntryBuf^[5] := Char(Long4);
 
 Long1 := Flags mod 256; Long2 := (Flags div 256) mod 256;
 Long3 := (Flags div 65536) mod 256; Long4 := (Flags div 16777216);
 EntryBuf^[6] := Char(Long1); EntryBuf^[7] := Char(Long2);
 EntryBuf^[8] := Char(Long3); EntryBuf^[9] := Char(Long4);

 Long1 := TimeStamp mod 256; Long2 := (TimeStamp div 256) mod 256;
 Long3 := (TimeStamp div 65536) mod 256; Long4 := (TimeStamp div 16777216);
 EntryBuf^[10] := Char(Long1); EntryBuf^[11] := Char(Long2);
 EntryBuf^[12] := Char(Long3); EntryBuf^[13] := Char(Long4);

 For i := 0 to Byte(Address[0]) do EntryBuf^[14+i] := Address[i];
 EntryPos := 15+Byte(Address[0]);

 For i := 0 to Byte(Filename[0]) do EntryBuf^[EntryPos+i] := Filename[i];
 EntryPos := EntryPos + Byte(Filename[0])+1;

 For i := 0 to Byte(TFA[0]) do EntryBuf^[EntryPos+i] := TFA[i];

 BlockWrite(STQ, EntryBuf^, EntryLen+2);
 FreeMem(EntryBuf, EntryLen+2);
 End;

Function tFDOutbound.OpenSTQ: Boolean;
Var
 Error: Integer;
 DT: TimeTyp;
 
 Begin
 OpenSTQ := False;
 Assign(STQ, STQFile);
 {$I-} ReSet(STQ, 1); {$I+}
 Error := IOResult;
 If (Error <> 0) then
  Begin
  If (Error = 5) then {file locked}
   Begin
   Delay(5);
   Assign(STQ, STQFile);
   {$I-} ReSet(STQ, 1); {$I+}
   Error := IOResult;
   If (Error <> 0) then
    Begin
    LogSetCurLevel(lh, 1);
    LogWriteLn(lh, 'tFDOutbound: Could not open "'+STQFile+'": Error #'+
     IntToStr(Error)+'!');
    Exit;
    End;
   End
  Else If (Error = 2) then {file not found}
   Begin
   If FileExist(LCKFile) then
    Begin
    Delay(10);
    Assign(STQ, STQFile);
    {$I-} ReSet(STQ, 1); {$I+}
    Error := IOResult;
    If (Error <> 0) then
     Begin
     LogSetCurLevel(lh, 1);
     LogWriteLn(lh, 'tFDOutbound: Could not open "'+STQFile+'": Error #'+
      IntToStr(Error)+'!');
     Exit;
     End;
    End
   Else
    Begin
    {$I-} ReWrite(STQ, 1); {$I+}
    Error := IOResult;
    If (Error <> 0) then
     Begin
     LogSetCurLevel(lh, 1);
     LogWriteLn(lh, 'tFDOutbound: Could not create "'+STQFile+'": Error #'+
      IntToStr(Error)+'!');
     Exit;
     End;
    Now(DT); TimeCreated := DTToUnixDate(DT); TimePacked := TimeCreated;
    LogSetCurLevel(lh, 3);
    LogWriteLn(lh, 'Creating new STQ');
    WriteHdr;
    Close(STQ);
{$IfDef UNIX}
    ChMod(STQFile, FilePerm);
{$EndIf}
    ReSet(STQ, 1);
    End;
   End
  Else
   Begin
   LogSetCurLevel(lh, 1);
   LogWriteLn(lh, 'tFDOutbound: Could not open "'+STQFile+'": Error #'+
    IntToStr(Error)+'!');
   Exit;
   End;
  End;
 OpenSTQ := True;
 End;
 
Procedure tFDOutbound.ForceRescan;
 Begin
 CreateSem(FlagDir + 'FDRESCAN.NOW');
 End;

Function tFDOutbound.FileBusy(FName: String): Boolean;
Var
 Addr: TNetAddr;

 Begin
 If not OpenSTQ then Exit;
 ReadHdr;

 If (not EOF(STQ)) then
  Begin
   Repeat
   ReadEntry;
   Str2Addr(Address, Addr);

   Until (EOF(STQ) or (FName = FileName));
  FileBusy := (FName <> FileName)
   or ((Flags and $80000000) > 0); {no entry or deleted entry => file already sent}
  If (FName <> FileName) then FileBusy := False {not in STQ => not busy}
  Else
   Begin
   If (Flags and FQflgDeleted) > 0 then FileBusy := False
   Else If (Flags and FQflgLocked) > 0 then FileBusy := False {ignore entry}
   Else If (Flags and FQflgSendStart) > 0 then FileBusy := True
   Else FileBusy := False;
   End;
  End
 Else FileBusy := False; {no entry in STQ => file cannot be busy}
 Close(STQ);
 End;

Procedure tFDOutbound.PurgeArchsDir(Dir: String);
Var
{$IfDef SPEED}
  SRec: TSearchRec;
{$Else}
  SRec: SearchRec;
{$EndIf}
  l: Byte;

 Begin
 SRec.Name := Dir + DirSep+ '*.*';
 FindFirst(SRec.Name, AnyFile, SRec);
 While (DosError = 0) do
  Begin
  l := Length(SRec.Name);
  If (SRec.Attr and Directory) = 0 then
   Begin
   If (SRec.Name[l-3] = '.') and (UpCase(SRec.Name[l-2]) = 'C') then
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
       LogSetCurLevel(lh, 1);
       LogWriteLn(lh, 'tFDOutbound: Couldn''t delete '+Dir+DirSep+SRec.Name+'!');
       End
      Else WriteLn(' Done');
      End;
     End;
    End;
   End
  Else If (SRec.Name[1] <> '.') then PurgeArchsDir(Dir + DirSep + SRec.Name);
  FindNext(SRec);
  End;
 End;


Begin
End.

