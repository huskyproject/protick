Program ProTick;
{$I-}{$Q-}
{$ifdef SPEED}
{$Else}
 {$ifdef VIRTUALPASCAL}
  {$Define VP}
  {$M 65520}
 {$Else}
  {$M 65520, 0, 655360}
 {$endif}
{$endif}
{$ifdef FPC}
 {$PackRecords 1}
{$endif}

Uses
{$ifdef SPEED}
  BseDOS, BseDev,
{$endif}
{$ifdef UNIX}
 {$ifdef FPC}
  linux,
 {$endif}
{$endif}
{$ifndef __GPC__}
  DOS,
{$endif}
{$ifndef __GPC__}
  strings,
{$endif}
  MKGlobT, MKMisc, MKMsgAbs, MKMsgFid, MKMsgEzy, MKMsgJam, MKMsgHud, MKMsgSqu,
  Types, GeneralP,
  CRC, Log, IniFile,
  PTRegKey,
  TickCons, TickType, PTProcs, PTVar, PTMsg, PTOut,
{$ifdef FIDOCONF}
  smapi, fidoconf, PTFConf;
{$Else}
  PTCfg;
{$endif}
{$ifdef VP}
 {$ifdef VPDEMO}
  {$Dynamic VP11DEMO.LIB}
 {$endif}
{$endif}

Procedure Toss; Forward;
Procedure Hatch; Forward;
Procedure NewFilesHatch; Forward;
Procedure Scan; Forward;
Procedure Maint; Forward;
Procedure _Pack; Forward;

Procedure CheckBsy; Forward;
Procedure Init; Forward;
Procedure DispAnnList; Forward;
Procedure Syntax; Forward;
Procedure SendTic(Usr: PUser; Tic: PTick; FName: String); Forward;
Function CheckForDupe(Tic:PTick):Boolean; Forward;
Procedure WriteDupe(Tic:PTick); Forward;
Procedure WriteLName(Path: DirStr; SName: String12; LName: String40); Forward;
Procedure AddAnnFile(ar: String; fn: String; desc: PChar2; From: TNetAddr); Forward;
Procedure DoAnnounce; Forward;
Procedure DoNMAnn; Forward;

Procedure Done; Far;
Var
  f: Text;

  Begin
  WriteLn('MemAvail: ', MemAvail);
  If Debug then
    Begin
    WriteLn('<Return>');
    ReadLn;
    End;
  FreeMem(HDesc, 65535);
  Ini.WriteIni;
  Ini.Done;
  If CreatedBsy then
   Begin
   Assign(f, Cfg^.FlagDir + DirSep+'protick.bsy');
   {$I-} Erase(f); {$I+}
   If (IOResult <> 0) then
     Begin
     LogSetCurLevel(LogHandle, 1);
     LogWriteLn(LogHandle, 'Couldn''t delete '+Cfg^.FlagDir+DirSep+
      'protick.bsy');
     End;
   End;
  CloseLog(LogHandle);
  LogDone;
  DispAnnList;
  If (Cfg^.Areas <> Nil) then
    Begin
    CurArea := Cfg^.Areas;
      Repeat
      If CurArea^.Next <> Nil then CurArea := CurArea^.Next
      Else If CurArea^.Prev <> Nil then
        Begin
        CurArea := CurArea^.Prev;
        If CurArea^.Next^.Users <> Nil then
          Begin
          CurConnUser:= CurArea^.Next^.Users;
            Repeat
            If CurConnUser^.Next <> Nil then CurConnUser := CurConnUser^.Next
            Else If CurConnUser^.Prev <> Nil then
              Begin
              CurConnUser := CurConnUser^.Prev;
              Dispose(CurConnUser^.Next);
              CurConnUser^.Next := Nil;
              End;
            Until (CurConnUser = CurArea^.Next^.Users);
          Dispose(CurArea^.Next^.Users);
          CurArea^.Next^.Users := Nil;
          End;
        Dispose(CurArea^.Next);
        CurArea^.Next := Nil;
        End;
      Until (CurArea = Cfg^.Areas);
    If CurArea^.Users <> Nil then
      Begin
      CurConnUser:=CurArea^.Users;
        Repeat
        If CurConnUser^.Next <> Nil then CurConnUser := CurConnUser^.Next
        Else If CurConnUser^.Prev <> Nil then
          Begin
          CurConnUser := CurConnUser^.Prev;
          Dispose(CurConnUser^.Next);
          CurConnUser^.Next := Nil;
          End;
        Until (CurConnUser = CurArea^.Users);
      Dispose(CurArea^.Users);
      CurArea^.Users := Nil;
      End;
    Dispose(Cfg^.Areas);
    Cfg^.Areas := Nil;
    End;
  If (Cfg^.Users <> Nil) then
    Begin
    CurUser := Cfg^.Users;
      Repeat
      If CurUser^.Next <> Nil then CurUser := CurUser^.Next
      Else If CurUser^.Prev <> Nil then
        Begin
        CurUser := CurUser^.Prev;
        Dispose(CurUser^.Next);
        CurUser^.Next := Nil;
        End;
      Until (CurUser = Cfg^.Users);
    Dispose(Cfg^.Users);
    Cfg^.Users := Nil;
    End;
  If (Cfg^.UpLinks <> Nil) then
    Begin
    CurUpLink := Cfg^.UpLinks;
      Repeat
      If CurUpLink^.Next <> Nil then CurUpLink := CurUpLink^.Next
      Else If CurUpLink^.Prev <> Nil then
        Begin
        CurUpLink := CurUpLink^.Prev;
        Dispose(CurUpLink^.Next);
        CurUpLink^.Next := Nil;
        End;
      Until (CurUpLink = Cfg^.UpLinks);
    Dispose(Cfg^.UpLinks);
    Cfg^.UpLinks := Nil;
    End;
  If (AutoAddList <> Nil) then
    Begin
    CurAutoAddList := AutoAddList;
      Repeat
      If CurAutoAddList^.Next <> Nil then CurAutoAddList := CurAutoAddList^.Next
      Else If CurAutoAddList^.Prev <> Nil then
        Begin
        CurAutoAddList := CurAutoAddList^.Prev;
        Dispose(CurAutoAddList^.Next);
        CurAutoAddList^.Next := Nil;
        End;
      Until (CurAutoAddList = AutoAddList);
    Dispose(AutoAddList);
    AutoAddList := Nil;
    End;
  If (TossList <> Nil) then
    Begin
    CurTossList := TossList;
      Repeat
      If CurTossList^.Next <> Nil then CurTossList := CurTossList^.Next
      Else If CurTossList^.Prev <> Nil then
        Begin
        CurTossList := CurTossList^.Prev;
        Dispose(CurTossList^.Next);
        CurTossList^.Next := Nil;
        End;
      Until (CurTossList = TossList);
    Dispose(TossList);
    TossList := Nil;
    End;
  Dispose(Cfg);
  Dispose(Outbound, Done);
  Cfg := Nil;
  WriteLn('MemAvail: ', MemAvail);
  End;

Procedure CheckBsy;
Var
  f: File;
  s: String;

  Begin
  s := Cfg^.FlagDir; {FPC doesn't like "Cfg^.FlagDir+DirSep+'ProTick.BSY'" :( }
  Assign(f, s + DirSep+'protick.bsy');
  {$I-} ReSet(f); {$I+}
  If (IOResult = 0) then
   Begin
   WriteLn('protick.bsy found - aborting');
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'protick.bsy found - aborting');
   Close(f);
   Done;
   Halt(Err_Bsy);
   End
  Else
   Begin
   {$I-} ReWrite(f); {$I+}
   If (IOResult <> 0) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Couldn''t create '+Cfg^.FlagDir+DirSep+
     'protick.bsy!');
    Done;
    Halt(Err_Bsy);
    End;
   Close(f);
   End;
  CreatedBsy := True;
  End;


Procedure Syntax;
  Begin
  WriteLn('Syntax: ProTick <Command> [options]');
  WriteLn;
  WriteLn('Valid commands:');
  WriteLn('TOSS                          - Process TICs');
  WriteLn('SCAN                          - Scan for Mails');
  WriteLn('HATCH                         - Hatch file');
  WriteLn('NEWFILESHATCH / NFH           - Hatch new files');
  WriteLn('MAINT                         - daily maintenance');
  WriteLn('PACK                          - create archives');
  WriteLn('CHECK                         - check config');
  WriteLn;
  WriteLn('Valid options:');
  WriteLn('-D[ebug]                      - debug mode');
  WriteLn('-C<Config>                    - use <Config> as config');
  WriteLn('-nodupe                       - do not perform dupechecking');
  WriteLn('File=<File>                   - [H] file');
  WriteLn('Area=<Area>                   - [H] area');
  WriteLn('Desc=<Desc>                   - [H] description');
  WriteLn('Replace=<FileMask>            - [H] files to replace');
  WriteLn('Move=<Yes|No|0|1|True|False>  - [H] delete files after hatching');
  WriteLn('PW=<PassWord>                 - [H] password');
  WriteLn('H = Hatch');
  WriteLn;
  End;


Procedure Init;
Var
  i: ULong;
  Error: Integer;
  s, s1: String;
  f: Text;

  Begin
  WriteLn('MemAvail: ', MemAvail);
  Version := _Version;
  CurAnnArea := NIL;
  CurAnnFile := NIL;
  AnnAreas := NIL;
  AnnFiles := NIL;
  MainDone := ProTick.Done;
  HArea := '';
  HFile := '';
  HFrom := EmptyAddr;
  HTo := EmptyAddr;
  HOrigin := EmptyAddr;
  HReplace := '';
  HMove := False;
  HPW := '';
  AutoAddList := NIL;
  TossList := NIL;
  CurAutoAddList := NIL;
  CurTossList := NIL;
  CreatedBsy := False;
  Randomize;
{$ifdef SPEED}
  ExecViaSession := False;
  AsynchExec := False;
{$endif}
  GetMem(HDesc, 65535);
  HDesc^[0] := #0;
  If (RegInfo.Ver <> 0) then
    Begin
    Version := _Version + '+ #' + IntToStr(RegInfo.Serial);
    WriteLn('ProTick'+Version);
    With RegInfo do WriteLn('Registered to '+Name+' ('+Addr2Str(Addr)+')');
    Case RegInfo.Ver of
      1: Write('noncommercial version, ');
      2: Write('commercial version, ');
      3: Write('author version, ');
      End;
    If (RegInfo.Copies = 0) then WriteLn('unlimited copies')
    Else WriteLn(RegInfo.Copies, ' copies');
    End
  Else
    Begin
    Version := _Version + ' unreg';
    WriteLn('ProTick'+Version);
    End;
  Debug := False;
  DupeCheck := True;
  Command := '';
  FSplit(ParamStr(0), s1, s, s);
  s := GetEnv('PT');
{$ifdef UNIX}
  s := FSearch('protick.cfg', '.;'+s+';/etc/fido');
{$Else}
  s := FSearch('protick.cfg', '.;'+s+';c:\fido;'+s1);
{$endif}
  CfgName := s;
  If (ParamCount < 1) then
    Begin
    Syntax;
    Halt(Err_NoParams);
    End;
  For i := 1 to ParamCount do
    Begin
    s := RepEnv(UpStr(ParamStr(i)));
    If (Pos('-D', s) = 1) then Debug := True
    Else If (Pos('-C', s) = 1) then CfgName := RepEnv(Copy(ParamStr(i), 3, Length(s) - 2))
    Else If (s = '-NODUPE') then DupeCheck := False
    Else If (s = 'SCAN') then Command := s
    Else If (s = 'TOSS') then Command := s
    Else If (s = 'HATCH') then Command := s
    Else If (s = 'NEWFILESHATCH') then Command := s
    Else If (s = 'NFH') then Command := 'NEWFILESHATCH'
    Else If (s = 'MAINT') then Command := s
    Else If (s = 'PACK') then Command := s
    Else If (s = 'CHECK') then Command := s
    Else If (Pos('AREA', s) = 1) then HArea := RepEnv(Copy(ParamStr(i), 6, Length(s) - 5))
    Else If (Pos('FILE', s) = 1) then HFile := RepEnv(Copy(ParamStr(i), 6, Length(s) - 5))
    Else If (Pos('DESC', s) = 1) then StrPCopy(Pointer(HDesc),
      Translate(RepEnv(Copy(ParamStr(i), 6, Length(s) - 5)), '_', ' '))
    Else If (Pos('PASSWORD', s) = 1) then HPW := RepEnv(Copy(ParamStr(i), 10, Length(s) - 9))
    Else If (Pos('PWD', s) = 1) then HPW := RepEnv(Copy(ParamStr(i), 5, Length(s) - 4))
    Else If (Pos('PW', s) = 1) then HPW := RepEnv(Copy(ParamStr(i), 4, Length(s) - 3))
    Else If (Pos('REPLACE', s) = 1) then HReplace := RepEnv(Copy(ParamStr(i), 9, Length(s) - 8))
    Else If (Pos('MOVE', s) = 1) then
      Begin
      s := UpStr(RepEnv(Copy(s, 6, Length(s) - 5)));
      HMove := (s = 'TRUE') or (s = 'ON') or (s = '1') or (s[1] = 'Y') or (s[1] = 'J');
      End
    Else
      Begin
      WriteLn('Unknown command "'+s+'"');
      Syntax;
      Halt(Err_UnknownCommand);
      End;
    End;
  If (CfgName = '') then
   Begin
   WriteLn('Could not locate config!');
   Halt(Err_NoCfg);
   End
  Else If not FileExist(CfgName) then
   Begin
   WriteLn('Couldn''t open "'+CfgName+'"!');
   Halt(Err_NoCfg);
   End;
  WriteLn;
  ParseCfg;
  Case Cfg^.OBType of
   OB_BT: Outbound := New(pBTOutbound, Init(Cfg, LogHandle, Cfg^.Outbound, Cfg^.Addrs[1]));
   OB_FD: Outbound := New(pFDOutbound, Init(Copy(Cfg^.Outbound, 1,
    Pos(',', Cfg^.Outbound)-1), Copy(Cfg^.Outbound, Pos(',', Cfg^.Outbound)+1,
    Length(Cfg^.Outbound)), LogHandle, Cfg^.TicOut, Cfg^.FlagDir));
   {OB_TMail: Outbound := New(pTMailOutbound, Init); }
   Else
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Invalid outbound type!');
    Done;
    Halt(Err_Internal);
    End;
   End;
  CheckBsy;
  End;

