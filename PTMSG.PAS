Unit PTMsg;

InterFace

Uses
  DOS,
  Types, GeneralP,
  Log, MKMsgAbs, MKGlobT,
  PTRegKey, TickType, TickCons, PTVar, PTProcs;

Procedure ProcessMail;

Procedure ConnectArea(Name: String; DReScan: Boolean; RSParams: String);
Procedure ReScan(Name, Params: String);
Procedure DisConnectArea(Name: String);
Procedure SendRsp(_Type: Word; Params: String);
Procedure SetActive(Act: Boolean);
Procedure SetPack(Pack: String);
Procedure AKAMatch(InAddr: TNetAddr; var OutAddr: TNetAddr);

Implementation

Procedure ProcessMail;
Var
  MKAddr: AddrType;
  A1: TNetAddr;
  Pwd: String;
  s1: String;
  DoReScan: Boolean;
  ReScanParams: String;
  DoDelReq: Boolean;
  Body: PString80List;
  CurBody: PString80List;

  Begin
  DoReScan := False;
  ReScanParams := '';
  DoDelReq := Cfg^.DelReq;
  With NM^ do
    Begin
    LogSetCurLevel(LogHandle, 3);
    LogWriteLn(LogHandle, 'Processing msg #'+IntToStr(GetMsgNum));

    MsgTxtStartUp;
    SetRcvd(True);
    ReWriteHdr;

    GetOrig(MKAddr);
    MKAddr2TNetAddr(MKAddr, A1);
    LogSetCurLevel(LogHandle, 2);
    LogWriteLn(LogHandle, 'From: '+GetFrom+' ('+Addr2Str(A1)+')');

    GetDest(MKAddr);
    MKAddr2TNetAddr(MKAddr, A1);
    LogSetCurLevel(LogHandle, 5);
    LogWriteLn(LogHandle, 'To: '+GetTo+' ('+Addr2Str(A1)+')');

    GetOrig(MKAddr);
    MKAddr2TNetAddr(MKAddr, A1);
    Pwd := UpStr(GetSubj);

    If ((A1.Zone = 0) and (A1.Net = 0) and (A1.Node = 0)) then
      Begin
      LogSetCurLevel(LogHandle, 2);
      LogWriteLn(LogHandle, 'Unlisted sender: '+Addr2Str(A1));
      SendRsp(rs_Unlisted, '');
      Exit;
      End;
    CurUser := Cfg^.Users;
    While (not CompAddr(CurUser^.Addr, A1)) and (CurUser^.Next <> Nil) do
      CurUser := CurUser^.Next;
    If (not CompAddr(CurUser^.Addr, A1)) then
      Begin
      LogSetCurLevel(LogHandle, 2);
      LogWriteLn(LogHandle, 'Unlisted sender: '+Addr2Str(A1));
      SendRsp(rs_Unlisted, '');
      Exit;
      End;
    If (UpStr(CurUser^.Pwd) <> Pwd) then
      Begin
      LogSetCurLevel(LogHandle, 2);
      LogWriteLn(LogHandle, 'Wrong password! User: "'+CurUser^.Pwd+'" Msg: "'+Pwd+'"');
      SendRsp(rs_WrongPwd, Pwd);
      Exit;
      End;

    {read mail into stringlist}
    New(Body); Body^.s := ''; Body^.Next := NIL;
    CurBody := Body;
    While not EOM do
     Begin
     New(CurBody^.Next);
     CurBody := CurBody^.Next;
     CurBody^.Next := NIL;
     CurBody^.s := GetString;
     End;
    CurBody := Body;

    While (CurBody^.Next <> NIL) do
      Begin
      CurBody := CurBody^.Next;
      s1 := UpStr(CurBody^.s);
      s1 := KillTrailingSpcs(KillLeadingSpcs(s1));
      If (s1[1] = #1) then Continue;
      If (s1 = '') then Continue;
      If (s1 = #10) then Continue;
      If (s1[1] = '%') then
        Begin
        Delete(s1, 1, 1);
        If Pos('RESCAN', s1) = 1 then
          Begin
          DoRescan := True;
          If (Length(s1) > 7) then ReScanParams := Copy(s1, 8, Length(s1) - 8)
          Else ReScanParams := '';
          End
        Else If Pos('PAUSE', s1) = 1 then
          Begin
          If ((CurUser^.May and um_Pause) = 0) then
            Begin
            LogSetCurLevel(LogHandle, 2);
            LogWriteLn(LogHandle, 'User isn''t allowed to pause');
            SendRsp(rs_NoPause, '');
            End
          Else
            Begin
            SetActive(False);
            LogSetCurLevel(LogHandle, 3);
            LogWriteLn(LogHandle, 'paused.');
            SendRsp(rs_Pause, '');
            End;
          End
        Else If Pos('RESUME', s1) = 1 then
          Begin
          If ((CurUser^.May and um_Pause) = 0) then
            Begin
            LogSetCurLevel(LogHandle, 2);
            LogWriteLn(LogHandle, 'User isn''t allowed to resume');
            SendRsp(rs_NoPause, '');
            End
          Else
            Begin
            SetActive(True);
            LogSetCurLevel(LogHandle, 3);
            LogWriteLn(LogHandle, 'resumed.');
            SendRsp(rs_Resume, '');
            End;
          End
        Else If Pos('PACK', s1) = 1 then
          Begin
          If ((CurUser^.May and um_Compression) = 0) then
            Begin
            LogSetCurLevel(LogHandle, 2);
            LogWriteLn(LogHandle, 'User isn''t allowed change compression');
            SendRsp(rs_NoComp, '');
            End
          Else
            Begin
            Delete(s1, 1, 5);
            SetPack(s1);
            End;
          End
        Else If Pos('COMPRESSION', s1) = 1 then
          Begin
          If ((CurUser^.May and um_Compression) = 0) then
            Begin
            LogSetCurLevel(LogHandle, 2);
            LogWriteLn(LogHandle, 'User isn''t allowed change compression');
            SendRsp(rs_NoComp, '');
            End
          Else
            Begin
            Delete(s1, 1, 12);
            SetPack(s1);
            End;
          End
        Else If Pos('COMPRESS', s1) = 1 then
          Begin
          If ((CurUser^.May and um_Compression) = 0) then
            Begin
            LogSetCurLevel(LogHandle, 2);
            LogWriteLn(LogHandle, 'User isn''t allowed change compression');
            SendRsp(rs_NoComp, '');
            End
          Else
            Begin
            Delete(s1, 1, 9);
            SetPack(s1);
            End;
          End
        Else If (Pos('LIST', s1) = 1) then
          Begin
          SendRsp(rs_List, '');
          LogSetCurLevel(LogHandle, 3);
          LogWriteLn(LogHandle, 'sent list of available areas');
          End
        Else If (Pos('QUERY', s1) = 1) then
          Begin
          SendRsp(rs_Query, '');
          LogSetCurLevel(LogHandle, 3);
          LogWriteLn(LogHandle, 'sent list of connected areas');
          End
        Else If (Pos('UNLINKED', s1) = 1) then
          Begin
          SendRsp(rs_Unlinked, '');
          LogSetCurLevel(LogHandle, 3);
          LogWriteLn(LogHandle, 'sent list of disconnected areas');
          End
        Else If (Pos('HELP', s1) = 1) then
          Begin
          SendRsp(rs_Help, '');
          LogSetCurLevel(LogHandle, 3);
          LogWriteLn(LogHandle, 'sent help.');
          End
        Else If (Pos('QUIT', s1) = 1) then
          Begin
          Break;
          End
        Else If (Pos('NOTE', s1) = 1) then
          Begin
          Break;
          LogSetCurLevel(LogHandle, 3);
          LogWriteLn(LogHandle, '%NOTE');
          DoDelReq := False;
          End
        Else
          Begin
          LogSetCurLevel(LogHandle, 2);
          LogWriteLn(LogHandle, 'Unknown command "'+s1+'"');
          SendRsp(rs_UnKnownCmd, s1);
          SendRsp(rs_Help, '');
          End;
        End
      Else If (Copy(s1, 1, 3) = '---') then
        Begin
        Break;
        End
      Else If (s1[1] = '-') then
        Begin
        Delete(s1, 1, 1);
        s1 := KillTrailingSpcs(KillLeadingSpcs(s1));
        If (s1[1] <> '-') then
          Begin
          If ((CurUser^.May and um_DisConnect) = 0) then
            Begin
            LogSetCurLevel(LogHandle, 2);
            LogWriteLn(LogHandle, 'User isn''t allowed to disconnect areas');
            SendRsp(rs_NoDisConnect, '');
            End
          Else
            Begin
            DisConnectArea(s1);
            End;
          End;
        End
      Else If (s1[1] = '=') then
        Begin
        Delete(s1, 1, 1);
        s1 := KillTrailingSpcs(KillLeadingSpcs(s1));
        If ((CurUser^.May and um_Connect) = 0) then
          Begin
          LogSetCurLevel(LogHandle, 2);
          LogWriteLn(LogHandle, 'User isn''t allowed to connect areas');
          SendRsp(rs_NoConnect, '');
          End
        Else
          Begin
          ConnectArea(s1, True, ReScanParams);
          End;
        End
      Else If (Pos('...', s1) <> 1) then
        Begin
        If (s1[1] = '+') then Delete(s1, 1, 1);
        s1 := KillTrailingSpcs(KillLeadingSpcs(s1));
        If ((CurUser^.May and um_Connect) = 0) then
          Begin
          LogSetCurLevel(LogHandle, 2);
          LogWriteLn(LogHandle, 'User isn''t allowed to connect areas');
          SendRsp(rs_NoConnect, '');
          End
        Else
          Begin
          ConnectArea(s1, DoRescan, ReScanParams);
          End;
        End;
      End;

    CurBody := Body;
    While (CurBody <> NIL) do
     Begin
     Body := CurBody^.Next;
     Dispose(CurBody);
     CurBody := Body;
     End;

    If Cfg^.DelReq then DeleteMsg;
    End;
  End;

Procedure ConnectArea(Name: String; DReScan: Boolean; RSParams: String);
Var
  DoReScan: Boolean;
  i: LongInt;
  s: String;
  ReScanParams: String;
  A1: TNetAddr;
  Found: Boolean;
  DoAddArea: Boolean;
  SecFault: Boolean;

  Begin
  DoReScan := DReScan;
  ReScanParams := RSParams;
  Found := False;
  DoAddArea := False;
  SecFault := False;
  s := Name;
  i := Pos(',R', s);
  If (i > 0) then
    Begin
    DoReScan := True;
    If (i < (Length(s) - 3)) then ReScanParams := Copy(s, i+3, Length(s) - i - 3);
    s := Copy(s, 1, i - 1);
    End;
  CurArea := Cfg^.Areas;
  While (CurArea^.Next <> Nil) do
    Begin
    While ((CurArea^.Next <> Nil) and (not Match(UpStr(CurArea^.Name), s))) do CurArea := CurArea^.Next;
    If not (CurArea^.Group in CurUser^.Groups) then
      Begin
      If CurArea^.Next <> Nil then
        Begin
        CurArea := CurArea^.Next;
        Continue;
        End;
      SecFault := True;
      End
    Else
      Begin
      If (CurArea^.Level > CurUser^.Level) then
        Begin
        If CurArea^.Next <> Nil then
          Begin
          CurArea := CurArea^.Next;
          Continue;
          End;
        SecFault := True;
        End
      Else
        Begin
        If ((CurArea^.Flags and fa_RemoteChange) = 0) then
          Begin
          LogSetCurLevel(LogHandle, 2);
          LogWriteLn(LogHandle, 'Area "'+CurArea^.Name+'" may not be linked remotely');
          SendRsp(rs_NoRemote, CurArea^.Name);
          If CurArea^.Next <> Nil then
            Begin
            CurArea := CurArea^.Next;
            Continue;
            End;
          SecFault := True;
          End;
        End;
      End;
    If (not Match(UpStr(CurArea^.Name), s)) or SecFault then
      Begin
      If not Found then
        Begin
        LogSetCurLevel(LogHandle, 2);
        LogWriteLn(LogHandle, 'Area "'+s+'" not found');
        SendRsp(rs_UnKnownArea, s);
        End;
      End
    Else
      Begin
      Found := True;
      CurConnUser := CurArea^.Users;
      DoAddArea := False;
      If (CurConnUser <> NIL) then
        Begin
        While ((CurConnUser^.Next <> Nil) and (CurConnUser^.User <> CurUser)) do CurConnUser := CurConnUser^.Next;
        If (CurConnUser^.User <> CurUser) then
          Begin
          New(CurConnUser^.Next);
          CurConnUser^.Next^.Prev := CurConnUser;
          CurConnUser := CurConnUser^.Next;
          CurConnUser^.Next := Nil;
          CurConnUser^.User := CurUser;
          CurConnUser^.Receive := CurUser^.Receives;
          CurConnUser^.Send := CurUser^.Sends;
          DoAddArea := True;
          End;
        End
      Else
        Begin
        New(CurArea^.Users);
        CurConnUser := CurArea^.Users;
        CurConnUser^.Prev := NIL;
        CurConnUser^.Next := NIL;
        CurConnUser^.User := CurUser;
        CurConnUser^.Receive := CurUser^.Receives;
        CurConnUser^.Send := CurUser^.Sends;
        DoAddArea := True;
        End;
      If DoAddArea then
        Begin
        DoAddArea := False;
        With Ini do
          Begin
          SetSection('USER');
            Repeat
            While (UpStr(ReSecEnName) <> 'ADDR') do If not SetNextOpt then Break;
            If (UpStr(ReSecEnName) <> 'ADDR') then Break;
            Str2Addr(ReSecEnValue, A1);
            If CompAddr(A1, CurUser^.Addr) then Break;
            SetNextOpt;
            Until CompAddr(A1, CurUser^.Addr);
          If (not CompAddr(A1, CurUser^.Addr)) then
            Begin
            LogSetCurLevel(LogHandle, 1);
            LogWriteLn(LogHandle, 'User "'+CurUser^.Name+'" ('+Addr2Str(CurUser^.Addr)+') not found in ConfigFile!');
            End
          Else
            Begin
            LogSetCurLevel(LogHandle, 4);
            LogWriteLn(LogHandle, 'Connected to '+CurArea^.Name);
            SendRsp(rs_Connect, CurArea^.Name);
            InsertSecEntry('Area', CurArea^.Name, '');
            End;
          End;
        End
      Else
        Begin
        If (Pos('*', Name) = 0) and (Pos('?', Name) = 0) then
          Begin
          LogSetCurLevel(LogHandle, 4);
          LogWriteLn(LogHandle, 'Already connected to '+s);
          SendRsp(rs_AlreadyConn, s);
          End;
        End;
      End;
    If (CurArea^.Next <> Nil) then CurArea := CurArea^.Next;
    End;
  If DoReScan then ReScan(s, ReScanParams);
  End;

Procedure DisConnectArea(Name: String);
Var
  A1: TNetAddr;
  s: String;
  Found: Boolean;
  SecFault: Boolean;

  Begin
  CurArea := Cfg^.Areas;
  Found := False;
  SecFault := False;
  While (CurArea^.Next <> Nil) do
    Begin
    While ((CurArea^.Next <> Nil) and (not Match(UpStr(CurArea^.Name), Name))) do CurArea := CurArea^.Next;
    If ((CurArea^.Flags and fa_RemoteChange) = 0) then
      Begin
      LogSetCurLevel(LogHandle, 2);
      LogWriteLn(LogHandle, 'Area "'+CurArea^.Name+'" may not be unlinked remotely');
      SendRsp(rs_NoRemote, CurArea^.Name);
      If CurArea^.Next <> Nil then
        Begin
        CurArea := CurArea^.Next;
        Continue;
        End;
      SecFault := True;
      End;
    If ((CurArea^.Flags and fa_Mandatory) > 0) then
      Begin
      LogSetCurLevel(LogHandle, 2);
      LogWriteLn(LogHandle, 'Area "'+CurArea^.Name+'" is mandatory');
      SendRsp(rs_Mandatory, CurArea^.Name);
      If CurArea^.Next <> Nil then
        Begin
        CurArea := CurArea^.Next;
        Continue;
        End;
      SecFault := True;
      End;
    If (not Match(UpStr(CurArea^.Name), Name)) or SecFault then
      Begin
      If (not Found) and (not SecFault) then
        Begin
        LogSetCurLevel(LogHandle, 2);
        LogWriteLn(LogHandle, 'Area "'+Name+'" not found');
        SendRsp(rs_UnKnownArea, Name);
        End;
      End
    Else
      Begin
      Found := True;
      If (CurArea^.Users <> Nil) then
        Begin
        CurConnUser := CurArea^.Users;
        While ((CurConnUser^.Next <> Nil) and (CurConnUser^.User <> CurUser)) do CurConnUser := CurConnUser^.Next;
        If (CurConnUser^.User = CurUser) then
          Begin
          If (CurConnUser^.Next <> Nil) then
            Begin
            If (CurConnUser = CurArea^.Users) then
              Begin
              CurArea^.Users := CurConnUser^.Next;
              End
            Else
              Begin
              CurConnUser^.Prev^.Next := CurConnUser^.Next;
              CurConnUser^.Next^.Prev := CurConnUser^.Prev;
              End;
            End
          Else
            Begin
            If (CurConnUser = CurArea^.Users) then
              Begin
              CurArea^.Users := Nil;
              End
            Else
              Begin
              CurConnUser^.Prev^.Next := Nil;
              End;
            End;
          Dispose(CurConnUser);
          CurConnUser := NIL;
          With Ini do
            Begin
            SetSection('USER');
              Repeat
              While (UpStr(ReSecEnName) <> 'ADDR') do If not SetNextOpt then Break;
              If (UpStr(ReSecEnName) <> 'ADDR') then Break;
              Str2Addr(ReSecEnValue, A1);
              If CompAddr(A1, CurUser^.Addr) then Break;
              SetNextOpt;
              Until CompAddr(A1, CurUser^.Addr);
            If (not CompAddr(A1, CurUser^.Addr)) then
              Begin
              LogSetCurLevel(LogHandle, 1);
              LogWriteLn(LogHandle, 'User "'+CurUser^.Name+'" ('+Addr2Str(CurUser^.Addr)+') not found in ConfigFile!');
              End
            Else
              Begin
                Repeat
                If not SetNextOpt then Break;
                s := UpStr(ReSecEnValue);
                If (Pos(',', s) <> 0) then s := Copy(s, 1, Pos(',', s) - 1);
              Until ((UpStr(ReSecEnName) = 'AREA') and Match(s, UpStr(Name)));
              If Match(s, UpStr(Name)) then
                Begin
                LogSetCurLevel(LogHandle, 4);
                LogWriteLn(LogHandle, 'DisConnected from '+s);
                SendRsp(rs_DisConnect, s);
                DelCurEntry(False);
                End;
              End;
            End;
          End
        Else
          Begin
          If (Pos('*', Name) = 0) and (Pos('?', Name) = 0) then
            Begin
            LogSetCurLevel(LogHandle, 4);
            LogWriteLn(LogHandle, 'Not connected to '+Name);
            SendRsp(rs_NotConn, Name);
            End;
          End;
        End
      Else
        Begin
        If (Pos('*', Name) = 0) and (Pos('?', Name) = 0) then
          Begin
          LogSetCurLevel(LogHandle, 4);
          LogWriteLn(LogHandle, 'Not connected to '+Name);
          SendRsp(rs_NotConn, Name);
          End;
        End;
      End;
    If (CurArea^.Next <> Nil) then CurArea := CurArea^.Next;
    End;
  End;

Procedure ReScan(Name, Params: String);
  Begin
  If ((CurUser^.May and um_Rescan) = 0) then
    Begin
    LogSetCurLevel(LogHandle, 2);
    LogWriteLn(LogHandle, 'User isn''t allowed to rescan areas');
    SendRsp(rs_NoReScan, '');
    End
  Else
    Begin
    LogSetCurLevel(LogHandle, 3);
    LogWriteLn(LogHandle, 'Rescan not implemented.');
    SendRsp(rs_NotImplemented, 'Rescan');
    End;
  End;

Procedure SendRsp(_Type: Word; Params: String);
Var
  s: String;
  DT: TimeTyp;
  MKAddr: AddrType;
  A1: TNetAddr;

  Procedure SendList;
  Var
    CA: PArea;
    CG: Byte;
    CCG: Byte;
    Found: Byte;

    Begin
    With NM2^ do
      Begin
      DoStringLn('List of areas available to you:');
      DoStringLn('');
      For CG := 1 to 255 do If (CG in CurUser^.Groups) then
       Begin
       Found := 0;
       For CCG := 1 to Cfg^.NumGroups do If (Cfg^.Groups[CCG].Index = CG) then
        Begin Found := CCG; Break; End;
       If (Found > 0) then DoStringLn('Group '+Cfg^.Groups[Found].Name)
       Else DoStringLn('Group <unknown>');
       CA := Cfg^.Areas;
       If (CA^.Group = CG) and
         (CA^.Level <= CurUser^.Level) then
          DoStringLn(CA^.Name+Copy(Leer, 1, 30-Length(CA^.Name))+CA^.Desc);
         Repeat
         CA := CA^.Next;
         If (CA^.Group = CG) and ((CA^.Flags and fa_Hidden) = 0) and
           (CA^.Level <= CurUser^.Level) then
            DoStringLn(CA^.Name+Copy(Leer, 1, 30-Length(CA^.Name))+CA^.Desc);
         Until (CA^.Next = Nil);
       DoStringLn('');
       End;
      End;
    End;

  Procedure SendQuery;
  Var
    CA: PArea;
    CG: Byte;
    CCG: Byte;
    Found: Byte;
    WroteGroup: Boolean;

    Function CheckConn: Boolean;
    Var
      CCU: PConnectedUser;

      Begin
      CheckConn := False;
      If (CA^.Users = NIL) then Exit;
      CCU := CA^.Users;
      If (CCU^.User = CurUser) then
        Begin
        CheckConn := True;
        Exit;
        End;
      If (CCU^.Next = NIL) then Exit;
        Repeat
        CCU := CCU^.Next;
        If (CCU^.User = CurUser) then
          Begin
          CheckConn := True;
          Exit
          End;
        Until (CCU^.Next = NIL);
      End;

    Begin
    With NM2^ do
      Begin
      DoStringLn('List of connected areas:');
      DoStringLn('');
      For CG := 1 to 255 do 
       Begin
       WroteGroup := False;
       CA := Cfg^.Areas;
       If ((CA^.Group = CG) and CheckConn) then
        Begin
        If not WroteGroup then
         Begin
         WroteGroup := True;
         Found := 0;
         For CCG := 1 to Cfg^.NumGroups do If (Cfg^.Groups[CCG].Index = CG) then
          Begin Found := CCG; Break; End;
         If (Found > 0) then DoStringLn('Group '+Cfg^.Groups[Found].Name)
         Else DoStringLn('Group <unknown>');
         End;
        DoStringLn(CA^.Name+Copy(Leer, 1, 30-Length(CA^.Name))+CA^.Desc);
        End;
         Repeat
         CA := CA^.Next;
         If ((CA^.Group = CG) and CheckConn) then
          Begin
          If not WroteGroup then
           Begin
           WroteGroup := True;
           Found := 0;
           For CCG := 1 to Cfg^.NumGroups do If (Cfg^.Groups[CCG].Index = CG) then
            Begin Found := CCG; Break; End;
           If (Found > 0) then DoStringLn('Group '+Cfg^.Groups[Found].Name)
           Else DoStringLn('Group <unknown>');
           End;
          DoStringLn(CA^.Name+Copy(Leer, 1, 30-Length(CA^.Name))+CA^.Desc);
          End;
         Until (CA^.Next = Nil);
       If WroteGroup then DoStringLn('');
       End;
      End;
    End;

  Procedure SendUnlinked;
  Var
    CA: PArea;
    CG: Byte;
    CCG: Byte;
    Found: Byte;
    WroteGroup: Boolean;

    Function CheckConn: Boolean;
    Var
      CCU: PConnectedUser;

      Begin
      CheckConn := False;
      If (CA^.Users = NIL) then Exit;
      CCU := CA^.Users;
      If (CCU^.User = CurUser) then
        Begin
        CheckConn := True;
        Exit;
        End;
      If (CCU^.Next = NIL) then Exit;
        Repeat
        CCU := CCU^.Next;
        If (CCU^.User = CurUser) then
          Begin
          CheckConn := True;
          Exit
          End;
        Until (CCU^.Next = NIL);
      End;

    Begin
    With NM2^ do
      Begin
      DoStringLn('List of disconnected areas:');
      DoStringLn('');
      For CG := 1 to 255 do If (CG in CurUser^.Groups) then
       Begin
       CA := Cfg^.Areas;
       WroteGroup := False;
       If (CA^.Group = CG) and (CA^.Level <= CurUser^.Level) and
         (not CheckConn) then
         Begin
         If not WroteGroup then
          Begin
          WroteGroup := True;
          Found := 0;
          For CCG := 1 to Cfg^.NumGroups do If (Cfg^.Groups[CCG].Index = CG) then
           Begin Found := CCG; Break; End;
          If (Found > 0) then DoStringLn('Group '+Cfg^.Groups[Found].Name)
          Else DoStringLn('Group <unknown>');
          End;
         DoStringLn(CA^.Name+Copy(Leer, 1, 30-Length(CA^.Name))+CA^.Desc);
         End;

         Repeat
         CA := CA^.Next;
         If (CA^.Group = CG) and (CA^.Level <= CurUser^.Level) and
           ((CA^.Flags and fa_Hidden) = 0) and (not CheckConn) then
           Begin
           If not WroteGroup then
            Begin
            WroteGroup := True;
            Found := 0;
            For CCG := 1 to Cfg^.NumGroups do If (Cfg^.Groups[CCG].Index = CG) then
             Begin Found := CCG; Break; End;
            If (Found > 0) then DoStringLn('Group '+Cfg^.Groups[Found].Name)
            Else DoStringLn('Group <unknown>');
            End;
           DoStringLn(CA^.Name+Copy(Leer, 1, 30-Length(CA^.Name))+CA^.Desc);
           End;
         Until (CA^.Next = Nil);
       If WroteGroup then DoStringLn('');
       End;
      End;
    End;

  Procedure UnListed;
    Begin
    NM2^.DoStringLn('You are not listed in the configuration. Did you use the right AKA?');
    End;

  Procedure WrongPwd;
    Begin
    NM2^.DoStringLn('Wrong password:"'+Params+'"');
    End;

  Procedure UnKnownCmd;
    Begin
    NM2^.DoStringLn('Unknown command: "'+Params+'"');
    End;

  Procedure NoDisConnect;
    Begin
    NM2^.DoStringLn('You are not allowed to disconnect areas.');
    End;

  Procedure NoConnect;
    Begin
    NM2^.DoStringLn('You are not allowed to connect areas.');
    End;

  Procedure NoReScan;
    Begin
    NM2^.DoStringLn('You are not allowed to rescan areas.');
    End;

  Procedure UnKnownArea;
    Begin
    NM2^.DoStringLn('Unknown area: "'+Params+'"');
    End;

  Procedure AlreadyConn;
    Begin
    NM2^.DoStringLn('Area "'+Params+'" already connected.');
    End;

  Procedure NotConn;
    Begin
    NM2^.DoStringLn('Area "'+Params+'" not connected.');
    End;

  Procedure NoPause;
    Begin
    NM2^.DoStringLn('You are not allowed to pause.');
    End;

  Procedure NoComp;
    Begin
    NM2^.DoStringLn('You are not allowed to change compression.');
    End;

  Procedure UnKnownPacker;
    Begin
    NM2^.DoStringLn('Unknown packer: "'+Params+'"');
    End;

  Procedure NotImplemented;
    Begin
    NM2^.DoStringLn(Params+' not implemented yet.');
    End;

  Procedure Connect;
    Begin
    NM2^.DoStringLn(Params+' linked.');
    End;

  Procedure DisConnect;
    Begin
    NM2^.DoStringLn(Params+' unlinked.');
    End;

  Procedure Pause;
    Begin
    NM2^.DoStringLn('Paused.');
    End;

  Procedure Resume;
    Begin
    NM2^.DoStringLn('Resumed.');
    End;

  Procedure PackFiles;
    Begin
    NM2^.DoStringLn('PackFiles: '+Params);
    End;

  Procedure PackTICs;
    Begin
    NM2^.DoStringLn('PackTICs: '+Params);
    End;

  Procedure Packer;
    Begin
    NM2^.DoStringLn('Packer: '+Params);
    End;

  Procedure NoRemote;
    Begin
    NM2^.DoStringLn(Params+' may not be (un)linked remotely.');
    End;

  Procedure Mandatory;
    Begin
    NM2^.DoStringLn(Params+' is mandatory.');
    End;

  Procedure UnKnownResponse;
    Begin
    NM2^.DoStringLn('Unknown response (#'+Params+'). Please report to SysOp!');
    End;

  Procedure Help;
    Begin
    With NM2^ do
      Begin
      DoStringLn('available commands:');
      DoStringLn('');
      DoStringLn('%HELP           this help :)');
      DoStringLn('%LIST           list of areas available to you');
      DoStringLn('%QUERY          list of connected areas');
      DoStringLn('%UNLINKED       list of disconnected areas');
      DoStringLn('%PACK           \ on = pack all, off = pack none, files = pack files,');
      DoStringLn('%COMPRESS       | tics = pack tics, Extension = set packer to use');
      DoStringLn('%COMPRESSION    / examples: "%PACK ON", "%PACK ZIP"');
      DoStringLn('%PAUSE          stop sending files (e.g. for holiday)');
      DoStringLn('%RESUME         resume sending files (holiday over :) )');
      DoStringLn('%QUIT           everything below (e.g. signature) is ignored');
      DoStringLn('%NOTE           everything below is ignored, message will NOT be deleted');
      DoStringLn('<Area>          connect area');
      DoStringLn('+<Area>         connect area');
      DoStringLn('-<Area>         disconnect area');
      End;
    End;

  Procedure ParamNeeded;
    Begin
    NM2^.DoStringLn(Params+': parameter needed');
    End;


  Begin
  With NM2^ do
    Begin
    StartNewMsg;
    s := 'ProTick';
    SetFrom(s);
    SetKillSent(Cfg^.DelRsp);
    If (_Type <> rs_Unlisted) then
      Begin
      SetTo(CurUser^.Name);
      TNetAddr2MKAddr(CurUser^.Addr, MKAddr);
      SetDest(MKAddr);
      If not CompAddr(CurUser^.OwnAddr, EmptyAddr) then A1 := CurUser^.OwnAddr
      Else AKAMatch(CurUser^.Addr, A1);
      End
    Else
      Begin
      SetTo(NM^.GetFrom);
      NM^.GetOrig(MKAddr);
      SetDest(MKAddr);
      MKAddr2TNetAddr(MKAddr, A1);
      AKAMatch(A1, A1);
      End;
    TNetAddr2MKAddr(A1, MKAddr);
    SetOrig(MKAddr);
    SetLocal(True);
    SetPriv(True);
    SetSubj('FileFix response');
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
    SetRefer(NM^.GetMsgNum);
    DoKludgeLn(#01'MSGID: '+Addr2Str(A1)+' '+GetMsgID);

    Case _Type of
      rs_List: SendList;
      rs_Unlisted: UnListed;
      rs_WrongPwd: WrongPwd;
      rs_UnKnownCmd: UnKnownCmd;
      rs_NoDisConnect: NoDisConnect;
      rs_NoConnect: NoConnect;
      rs_NoReScan: NoReScan;
      rs_UnKnownArea: UnKnownArea;
      rs_AlreadyConn: AlreadyConn;
      rs_NotConn: NotConn;
      rs_NoPause: NoPause;
      rs_NoComp: NoComp;
      rs_UnKnownPacker: UnKnownPacker;
      rs_NotImplemented: NotImplemented;
      rs_Help: Help;
      rs_ParamNeeded: ParamNeeded;
      rs_Connect: Connect;
      rs_DisConnect: DisConnect;
      rs_Pause: Pause;
      rs_Resume: Resume;
      rs_PackFiles: PackFiles;
      rs_PackTICs: PackTICs;
      rs_Packer: Packer;
      rs_NoRemote: NoRemote;
      rs_Mandatory: Mandatory;
      rs_Query: SendQuery;
      rs_Unlinked: SendUnlinked;
      Else UnKnownResponse;
      End;

    DoStringLn('');
    DoStringLn('--- ProTick'+Version);
    If (WriteMsg <> 0) then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'Couldn''t write response!');
      Exit;
      End;
    NM^.InitMsgHdr;
    NM^.MsgTxtStartUp;
    NM^.SetSeeAlso(GetMsgNum);
    NM^.ReWriteHdr;
    End;
  End;

Procedure SetActive(Act: Boolean);
Var
  s1: String;
  A1: TNetAddr;

  Begin
  CurUser^.Active := Act;
  With Ini do
    Begin
    SetSection('USER');
      Repeat
      While (UpStr(ReSecEnName) <> 'ADDR') do If not SetNextOpt then Break;
      If (UpStr(ReSecEnName) <> 'ADDR') then Break;
      Str2Addr(ReSecEnValue, A1);
      If CompAddr(A1, CurUser^.Addr) then Break;
      SetNextOpt;
      Until CompAddr(A1, CurUser^.Addr);
    If not CompAddr(A1, CurUser^.Addr) then
      Begin
      LogSetCurLevel(LogHandle, 1);
      LogWriteLn(LogHandle, 'User "'+CurUser^.Name+'" ('+Addr2Str(CurUser^.Addr)+') not found in ConfigFile!');
      End
    Else
      Begin
      While ((UpStr(ReSecEnName) <> 'USER') and (UpStr(ReSecEnName) <> 'ACTIVE')) do If not SetNextOpt then Break;
      If (UpStr(ReSecEnName) = 'ACTIVE') then
        Begin
        If Act then WriteSecEntry('Active', 'Yes', '')
        Else WriteSecEntry('Active', 'No', '');
        End
      Else If (UpStr(ReSecEnName) = 'USER') then
        Begin
        SetPrevOpt;
        If Act then InsertSecEntry('Active', 'Yes', '')
        Else InsertSecEntry('Active', 'No', '');
        End
      Else
        Begin
        If Act then AddSecEntry('Active', 'Yes', '')
        Else AddSecEntry('Active', 'No', '');
        End;
      If Act then
        Begin
        LogSetCurLevel(LogHandle, 2);
        LogWriteLn(LogHandle, 'Set User '+CurUser^.Name+' ('+Addr2Str(CurUser^.Addr)+') to ACTIVE');
        End
      Else
        Begin
        LogSetCurLevel(LogHandle, 2);
        LogWriteLn(LogHandle, 'Set User '+CurUser^.Name+' ('+Addr2Str(CurUser^.Addr)+') to PASSIVE');
        End;
      End;
    End;
  End;

Procedure SetPack(Pack: String);
{PACK=ON/OFF/J/N/Y/YES/NO/JA/NEIN/0/1/ALL/FILES/TICS/NONE/<ArcExt>}
Var
  s: String;
  A1: TNetAddr;
  i: LongInt;
  ChTICs, ChFiles, ChPacker: Boolean;
  Found: LongInt;

  Begin
  ChTICs := False;
  ChFiles := False;
  ChPacker := False;
  While (Length(s) > 0) and (s[1] = ' ') do Delete(s, 1, 1);
  If (s = '') then
    Begin
    LogSetCurLevel(LogHandle, 3);
    LogWriteLn(LogHandle, 'set compression: parameter needed');
    SendRsp(rs_ParamNeeded, 'set compression');
    End;
  s := UpStr(Pack);
  If ((s = 'ON') or (s = 'Y') or (s = 'YES') or (s = '1') or (s = 'J') or
    (s = 'JA') or (s = 'ALL')) then
    Begin
    ChTICs := not CurUser^.PackTICs;
    ChFiles := not CurUser^.PackFiles;
    CurUser^.PackTICs := True;
    CurUser^.PackFiles := True;
    End
  Else If ((s = 'OFF') or (s = 'N') or (s = 'NO') or (s = '0') or (s = 'NEIN') or
    (s = 'NONE')) then
    Begin
    ChTICs := CurUser^.PackTICs;
    ChFiles := CurUser^.PackFiles;
    CurUser^.PackTICs := False;
    CurUser^.PackFiles := False;
    End
  Else If (s = 'FILES') then
    Begin
    ChTICs := not CurUser^.PackTICs;
    ChFiles := CurUser^.PackFiles;
    CurUser^.PackTICs := False;
    CurUser^.PackFiles := True;
    End
  Else If (s = 'TICS') then
    Begin
    ChTICs := CurUser^.PackTICs;
    ChFiles := not CurUser^.PackFiles;
    CurUser^.PackTICs := True;
    CurUser^.PackFiles := False;
    End
  Else
    Begin
    Found := 1;
    For i := 1 to Cfg^.NumPacker do If (s = Cfg^.Packer[i].Ext) then Begin Found := i; Break; End;
    If (s = Cfg^.Packer[Found].Ext) then
      Begin
      CurUser^.Packer := Cfg^.Packer[Found].Index;
      ChPacker := True;
      End
    Else
      Begin
      LogSetCurLevel(LogHandle, 3);
      LogWriteLn(LogHandle, 'Unknown Packer "'+s+'"');
      SendRsp(rs_UnKnownPacker, s);
      End;
    End;
  With Ini do
    Begin
    If ChFiles then
      Begin
      SetSection('USER');
        Repeat
        While (UpStr(ReSecEnName) <> 'ADDR') do If not SetNextOpt then Break;
        If (UpStr(ReSecEnName) <> 'ADDR') then Break;
        Str2Addr(ReSecEnValue, A1);
        If CompAddr(A1, CurUser^.Addr) then Break;
        SetNextOpt;
        Until CompAddr(A1, CurUser^.Addr);
      If not CompAddr(A1, CurUser^.Addr) then
        Begin
        LogSetCurLevel(LogHandle, 1);
        LogWriteLn(LogHandle, 'User "'+CurUser^.Name+'" ('+Addr2Str(CurUser^.Addr)+') not found in ConfigFile!');
        End
      Else
        Begin
        While ((UpStr(ReSecEnName) <> 'USER') and (UpStr(ReSecEnName) <> 'PACKFILES')) do If not SetNextOpt then Break;
        If (UpStr(ReSecEnName) = 'PACKFILES') then
          Begin
          If CurUser^.PackFiles then WriteSecEntry('PackFiles', 'Yes', '')
          Else WriteSecEntry('PackFiles', 'No', '');
          End
        Else If (UpStr(ReSecEnName) = 'USER') then
          Begin
          SetPrevOpt;
          If CurUser^.PackFiles then InsertSecEntry('PackFiles', 'Yes', '')
          Else InsertSecEntry('PackFiles', 'No', '');
          End
        Else
          Begin
          If CurUser^.PackFiles then AddSecEntry('PackFiles', 'Yes', '')
          Else AddSecEntry('PackFiles', 'No', '');
          End;
        If CurUser^.PackFiles then
          Begin
          LogSetCurLevel(LogHandle, 3);
          LogWriteLn(LogHandle, 'Set PackFiles for User '+CurUser^.Name+' ('+Addr2Str(CurUser^.Addr)+') to Yes');
          SendRsp(rs_PackFiles, 'On');
          End
        Else
          Begin
          LogSetCurLevel(LogHandle, 3);
          LogWriteLn(LogHandle, 'Set PackFiles for User '+CurUser^.Name+' ('+Addr2Str(CurUser^.Addr)+') to No');
          SendRsp(rs_PackFiles, 'Off');
          End;
        End;
      End;
    If ChTICs then
      Begin
      SetSection('USER');
        Repeat
        While (UpStr(ReSecEnName) <> 'ADDR') do If not SetNextOpt then Break;
        If (UpStr(ReSecEnName) <> 'ADDR') then Break;
        Str2Addr(ReSecEnValue, A1);
        If CompAddr(A1, CurUser^.Addr) then Break;
        SetNextOpt;
        Until CompAddr(A1, CurUser^.Addr);
      If not CompAddr(A1, CurUser^.Addr) then
        Begin
        LogSetCurLevel(LogHandle, 1);
        LogWriteLn(LogHandle, 'User "'+CurUser^.Name+'" ('+Addr2Str(CurUser^.Addr)+') not found in ConfigFile!');
        End
      Else
        Begin
        While ((UpStr(ReSecEnName) <> 'USER') and (UpStr(ReSecEnName) <> 'PACKTICS')) do If not SetNextOpt then Break;
        If (UpStr(ReSecEnName) = 'PACKTICS') then
          Begin
          If CurUser^.PackTICs then WriteSecEntry('PackTICs', 'Yes', '')
          Else WriteSecEntry('PackTICs', 'No', '');
          End
        Else If (UpStr(ReSecEnName) = 'USER') then
          Begin
          SetPrevOpt;
          If CurUser^.PackTICs then InsertSecEntry('PackTICs', 'Yes', '')
          Else InsertSecEntry('PackTICs', 'No', '');
          End
        Else
          Begin
          If CurUser^.PackTICs then AddSecEntry('PackTICs', 'Yes', '')
          Else AddSecEntry('PackTICs', 'No', '');
          End;
        If CurUser^.PackTICs then
          Begin
          LogSetCurLevel(LogHandle, 3);
          LogWriteLn(LogHandle, 'Set PackTICs for User '+CurUser^.Name+' ('+Addr2Str(CurUser^.Addr)+') to Yes');
          SendRsp(rs_PackTICs, 'On');
          End
        Else
          Begin
          LogSetCurLevel(LogHandle, 3);
          LogWriteLn(LogHandle, 'Set PackTICs for User '+CurUser^.Name+' ('+Addr2Str(CurUser^.Addr)+') to No');
          SendRsp(rs_PackTICs, 'Off');
          End;
        End;
      End;
    If ChPacker then
      Begin
      SetSection('USER');
        Repeat
        While (UpStr(ReSecEnName) <> 'ADDR') do If not SetNextOpt then Break;
        If (UpStr(ReSecEnName) <> 'ADDR') then Break;
        Str2Addr(ReSecEnValue, A1);
        If CompAddr(A1, CurUser^.Addr) then Break;
        SetNextOpt;
        Until CompAddr(A1, CurUser^.Addr);
      If not CompAddr(A1, CurUser^.Addr) then
        Begin
        LogSetCurLevel(LogHandle, 1);
        LogWriteLn(LogHandle, 'User "'+CurUser^.Name+'" ('+Addr2Str(CurUser^.Addr)+') not found in ConfigFile!');
        End
      Else
        Begin
        While ((UpStr(ReSecEnName) <> 'USER') and (UpStr(ReSecEnName) <> 'PACKER')) do If not SetNextOpt then Break;
        If (UpStr(ReSecEnName) = 'PACKER') then
          Begin
          WriteSecEntry('Packer', IntToStr(CurUser^.Packer), '')
          End
        Else If (UpStr(ReSecEnName) = 'USER') then
          Begin
          SetPrevOpt;
          InsertSecEntry('Packer', IntToStr(CurUser^.Packer), '')
          End
        Else
          Begin
          AddSecEntry('Packer', IntToStr(CurUser^.Packer), '')
          End;
        Found := 1;
        For i := 1 to Cfg^.NumPacker do If (CurUser^.Packer = Cfg^.Packer[i].Index) then Begin Found := i; Break; End;
        LogSetCurLevel(LogHandle, 3);
        LogWriteLn(LogHandle, 'Set Packer for User '+CurUser^.Name+' ('+
          Addr2Str(CurUser^.Addr)+') to '+IntToStr(CurUser^.Packer)+' ('+
          Cfg^.Packer[Found].Ext+')');
        SendRsp(rs_Packer, Cfg^.Packer[Found].Ext);
        End;
      End;
    End;
  End;

Procedure AKAMatch(InAddr: TNetAddr; var OutAddr: TNetAddr);
Var
  i: Byte;
  Found: Boolean;

  Begin
  Found := False;
  For i := 1 to Cfg^.NumAddrs do If (InAddr.Zone = Cfg^.Addrs[i].Zone) then
    Begin
    Found := True;
    OutAddr := Cfg^.Addrs[i];
    Break;
    End;
  If not Found then OutAddr := Cfg^.Addrs[1];
  End;


End.