Procedure Toss;
Var
  FName: String;
{$ifdef SPEED}
  SRec: TSearchRec;
{$Else}
  SRec: SearchRec;
{$endif}
  f: Text;
  Line: String;
  Tic: PTick;
{$ifdef VIRTUALPASCAL}
  Error: LongInt;
{$Else}
  Error: Integer;
{$endif}
  s: String;
  s1: String;
  i: LongInt;
  DT: TimeTyp;
  ACArea: PArea;
  ACCUser: PConnectedUser;
  a: TNetAddr;
  bo: Boolean;
  Local: Boolean;
  PPos, j: Word;
  PT: Boolean;

  Procedure ParseTIC;
    Begin
    While not EOF(f) do
      Begin
      {$I-} ReadLn(f, Line); {$I+}
      If (Line[Byte(Line[0])] = #13) then Line[0] := Char(Byte(Line[0])-1);
      If (IOResult <> 0) then
        Begin
        LogSetCurLevel(LogHandle, 1);
        LogWriteLn(LogHandle, 'Error reading "' + Cfg^.InBound+DirSep+
         SRec.Name+'"!');
        End;
      If (Line = '') then
      Else If (Pos('AREA ', UpStr(Line)) = 1) or (Pos('AREA:', UpStr(Line)) = 1) then
        Begin
        Delete(Line, 1, 5);
        Tic^.Area := UpStr(KillLeadingSpcs(Line));
        LogSetCurLevel(LogHandle, 3);
        LogWriteLn(LogHandle, 'Area '+Tic^.Area);
        End
      Else If (Pos('AREADESC ', UpStr(Line)) = 1) or (Pos('AREADESC:', UpStr(Line)) = 1) then
        Begin
        Delete(Line, 1, 9);
        Tic^.AreaDesc := KillLeadingSpcs(Line);
        LogSetCurLevel(LogHandle, 5);
        LogWriteLn(LogHandle, 'AreaDesc '+ Tic^.AreaDesc);
        End
      Else If (Pos('RELEASE ', UpStr(Line)) = 1) or (Pos('RELEASE:', UpStr(Line)) = 1) then
        Begin
        Delete(Line, 1, 8);
        Val('$' + KillLeadingSpcs(Line), Tic^.ReleaseTime, Error);
        LogSetCurLevel(LogHandle, 3);
        LogWriteLn(LogHandle, 'Release '+ IntToStr(Tic^.ReleaseTime));
        End
      Else If (Pos('REPLACES ', UpStr(Line)) = 1) or (Pos('REPLACES:', UpStr(Line)) = 1) then
        Begin
        Delete(Line, 1, 9);
        Tic^.Replaces := LowStr(KillLeadingSpcs(Line));
        LogSetCurLevel(LogHandle, 3);
        LogWriteLn(LogHandle, 'Replaces '+Tic^.Replaces);
        End
      Else If (Pos('FILE ', UpStr(Line)) = 1) or (Pos('FILE:', UpStr(Line)) = 1) then
        Begin
        Delete(Line, 1, 5);
        LogSetCurLevel(LogHandle, 3);
        Tic^.Name := LowStr(KillLeadingSpcs(Line));
        LogWriteLn(LogHandle, 'File "'+Tic^.Name+'"');
        End
      Else If (Pos('SIZE ', UpStr(Line)) = 1) or (Pos('SIZE:', UpStr(Line)) = 1) then
        Begin
        Delete(Line, 1, 5);
        Val(KillLeadingSpcs(Line), Tic^.Size, Error);
        LogSetCurLevel(LogHandle, 4);
        LogWriteLn(LogHandle, 'Size '+IntToStr(Tic^.Size));
        End
      Else If (Pos('DATE ', UpStr(Line)) = 1) or (Pos('DATE:', UpStr(Line)) = 1) then
        Begin
        Delete(Line, 1, 5);
        Val('$' + KillLeadingSpcs(Line), Tic^.Date, Error);
        LogSetCurLevel(LogHandle, 4);
        LogWriteLn(LogHandle, 'Date '+ IntToStr(Tic^.Date));
        End
      Else If (Pos('CREATED ', UpStr(Line)) = 1) or (Pos('CREATED:', UpStr(Line)) = 1) then
        Begin
        Delete(Line, 1, 8);
        Tic^.CreatedBy := KillLeadingSpcs(Line);
        LogSetCurLevel(LogHandle, 5);
        LogWriteLn(LogHandle, 'Created '+Tic^.CreatedBy);
        End
      Else If (Pos('CRC ', UpStr(Line)) = 1) or (Pos('CRC:', UpStr(Line)) = 1) then
        Begin
        Delete(Line, 1, 4);
        Val('$' + KillLeadingSpcs(Line), Tic^.CRC, Error);
        LogSetCurLevel(LogHandle, 3);
        LogWriteLn(LogHandle, 'CRC '+WordToHex(word(Tic^.CRC SHR 16))+ WordToHex(word(Tic^.CRC mod 65536)));
        End
      Else If (Pos('ORIGIN ', UpStr(Line)) = 1) or (Pos('ORIGIN:', UpStr(Line)) = 1) then
        Begin
        Delete(Line, 1, 7);
        Str2Addr(Line, Tic^.Origin);
        LogSetCurLevel(LogHandle, 4);
        LogWriteLn(LogHandle, 'Origin '+Addr2Str(Tic^.Origin));
        End
      Else If (Pos('FROM ', UpStr(Line)) = 1) or (Pos('FROM:', UpStr(Line)) = 1) then
        Begin
        Delete(Line, 1, 5);
        Str2Addr(Line, Tic^.From);
        LogSetCurLevel(LogHandle, 3);
        LogWriteLn(LogHandle, 'From '+Addr2Str(Tic^.From));
        End
      Else If (Pos('TO ', UpStr(Line)) = 1) or (Pos('TO:', UpStr(Line)) = 1) then
        Begin
        Delete(Line, 1, 3);
        If (Pos(',', Line) = 0) then
          Begin
          LogSetCurLevel(LogHandle, 4);
          If (Pos(':', Line) <> 0) and (Pos('/', Line) <> 0) then
            Begin
            Str2Addr(Line, Tic^._To);
            LogWriteLn(LogHandle, 'To '+Addr2Str(Tic^._To));
            End
          Else
            Begin
            Tic^.ToName := Line;
            LogWriteLn(LogHandle, 'To '+Tic^.ToName);
            End;
          End
        Else
          Begin
          Tic^.ToName := Copy(Line, 1, Pos(',', Line) - 1);
          Str2Addr(Copy(Line, Pos(',', Line) + 1, Length(Line) - Pos(',', Line)), Tic^._To);
          LogSetCurLevel(LogHandle, 4);
          LogWriteLn(LogHandle, 'To '+Tic^.ToName+', '+Addr2Str(Tic^._To));
          End;
        End
      Else If (Pos('TONAME ', UpStr(Line)) = 1) or (Pos('TONAME:', UpStr(Line)) = 1) then
        Begin
        Delete(Line, 1, 7);
        Tic^.ToName := Line;
        LogSetCurLevel(LogHandle, 4);
        LogWriteLn(LogHandle, 'ToName '+Tic^.ToName);
        End
      Else If (Pos('DEST ', UpStr(Line)) = 1) or (Pos('DEST:', UpStr(Line)) = 1) then
        Begin
        Delete(Line, 1, 5);
        Str2Addr(Line, Tic^._To);
        LogSetCurLevel(LogHandle, 4);
        LogWriteLn(LogHandle, 'Dest '+Addr2Str(Tic^._to));
        End
      Else If (Pos('DESTINATION ', UpStr(Line)) = 1) or (Pos('DESTINATION:', UpStr(Line)) = 1) then
        Begin
        Delete(Line, 1, 12);
        Str2Addr(Copy(Line, 1, Pos(',', Line) - 1), Tic^._To );
        Delete(Line, 1, Pos(',', Line));
        Tic^.ToName := Line;
        LogSetCurLevel(LogHandle, 4);
        LogWriteLn(LogHandle, 'Dest '+Addr2Str(Tic^._to));
        End
      Else If (Pos('DESC ', UpStr(Line)) = 1) or (Pos('DESC:', UpStr(Line)) = 1) then
        Begin
        Delete(Line, 1, 5);
        Tic^.Desc := KillLeadingSpcs(Line);
        LogSetCurLevel(LogHandle, 3);
        LogWriteLn(LogHandle, 'Desc '+ Tic^.Desc);
        End
      Else If (Pos('LDESC ', UpStr(Line)) = 1) or (Pos('LDESC:', UpStr(Line)) = 1) then
        Begin
        Delete(Line, 1, 6);
        Inc(Tic^.NumLDesc);
        Tic^.LDesc[Tic^.NumLDesc] := KillLeadingSpcs(Line);
        LogSetCurLevel(LogHandle, 3);
        LogWriteLn(LogHandle, 'LDesc '+Tic^.LDesc[Tic^.NumLDesc]);
        End
      Else If (Pos('ERROR ', UpStr(Line)) = 1) or (Pos('ERROR:', UpStr(Line)) = 1) then
        Begin
        Delete(Line, 1, 6);
        LogSetCurLevel(LogHandle, 3);
        LogWriteLn(LogHandle, 'Previous error '+Line);
        End
      Else If (Pos('SEENBY ', UpStr(Line)) = 1) or (Pos('SEENBY:', UpStr(Line)) = 1) then
        Begin
        Delete(Line, 1, 7);
        s := KillLeadingSpcs(Line);
        While (Pos(' ', s) <> 0) do
          Begin
          Inc(Tic^.NumSB);
          Str2Addr(Copy(s, 1, Pos(' ', s) - 1), Tic^.SeenBy[Tic^.NumSB]);
          With Tic^ do If NumSB > 1 then
            Begin
            if SeenBy[NumSB].Zone = 0 then SeenBy[NumSB].Zone := SeenBy[NumSB-1].Zone;
            if SeenBy[NumSB].Net = 0 then SeenBy[NumSB].Net := SeenBy[NumSB-1].Net;
            end;
          LogSetCurLevel(LogHandle, 5);
          LogWriteLn(LogHandle, 'SeenBy '+ Addr2Str(Tic^.SeenBy[Tic^.NumSB]));
          Delete(s, 1, Pos(' ', s));
          End;
        Inc(Tic^.NumSB);
        Str2Addr(s, Tic^.SeenBy[Tic^.NumSB]);
        With Tic^ do If NumSB > 1 then
          Begin
          if SeenBy[NumSB].Zone = 0 then SeenBy[NumSB].Zone := SeenBy[NumSB-1].Zone;
          if SeenBy[NumSB].Net = 0 then SeenBy[NumSB].Net := SeenBy[NumSB-1].Net;
          if SeenBy[NumSB].Node = 0 then SeenBy[NumSB].Node := SeenBy[NumSB-1].Node;
          end;
        LogSetCurLevel(LogHandle, 5);
        LogWriteLn(LogHandle, 'SeenBy '+ Addr2Str(Tic^.SeenBy[Tic^.NumSB]));
        End
      Else If (Pos('PATH ', UpStr(Line)) = 1) or (Pos('PATH:', UpStr(Line)) = 1) then
        Begin
        Delete(Line, 1, 5);
        Inc(Tic^.NumPath);
        Tic^.Path[Tic^.NumPath] := KillLeadingSpcs(Line);
        LogSetCurLevel(LogHandle, 4);
        LogWriteLn(LogHandle, 'Path '+ Tic^.Path[Tic^.NumPath]);
        End
      Else If (Pos('PW ', UpStr(Line)) = 1) or (Pos('PW:', UpStr(Line)) = 1) then
        Begin
        Delete(Line, 1, 3);
        Tic^.Pwd := UpStr(KillSpcs(Line));
        {LogSetCurLevel(LogHandle, 5);
        LogWriteLn(LogHandle, 'PassWord '+Tic^.Pwd);}
        End
      Else
        Begin
        Inc(Tic^.NumApp);
        Tic^.App[Tic^.NumApp] := Line;
        LogSetCurLevel(LogHandle, 4);
        LogWriteLn(LogHandle, 'App '+Tic^.App[Tic^.NumApp]);
        End;
      End;

    If (Pos('BY FILESCAN', UpStr(Tic^.CreatedBy)) = 1) then
      Begin
      Tic^.Date := 0;
      LogSetCurLevel(LogHandle, 3);
      LogWriteLn(LogHandle, 'Tic created by FileScan - ignoring date');
      End;
    End; {ParseTIC}

  Begin {Toss}
  LogSetCurLevel(LogHandle, 3);
  LogWriteLn(LogHandle, 'Toss');
  FSplit(CfgName, s, s1, s1);
  Assign(ArcList, Cfg^.ArcLst);
{$ifdef SPEED}
  {$I-} Append(ArcList); {$I+}
  If (IOResult <> 0) then
    Begin
    {$I-} ReWrite(ArcList); {$I+}
    If (IOResult <> 0) then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Couldn''t open "'+Cfg^.arcLst+'"!');
      Done;
      Halt(Err_ArcList);
      End;
    End;
{$Else}
 {$ifdef FPC}
  If (DosAppend(ArcList) <> 0) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Couldn''t open "'+Cfg^.arcLst+'"!');
    Done;
    Halt(Err_ArcList);
    End;
 {$Else}
  If (DosAppend(File(ArcList)) <> 0) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Couldn''t open "'+Cfg^.ArcLst+'"!');
    Done;
    Halt(Err_ArcList);
    End;
 {$endif}
{$endif}
  Assign(PTList, Cfg^.PTLst);
{$ifdef SPEED}
  {$I-} Append(PTList); {$I+}
  If (IOResult <> 0) then
    Begin
    {$I-} ReWrite(PTList); {$I+}
    If (IOResult <> 0) then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Couldn''t open "'+Cfg^.PTLst+'"!');
      Done;
      Halt(Err_PTList);
      End;
    End;
{$Else}
 {$ifdef FPC}
  If (DosAppend(PTList) <> 0) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Couldn''t open "'+Cfg^.PTLst+'"!');
    Done;
    Halt(Err_PTList);
    End;
 {$Else}
  If (DosAppend(File(PTList)) <> 0) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Couldn''t open "'+Cfg^.PTLst+'"!');
    Done;
    Halt(Err_PTList);
    End;
 {$endif}
{$endif}
  If (Cfg^.NumArcNames > 0) then
   Begin
   LogSetCurLevel(LogHandle, 5);
   LogWriteLn(LogHandle, 'Searching for ARCs');
   For i := 1 to Cfg^.NumArcNames do
     Begin
     FName := Cfg^.InBound + DirSep + Cfg^.ArcNames[i].FileName;
     SRec.Name := FName;
     FindFirst(FName, AnyFile, SRec);
     While (DosError = 0) Do
       Begin
       LogSetCurLevel(LogHandle, 3);
       LogWriteLn(LogHandle, 'Processing '+Cfg^.InBound+DirSep+SRec.Name);
       If not UnPack(Cfg^.ArcNames[i].UnPacker, Cfg^.InBound+DirSep+
        SRec.Name, Cfg^.InBound) then
        Begin
        LogSetCurLevel(LogHandle, 2);
        LogWriteLn(LogHandle, 'Could not unpack "'+Cfg^.InBound+DirSep+
         SRec.Name+'"!');
        End
       Else
        Begin
        Assign(f, Cfg^.InBound+DirSep+SRec.Name);
        {$I-} Erase(f); {$I+}
        If IOResult <> 0 then
          Begin
          LogSetCurLevel(LogHandle, 1);
          LogWriteLn(LogHandle, 'Couldn''t erase "'+Cfg^.InBound+DirSep+
           SRec.Name+'"');
          End;
        End;
       FindNext(SRec);
       End;
{$ifdef OS2}
     FindClose(SRec);
{$endif}
     End;
   If Debug then
     Begin
     WriteLn('<Return>');
     ReadLn(s);
     If (UpStr(s) = 'BREAK') then
       Begin
       Exit;
       End;
     End;
   End;
  LogSetCurLevel(LogHandle, 5);
  LogWriteLn(LogHandle, 'Searching for TICs');
  New(Tic);
  FName := Cfg^.InBound + DirSep+'*.tic';
  SRec.Name := FName;
  FindFirst(FName, AnyFile, SRec);
  While (DosError = 0) Do
    Begin
    LogSetCurLevel(LogHandle, 3);
    LogWriteLn(LogHandle, '');
    LogWriteLn(LogHandle, 'Processing '+ Cfg^.InBound+DirSep+SRec.Name);
    Assign(f, Cfg^.InBound+DirSep+SRec.Name);
    {$I-} ReSet(f); {$I+}
    If IOResult <> 0 then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Couldn''t open "'+Cfg^.InBound+DirSep+SRec.Name+'"');
      FindNext(SRec);
      Continue;
      End;
     FillChar(Tic^, SizeOf(TTick), 0);
    ParseTIC;
    WriteLn;
    {$I-} Close(f); {$I+}
    If IOResult <> 0 then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Couldn''t close "'+Cfg^.InBound+DirSep+
       SRec.Name+'"');
      End;
    If Debug then
      Begin
      WriteLn('<Return>');
      ReadLn(s);
      If (UpStr(s) = 'BREAK') then
        Begin
{$ifdef OS2}
        FindClose(SRec);
{$endif}
        Dispose(Tic);
        Tic := Nil;
        Exit;
        End;
      End;
{TIC read, now process it...}
    With Tic^._To do bo := (Zone = 0) and (Net = 0) and (Node = 0) and (Point = 0) and (Domain = '');
    bo := bo or (Not Cfg^.CheckDest);
    For i := 1 to Cfg^.NumAddrs do bo := bo or CompAddr(Tic^._To, Cfg^.Addrs[i]);
    If not bo then
      Begin
      LogSetCurLevel(LogHandle, 2);
      LogWriteLn(LogHandle, 'Tic is not for us but for '+Addr2Str(Tic^._To));
      Tic^.Bad := bt_NotForUs;
      End
    Else
      Begin
      Local := False;
      For i := 1 to Cfg^.NumAddrs do Local := Local or CompAddr(Tic^.From, Cfg^.Addrs[i]);
      CurArea := Cfg^.Areas;
      While ((CurArea^.Next <> Nil) and (UpStr(CurArea^.Name) <> Tic^.Area)) do
        Begin
        CurArea := CurArea^.Next;
        End;
      If (UpStr(CurArea^.Name) <> Tic^.Area) then
        Begin
        CurUser := Cfg^.Users;
        While ((not CompAddr(CurUser^.Addr, Tic^.From)) or
          ((CurUser^.Addr.Zone = 0) and (CurUser^.Addr.Net = 0))) and
          (CurUser^.Next <> Nil) do CurUser := CurUser^.Next;
        If not (CompAddr(CurUser^.Addr, Tic^.From) or local) then
          Begin
          LogSetCurLevel(LogHandle, 2);
          LogWriteLn(LogHandle, 'Unlisted sender: '+Addr2Str(Tic^.From));
          Tic^.Bad := bt_Unlisted;
          End
        Else
          Begin
          If (not Local) then s := CurUser^.Pwd Else s := Cfg^.LocalPwd;
          If (Tic^.Pwd <> UpStr(s)) then
            Begin
            Tic^.Bad := bt_WrongPwd;
            LogSetCurLevel(LogHandle, 2);
            LogWriteLn(LogHandle, 'Wrong password! Tic: "'+Tic^.Pwd+'", User: "'+s+'"');
            End
          Else
            Begin
            If ((CurUser^.Flags and uf_AutoCreate) <> uf_AutoCreate) or (Tic^.Area = '') then
              Begin
              LogSetCurLevel(LogHandle, 2);
              LogWriteLn(LogHandle, 'Unknown area: "'+ Tic^.Area+ '"');
              Tic^.Bad := bt_UnknownArea;
              End
            Else
              Begin
              ACArea := Cfg^.Areas;
              While ((UpStr(ACArea^.Name) <>
                ('AUTOCREATE:'+IntToStr(CurUser^.ACGroup))) and (ACArea^.Next <> Nil)) do
                Begin
                ACArea := ACArea^.Next;
                End;
              If (UpStr(ACArea^.Name) <> 'AUTOCREATE:'+IntToStr(CurUser^.ACGroup)) then
                Begin
                LogSetCurLevel(LogHandle, 1);
                LogWriteLn(LogHandle, 'No AutoCreate defaults for group '+IntToStr(CurUser^.ACGroup)+' found!');
                Tic^.Bad := bt_UnknownArea;
                End
              Else
                Begin
                New(CurArea^.Next);
                CurArea^.Next^.Prev := CurArea;
                CurArea := CurArea^.Next;
                CurArea^.Next := Nil;

                CurArea^.Path := ACArea^.Path;
                CurArea^.Desc := ACArea^.Desc;
                CurArea^.BBSArea := ACArea^.BBSArea;
                CurArea^.MoveTo := ACArea^.MoveTo;
                CurArea^.ReplaceExt := ACArea^.ReplaceExt;
                CurArea^.Group := ACArea^.Group;
                CurArea^.Level := ACArea^.Level;
                CurArea^.Addr := ACArea^.Addr;
                CurArea^.Flags := ACArea^.Flags;
                CurArea^.CostPerMB := ACArea^.CostPerMB;
                CurArea^.AnnGroups := ACArea^.AnnGroups;
                If (ACArea^.Users <> NIL) then
                  Begin
                  ACCUser := ACArea^.Users;
                  New(CurArea^.Users);
                  CurConnUser := CurArea^.Users;
                  CurConnUser^.User := ACCUser^.User;
                  CurConnUser^.Receive := ACCUser^.Receive;
                  CurConnUser^.Send := ACCUser^.Send;
                  If (ACCUser^.Next <> NIL) Then
                    Repeat
                    ACCUser := ACCUser^.Next;
                    New(CurConnUser^.Next);
                    CurConnUser^.Next^.Prev := CurConnUser;
                    CurConnUser := CurConnUser^.Next;
                    CurConnUser^.Next := Nil;
                    CurConnUser^.User := ACCUser^.User;
                    CurConnUser^.Receive := ACCUser^.Receive;
                    CurConnUser^.Send := ACCUser^.Send;
                    Until (ACCUser^.Next = NIL);
                  End;

                CurArea^.Name := Tic^.Area;
                If (Tic^.AreaDesc <> '') then CurArea^.Desc := Tic^.AreaDesc;
                Today(DT);
                Now(DT);
                CurArea^.LastHatch := DTToUnixDate(DT);
                s1 := Lowstr(CurArea^.Name);
                If Cfg^.SplitDirs then
                 Begin
                 s1 := Translate(s1, ' ', DirSep);
                 s1 := Translate(s1, '.', DirSep);
                 s1 := Translate(s1, '_', DirSep);
                 s1 := Translate(s1, '/', DirSep);
                 s1 := Translate(s1, '-', DirSep);
                 End
                Else
                 Begin
                 s1 := Translate(s1, ' ', '_');
                 s1 := Translate(s1, '/', '_');
                 End;
                s := '';
                If not Cfg^.LongDirNames then
                 Begin
                 If (Length(s1) > 8) then
                  Begin
                  While (Length(s1) > 8) do
                   Begin
                   If (Pos(DirSep, s1) > 8) or (Pos(DirSep, s1) = 0) then
                    Begin
                    s := s + Copy(s1, 1, 8) + DirSep;
                    Delete(s1, 1, 8);
                    End
                   Else
                    Begin
                    s := s + Copy(s1, 1, Pos(DirSep, s1));
                    Delete(s1, 1, Pos(DirSep, s1));
                    End;
                   End;
                  s := s + s1;
                  End
                 Else s := s1;
                 End
                Else s := s1;
                CurArea^.Path := CurArea^.Path + DirSep + s;

                If (not MakeDir(CurArea^.Path)) then
                  Begin
                  LogSetCurLevel(LogHandle, 1);
                  LogWriteLn(LogHandle, 'Couldn''t create directory "'+CurArea^.Path+'"!');
                  End
                Else
                  Begin
                  LogSetCurLevel(LogHandle, 3);
                  LogWriteLn(LogHandle, 'Created directory "'+CurArea^.Path+'"');
                  End;
                If (CurArea^.Users = Nil) then
                  Begin
                  New(CurArea^.Users);
                  CurArea^.Users^.Next := Nil;
                  CurArea^.Users^.Prev := Nil;
                  CurArea^.Users^.User := CurUser;
                  CurArea^.Users^.Send := True;
                  CurArea^.Users^.Receive := CurUser^.Receives;
                  End
                Else
                  Begin
                  CurConnUser := CurArea^.Users;
                  While (CurConnUser^.Next <> Nil) do CurConnUser := CurConnUser^.Next;
                  New(CurConnUser^.Next);
                  CurConnUser^.Next^.Prev := CurConnUser;
                  CurConnUser := CurConnUser^.Next;
                  CurConnUser^.Next := Nil;
                  CurConnUser^.User := CurUser;
                  CurConnUser^.Send := True;
                  CurConnUser^.Receive := CurUser^.Receives;
                  End;
                CurConnUser := CurArea^.Users;
                Ini.SetSection('USER');
                  Repeat
                  While ((UpStr(Ini.ReSecEnName) <> 'ADDR') and Ini.SetNextOpt) do ;
                  Str2Addr(Ini.ReSecEnValue, A);
                  Until (CompAddr(A, CurConnUser^.User^.Addr) or (not Ini.SetNextOpt));
                s := '';
                If CurConnUser^.Receive then s := 'R';
                If CurConnUser^.Send then s := s + 'S';
                If CompAddr(A, CurConnUser^.User^.Addr) Then Ini.InsertSecEntry('Area', CurArea^.Name+', '+s, '');
                While (CurConnUser^.Next <> Nil) do
                  Begin
                  CurConnUser := CurConnUser^.Next;
                  Ini.SetSection('USER');
                    Repeat
                    While ((UpStr(Ini.ReSecEnName) <> 'ADDR') and Ini.SetNextOpt) do ;
                    Str2Addr(Ini.ReSecEnValue, A);
                    Until (CompAddr(A, CurConnUser^.User^.Addr) or (not Ini.SetNextOpt));
                  s := '';
                  If CurConnUser^.Receive then s := 'R';
                  If CurConnUser^.Send then s := s + 'S';
                  If CompAddr(A, CurConnUser^.User^.Addr) Then Ini.InsertSecEntry('Area', CurArea^.Name+', '+s, '');
                  End;
                With Ini do With CurArea^ do
                  Begin
                  SetSection('FILEAREAS');
                  While SetNextOpt do ;
                  AddSecEntry('Area', Name, '');
                  If (Desc <> '') then AddSecEntry('Desc', Desc, '');
                  If (BBSArea <> '') then AddSecEntry('BBSArea', BBSArea, '');
                  AddSecEntry('Path', Path, '');
                  If (MoveTo <> '') Then AddSecEntry('MoveTo', MoveTo, '');
                  If (ReplaceExt <> '') Then AddSecEntry('ReplaceExt', ReplaceExt, '');
                  AddSecEntry('Group', IntToStr(Group), '');
                  AddSecEntry('Level', IntToStr(Level), '');
                  AddSecEntry('Addr', Addr2Str(Addr), '');
                  AddSecEntry('LastHatch', WordToHex(word(LastHatch SHR 16))+
                   WordToHex(word(LastHatch mod 65536)), '');
                  If (CostPerMB <> 0) Then AddSecEntry('CostPerMB', IntToStr(CostPerMB), '');
                  s := '';
                  For i := 1 to 255 do If i in AnnGroups then s := s + IntToStr(i) + ',';
                  Delete(s, Length(s), 1);
                  If (s <> '') Then AddSecEntry('Announce', s, '');
                  s := '';
                  If (Flags and fa_PT) > 0 then If (s <> '') then s := s +', PT' Else s := 'PT';
                  If (Flags and fa_Dupe) > 0 then  If (s <> '') then s := s + ', Dupe' Else s := 'Dupe';
                  If (Flags and fa_CRC) > 0 then  If (s <> '') then s := s + ', CRC' Else s := 'CRC';
                  If (Flags and fa_Touch) > 0 then  If (s <> '') then s := s + ', Touch' Else s := 'Touch';
                  If (Flags and fa_Mandatory) > 0 then  If (s <> '') then s := s + ', Man' Else s := 'Man';
                  If (Flags and fa_NoPause) > 0 then  If (s <> '') then s := s + ', NoPause' Else s := 'NoPause';
                  If (Flags and fa_NewFilesHatch) > 0 then  If (s <> '') then s := s + ', Hatch' Else s := 'New';
                  If (Flags and fa_CS) > 0 then  If (s <> '') then s := s + ', CS' Else s := 'CS';
                  If (Flags and fa_RemoteChange) > 0 then  If (s <> '') then s := s + ', Rem' Else s := 'Rem';
                  If (Flags and fa_Hidden) > 0 then  If (s <> '') then s := s + ', Hid' Else s := 'Hid';
                  If (s <> '') Then AddSecEntry('Flags', s, '');
                  AddSecEntry(';', '', ' ');
                  WriteIni;
                  LogSetCurLevel(LogHandle, 2);
                  LogWriteLn(LogHandle, 'autocreated area "'+CurArea^.Name+'"');
                  AddAutoArea(CurArea^.Name);
                  End;
                End;
              End;
            End;
          End;
        End;
      CurArea := Cfg^.Areas;
      While ((CurArea^.Next <> Nil) and (UpStr(CurArea^.Name) <> Tic^.Area)) do
        Begin
        CurArea := CurArea^.Next;
        End;
      If (UpStr(CurArea^.Name) <> Tic^.Area) then
      Else
        Begin
        CurConnUser := CurArea^.Users;
        If (CurConnUser <> Nil) then While (not CompAddr(CurConnUser^.User^.Addr, Tic^.From)) and (CurConnUser^.Next <> Nil) do
          CurConnUser := CurConnUser^.Next;
        If (not Local) and ((CurConnUser = Nil) or (not CompAddr(CurConnUser^.User^.Addr, Tic^.From))) then
          Begin
          Tic^.Bad := bt_NotConnected;
          LogSetCurLevel(LogHandle, 2);
          LogWriteLn(LogHandle, Addr2Str(Tic^.From)+' not connected to Area '+ Tic^.Area);
          End
        Else
          Begin
          If not (Local or CurConnUser^.Send) then
            Begin
            Tic^.Bad := bt_NoSend;
            LogSetCurLevel(LogHandle, 2);
            LogWriteLn(LogHandle, Addr2Str(CurConnUser^.User^.Addr)+ ' not SEND-connected to '+CurArea^.Name);
            End
          Else
            Begin
            If (Tic^.CRC <> 0) and ((CurArea^.Flags and fa_CRC) = fa_CRC) Then
              Begin
              Write('Checking CRC...');
              i := GetCRC(Cfg^.InBound + DirSep + Tic^.Name);
              End
            Else i := 0;
            If (i = $FFFFFFFF) then
              Begin
              WriteLn;
              LogSetCurLevel(LogHandle, 2);
              LogWriteLn(LogHandle, 'File "'+Cfg^.InBound+DirSep+Tic^.Name+'" locked or not in InBound');
              Tic^.Bad := bt_NoFile;
              End
            Else If (i <> Tic^.CRC) and ((CurArea^.Flags and fa_CRC) = fa_CRC) then
              Begin
              WriteLn;
              LogSetCurLevel(LogHandle, 2);
              LogWriteLn(LogHandle, 'Incorrect CRC! File: '+ WordToHex(word(i SHR 16))+
               WordToHex(word(i mod 65536))+', TIC: '+ WordToHex(word(Tic^.CRC SHR 16))+
               WordToHex(word(Tic^.CRC mod 65536)));
              Tic^.Bad := bt_CRC;
              End
            Else
              Begin
              If (Tic^.CRC <> 0) and ((CurArea^.Flags and fa_CRC) = fa_CRC) then WriteLn(' OK');
              If (((CurArea^.Flags and fa_Dupe) = fa_Dupe) and CheckForDupe(Tic) and DupeCheck) then
                Begin
                Tic^.Bad := bt_Dupe;
                LogSetCurLevel(LogHandle, 2);
                LogWriteLn(LogHandle, 'Dupe!');
                End
              Else
                Begin
{Tic is OK, process it...}
                PT := (CurArea^.Flags and fa_PT) <> 0;
                If not PT and (Tic^.Replaces <> '') then ReplaceFiles(CurArea^.Path +
                 DirSep + Tic^.Replaces);
                If not PT then ReplaceFiles(CurArea^.Path + DirSep +
                 Tic^.Name);
                If PT then
                 Begin
                 If not MoveFile(Cfg^.InBound + DirSep + Tic^.Name,
                  Cfg^.PT + DirSep + Tic^.Name) then
                  Begin
                  LogSetCurLevel(LogHandle, 1);
                  LogWriteLn(LogHandle, 'Couldn''t move "'+Cfg^.InBound +
                   DirSep + Tic^.Name+'" to "'+ Cfg^.PT + DirSep +
                   Tic^.Name+'"!');
                  End;
                 End;
                If not PT and (not RepFile(Cfg^.InBound + DirSep +
                 Tic^.Name, CurArea^.Path + DirSep + Tic^.Name)) then
                  Begin
                  Tic^.Bad := bt_CouldntMove;
                  LogSetCurLevel(LogHandle, 1);
                  LogWriteLn(LogHandle, 'Couldn''t move "'+Cfg^.InBound +
                   DirSep + Tic^.Name+'" to "'+ CurArea^.Path + DirSep +
                   Tic^.Name+'"!');
                  End
                Else
                  Begin
                  If DupeCheck then WriteDupe(Tic);
                  s := UpStr(Tic^.Desc);
                  If (Pos('LONGNAME:', s) = 1) then WriteLName(CurArea^.Path, Tic^.Name,
                   KillLeadingSpcs(KillTrailingSpcs(Copy(Tic^.Desc, 10, Length(Tic^.Desc)-9))))
                  Else If (Pos('ORIGINAL NAME:', s) = 1) then WriteLName(CurArea^.Path, Tic^.Name,
                   KillLeadingSpcs(KillTrailingSpcs(Copy(Tic^.Desc, 15, Length(Tic^.Desc)-14))))
                  Else
                   Begin
                   s := UpStr(Tic^.LDesc[1]);
                   If (Pos('LONGNAME:', s) = 1) then WriteLName(CurArea^.Path, Tic^.Name,
                    KillLeadingSpcs(KillTrailingSpcs(Copy(Tic^.Desc, 10, Length(Tic^.Desc)-9))))
                   Else If (Pos('ORIGINAL NAME:', s) = 1) then WriteLName(CurArea^.Path, Tic^.Name,
                    KillLeadingSpcs(KillTrailingSpcs(Copy(Tic^.Desc, 15, Length(Tic^.Desc)-14))))
                   Else
                    Begin
                    s := UpStr(Tic^.LDesc[2]);
                    If (Pos('LONGNAME:', s) = 1) then WriteLName(CurArea^.Path, Tic^.Name,
                     KillLeadingSpcs(KillTrailingSpcs(Copy(Tic^.Desc, 10, Length(Tic^.Desc)-9))))
                    Else If (Pos('ORIGINAL NAME:', s) = 1) then WriteLName(CurArea^.Path, Tic^.Name,
                     KillLeadingSpcs(KillTrailingSpcs(Copy(Tic^.Desc, 15, Length(Tic^.Desc)-14))));
                    End;
                   End;
                  HDesc^[0] := #0;
                  PPos := 0;
                  If (Tic^.NumLDesc > 0) then
                   Begin
                   If (Tic^.Desc <> Tic^.LDesc[1]) then
                    Begin
                    For j := 0 to Length(Tic^.Desc)-1 do
                     HDesc^[PPos+j] := Tic^.Desc[j+1];
                    PPos := PPos + Length(Tic^.Desc) + 2;
                    HDesc^[PPos-2] := #13;
                    HDesc^[PPos-1] := #10;
                    End;
                   For i := 1 to Tic^.NumLDesc do
                    Begin
                    If (Length(Tic^.LDesc[i]) = 0) then j := 0
                    Else For j := 0 to Byte(Tic^.LDesc[i][0])-1 do
                     HDesc^[PPos+j] := Tic^.LDesc[i][j+1];
                    PPos := PPos+Length(Tic^.LDesc[i])+2;
                    HDesc^[PPos-2] := #13;
                    HDesc^[PPos-1] := #10;
                    End;
                   HDesc^[PPos] := #0;
                   End
                  Else
                   Begin
                   StrPCopy(Pointer(HDesc), Tic^.Desc);
                   HDesc^[Length(Tic^.Desc)] := #0;
                   End;
                  If not PT then SetFileDesc(CurArea^.Path + DirSep +
                   Tic^.Name, HDesc);
                  AddAnnFile(Tic^.Area, Tic^.Name, HDesc, Tic^.From);
                  If not PT then AddTossArea(CurArea^.Name, CurArea^.BBSArea);
                  Today(DT);
                  Now(DT);
                  With Tic^._To do If ((Zone <> 0) or (Net <> 0) or (Node <> 0) or (Point <> 0)) then
                    Begin
                    Inc(Tic^.NumPath);
                    s := Addr2Str(Tic^._To) + ' ' + DTToUnixHexStr(DT) +
                      ' ' + WkDays3Eng[DT.DayOfWeek] + ' ' + Months3Eng[DT.Month] + ' ' +
                      IntToStr(DT.Day) + ' ' + Time2Str(DT) + ' ' + IntToStr(DT.Year) +
                      ' ProTick' + Version;
                    Tic^.Path[Tic^.NumPath] := s;
                    LogSetCurLevel(LogHandle, 5);
                    LogWriteLn(LogHandle, 'Added Path "'+ Tic^.Path[Tic^.NumPath]+ '"');
                    Inc(Tic^.NumSB);
                    Tic^.SeenBy[Tic^.NumSB] := Tic^._To;
                    LogSetCurLevel(LogHandle, 5);
                    LogWriteLn(LogHandle, 'Added SeenBy "'+Addr2Str(Tic^._To)+'"');
                    End;
{$ifdef FPC}
                  With Tic^._To do If (not CompAddr(Tic^._To, CurArea^.Addr)) or
{$Else}
                  With Tic^._To do If (not CompAddr(Tic^._To, CurArea^.Addr)) XOR
{$endif}
                    ((Zone = 0) and (Net = 0) and (Node = 0) and (Point = 0)) then
                    Begin
                    Inc(Tic^.NumPath);
                    s := Addr2Str(CurArea^.Addr) + ' ' + DTToUnixHexStr(DT) +
                      ' ' + WkDays3Eng[DT.DayOfWeek] + ' ' + Months3Eng[DT.Month] + ' ' +
                      IntToStr(DT.Day) + ' ' + Time2Str(DT) + ' ' + IntToStr(DT.Year) +
                      ' ProTick' + Version;
                    Tic^.Path[Tic^.NumPath] := s;
                    LogSetCurLevel(LogHandle, 5);
                    LogWriteLn(LogHandle, 'Added Path "'+ Tic^.Path[Tic^.NumPath]+ '"');
                    Inc(Tic^.NumSB);
                    Tic^.SeenBy[Tic^.NumSB] := CurArea^.Addr;
                    LogSetCurLevel(LogHandle, 5);
                    LogWriteLn(LogHandle, 'Added SeenBy "'+Addr2Str(CurArea^.Addr)+'"');
                    End;
                  CurConnUser := CurArea^.Users;
                  If (CurConnUser <> NIL) then
                    Begin
                      Repeat
                      While (not CurConnUser^.Receive) and (CurConnUser^.Next <> Nil) do
                        CurConnUser := CurConnUser^.Next;
                      If CurConnUser^.Receive then
                        Begin
                        If (not CompAddr(Tic^.From, CurConnUser^.User^.Addr)) then
                          Begin
                          If (CurConnUser^.User^.Active or
                             ((CurArea^.Flags and fa_NoPause) > 0)) and
                             (not CompAddr(Tic^.From, CurConnUser^.User^.Addr)) then
                            Begin
                            CurUser := CurConnUser^.User;
                            Inc(Tic^.NumSB);
                            Tic^.SeenBy[Tic^.NumSB] := CurUser^.Addr;
                            LogSetCurLevel(LogHandle, 5);
                            LogWriteLn(LogHandle, 'Added SeenBy '+ Addr2Str(Tic^.SeenBy[Tic^.NumSB]));
                            End;
                          End;
                        If (CurConnUser^.Next <> Nil) then CurConnUser := CurConnUser^.Next
                        Else Break;
                        End;
                      Until ((CurConnUser^.Next = Nil) and (not CurConnUser^.Receive));
                    CurConnUser := CurArea^.Users;
                      Repeat
                      While (not CurConnUser^.Receive) and (CurConnUser^.Next <> Nil) do
                        CurConnUser := CurConnUser^.Next;
                      If CurConnUser^.Receive Then
                        Begin
                        If (CurConnUser^.User^.Active or
                           ((CurArea^.Flags and fa_NoPause) > 0)) and
                           (not CompAddr(Tic^.From, CurConnUser^.User^.Addr)) then
                          Begin
                          CurUser := CurConnUser^.User;
                          LogSetCurLevel(LogHandle, 3);
                          LogWriteLn(LogHandle, 'Forwarding to '+CurUser^.Name+' ('+Addr2Str(CurUser^.Addr)+')');
                          If not PT then SendTIC(CurUser, Tic, CurArea^.Path +
                           DirSep + Tic^.Name)
                          Else SendTIC(CurUser, Tic, Cfg^.PT + DirSep +
                           Tic^.Name);
                          WriteLn;
                          End;
                        If (CurConnUser^.Next <> Nil) then CurConnUser := CurConnUser^.Next
                        Else Break;
                        End;
                      Until ((CurConnUser^.Next = Nil) and (not CurConnUser^.Receive));
                      End;
                    End;
                  End;
                End;
              End;
            End;
          End;
        End;
      If (Tic^.Bad <> 0) then
      Begin
      WriteLn;
      If (Tic^.Bad <> bt_NotForUs) then
        Begin
        Assign(f, Cfg^.InBound+DirSep+SRec.Name);
        {$I-} Append(f); {$I+}
        If (IOResult <> 0) then
          Begin
          LogSetCurLevel(LogHandle, 1);
          LogWriteLn(LogHandle, 'Couldn''t append to "'+Cfg^.InBound +
           DirSep + SRec.Name+'"!');
          End
        Else
          Begin
          {$I-}
          WriteLn(f, 'ERROR #'+IntToStr(Tic^.Bad)+': '+TicErrorStr(Tic^.Bad));
          If (IOResult <> 0) then
            Begin
            LogSetCurLevel(LogHandle, 1);
            LogWriteLn(LogHandle, 'Error writing "'+Cfg^.InBound + DirSep +
             SRec.Name+'"!');
            End;
          Close(f); {$I+}
          If (IOResult <> 0) then
            Begin
            LogSetCurLevel(LogHandle, 1);
            LogWriteLn(LogHandle, 'Couldn''t close "'+Cfg^.InBound +
             DirSep + SRec.Name+'"!');
            End;
          End;
        If not MoveFile(Cfg^.InBound + DirSep + Tic^.Name, Cfg^.Bad +
         DirSep + Tic^.Name) Then
          Begin
          LogSetCurLevel(LogHandle, 1);
          LogWriteLn(LogHandle, 'Couldn''t move "'+Cfg^.InBound + DirSep +
           Tic^.Name+'" to "'+Cfg^.Bad + DirSep + Tic^.Name+'"!');
          End;
        If not MoveFile(Cfg^.InBound + DirSep + SRec.Name, Cfg^.Bad +
         DirSep + SRec.Name) Then
          Begin
          LogSetCurLevel(LogHandle, 1);
          LogWriteLn(LogHandle, 'Couldn''t move "'+Cfg^.InBound + DirSep +
           SRec.Name+'" to "'+Cfg^.Bad + DirSep + SRec.Name+'"!');
          End;
        End;
      End
    Else
      Begin
      {$I-} Erase(f); {$I+}
      If (IOResult <> 0) then
        Begin
        LogSetCurLevel(LogHandle, 1);
        LogWriteLn(LogHandle, 'Couldn''t erase "'+Cfg^.InBound + DirSep +
         SRec.Name+'"!');
        End;
      End;
    If Debug then
      Begin
      WriteLn('<Return>');
      ReadLn(s);
      If (UpStr(s) = 'BREAK') then
        Begin
{$ifdef OS2}
        FindClose(SRec);
{$endif}
        Dispose(Tic);
        Tic := Nil;
        Exit;
        End;
      End;
    FindNext(SRec);
    End;
{$ifdef OS2}
  FindClose(SRec);
{$endif}
  Dispose(Tic);
  Tic := Nil;
  {$I-} Close(ArcList); {$I+}
  If (IOResult <> 0) then
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Couldn''t close "'+Cfg^.ArcLst+'"!');
   End
  Else
   Begin
{$ifdef UNIX}
   ChMod(Cfg^.ArcLst, FilePerm);
{$endif}
   End;
  {$I-} Close(PTList); {$I+}
  If (IOResult <> 0) then
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Couldn''t close "'+Cfg^.PTLst+'"!');
   End
  Else
   Begin
{$ifdef UNIX}
   ChMod(Cfg^.PTLst, FilePerm);
{$endif}
   End;
  WriteTossArea;
  WriteBBSArea;
  WriteAutoArea;
  DoAnnounce;
  DoNMAnn;
  End;

Procedure SendTic(Usr: PUser; Tic: PTick; FName: String);
Var
  f: Text;
  f1: File;
  fn: String;
  fn1: FileStr;
  Ext: FileStr;
  Line: String;
  Error: Integer;
  s: String;
  i: LongInt;
  DT: TimeTyp;

  Begin
  FSplit(FName, s, fn1, Ext);
  fn1 := fn1 + Ext;
  With Tic^ do
   If ((Usr^.Flags and uf_SendTIC) = uf_SendTIC) then
    Begin
    i := 0;
      Repeat
      fn := Cfg^.TicOut + DirSep + 'pt' + Copy(RandName, 1, 6) + '.tic';
      Assign(f, fn);
      {$I-} ReSet(f); {$I+}
      Error := IOResult;
      If (Error = 0) then {$I-} Close(f); {$I+}
      Error := Error+IOResult;
      Inc(i);
      Until (Error <> 0) or (i >= 10000);
    LogSetCurLevel(LogHandle, 4);
    LogWriteLn(LogHandle, 'creating TIC: '+fn);
    {$I-} ReWrite(f); {$I+}
    If (IOResult <> 0) then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Couldn''t create "'+fn+'"!');
      End
    Else
      Begin
      {$I-}
      Write(f, 'Area '+Area+#13#10);
      If (IOResult <> 0) then
        Begin
        LogSetCurLevel(LogHandle, 1);
        LogWriteLn(LogHandle, 'Error writing "'+fn+'"!');
        Close(f);
        If (IOResult <> 0) then
          Begin
          LogSetCurLevel(LogHandle, 1);
          LogWriteLn(LogHandle, 'Couldn''t close "'+fn+'"!');
          End;
        Exit;
        End;
      If (AreaDesc <> '') then Write(f, 'AreaDesc '+AreaDesc+#13#10);
{$ifdef SPEED}
      If (Origin <> EmptyAddr) then Write(f, 'Origin ' + Addr2Str(Origin)+#13#10);
      If (Usr^.OwnAddr <> EmptyAddr) then Write(f, 'From '+Addr2Str(Usr^.OwnAddr)+#13#10)
      Else If (CurArea^.Addr <> EmptyAddr) then Write(f, 'From '+Addr2Str(CurArea^.Addr)+#13#10)
      Else If (_To <> EmptyAddr) then Write(f, 'From ' + Addr2Str(_To)+#13#10);
{$Else}
      With Origin do If ((Zone<>0) or (Net<>0) or (Node<>0) or (Point<>0)
        or  (Domain<>'')) then Write(f, 'Origin ' + Addr2Str(Origin)+#13#10);
      If ((Usr^.OwnAddr.Zone<>0) or (Usr^.OwnAddr.Net<>0) or (Usr^.OwnAddr.Node<>0)
        or (Usr^.OwnAddr.Point<>0) or (Usr^.OwnAddr.Domain<>'')) then
        Write(f, 'From ' + Addr2Str(Usr^.OwnAddr)+#13#10)
      Else If ((CurArea^.Addr.Zone<>0) or (CurArea^.Addr.Net<>0)
        or (CurArea^.Addr.Node<>0) or (CurArea^.Addr.Point<>0)
        or (CurArea^.Addr.Domain<>'')) then Write(f, 'From ' + Addr2Str(CurArea^.Addr)+#13#10)
      Else If ((_To.Zone<>0) or (_To.Net<>0) or (_To.Node<>0) or (_To.Point<>0)
        or  (_To.Domain<>'')) then Write(f, 'From ' + Addr2Str(_To)+#13#10);
{$endif}
      Write(f, 'To ' + Usr^.Name + ', ' + Addr2Str(Usr^.Addr)+#13#10);
      Write(f, 'File '+ Name+#13#10);
      If (Desc <> '') then Write(f, 'Desc '+Desc+#13#10);
      If (NumLDesc > 0) then For i := 1 to NumLDesc do Write(f, 'LDesc '+LDesc[i]+#13#10);
      If (CRC <> 0) then Write(f, 'CRC '+WordToHex(word(CRC SHR 16))+
       WordToHex(word(CRC mod 65536))+#13#10);
      Write(f, 'Created by ProTick'+Version+#13#10);
      For i := 1 to NumPath do Write(f, 'Path '+Path[i]+#13#10);
      For i := 1 to NumSB do Write(f, 'SeenBy '+Addr2Str(SeenBy[i])+#13#10);
      If (Usr^.Pwd <> '') then Write(f, 'PW ' + Usr^.Pwd+#13#10);
      If (ReleaseTime > 0) then Write(f, 'ReleaseTime '+
       WordToHex(word(ReleaseTime SHR 16))+WordToHex(word(ReleaseTime mod 65536))+#13#10);
      If (Replaces <> '') then Write(f, 'Replaces ' + Replaces+#13#10);
      If (Size > 0) then Write(f, 'Size '+IntToStr(Size)+#13#10);
      If (Date > 0) then Write(f, 'Date '+WordToHex(word(Date SHR 16))+
       WordToHex(word(Date mod 65536))+#13#10);
      If (NumApp > 0) then For i := 1 to NumApp do Write(f, App[i]+#13#10);
      If (IOResult <> 0) then
        Begin
        LogSetCurLevel(LogHandle, 1);
        LogWriteLn(LogHandle, 'Error writing "'+fn+'"!');
        End;
      Close(f); {$I+}
      If (IOResult <> 0) then
        Begin
        LogSetCurLevel(LogHandle, 1);
        LogWriteLn(LogHandle, 'Couldn''t close "'+fn+'"!');
        End;
{$ifdef UNIX}
      ChMod(fn, FilePerm);
{$endif}
      If (Usr^.PackTICs or Usr^.PackFiles) then
        Begin
        If Usr^.PackFiles then
          Begin
          ALE.Addr.Zone := Usr^.Addr.Zone;
          ALE.Addr.Net := Usr^.Addr.Net;
          ALE.Addr.Node := Usr^.Addr.Node;
          ALE.Addr.Point := Usr^.Addr.Point;
          ALE.Addr.Domain := Usr^.Addr.Domain;
          ALE.FileName := FName;
          ALE.Del := False;
          ALE.PTFN := '';
          Write(ArcList, ALE);
          End
        Else Outbound^.SendFile(Usr, FName, ac_Nothing);
        If Usr^.PackTICs then
          Begin
          ALE.Addr.Zone := Usr^.Addr.Zone;
          ALE.Addr.Net := Usr^.Addr.Net;
          ALE.Addr.Node := Usr^.Addr.Node;
          ALE.Addr.Point := Usr^.Addr.Point;
          ALE.Addr.Domain := Usr^.Addr.Domain;
          ALE.FileName := fn;
          ALE.Del := True;
          ALE.PTFN := '';
          If ((CurArea^.Flags and fa_PT) <> 0) and not Usr^.PackFiles then
            Begin
            ALE.PTFN := fn1;
            End;
          Write(ArcList, ALE);
          End
        Else
          Begin
          Outbound^.SendFile(Usr, fn, ac_Del);
          If (CurArea^.Flags and fa_PT) <> 0 then
            Begin
            PTLE.TICName := fn; {TIC}
            PTLE.FileName := fn1; {passthrough file}
            Write(PTList, PTLE);
            End;
          End;
        End
      Else
        Begin
        Outbound^.SendFile(Usr, FName, ac_Nothing);
        Outbound^.SendFile(Usr, fn, ac_Del);
        If (CurArea^.Flags and fa_PT) <> 0 then
          Begin
          PTLE.TICName := fn; {TIC}
          PTLE.FileName := fn1; {passthrough file}
          Write(PTList, PTLE);
          End;
        End;
      End;
    End
  Else
    Begin
    If Usr^.PackFiles then
     Begin
     ALE.Addr.Zone := Usr^.Addr.Zone;
     ALE.Addr.Net := Usr^.Addr.Net;
     ALE.Addr.Node := Usr^.Addr.Node;
     ALE.Addr.Point := Usr^.Addr.Point;
     ALE.Addr.Domain := Usr^.Addr.Domain;
     ALE.FileName := FName;
     ALE.Del := False;
     Write(ArcList, ALE);
     End
    Else
     Begin
     Outbound^.SendFile(Usr, FName, ac_Nothing);
     If (CurArea^.Flags and fa_PT) <> 0 then
      Begin
      PTLE.TICName := '!'+Addr2Str(Usr^.Addr);
      PTLE.FileName := fn1;
      Write(PTList, PTLE);
      End;
     End;
    End;
  End;

Function CheckForDupe(Tic:PTick):Boolean;
Var
  f: File of TDupeEntry;
  s: String;
  CurEntry: TDupeEntry;
  CFDupe: Boolean;
  i: LongInt;
  j: Byte;
  A1: TNetAddr;

  Begin
  CFDupe := False;
  For i := 1 to Tic^.NumPath do For j := 1 to Cfg^.NumAddrs do
    Begin
    If (Pos(' ', Tic^.Path[i]) > 0) then Str2Addr(Copy(Tic^.Path[i], 1, Pos(' ', Tic^.Path[i])), A1)
    Else Str2Addr(Tic^.Path[i], A1);
    CFDupe := CFDupe or (CompAddr(A1, Cfg^.Addrs[j]) and not (A1.Zone=0));
    End;
  CheckForDupe := CFDupe;
  If CFDupe then Exit;
  Assign(f, Cfg^.DupeFile);
  {$I-} ReSet(f); {$I+}
  If (IOResult = 0) then
    Begin
    While not EOF(f) do
      Begin
      {$I-} Read(f, CurEntry); {$I+}
      If (IOResult <> 0) then
        Begin
        LogSetCurLevel(LogHandle, 1);
        LogWriteLn(LogHandle, 'Error reading "'+Cfg^.DupeFile+'"!');
        Break;
        End;
      If (UpStr(Tic^.Area) = UpStr(CurEntry.Area)) Then
        If (UpStr(Tic^.Name) = UpStr(CurEntry.Name)) Then
          If (Tic^.CRC = CurEntry.CRC) then CFDupe := True;
      End;
    CheckForDupe := CFDupe;
    {$I-} Close(f); {$I+}
    If (IOResult <> 0) then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Couldn''t close "'+Cfg^.DupeFile+'"!');
      Exit;
      End;
    End;
  End;

Procedure WriteDupe(Tic:PTick);
Var
  f: File of TDupeEntry;
  s: String;
  CurEntry: TDupeEntry;
  DT: TimeTyp;

  Begin
  Today(DT); Now(DT);
  Assign(f, Cfg^.DupeFile);
{$ifdef SPEED}
  {$I-} Append(f); {$I+}
  If (IOResult <> 0) then
    Begin
    {$I-} ReWrite(f); {$I+}
    If (IOResult <> 0) then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Couldn''t open "'+Cfg^.DupeFile+'"!');
      Exit;
      End;
    End;
{$Else}
 {$ifdef FPC}
 If (DosAppend(f) <> 0) then
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Couldn''t open "'+Cfg^.DupeFile+'"!');
   Exit;
   End;
 {$Else}
  If (DosAppend(File(f)) <> 0) then
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Couldn''t open "'+Cfg^.DupeFile+'"!');
   Exit;
   End;
 {$endif}
{$endif}
  CurEntry.Area := Tic^.Area;
  CurEntry.Name := Tic^.Name;
  CurEntry.CRC := Tic^.CRC;
  CurEntry.Date := DTToUnixDate(DT);
  {$I-} Write(f, CurEntry); {$I+}
  If (IOResult <> 0) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Error writing to "'+Cfg^.DupeFile+'"!');
    End;
  {$I-} Close(f); {$I+}
  If (IOResult <> 0) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Couldn''t close "'+Cfg^.DupeFile+'"!');
    End
  Else
   Begin
{$ifdef UNIX}
   ChMod(Cfg^.DupeFile, FilePerm);
{$endif}
   End;
  End;

Procedure WriteLName(Path: DirStr; SName: String12; LName: String40);
Var
  f: Text;
  s, Dir: String;

  Begin
  LogSetCurLevel(LogHandle, 4);
  LogWriteLn(LogHandle, 'Longname: '+LName);
  SetLongName(Path, SName, LName);
  FSplit(CfgName, Dir, s, s);
  Assign(f, Cfg^.LNameLst);
  {$I-} Append(f); {$I+}
  If (IOResult <> 0) then
    Begin
    Assign(f, Cfg^.LNameLst);
    {$I-} ReWrite(f); {$I+}
    If (IOResult <> 0) then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Couldn''t open "'+Cfg^.LNameLst+'"!');
      Exit;
      End;
    End;
  {$I-} WriteLn(f, Path + ',' + SName + ',' + LName); {$I+}
  If (IOResult <> 0) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Error writing to "'+Cfg^.LNameLst+'"!');
    End;
  {$I-} Close(f); {$I+}
  If (IOResult <> 0) then
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Couldn''t close "'+Cfg^.LNameLst+'"!');
   End
  Else
   Begin
{$ifdef UNIX}
   ChMod(Cfg^.LNameLst, FilePerm);
{$endif}
   End;
  End;


Procedure Hatch;
Var
  s, Dir, Name, Ext: String;
  i: LongInt;
  f: Text;
  f1: File of Byte;
  CRC, FSize: ULong;
  crlf: PChar2;
  PPos: PChar2;
  pc : PChar2;

  Begin
  PPos := HDesc;
  GetMem(crlf, 3);
  GetMem(pc, 256);
  crlf^[0] := #13; crlf^[1] := #10; crlf^[2] := #0;
  LogSetCurLevel(LogHandle, 3);
  LogWriteLn(LogHandle, 'Hatch');
  If (HFile = '') then
    Begin
    Write('File: ');
    ReadLn(HFile);
    Write('Area: ');
    ReadLn(HArea);
    Write('Replaces: ');
    ReadLn(HReplace);
    Write('Desc: ');
    ReadLn(s);
    StrPCopy(Pointer(HDesc), s);
    Write('Delete files after hatching? ');
    ReadLn(s);
    s := UpStr(s);
    HMove := (s = 'TRUE') or (s = 'ON') or (s = '1') or (s[1] = 'Y') or (s[1] = 'J');
    End;
  If (HArea = '') then
    Begin
    WriteLn('No Area specified');
    Exit;
    End;
  HArea := UpStr(HArea);
  CurArea := Cfg^.Areas;
  While ((CurArea <> NIL) and (UpStr(CurArea^.Name) <> HArea)) do CurArea := CurArea^.Next;
  If (CurArea = NIL) then
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Area "'+HArea+'" for hatching not found in config!');
   Exit;
   End;
  CopyAddr(HFrom, CurArea^.Addr);
  CopyAddr(HTo, CurArea^.Addr);
  CopyAddr(HOrigin, CurArea^.Addr);
  HPW := Cfg^.LocalPwd;
  FSplit(HFile, Dir, Name, Ext);
  Name := LowStr(Name);
  Ext := LowStr(Ext);
  If (Dir <> Cfg^.InBound) then
    Begin
    If HMove then
      Begin
      If not MoveFile(HFile, Cfg^.InBound + DirSep + Name + Ext) then
        Begin
        LogSetCurLevel(LogHandle, 1);
        LogWriteLn(LogHandle, 'Couldn''t move file "'+HFile+'" to "'+
         Cfg^.InBound + DirSep + Name + Ext+'"');
        If not FileExist(Cfg^.InBound + Name + Ext) then Exit;
        End;
      End
    Else
      Begin
      If FileExist(Cfg^.InBound + DirSep + Name + Ext) then
        Begin
        Assign(f1, HFile);
        {$I-} i := FileSize(f1); {$I+}
        If (IOResult <> 0) then
          Begin
          LogSetCurLevel(LogHandle, 1);
          LogWriteLn(LogHandle, 'Couldn''t determine size of "'+HFile+'"!');
          End;
        Assign(f1, Cfg^.InBound + DirSep + Name + Ext);
        {$I-} If (i <> FileSize(f1)) then {$I+}
          Begin
          If (IOResult <> 0) then
            Begin
            LogSetCurLevel(LogHandle, 1);
            LogWriteLn(LogHandle, 'Couldn''t determine size of "'+
             Cfg^.InBound+DirSep+Name+Ext+'"!');
            End;
          LogSetCurLevel(LogHandle, 1);
          LogWriteLn(LogHandle, 'Another file named "'+ Name + Ext +
           '" already in InBound');
          FreeMem(crlf, 2);
          Exit;
          End;
        If (IOResult <> 0) then
          Begin
          LogSetCurLevel(LogHandle, 1);
          LogWriteLn(LogHandle, 'Couldn''t determine size of "'+Cfg^.InBound+
          DirSep+Name+Ext+'"!');
          End;
        End
      Else
        Begin
        If not CopyFile(HFile, Cfg^.InBound + DirSep + Name + Ext) then
          Begin
          LogSetCurLevel(LogHandle, 1);
          LogWriteLn(LogHandle, 'Couldn''t copy file "'+HFile+'" to inbound');
          FreeMem(crlf, 2);
          Exit;
          End;
        End;
      End;
    End;
  If not FileExist(Cfg^.InBound + DirSep + Name + Ext) then Exit;
  i := 0;
    Repeat
    Inc(i);
    s := Cfg^.InBound + DirSep + 'pt' + Copy(RandName, 1, 6) + '.tic';
    Until (not FileExist(s)) or (i = $FFFF);
  If (i >= $FFFF) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Couldn''t find unused filename for TIC!');
    FreeMem(crlf, 3);
    Exit;
    End;
  Assign(f1, Cfg^.InBound + DirSep + Name + Ext);
  {$I-} ReSet(f1);
  FSize := FileSize(f1); {$I+}
  i := IOResult;
  If (i <> 0) then
   Begin
   FSize := 0;
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Couldn''t determine filesize: Error #'+IntToStr(i)+'!');
   End
  Else
   Begin
   {$I-} Close(f1); {$I+}
   i := IOResult;
   End;
  CRC := GetCRC(Cfg^.InBound + DirSep + Name + Ext);
  Assign(f, s);
  {$I-} ReWrite(f); {$I+}
  If (IOResult <> 0) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Couldn''t create "'+s+'"');
    FreeMem(crlf, 3);
    Exit;
    End;
  WriteLn(f, 'File '+Name+Ext);
  WriteLn(f, 'Area '+HArea);
{$ifdef SPEED}
  If (HFrom <> EmptyAddr) then WriteLn(f, 'From '+Addr2Str(HFrom));
  If (HTo <> EmptyAddr) then WriteLn(f, 'To '+Addr2Str(HTo));
  If (HOrigin <> EmptyAddr) then WriteLn(f, 'Origin '+Addr2Str(HOrigin));
{$Else}
      With HFrom do If ((Zone<>0) or (Net<>0) or (Node<>0) or (Point<>0)
        or  (Domain<>'')) then WriteLn(f, 'From '+Addr2Str(HFrom));
      With HTo do If ((Zone<>0) or (Net<>0) or (Node<>0) or (Point<>0)
        or  (Domain<>'')) then WriteLn(f, 'To '+Addr2Str(HTo));
      With HOrigin do If ((Zone<>0) or (Net<>0) or (Node<>0) or (Point<>0)
        or  (Domain<>'')) then WriteLn(f, 'Origin '+Addr2Str(HOrigin));
{$endif}
  If (HDesc^[0] > #0) then
    Begin
    If (StrPos(Pointer(HDesc), Pointer(crlf)) = NIL) then WriteLn(f, 'Desc '+StrPas(Pointer(HDesc)))
    Else
      Begin
      Write(f, 'Desc ');
      i := 0;
      While (HDesc^[i] <> #13) or (HDesc^[i+1] <> #10) Do
        Begin
        Write(f, HDesc^[i]);
        Inc(i);
        End;
      WriteLn(f);
      While (StrPos(Pointer(HDesc), Pointer(crlf)) <> NIL) do
        Begin
        Write(f, 'LDesc ');
        i := 0;
        While (HDesc^[i] <> #13) or (HDesc^[i+1] <> #10) do
          Begin
          Write(f, HDesc^[i]);
          Inc(i);
          End;
        WriteLn(f);
{$ifdef OS2}
        HDesc := Pointer(StrPos(Pointer(HDesc), Pointer(crlf))+2);
{$Else}
 {$ifdef FPC}
        HDesc := Pointer(StrPos(Pointer(HDesc), Pointer(crlf))+2);
 {$Else}
        HDesc := Pointer(StrPos(Pointer(HDesc), Pointer(crlf)));
        MemW[Seg(HDesc):Ofs(HDesc)+2] := MemW[Seg(HDesc):Ofs(HDesc)+2] + 2;
 {$endif}
{$endif}
        End;
      If (HDesc^[i] > #0) then
        Begin
        Write(f, 'LDesc ');
        i := 0;
          Repeat
          Write(f, HDesc^[i]);
          Inc(i);
          Until (HDesc^[i] = #0);
        WriteLn(f);
        End;
      End;
    End;
  If (HReplace <> '') then WriteLn(f, 'Replaces '+HReplace);
  If (FSize <> 0) then WriteLn(f, 'Size '+IntToStr(FSize));
  WriteLn(f, 'CRC '+ WordToHex(word(CRC SHR 16)) + WordToHex(word(CRC mod 65536)));
  If (HPW <> '') then WriteLn(f, 'PW ' + HPW);
  WriteLn(f, 'Created by ProTick'+Version);
  {$I-} Close(f); {$I+}
  If (IOResult <> 0) then
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Couldn''t close "'+s+'"');
   End
  Else
   Begin
{$ifdef UNIX}
   ChMod(s, FilePerm);
{$endif}
   End;
  FreeMem(crlf, 3);
  FreeMem(pc, 256);
  HDesc := PPos;
  End;

Procedure NewFilesHatch;
Var
  FName: String;
{$ifdef SPEED}
  SRec: TSearchRec;
{$Else}
  SRec: SearchRec;
{$endif}
  f: Text;
  DT: TimeTyp;
  DOW: Word;
  s: String;

  Begin
  LogSetCurLevel(LogHandle, 3);
  LogWriteLn(LogHandle, 'NewFilesHatch');
  CurArea := Cfg^.Areas;
  While (CurArea^.Next <> NIL) do
    Begin
    While ((CurArea^.Next <> NIL) and ((CurArea^.Flags and fa_NewFilesHatch) = 0)) do
      Begin
      CurArea := CurArea^.Next;
      End;
    If ((CurArea^.Flags and fa_NewFilesHatch) = 0) then Break;
    With Ini do With CurArea^ do
      Begin
      SetSection('FILEAREAS');
      While (UpStr(ReSecEnName) <> 'AREA') or (UpStr(ReSecEnValue) <> UpStr(Name)) do
        If not SetNextOpt then Break;
      If (UpStr(ReSecEnName) <> 'AREA') or (UpStr(ReSecEnValue) <> UpStr(Name)) then
        Begin
        LogSetCurLevel(LogHandle, 3);
        LogWriteLn(LogHandle, 'Couldn''t find area "'+Name+'" in ConfigFile!');
        End
      Else
        Begin
        SetNextOpt;
        s := UpStr(ReSecEnName);
        While ((s <> 'LASTHATCH') and (s <> 'AREA')) do
          Begin
          If not SetNextOpt then Break;
          s := UpStr(ReSecEnName);
          End;
        Today(DT);
        Now(DT);
        If UpStr(ReSecEnName) <> 'LASTHATCH' then
          Begin
          SetPrevOpt;
          InsertSecEntry('LastHatch',
            WordToHex(word(DTToUnixDate(DT) SHR 16))+ WordToHex(word(DTToUnixDate(DT))), '')
          End
        Else WriteSecEntry('LastHatch',
            WordToHex(word(DTToUnixDate(DT) SHR 16))+ WordToHex(word(DTToUnixDate(DT))), '')
        End;
      End;
    FName := CurArea^.Path + DirSep + '*.*';
    SRec.Name := FName;
    FindFirst(FName, AnyFile and (not Directory), SRec);
    While (DosError = 0) Do
      Begin
      If (Pos('FILES.', UpStr(SRec.Name)) = 1) then
        Begin
        FindNext(SRec);
        Continue;
        End;
      Assign(f, CurArea^.Path + DirSep + SRec.Name);
      {$I-} ReSet(f); {$I+}
      If (IOResult <> 0) then
        Begin
        LogSetCurLevel(LogHandle, 1);
        LogWriteLn(LogHandle, 'Couldn''t open "'+ CurArea^.Path + DirSep +
         SRec.Name + '"!');
        FindNext(SRec);
        Continue;
        End;
      With DT do GetFTime2(f, Year, Month, Day, Hour, Min, Sec);
      {$I-} Close(f); {$I+}
      If (IOResult <> 0) then
        Begin
        LogSetCurLevel(LogHandle, 1);
        LogWriteLn(LogHandle, 'Couldn''t close "'+ CurArea^.Path + DirSep
         + SRec.Name + '"!');
        End;
      If (DTToUnixDate(DT) > CurArea^.LastHatch) then
        Begin
        LogSetCurLevel(LogHandle, 3);
        LogWriteLn(LogHandle, 'Processing '+CurArea^.Path+DirSep+SRec.Name);
        HArea := CurArea^.Name;
        HFrom := CurArea^.Addr;
        HTo := CurArea^.Addr;
        HOrigin := CurArea^.Addr;
        HFile:= CurArea^.Path+DirSep+SRec.Name;
        HMove:= True;
        HReplace:= '';
        HDesc^[0] := #0;
        GetFileDesc(CurArea^.Path+DirSep+SRec.Name, HDesc);
        Hatch;
        End;
      FindNext(SRec);
      End;
{$ifdef OS2}
    FindClose(SRec);
{$endif}
    If (CurArea^.Next <> NIL) then CurArea := CurArea^.Next;
    End;
  End;

Procedure Scan;
Var
  A1: TNetAddr;
  MKAddr: AddrType;
  bo: Boolean;
  i,j: LongInt;
  s1: String;

  Begin
  LogSetCurLevel(LogHandle, 3);
  LogWriteLn(LogHandle, 'Scan');
  Case UpCase(Cfg^.NetMail[1]) of
    'H': NM := New(HudsonMsgPtr, Init);
    'S': NM := New(SqMsgPtr, Init);
    'F': NM := New(FidoMsgPtr, Init);
    'E': NM := New(EzyMsgPtr, Init);
    'J': NM := New(JamMsgPtr, Init);
    Else
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Invalid type for netmail area!');
      Exit;
      End;
    End;
  NM^.SetMsgPath(Copy(Cfg^.NetMail, 2, Length(Cfg^.NetMail) - 1));
  If (NM^.OpenMsgBase <> 0) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Couldn''t open netmail area!');
    Dispose(NM, Done);
    Exit;
    End;
  Case UpCase(Cfg^.NetMail[1]) of
    'H': NM2 := New(HudsonMsgPtr, Init);
    'S': NM2 := New(SqMsgPtr, Init);
    'F': NM2 := New(FidoMsgPtr, Init);
    'E': NM2 := New(EzyMsgPtr, Init);
    'J': NM2 := New(JamMsgPtr, Init);
    Else
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Invalid type for netmail area!');
      Dispose(NM, Done);
      Exit;
      End;
    End;
  NM2^.SetMsgPath(Copy(Cfg^.NetMail, 2, Length(Cfg^.NetMail) - 1));
  If (NM2^.OpenMsgBase <> 0) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Couldn''t open netmail area!');
    If (NM^.CloseMsgBase <> 0) then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Couldn''t close netmail area!');
      End;
    Dispose(NM, Done);
    Dispose(NM2, Done);
    Exit;
    End;
  If (UpCase(Cfg^.NetMail[1]) = 'F') then FidoMsgPtr(NM)^.SetDefaultZone(0);
  If (UpCase(Cfg^.NetMail[1]) = 'F') then FidoMsgPtr(NM2)^.SetDefaultZone(0);
  NM^.SetMailType(mmtNetMail);
  NM2^.SetMailType(mmtNetMail);
  With NM^ do
    Begin
    SeekFirst(1);
    While SeekFound do
      Begin
      InitMsgHdr;
{$ifdef UNIX}
      WriteLn('Msg #', GetMsgDisplayNum);
{$Else}
      Write(#13'Msg #', GetMsgDisplayNum, '     ');
{$endif}
      GetDest(MKAddr);
      MKAddr2TNetAddr(MKAddr, A1);
      bo := False;
      For i := 1 to Cfg^.NumAddrs do bo := bo or CompAddr(A1, Cfg^.Addrs[i]);
      If bo then
        Begin
        s1 := UpStr(GetTo);
        bo := False;
        For i := 1 to Cfg^.NumMgrNames do
         Begin
         j := Pos(UpStr(Cfg^.MgrNames[i]), s1);
         bo := bo or ((j > 0) and ((Length(s1) = (j+Length(Cfg^.MgrNames[i])-1))
          or (s1[j+Length(Cfg^.MgrNames[i])] = ' ')));
         End;
        If (bo and (not IsRcvd)) then
         Begin
         WriteLn;
         ProcessMail;
         End;
        End;
      SeekNext;
      End;
    WriteLn;
    If (NM^.CloseMsgBase <> 0) then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Couldn''t close netmail area!');
      End;
    If (NM2^.CloseMsgBase <> 0) then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Couldn''t close netmail area!');
      End;
    End;
  Dispose(NM, Done);
  Dispose(NM2, Done);
  End;

Procedure Maint;
  Begin
  WriteLn('Maint');
  WriteLn;
  LogSetCurLevel(loghandle, 5);
  LogWriteLn(loghandle, 'Calling PurgeArchs');
  Outbound^.PurgeArchs;
  LogSetCurLevel(loghandle, 5);
  LogWriteLn(loghandle, 'Calling DelPT');
  DelPT;
  LogWriteLn(loghandle, 'Calling PurgeDupes');
  PurgeDupes;
  LogSetCurLevel(loghandle, 5);
  LogWriteLn(loghandle, 'Done');
  End;

Procedure _Pack;
Var
  s, s1: String;
  A1: TNetAddr;
  PackName: String;
  f1: File of Byte;
  Error: Integer;
  IsRead: Boolean;
  DoEnd: Boolean;
  AC, ACC: PArcList;
  f: Text;
  ListName: String;
  Dir: String;
  p: Pointer;
  i: Byte;
  NewArc: Boolean;

  Procedure ReadList;
    Begin
    New(AC);
    ACC := AC;
    ACC^.Prev := NIL;
    ACC^.Next := NIL;
    Read(ArcList, ACC^.a);
    While not EOF(ArcList) Do
      Begin
      New(ACC^.Next);
      ACC^.Next^.Prev := ACC;
      ACC := ACC^.Next;
      ACC^.Next := NIL;
      Read(ArcList, ACC^.a);
      If (Byte(Acc^.a.Addr.Domain[0]) > 20) then Acc^.a.Addr.Domain[0] := #20;
      End;
    {$I-} Close(ArcList); {$I+}
    If (IOResult <> 0) then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Couldn''t close ArcList!');
      End;
    End;

  Procedure Sort; {Bubblesort}
  Var
    Swapped: Boolean;

    Procedure Swap(var a, b: TArcListEntry);
    Var
      c: TArcListEntry;

      Begin
      c := a;
      a := b;
      b := c;
      End;

    Begin
      Repeat
      ACC := AC;
      Swapped := False;
      While (ACC^.Next <> NIL) do
        Begin
        If Addr2Str(ACC^.a.Addr) > Addr2Str(ACC^.Next^.a.Addr) then
          Begin
          Swap(ACC^.a, ACC^.Next^.a);
          Swapped := True;
          End;
        ACC := ACC^.Next;
        End;
      Until not Swapped;
    End;

  Procedure DelFiles;
  Var
   OldAddr: TNetAddr;
   DoDel: Boolean;

    Begin
    ACC := AC;
    While (ACC^.Next <> NIL) do ACC := ACC^.Next;
     Repeat
     OldAddr := ACC^.a.Addr;
     DoDel := ACC^.IsDone;
      Repeat
      If DoDel then
       Begin
       If ACC^.a.Del then
         Begin
         LogSetCurLevel(LogHandle, 4);
         LogWriteLn(LogHandle, 'deleting '+ACC^.a.FileName);
         DelFile(ACC^.a.FileName);
         End;
       ACC := ACC^.Prev;
       End
      Else
       Begin
       ACC := ACC^.Prev;
       End;
      Until (ACC = NIL) or (not CompAddr(OldAddr, ACC^.a.Addr));
     Until (ACC = NIL);
    End;

  Procedure DispList;
  Var
   OldAddr: TNetAddr;
   DoDel: Boolean;

    Begin
    ACC := AC;
    While (ACC^.Next <> NIL) do ACC := ACC^.Next;
     Repeat
     OldAddr := ACC^.a.Addr;
     DoDel := ACC^.IsDone;
      Repeat
      If DoDel then
       Begin
       If (ACC^.Prev <> NIL) then
        Begin
        ACC^.Prev^.Next := ACC^.Next;
        If (ACC^.Next <> NIL) then ACC^.Next^.Prev := ACC^.Prev;
        End
       Else
        Begin
        If (ACC^.Next <> NIL) then ACC^.Next^.Prev := NIL;
        AC := ACC^.Next;
        End;
       p := ACC^.Prev;
       Dispose(ACC);
       ACC := p;
       End
      Else
       Begin
       ACC := ACC^.Prev;
       End;
      Until (ACC = NIL) or (not CompAddr(OldAddr, ACC^.a.Addr));
     Until (ACC = NIL);
    End;


  Begin
  LogSetCurLevel(LogHandle, 3);
  LogWriteLn(LogHandle, 'Pack');
  FSplit(CfgName, s, s1, s1);
  ListName := s + 'files.lst';
  Assign(ArcList, Cfg^.ArcLst);
  Assign(PTList, Cfg^.PTLst);
  Assign(f, ListName);
{$ifdef SPEED}
  {$I-} Append(PTList); {$I+}
  If (IOResult <> 0) then
    Begin
    {$I-} ReWrite(PTList); {$I+}
    If (IOResult <> 0) then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Couldn''t open "'+Cfg^.PTLst+'"!');
      Done;
      Halt(Err_PTList);
      End;
    End;
{$Else}
 {$ifdef FPC}
  If (DosAppend(PTList) <> 0) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Couldn''t open "'+Cfg^.PTLst+'"!');
    Done;
    Halt(Err_PTList);
    End;
 {$Else}
  If (DosAppend(File(PTList)) <> 0) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Couldn''t open "'+Cfg^.PTLst+'"!');
    Done;
    Halt(Err_PTList);
    End;
 {$endif}
{$endif}
  {$I-} ReSet(ArcList); {$I+}
  If (IOResult <> 0) then Exit;
  If EOF(ArcList) then
   Begin
   Close(ArcList);
   Exit;
   End;
  ReadList;
  Sort;
  DoEnd := False;
  ACC := AC;
    Repeat
    CurUser := Cfg^.Users;
    While ((CurUser^.Next <> Nil) and (not CompAddr(ACC^.a.Addr, CurUser^.Addr))) do CurUser := CurUser^.Next;
    If not CompAddr(ACC^.a.Addr, CurUser^.Addr) then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'User '+Addr2Str(ACC^.a.Addr)+' in ArcList but not found in Config!');
      End
    Else
      Begin
      PackName := Outbound^.ArchiveName(CurUser);
      NewArc := not FileExist(PackName);
      LogSetCurLevel(LogHandle, 4);
      LogWriteLn(LogHandle, 'Processing '+PackName);

      Assign(f, ListName);
      ReWrite(f);
      If (IOResult <> 0) then
        Begin
        LogSetCurLevel(LogHandle, 1);
        LogWriteLn(LogHandle, 'Couldn''t create "'+ListName+'"!');
        DispList;
        Exit;
        End;

        Repeat
        LogSetCurLevel(LogHandle, 4);
        LogWriteLn(LogHandle, 'adding '+ACC^.a.FileName);
        WriteLn(f, ACC^.a.FileName);
        If (ACC^.a.PTFN <> '') then
          Begin
          LogSetCurLevel(LogHandle, 4);
          LogWriteLn(LogHandle, 'adding '+ACC^.a.PTFN+' to pt.lst');
          PTLE.TICName := PackName; {archive}
          PTLE.FileName := ACC^.a.PTFN; {passthrough file}
          Write(PTList, PTLE);
          End;
        If (ACC^.Next <> Nil) then ACC := ACC^.Next Else DoEnd := True;
        Until (not CompAddr(CurUser^.Addr, ACC^.a.Addr)) or DoEnd;
      {$I-} Close(f); {$I+}
      If (IOResult <> 0) then
        Begin
        LogSetCurLevel(LogHandle, 1);
        LogWriteLn(LogHandle, 'Couldn''t close "'+ListName+'"!');
        End
      Else
       Begin
{$ifdef UNIX}
       ChMod(ListName, FilePerm);
{$endif}
       End;
      If not Pack(CurUser^.Packer, PackName, ListName) then
       Begin
       LogSetCurLevel(LogHandle, 2);
       LogWriteLn(LogHandle, 'skipping user "'+CurUser^.Name+'" ('+Addr2Str(CurUser^.Addr)+')');
       If DoEnd then ACC^.IsDone := False Else ACC^.Prev^.IsDone := False;
       End
      Else If DoEnd then ACC^.IsDone := True Else ACC^.Prev^.IsDone := True;
      If NewArc then
        Begin
        LogSetCurLevel(LogHandle, 4);
        LogWriteLn(LogHandle, 'sending '+PackName);
        Outbound^.SendFile(CurUser, PackName, ac_Trunc);
        End;
      End;
    Until DoEnd;
  DelFiles;
  If FileExist(ListName) then
    Begin
    {$I-} Erase(f); {$I+}
    If (IOResult <> 0) then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Couldn''t delete "'+ListName+'"!');
      End;
    End;
  DispList;
  {$I-} ReWrite(ArcList); {$I+}
  If (IOResult <> 0) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Couldn''t open "'+Cfg^.ArcLst+'"!');
    End;
  ACC := AC;
  While (ACC <> NIL) do
   Begin
   Write(ArcList, ACC^.a);
   ACC := ACC^.Next;
   End;
  {$I-} Close(ArcList); {$I+}
  If (IOResult <> 0) then
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Couldn''t close "'+Cfg^.ArcLst+'"!');
   End
  Else
   Begin
{$ifdef UNIX}
   ChMod(Cfg^.ArcLst, FilePerm);
{$endif}
   End;
  {$I-} Close(PTList); {$I+}
  If (IOResult <> 0) then
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Couldn''t close "'+Cfg^.PTLst+'"!');
   End
  Else
   Begin
{$ifdef UNIX}
   ChMod(Cfg^.PTLst, FilePerm);
{$endif}
   End;
  ACC := AC;
  While (ACC <> NIL) do
   Begin
   p := ACC^.Next;
   Dispose(ACC);
   ACC := p;
   End;
  AC := NIL;
  End;

Procedure AddAnnFile(ar: String; fn: String; desc: PChar2; From: TNetAddr);
Var
  s: String;
  pc: PChar2;

  Begin
  s := UpStr(ar);
  CurAnnArea := AnnAreas;
  If (AnnAreas = NIL) then
    Begin
    New(AnnAreas);
    CurAnnArea := AnnAreas;
    CurAnnArea^.Prev := NIL;
    CurAnnArea^.Next := NIL;
    CurAnnArea^.Files := NIL;
    CurAnnArea^.Area := s;
    CurAnnArea^.Desc := '';
    CurAnnArea^.AnnGroups := CurArea^.AnnGroups;
    End
  Else If (UpStr(CurAnnArea^.Area) <> s) then
    Begin
    While (CurAnnArea^.Next <> NIL) and (UpStr(CurAnnArea^.Area) <> s) do
      CurAnnArea := CurAnnArea^.Next;
    If (UpStr(CurAnnArea^.Area) <> s) then
      Begin
      New(CurAnnArea^.Next);
      CurAnnArea^.Next^.Prev := CurAnnArea;
      CurAnnArea := CurAnnArea^.Next;
      CurAnnArea^.Next := NIL;
      CurAnnArea^.Files := NIL;
      CurAnnArea^.Area := s;
      CurAnnArea^.Desc := '';
      CurAnnArea^.AnnGroups := CurArea^.AnnGroups;
      End;
    End;
  CurAnnFile := CurAnnArea^.Files;
  If (CurAnnArea^.Files = NIL) then
    Begin
    New(CurAnnArea^.Files);
    CurAnnFile := CurAnnArea^.Files;
    CurAnnFile^.Prev := NIL;
    CurAnnFile^.Next := NIL;
    End
  Else
    Begin
    While (CurAnnFile^.Next <> NIL) do CurAnnFile := CurAnnFile^.Next;
    New(CurAnnFile^.Next);
    CurAnnFile^.Next^.Prev := CurAnnFile;
    CurAnnFile := CurAnnFile^.Next;
    CurAnnFile^.Next := NIL;
    End;
  CurAnnFile^.Name := fn;
  CurAnnFile^.Sender := From;
  If (Desc <> NIL) then
    Begin
    If (Desc^[0] = #0) then CurAnnFile^.Desc := NIL
    Else
      Begin
      GetMem(CurAnnFile^.Desc, 65535);
      StrCopy(Pointer(CurAnnFile^.Desc), Pointer(Desc));
      pc := Pointer(StrNew(Pointer(CurAnnFile^.Desc)));
{      StrDispose(Pointer(CurAnnFile^.Desc)); }
      CurAnnFile^.Desc := pc;
      End;
    End
  Else CurAnnFile^.Desc := NIL;
  CurAnnFile^.Size := GetFSize(CurArea^.Path + DirSep + fn);
  With CurAnnFile^.Date do GetFileTime(CurArea^.Path+DirSep+fn, Year, Month, Day, Hour, Min, Sec);
  End;

Procedure DispAnnList;
  Begin
  If (Cfg^.AnnGroups <> Nil) then
   Begin
   CurAnnGroup := Cfg^.AnnGroups;
    Repeat
    If (CurAnnGroup^.Next <> NIL) then CurAnnGroup := CurAnnGroup^.Next
    Else If (CurAnnGroup^.Prev <> NIL) then
     Begin
     CurAnnGroup := CurAnnGroup^.Prev;
     Dispose(CurAnnGroup^.Next);
     CurAnnGroup^.Next := NIL;
     End;
    Until (CurAnnGroup = Cfg^.AnnGroups);
   Dispose(CurAnnGroup);
   CurAnnGroup := NIL;
   Cfg^.AnnGroups := NIL;
   End;
  If (AnnAreas <> Nil) then
    Begin
    CurAnnArea := AnnAreas;
      Repeat
      If CurAnnArea^.Next <> NIL then CurAnnArea := CurAnnArea^.Next
      Else If CurAnnArea^.Prev <> NIL then
        Begin
        If CurAnnArea^.Files <> NIL then
          Begin
          AnnFiles := CurAnnArea^.Files;
          CurAnnFile := AnnFiles;
            Repeat
            If CurAnnFile^.Next <> NIL then CurAnnFile := CurAnnFile^.Next
            Else If CurAnnFile^.Prev <> NIL then
              Begin
              If (CurAnnFile^.Desc <> NIL) then
                StrDispose(Pointer(CurAnnFile^.Desc));
              CurAnnFile := CurAnnFile^.Prev;
              Dispose(CurAnnFile^.Next);
              CurAnnFile^.Next := NIL;
              End;
            Until (CurAnnFile = AnnFiles);
          StrDispose(Pointer(AnnFiles^.Desc));
          Dispose(AnnFiles);
          AnnFiles := NIL;
          CurAnnFile := NIL;
          CurAnnArea^.Files := NIL;
          End;
        CurAnnArea := CurAnnArea^.Prev;
        Dispose(CurAnnArea^.Next);
        CurAnnArea^.Next := NIL;
        End;
      Until (CurAnnArea = AnnAreas);
    Dispose(AnnAreas);
    AnnAreas := NIL;
    CurAnnArea := NIL;
    End;
  End;

Procedure MsgCopyFile(Msg: AbsMsgPtr; FName: String);
Var
 f: Text;
 Error: Integer;
 Line: String;

 Begin
 {sanity check}
 If (FName = '') then exit;

 Assign(f, FName);
 {$I-} ReSet(f); {$I+}
 Error := IOResult;
 If (Error <> 0) then
  Begin
  LogSetCurLevel(LogHandle, 1);
  LogWriteLn(LogHandle, 'Could not open file "'+FName+'"!');
  Exit;
  End;

 While (not EOF(f)) do
  Begin
  ReadLn(f, Line);
  {strip CR/LF}
  While (Line[Length(Line)] in [#10, #13]) do Line[0] := Char(Byte(Line[0]) - 1);
  Msg^.DoStringLn(Line);
  End;

 Close(f);
 End;

Procedure DoAnnounce;
Var
  DoEndArea, DoEndFile: Boolean;
  s, s2: String;
  crlf: PChar2;
  ODesc: PChar2;
  MKAddr: AddrType;
  DT: TimeTyp;
  i: LongInt;
  CurAG: LongInt;
  b: Boolean;
  p: Pointer;
  Error: Integer;

  Begin
  If AnnAreas = NIL then Exit;
  GetMem(crlf, 3);
  crlf^[0] := #13; crlf^[1] := #10; crlf^[2] := #0;
  CurAnnArea := AnnAreas;
  DoEndArea := False;
  LogSetCurLevel(LogHandle, 3);
  LogWriteLn(LogHandle, 'Announce');
  WriteLn;
    Repeat
    For CurAG := 1 to 255 do If (CurAG in CurAnnArea^.AnnGroups) then
      Begin
      CurAnnGroup := Cfg^.AnnGroups;
      While ((CurAnnGroup^.Next <> NIL) and (CurAnnGroup^.Index <> CurAG)) do
        CurAnnGroup := CurAnnGroup^.Next;
      If (CurAnnGroup^.Index <> CurAG) then
        Begin
        LogSetCurLevel(LogHandle, 1);
        LogWriteLn(LogHandle, 'Unknown announcegroup: #'+IntToStr(CurAG)+'!');
        If CurAnnArea^.Next = NIL then
          Begin
          DoEndArea := True;
          Break;
          End
        Else
          Begin
          CurAnnArea := CurAnnArea^.Next;
          Continue;
          End;
        End;
      Case UpCase(CurAnnGroup^.Area[1]) of
        'H': AnnMsg := New(HudsonMsgPtr, Init);
        'S': AnnMsg := New(SqMsgPtr, Init);
        'F': AnnMsg := New(FidoMsgPtr, Init);
        'E': AnnMsg := New(EzyMsgPtr, Init);
        'J': AnnMsg := New(JamMsgPtr, Init);
        Else
          Begin
          LogSetCurLevel(LogHandle, 1);
          LogWriteLn(LogHandle, 'Invalid type for announce area: '+CurAnnGroup^.Area[1]+'!');
          If CurAnnArea^.Next = NIL then
            Begin
            DoEndArea := True;
            Break;
            End
          Else
            Begin
            CurAnnArea := CurAnnArea^.Next;
            Continue;
            End;
          End;
        End;
      AnnMsg^.SetMsgPath(Copy(CurAnnGroup^.Area, 2, Length(CurAnnGroup^.Area) - 1));
      {$I-} Error := AnnMsg^.OpenMsgBase; {$I+}
      If (Error <> 0) then
        Begin
        LogSetCurLevel(LogHandle, 1);
        LogWriteLn(LogHandle, 'Couldn''t open announce area "'+CurAnnGroup^.Area+
          '": Error '+IntToStr(Error)+'!');
        Dispose(AnnMsg, Done);
        If CurAnnArea^.Next = NIL then
          Begin
          DoEndArea := True;
          Break;
          End
        Else
          Begin
          CurAnnArea := CurAnnArea^.Next;
          Continue;
          End;
        End;
      WriteLn('Announcing to area "'+CurAnnGroup^.Area+'"');
      Case CurAnnGroup^.Typ of
       at_EchoMail: AnnMsg^.SetMailType(mmtEchoMail);
       at_Netmail: AnnMsg^.SetMailType(mmtNetMail);
       End;
      With AnnMsg^ do
        Begin
        StartNewMsg;
        SetTo(CurAnnGroup^.ToName);
        TNetAddr2MKAddr(CurAnnGroup^.ToAddr, MKAddr);
        SetDest(MKAddr);
        SetFrom(CurAnnGroup^.FromName);
        TNetAddr2MKAddr(CurAnnGroup^.FromAddr, MKAddr);
        SetOrig(MKAddr);
        SetSubj(CurAnnGroup^.Subj);
        SetLocal(True);
        If (CurAnnGroup^.Typ = at_Netmail) then SetPriv(True);
        Today(DT);
        If (DT.Year > 100) then DT.Year := DT.Year mod 100;
        Now(DT);
        If (DT.Month > 9) then s := IntToStr(DT.Month) + '-'
        Else s := '0' + IntToStr(DT.Month) + '-';
        If (DT.Day > 9) then s := s + IntToStr(DT.Day) + '-'
        Else s := s + '0' + IntToStr(DT.Day) + '-';
        If (DT.Year > 9) then s := s + IntToStr(DT.Year)
        Else s := s + '0' + IntToStr(DT.Year);
        SetDate(s);
        If (DT.Hour > 9) then s := IntToStr(DT.Hour) + ':'
        Else s := '0' + IntToStr(DT.Hour) + ':';
        If (DT.Min > 9) then s := s + IntToStr(DT.Min)
        Else s := s + '0' + IntToStr(DT.Min);
        SetTime(s);
        DoKludgeLn(#01'MSGID: '+Addr2Str(CurAnnGroup^.FromAddr)+' '+GetMsgID);
        MsgCopyFile(AnnMsg, CurAnnGroup^.HeaderFile);
        DoString('Area: '+CurAnnArea^.Area);
        If (CurAnnArea^.Desc <> '') then DoStringLn(' ('+CurAnnArea^.Desc+')')
        Else DoStringLn('');
        DoStringLn('-------------------------------------------------------------------------------');

        CurAnnFile := CurAnnArea^.Files;
        DoEndFile := False;
          Repeat
          With CurAnnFile^ do
            Begin
            s := Name;
            If (Length(s) < 12) then s := s + Copy(Leer, 1, 12 - Length(s));
            DoString(s+' ');
            If (Date.Year > 100) then Date.Year := Date.Year mod 100;
            Now(DT);
            If (Date.Day > 9) then s := IntToStr(Date.Day) + '.'
            Else s := '0' + IntToStr(Date.Day) + '.';
            If (Date.Month > 9) then s := s + IntToStr(Date.Month) + '.'
            Else s := s + '0' + IntToStr(Date.Month) + '.';
            If (Date.Year > 9) then s := s + IntToStr(Date.Year)
            Else s := s + '0' + IntToStr(Date.Year);
            DoString(s+' ');
            If (Size > 10000000) then
              Begin
              s := IntToStr(Size div 1000000);
              If (Length(s) < 9) then s := Copy(Leer, 1, 9 - Length(s))+ s;
              s := s + 'mb';
              End
            Else If (Size > 100000) then
              Begin
              s := IntToStr(Size div 1000);
              If (Length(s) < 9) then s := Copy(Leer, 1, 9 - Length(s))+ s;
              s := s + 'kb';
              End
            Else
              Begin
              s := IntToStr(Size);
              If (Length(s) < 10) then s := Copy(Leer, 1, 10 - Length(s))+ s;
              s := s + 'b';
              End;
            DoString(s+' ');
            If (Desc <> NIL) then
              Begin
              ODesc := Desc;
              b := False;
              p := StrPos(Pointer(Desc), Pointer(crlf));
{$ifdef OS2}
              While (p <> NIL) and (p < StrEnd(Pointer(Desc))) do
{$Else}
              While (p <> NIL) do
{$endif}
                Begin
                If not b then b := True Else DoString(Copy(Leer, 1, 34));
                i := 0;
                  Repeat
                  DoString(Desc^[i]);
                  Inc(i);
                  Until (Desc^[i] = #13) and (Desc^[i+1] = #10);
                DoStringLn('');
{$ifdef OS2}
                Desc := Pointer(StrPos(Pointer(Desc), Pointer(crlf))+2);
{$Else}
 {$ifdef FPC}
                Desc := Pointer(StrPos(Pointer(Desc), Pointer(crlf))+2);
 {$Else}
                Desc := Pointer(StrPos(Pointer(Desc), Pointer(crlf)));
                MemW[Seg(Desc):Ofs(Desc)+2] := MemW[Seg(Desc):Ofs(Desc)+2] + 2;
 {$endif}
{$endif}
                p := StrPos(Pointer(Desc), Pointer(crlf));
                End;
              If (Desc^[0] <> #0) then
                Begin
                i := 0;
                  Repeat
                  DoString(Desc^[i]);
                  Inc(i);
                  Until (Desc^[i] = #0);
                End;
              Desc := ODesc;
              End;
            DoStringLn('');
            End;

          If CurAnnFile^.Next = NIL then DoEndFile := True Else CurAnnFile := CurAnnFile^.Next;
          Until DoEndFile;

        DoStringLn('');
        MsgCopyFile(AnnMsg, CurAnnGroup^.FooterFile);
        DoStringLn('');
        DoStringLn('--- ProTick'+Version);
        If (CurAnnGroup^.Typ = at_EchoMail) then
         DoStringLn(' * Origin: '+Cfg^.BBS+' ('+
         Addr2StrND(CurAnnGroup^.FromAddr)+')');
        Error := WriteMsg;
        If (Error <> 0) then
          Begin
          LogSetCurLevel(LogHandle, 1);
          LogWriteLn(LogHandle, 'Couldn''t write announce to area "'+
           CurAnnGroup^.Area+'": Error '+IntToStr(Error)+'!');
          End;
        If (CloseMsgBase <> 0) then
          Begin
          LogSetCurLevel(LogHandle, 1);
          LogWriteLn(LogHandle, 'Couldn''t close announce area "'+CurAnnGroup^.Area+'"!');
          End;
        End;
      Dispose(AnnMsg, Done);
      End;
    If CurAnnArea^.Next = NIL then DoEndArea := True Else CurAnnArea := CurAnnArea^.Next;
    Until DoEndArea;

  FreeMem(crlf, 3);
  End;

Procedure DoNMAnn;
Var
 DoEndArea, DoEndFile: Boolean;
 s, s2: String;
 crlf: PChar2;
 ODesc: PChar2;
 MKAddr: AddrType;
 DT: TimeTyp;
 i: LongInt;
 b: Boolean;
 p: Pointer;
 Error: Integer;

 Begin
 If AnnAreas = NIL then Exit;
 GetMem(crlf, 3);
 crlf^[0] := #13; crlf^[1] := #10; crlf^[2] := #0;
 CurAnnArea := AnnAreas;
 DoEndArea := False;
  Repeat
  Case UpCase(Cfg^.Netmail[1]) of
   'H': NM := New(HudsonMsgPtr, Init);
   'S': NM := New(SqMsgPtr, Init);
   'F': NM := New(FidoMsgPtr, Init);
   'E': NM := New(EzyMsgPtr, Init);
   'J': NM := New(JamMsgPtr, Init);
  Else
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Invalid type for netmail area: "'+Cfg^.Netmail[1]+'"!');
   Exit;
   End;
  End;
  NM^.SetMsgPath(Copy(Cfg^.Netmail, 2, Length(Cfg^.Netmail) - 1));
  {$I-} Error := NM^.OpenMsgBase; {$I+}
  If (Error <> 0) then
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, 'Couldn''t open netmail area "'+Cfg^.Netmail+
          '": Error '+IntToStr(Error)+'!');
   Dispose(NM, Done);
   Exit;
   End;
  NM^.SetMailType(mmtNetMail);
  CurArea := Cfg^.Areas;
  While (CurArea^.Next <> NIL) and (UpStr(CurAnnArea^.Area) <>
   UpStr(CurArea^.Name)) do CurArea := CurArea^.Next;
  CurConnUser := CurArea^.Users;

  While (CurConnUser <> NIL) do
   Begin
   {could the current user get files from us?}
   If (((CurConnUser^.User^.Flags and uf_NMAnn) > 0) and
    CurConnUser^.Receive and (CurConnUser^.User^.Active or
    ((CurArea^.Flags and fa_NoPause) > 0))) then
    Begin
    {check if there is any file which was not sent by the current user}
    CurAnnFile := CurAnnArea^.Files;
    While ((CurAnnFile^.Next <> NIL) and
     CompAddr(CurAnnFile^.Sender, CurConnUser^.User^.Addr)) do
     CurAnnFile := CurAnnFile^.Next;
    {only send announce if he really got files from us}
    If not CompAddr(CurAnnFile^.Sender, CurConnUser^.User^.Addr) then
     With NM^ do
     Begin
     LogSetCurLevel(LogHandle, 4);
     LogWriteLn(LogHandle, 'sending netmail announce to "'+
      CurConnUser^.User^.Name+'" ('+Addr2Str(CurConnUser^.User^.Addr)+')');
     StartNewMsg;
     SetTo(CurConnUser^.User^.Name);
     TNetAddr2MKAddr(CurConnUser^.User^.Addr, MKAddr);
     SetDest(MKAddr);
     s := 'ProTick'+Version;
     SetFrom(s);
     If not CompAddr(CurConnUser^.User^.OwnAddr, EmptyAddr) then
      TNetAddr2MKAddr(CurConnUser^.User^.OwnAddr, MKAddr)
     Else TNetAddr2MKAddr(CurArea^.Addr, MKAddr);
     SetOrig(MKAddr);
     SetSubj('new files arrived in Area '+CurAnnArea^.Area);
     SetLocal(True);
     SetPriv(True);
     SetKillSent(Cfg^.DelRsp);
     Today(DT);
     If (DT.Year > 100) then DT.Year := DT.Year mod 100;
     Now(DT);
     If (DT.Month > 9) then s := IntToStr(DT.Month) + '-'
     Else s := '0' + IntToStr(DT.Month) + '-';
     If (DT.Day > 9) then s := s + IntToStr(DT.Day) + '-'
     Else s := s + '0' + IntToStr(DT.Day) + '-';
     If (DT.Year > 9) then s := s + IntToStr(DT.Year)
     Else s := s + '0' + IntToStr(DT.Year);
     SetDate(s);
     If (DT.Hour > 9) then s := IntToStr(DT.Hour) + ':'
     Else s := '0' + IntToStr(DT.Hour) + ':';
     If (DT.Min > 9) then s := s + IntToStr(DT.Min)
     Else s := s + '0' + IntToStr(DT.Min);
     SetTime(s);
     If not CompAddr(CurConnUser^.User^.OwnAddr, EmptyAddr) then
      DoKludgeLn(#01'MSGID: '+Addr2Str(CurConnUser^.User^.OwnAddr)+' '+GetMsgID)
     Else DoKludgeLn(#01'MSGID: '+Addr2Str(CurArea^.Addr)+' '+GetMsgID);
     DoStringLn('The following files were sent to you today:');
     DoStringLn('');
     DoString('Area: '+CurAnnArea^.Area);
     If (CurAnnArea^.Desc <> '') then DoStringLn(' ('+CurAnnArea^.Desc+')')
     Else DoStringLn('');
     DoStringLn('-------------------------------------------------------------------------------');

     CurAnnFile := CurAnnArea^.Files;
     DoEndFile := False;
      Repeat
      With CurAnnFile^ do
       Begin
       s := Name;
       If (Length(s) < 12) then s := s + Copy(Leer, 1, 12 - Length(s));
       DoString(s+' ');
       If (Date.Year > 100) then Date.Year := Date.Year mod 100;
       Now(DT);
       If (Date.Day > 9) then s := IntToStr(Date.Day) + '.'
       Else s := '0' + IntToStr(Date.Day) + '.';
       If (Date.Month > 9) then s := s + IntToStr(Date.Month) + '.'
       Else s := s + '0' + IntToStr(Date.Month) + '.';
       If (Date.Year > 9) then s := s + IntToStr(Date.Year)
       Else s := s + '0' + IntToStr(Date.Year);
       DoString(s+' ');
       If (Size > 10000000) then
        Begin
        s := IntToStr(Size div 1000000);
        If (Length(s) < 9) then s := Copy(Leer, 1, 9 - Length(s))+ s;
        s := s + 'mb';
        End
       Else If (Size > 100000) then
        Begin
        s := IntToStr(Size div 1000);
        If (Length(s) < 9) then s := Copy(Leer, 1, 9 - Length(s))+ s;
        s := s + 'kb';
        End
       Else
        Begin
        s := IntToStr(Size);
        If (Length(s) < 10) then s := Copy(Leer, 1, 10 - Length(s))+ s;
        s := s + 'b';
        End;
       DoString(s+' ');
       If (Desc <> NIL) then
        Begin
        ODesc := Desc;
        b := False;
        p := StrPos(Pointer(Desc), Pointer(crlf));
{$ifdef OS2}
        While (p <> NIL) and (p < StrEnd(Pointer(Desc))) do
{$Else}
        While (p <> NIL) do
{$endif}
         Begin
         If not b then b := True Else DoString(Copy(Leer, 1, 34));
         i := 0;
          Repeat
          DoString(Desc^[i]);
          Inc(i);
          Until (Desc^[i] = #13) and (Desc^[i+1] = #10);
         DoStringLn('');
{$ifdef OS2}
         Desc := Pointer(StrPos(Pointer(Desc), Pointer(crlf))+2);
{$Else}
 {$ifdef FPC}
         Desc := Pointer(StrPos(Pointer(Desc), Pointer(crlf))+2);
 {$Else}
         Desc := Pointer(StrPos(Pointer(Desc), Pointer(crlf)));
         MemW[Seg(Desc):Ofs(Desc)+2] := MemW[Seg(Desc):Ofs(Desc)+2] + 2;
 {$endif}
{$endif}
         p := StrPos(Pointer(Desc), Pointer(crlf));
         End;
        If (Desc^[0] <> #0) then
         Begin
         i := 0;
          Repeat
          DoString(Desc^[i]);
          Inc(i);
          Until (Desc^[i] = #0);
         End;
        Desc := ODesc;
        End;
       DoStringLn('');
       End;

      If CurAnnFile^.Next = NIL then DoEndFile := True Else CurAnnFile := CurAnnFile^.Next;
      Until DoEndFile;

     DoStringLn('');
     DoStringLn('--- ProTick'+Version);
     Error := WriteMsg;
     If (Error <> 0) then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Couldn''t write announce to netmail area "'+
             Cfg^.Netmail+'": Error '+IntToStr(Error)+'!');
      End;
     End;
    End;
   CurConnUser := CurConnUser^.Next;
   End;
  If (NM^.CloseMsgBase <> 0) then
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Couldn''t close netmail area!');
    End;
  Dispose(NM, Done);
  If CurAnnArea^.Next = NIL then DoEndArea := True
  Else CurAnnArea := CurAnnArea^.Next;
  Until DoEndArea;

 FreeMem(crlf, 3);
 End;


Begin
Init;
If Command = 'TOSS' Then Toss
Else If Command = 'HATCH' Then Hatch
Else If Command = 'SCAN' Then Scan
Else If Command = 'NEWFILESHATCH' then NewFilesHatch
Else If Command = 'MAINT' Then Maint
Else If Command = 'PACK' Then _Pack
Else If Command = 'CHECK' Then {do nothing}
Else Syntax;
Done;
End.
