Unit PTCfg;

InterFace

Uses
  DOS,
  Log, IniFile,
  Types, GeneralP,
  PTRegKey, TickType, TickCons, PTVar, PTProcs;

Procedure ParseCfg;


Implementation

Var
  i: LongInt;
  s, s1: String;
{$IfDef VIRTUALPASCAL}
  Error: LongInt;
{$Else}
  Error: Integer;
{$EndIf}

Procedure IniError(s: String);
  Begin
  LogSetCurLevel(LogHandle, 1);
  LogWriteLn(LogHandle, s);
  MainDone;
  Halt(Err_Ini);
  End;


Procedure ParseFileAreas;
Var
  f: Text;
  si: Byte;

  Begin
  With Ini do
    Begin
    If GetSecNum('FILEAREAS') = 0 then IniError('No FileAreas defined');
    SetSection('FILEAREAS');
    Cfg^.NumAreas := 0;
    While UpStr(ReSecEnName) = 'AREA' do
      begin
      Inc(Cfg^.NumAreas);
      If (Cfg^.NumAreas > 1) then
        Begin
        New(CurArea^.Next);
        FillChar(CurArea^.Next^, SizeOf(TArea), 0);
        CurArea^.Next^.Prev := CurArea;
        CurArea := CurArea^.Next;
        CurArea^.Next := Nil;
        End
      Else
        Begin
        New(Cfg^.Areas);
        CurArea := Cfg^.Areas;
        FillChar(CurArea^, SizeOf(TArea), 0);
        CurArea^.Next := Nil;
        CurArea^.Prev := Nil;
        End;
      s := ReSecEnValue;
      CurArea^.Name := s;
      If Debug then WriteLn('Area "', CurArea^.Name, '"');
      If not SetNextOpt then Break;
      While UpStr(ReSecEnName) <> 'AREA' do
        Begin
        s := UpStr(ReSecEnName);
        If s = 'ADDR' then
          Begin
          s := UpStr(ReSecEnValue);
          Str2Addr(s, CurArea^.Addr);
          If Debug then WriteLn('Addr: ', Addr2Str(CurArea^.Addr));
          End
        Else If s = 'LEVEL' then
          Begin
          Val(ReSecEnValue, CurArea^.Level, Error);
{$IfDef FPC}
          If Error > 1 then
{$Else}
          If Error <> 0 then
{$EndIf}
            Begin
            LogWriteLn(LogHandle, 'Illegal level "'+ReSecEnValue+'" for Area "'+CurArea^.Name+'"');
            End;
          If Debug then WriteLn('Level: ', CurArea^.Level);
          End
        Else If s = 'GROUP' then
          Begin
          Val(ReSecEnValue, CurArea^.Group, Error);
          If Error <> 0 then
            Begin
            LogWriteLn(LogHandle, 'Illegal group "'+ReSecEnValue+'" for Area "'+CurArea^.Name+'"');
            End;
          If Debug then WriteLn('Group: ', CurArea^.Group);
          End
        Else If s = 'COSTPERMB' then
          Begin
          Val(ReSecEnValue, CurArea^.CostPerMB, Error);
{$IfDef FPC}
          If Error > 1 then
{$Else}
          If Error <> 0 then
{$EndIf}
            Begin
            LogWriteLn(LogHandle, 'Illegal cost "'+ReSecEnValue+'" for Area "'+CurArea^.Name+'"');
            End;
          If Debug then WriteLn('CostPerMB: ', CurArea^.CostPerMB);
          End
        Else If s = 'LASTHATCH' then
          Begin
          Val('$'+ReSecEnValue, CurArea^.LastHatch, Error);
          If Error <> 0 then
            Begin
            LogWriteLn(LogHandle, 'Illegal LastHatch time "'+ReSecEnValue+'" for Area "'+CurArea^.Name+'"');
            End;
          If Debug then WriteLn('LastHatch: ', CurArea^.LastHatch);
          End
        Else If s = 'DESC' then
          Begin
          CurArea^.Desc := ReSecEnValue;
          If Debug then WriteLn('Desc: ', CurArea^.Desc);
          End
        Else If s = 'BBSAREA' then
          Begin
          CurArea^.BBSArea := ReSecEnValue;
          If Debug then WriteLn('BBSArea: ', CurArea^.BBSArea);
          End
        Else If s = 'PATH' then
          Begin
          CurArea^.Path := RepEnv(ReSecEnValue);
          If Debug then WriteLn('Path: ', CurArea^.Path);
          If not DirExist(CurArea^.Path) then
           Begin
           If (Cfg^.CreateDirs) then
            Begin
            MakeDir(CurArea^.Path);
            LogSetCurLevel(LogHandle, 2);
            LogWriteLn(LogHandle, 'created directory "'+CurArea^.Path+'" for '+
             'area "'+CurArea^.Name+'"');
            End
           Else
            Begin
            LogSetCurLevel(LogHandle, 2);
            LogWriteLn(LogHandle, 'directory "'+CurArea^.Path+'" of '+
             'area "'+CurArea^.Name+'" does not exist!');
            End;
           End;
          End
        Else If s = 'MOVETO' then
          Begin
          CurArea^.MoveTo := RepEnv(ReSecEnValue);
          If Debug then WriteLn('MoveTo: ', CurArea^.MoveTo);
          If (CurArea^.MoveTo <> '') and not DirExist(CurArea^.MoveTo) then
           Begin
           If (Cfg^.CreateDirs) then
            Begin
            MakeDir(CurArea^.MoveTo);
            LogSetCurLevel(LogHandle, 2);
            LogWriteLn(LogHandle, 'created oldfiles-directory "'+CurArea^.MoveTo+'" for '+
             'area "'+CurArea^.Name+'"');
            End
           Else
            Begin
            LogWriteLn(LogHandle, 'oldfiles-directory "'+CurArea^.MoveTo+'" of '+
             'area "'+CurArea^.Name+'" does not exist!');
            End;
           End;
          End
        Else If s = 'REPLACEEXT' then
          Begin
          CurArea^.ReplaceExt := ReSecEnValue;
          If Debug then WriteLn('ReplaceExt: ', CurArea^.ReplaceExt);
          End
        Else If s = 'ANNOUNCE' then
          Begin
          s := ReSecEnValue;
          If (s <> '') then
            Begin
            While (Pos(',', s) <> 0) Do
              Begin
              Val(Copy(s, 1, Pos(',', s) - 1), si, Error);
              If (Error = 0) then CurArea^.AnnGroups := CurArea^.AnnGroups + [si]
              Else
                Begin
                LogSetCurLevel(LogHandle, 1);
                LogWriteLn(LogHandle, 'Invalid Announcegroup "'+Copy(s, 1, Pos(',', s) - 1)+'" for area "'+CurArea^.Name+'"');
                End;
              Delete(s, 1, Pos(',', s));
              End;
            Val(s, si, Error);
            If (Error = 0) then CurArea^.AnnGroups := CurArea^.AnnGroups + [si]
            Else
              Begin
              LogSetCurLevel(LogHandle, 1);
              LogWriteLn(LogHandle, 'Invalid Announcegroup "'+s+'" for area "'+CurArea^.Name+'"');
              End;
            If Debug then
              Begin
              Write('AnnounceGroups: ');
              For si := 1 to 255 do If (si in CurArea^.AnnGroups) then Write(si, ' ');
              WriteLn;
              End;
            End;
          End
        Else If s = 'FLAGS' then
          Begin
          s := ReSecEnValue;
          If (s <> '') then With CurArea^ do
            Begin
            While (s <> '') Do
              Begin
              If (Pos(',', s) <> 0) then
                Begin
                s1 := KillLeadingSpcs(UpStr(Copy(s, 1, Pos(',', s) - 1)));
                Delete(s, 1, Pos(',', s));
                End
              Else
                Begin
                s1 := KillLeadingSpcs(UpStr(s));
                s := '';
                End;
              If (s1 = 'DUPE') then Flags := Flags or fa_Dupe
              Else If (s1 = 'DUPECHECK') then Flags := Flags or fa_Dupe
              Else if (s1 = 'PASSTHROUGH') then Flags := Flags or fa_PT
              Else if (s1 = 'PT') then Flags := Flags or fa_PT
              Else if (s1 = 'CRC') then Flags := Flags or fa_CRC
              Else if (s1 = 'TOUCH') then Flags := Flags or fa_Touch
              Else if (s1 = 'MANDATORY') then Flags := Flags or fa_Mandatory
              Else if (s1 = 'MAN') then Flags := Flags or fa_Mandatory
              Else if (s1 = 'NOPAUSE') then Flags := Flags or fa_NoPause
              Else if (s1 = 'NEWFILESHATCH') then Flags := Flags or fa_NewFilesHatch
              Else if (s1 = 'NEW') then Flags := Flags or fa_NewFilesHatch
              Else if (s1 = 'HATCH') then Flags := Flags or fa_NewFilesHatch
              Else if (s1 = 'COSTSHARING') then Flags := Flags or fa_CS
              Else if (s1 = 'CS') then Flags := Flags or fa_CS
              Else if (s1 = 'HIDDEN') then Flags := Flags or fa_Hidden
              Else if (s1 = 'HID') then Flags := Flags or fa_Hidden
              Else if (s1 = 'REMOTECHANGE') then Flags := Flags or fa_RemoteChange
              Else if (s1 = 'REMOTE') then Flags := Flags or fa_RemoteChange
              Else if (s1 = 'REM') then Flags := Flags or fa_RemoteChange
              Else
                Begin
                LogSetCurLevel(LogHandle, 1);
                LogWriteLn(LogHandle, 'Invalid flag "'+s1+'" for area "'+Name+'"');
                End;
              End;
            End;
          End
        Else
          Begin
          LogWriteLn(LogHandle, 'Unknown or out of sequence keyword: "'+ ReSecEnName+ '='+ReSecEnValue+'"');
          End;
        If not SetNextOpt then Break;
        End;
      If Debug then WriteLn;
      end;
    If Cfg^.NumAreas = 0 then IniError('No FileAreas defined');
    If Debug then
      Begin
      WriteLn('<Return>');
      ReadLn;
      End;
    End;
  End;

Procedure ParseAddrs;
Var
 i: Word;

  Begin
  With Ini do
    Begin
    If GetSecNum('ADDRESSES') = 0 then IniError('No Addresses defined');
    SetSection('ADDRESSES');
    I := 0;
      Repeat
      Inc(i);
      Str2Addr(ReSecEnValue, Cfg^.Addrs[i]);
      If Debug then WriteLn('Addr = '+Addr2Str(Cfg^.Addrs[i]));
      Until not SetNextOpt;
    Cfg^.NumAddrs := i;
    End;
  If Debug then
    Begin
    WriteLn('<Return>');
    ReadLn;
    End;
  End;

Procedure ParseDomains;
Var
 s: String;
 i: Byte;

  Begin
  Cfg^.NumDomains := 0;
  With Ini do
    Begin
    If GetSecNum('DOMAINS') = 0 then Exit;
    SetSection('DOMAINS');
    i := 0;
      Repeat
      Inc(i);
      s := ReSecEnValue;
      Cfg^.Domains[i].Domain := Copy(s, 1, Pos(',', s)-1);
      Delete(s, 1, Pos(',', s));
      Cfg^.Domains[i].Abbrev := s;
      If Debug then WriteLn('Domain="'+Cfg^.Domains[i].Domain+'" Abbrev="'+
       Cfg^.Domains[i].Abbrev+'"');
      Until not SetNextOpt;
    Cfg^.NumDomains := i;
    End;
  If Debug then
    Begin
    WriteLn('<Return>');
    ReadLn;
    End;
  End;

Procedure ParsePackers;
  Begin
  With Ini do
    Begin
    If GetSecNum('PACKER') = 0 then
     Begin
     Cfg^.NumPacker := 0;
     Exit;
     End;
    SetSection('PACKER');
    I := 0;
      Repeat
      Inc(i);
      With Cfg^.Packer[i] do
        Begin
        s := ReSecEnValue;
        Val(Copy(s, 1, Pos(',', s) - 1), Index, Error);
        Delete(s, 1, Pos(',', s));
        Ext := Copy(s, 1, Pos(',', s) - 1);
        Delete(s, 1, Pos(',', s));
        Cmd := s;
        End;
      Until not SetNextOpt;
    Cfg^.NumPacker := i;
    End;
  If Debug then
    Begin
    WriteLn('<Return>');
    ReadLn;
    End;
  End;

Procedure ParseUnPackers;
  Begin
  With Ini do
    Begin
    If GetSecNum('UNPACKER') = 0 then
     Begin
     Cfg^.NumUnPacker := 0;
     Exit;
     End;
    SetSection('UNPACKER');
    I := 0;
      Repeat
      Inc(i);
      With Cfg^.UnPacker[i] do
        Begin
        s := ReSecEnValue;
        Val(Copy(s, 1, Pos(',', s) - 1), Index, Error);
        Delete(s, 1, Pos(',', s));
        Ext := Copy(s, 1, Pos(',', s) - 1);
        Delete(s, 1, Pos(',', s));
        Cmd := s;
        End;
      Until not SetNextOpt;
    Cfg^.NumUnPacker := i;
    End;
  If Debug then
    Begin
    WriteLn('<Return>');
    ReadLn;
    End;
  End;

Procedure ParseGroups;
  Begin
  With Ini do
    Begin
    If GetSecNum('GROUPS') = 0 then IniError('No Groups defined');
    SetSection('GROUPS');
    I := 0;
      Repeat
      Inc(i);
      With Cfg^.Groups[i] do
        Begin
        s := ReSecEnValue;
        Val(Copy(s, 1, Pos(',', s) - 1), Index, Error);
        Delete(s, 1, Pos(',', s));
        Name := s;
        End;
      Until not SetNextOpt;
    If (i = 0) then IniError('No Groups defined');
    Cfg^.NumGroups := i;
    End;
  If Debug then
    Begin
    WriteLn('<Return>');
    ReadLn;
    End;
  End;

Procedure ParseAnnGroups;
  Begin
  Cfg^.AnnGroups := NIL;
  With Ini do
    Begin
    If GetSecNum('ANNOUNCEGROUPS') = 0 then
     Begin
     Cfg^.NumAnnGroups := 0;
     Exit;
     End;
    SetSection('ANNOUNCEGROUPS');
    I := 0;
    While UpStr(ReSecEnName) = 'GROUP' do
      Begin
      Inc(i);
      If (i > 1) then
        Begin
        New(CurAnnGroup^.Next);
        CurAnnGroup^.Next^.Prev := CurAnnGroup;
        CurAnnGroup := CurAnnGroup^.Next;
        CurAnnGroup^.Next := NIL;
        End
      Else
        Begin
        New(Cfg^.AnnGroups);
        CurAnnGroup := Cfg^.AnnGroups;
        CurAnnGroup^.Next := NIL;
        CurAnnGroup^.Prev := NIL;
        End;
      With CurAnnGroup^ do
        Begin
        Index := 1;
        Name := '';
        Area := '';
        Subj := '';
        Typ := at_Echomail;
        FromName := '';
        ToName := '';
        With FromAddr do
          Begin
          Zone := 0;
          Net := 0;
          Node := 0;
          Domain := '';
          End;
        ToAddr := FromAddr;
        HeaderFile := '';
        FooterFile := '';
        End;
      s := RepEnv(ReSecEnValue);
      Val(Copy(s, 1, Pos(',', s) - 1), CurAnnGroup^.Index, Error);
      Delete(s, 1, Pos(',', s));
      CurAnnGroup^.Name := s;
      If Debug then WriteLn('AnnounceGroup ', CurAnnGroup^.Index, '(', CurAnnGroup^.Name, ')');

      If not SetNextOpt then Break;
      With CurAnnGroup^ do
        Begin
        While UpStr(ReSecEnName) <> 'GROUP' do
          Begin
          s := UpStr(ReSecEnName);
          If s = 'FROM' then
            Begin
            s := RepEnv(ReSecEnValue);
            FromName := Copy(s, 1, Pos(',', s)-1);
            Str2Addr(Copy(s, Pos(',', s)+1, Length(s)-Pos(',', s)), FromAddr);
            If Debug then WriteLn('From: ', FromName, ' (', Addr2Str(FromAddr), ')');
            End
          Else If s = 'TO' then
            Begin
            s := RepEnv(ReSecEnValue);
            ToName := Copy(s, 1, Pos(',', s)-1);
            Str2Addr(Copy(s, Pos(',', s)+1, Length(s)-Pos(',', s)), ToAddr);
            If Debug then WriteLn('To: ', ToName, ' (', Addr2Str(ToAddr), ')');
            End
          Else If s = 'AREA' then
            Begin
            Area := RepEnv(ReSecEnValue);
            If Debug then WriteLn('Area: ', Area);
            End
          Else If s = 'SUBJ' then
            Begin
            Subj := RepEnv(ReSecEnValue);
            If Debug then WriteLn('Subj: ', Subj);
            End
          Else If s = 'TYPE' then
            Begin
            s := UpStr(RepEnv(ReSecEnValue));
            If (s = 'ECHOMAIL') then Typ := at_EchoMail
            Else If (s = 'NETMAIL') then Typ := at_NetMail
            Else
             Begin
             LogSetCurLevel(LogHandle, 1);
             LogWriteLn(LogHandle, 'Invalid announcegroup-type: "'+s+'"!');
             End;
            If Debug then
             Begin
             Write('Type: ');
             Case Typ of
              at_Echomail: WriteLn('EchoMail');
              at_Netmail: WriteLn('NetMail');
              Else WriteLn('Invalid!');
              End;
             End;
            End
          Else If s = 'HEADERFILE' then
            Begin
            HeaderFile := RepEnv(ReSecEnValue);
            If Debug then WriteLn('HeaderFile: ', HeaderFile);
            End
          Else If s = 'FOOTERFILE' then
            Begin
            FooterFile := RepEnv(ReSecEnValue);
            If Debug then WriteLn('FooterFile: ', FooterFile);
            End
          Else
            Begin
            LogWriteLn(LogHandle, 'Unknown or out of sequence keyword: "'+ ReSecEnName+ '='+ReSecEnValue+'"');
            End;
          If not SetNextOpt then Break;
          End;
        End;
      End;
    Cfg^.NumAnnGroups := i;
    End;
  If Debug then
    Begin
    WriteLn('<Return>');
    ReadLn;
    End;
  End;

Procedure ParseUser;
Var
 si: Byte;

  Begin
  With Ini do
    Begin
    If GetSecNum('USER') = 0 then IniError('No Users defined');
    SetSection('USER');
    I := 0;
    While UpStr(ReSecEnName) = 'USER' do
      Begin
      Inc(i);
      If (i > 1) then
        Begin
        New(CurUser^.Next);
        FillChar(CurUser^.Next^, SizeOf(TUser), 0);
        CurUser^.Next^.Prev := CurUser;
        CurUser := CurUser^.Next;
        CurUser^.Next := Nil;
        End
      Else
        Begin
        New(Cfg^.Users);
        CurUser := Cfg^.Users;
        FillChar(CurUser^, SizeOf(TUser), 0);
        CurUser^.Next := Nil;
        CurUser^.Prev := Nil;
        End;
      s := ReSecEnValue;
      CurUser^.Name := s;
      If Debug then WriteLn('User "', CurUser^.Name, '"');

      If not SetNextOpt then Break;
      While UpStr(ReSecEnName) <> 'USER' do
        Begin
        s := UpStr(ReSecEnName);
        If s = 'ADDR' then
          Begin
          s := UpStr(ReSecEnValue);
          Str2Addr(s, CurUser^.Addr);
          CurUser^.ArcAddr := CurUser^.Addr;
          If Debug then WriteLn('Addr: ', Addr2Str(CurUser^.Addr));
          End
        Else If s = 'ARCADDR' then
          Begin
          s := UpStr(ReSecEnValue);
          Str2Addr(s, CurUser^.ArcAddr);
          If Debug then WriteLn('ArcAddr: ', Addr2Str(CurUser^.ArcAddr));
          End
        Else If s = 'OWNADDR' then
          Begin
          s := UpStr(ReSecEnValue);
          Str2Addr(s, CurUser^.OwnAddr);
          If Debug then WriteLn('OwnAddr: ', Addr2Str(CurUser^.OwnAddr));
          End
        Else If s = 'ACTIVE' then
          Begin
          s := UpStr(ReSecEnValue);
          CurUser^.Active := (s = 'TRUE') or (s = 'ON') or (s = '1') or (Pos('Y', s) <> 0);
          If Debug then WriteLn('Active: ', CurUser^.Active);
          End
        Else If s = 'PWD' then
          Begin
          CurUser^.Pwd := UpStr(ReSecEnValue);
          If Debug then WriteLn('Pwd: ', CurUser^.Pwd);
          End
        Else If s = 'LEVEL' then
          Begin
          Val(ReSecEnValue, CurUser^.Level, Error);
{$IfDef FPC}
          If Error > 1 then
{$Else}
          If Error <> 0 then
{$EndIf}
            Begin
            LogWriteLn(LogHandle, 'Illegal Level: "'+ReSecEnValue+'"');
            End;
          If Debug then WriteLn('Level: ', CurUser^.Level);
          End
        Else If s = 'GROUPS' then
          Begin
          s := ReSecEnValue;
          If (s <> '') then
            Begin
            While (Pos(',', s) <> 0) Do
              Begin
              Val(Copy(s, 1, Pos(',', s) - 1), si, Error);
              If (Error = 0) then CurUser^.Groups := CurUser^.Groups + [si]
              Else
                Begin
                LogSetCurLevel(LogHandle, 1);
                LogWriteLn(LogHandle, 'Invalid group "'+Copy(s, 1, Pos(',', s) - 1)+'" for user '+CurUser^.Name+
                  ' ('+Addr2Str(CurUser^.Addr)+')');
                End;
              Delete(s, 1, Pos(',', s));
              End;
            Val(s, si, Error);
            If (Error = 0) then CurUser^.Groups := CurUser^.Groups + [si]
            Else
              Begin
              LogSetCurLevel(LogHandle, 1);
              LogWriteLn(LogHandle, 'Invalid group "'+Copy(s, 1, Pos(',', s) - 1)+'" for user '+CurUser^.Name+
                ' ('+Addr2Str(CurUser^.Addr)+')');
              End;
            If Debug then
              Begin
              Write('Groups: ');
              For si := 1 to 255 do If (si in CurUser^.Groups) then Write(si, ' ');
              WriteLn;
              End;
            End;
          End
        Else If s = 'MAIL' then
          Begin
          s := UpStr(ReSecEnValue);
          If (s = 'NORMAL') then CurUser^.MailFlags := ml_Normal
          Else If (s = 'DIRECT') then CurUser^.MailFlags := ml_Direct
          Else If (s = 'HOLD') then CurUser^.MailFlags := ml_Hold
          Else If (s = 'CRASH') then CurUser^.MailFlags := ml_Crash
          Else
            Begin
            LogSetCurLevel(LogHandle, 1);
            LogWriteLn(LogHandle, 'Invalid mail status "'+s+'" for user '+CurUser^.Name);
            End;
          End
        Else If s = 'FLAGS' then
          Begin
          s := ReSecEnValue;
          If (s <> '') then With CurUser^ do
            Begin
            While (s <> '') Do
              Begin
              If (Pos(',', s) <> 0) then
                Begin
                s1 := KillLeadingSpcs(UpStr(Copy(s, 1, Pos(',', s) - 1)));
                Delete(s, 1, Pos(',', s));
                End
              Else
                Begin
                s1 := KillLeadingSpcs(UpStr(s));
                s := '';
                End;
              If (s1 = 'SENDTIC') then Flags := Flags or uf_SendTIC
              Else If (s1 = 'TIC') then Flags := Flags or uf_SendTIC
              Else if (s1 = 'NOTIFY') then Flags := Flags or uf_Notify
              Else if (s1 = 'AUTOCREATE') then Flags := Flags or uf_AutoCreate
              Else if (s1 = 'AC') then Flags := Flags or uf_AutoCreate
              Else if (s1 = 'ADMIN') then Flags := Flags or uf_Admin
              Else if (s1 = 'NMANNOUNCE') then Flags := Flags or uf_NMAnn
              Else if (s1 = 'NMANN') then Flags := Flags or uf_NMAnn
              Else
                Begin
                LogSetCurLevel(LogHandle, 1);
                LogWriteLn(LogHandle, 'Invalid flag "'+s1+'" for user '+Name+' ('+Addr2Str(Addr)+')');
                End;
              End;
            End;
          End
        Else If s = 'MAY' then
          Begin
          s := ReSecEnValue;
          If (s <> '') then With CurUser^ do
            Begin
            While (s <> '') Do
              Begin
              If (Pos(',', s) <> 0) then
                Begin
                s1 := KillLeadingSpcs(UpStr(Copy(s, 1, Pos(',', s) - 1)));
                Delete(s, 1, Pos(',', s));
                End
              Else
                Begin
                s1 := KillLeadingSpcs(UpStr(s));
                s := '';
                End;
              If (s1 = 'CONNECT') then May := May or um_Connect
              Else If (s1 = 'CONN') then May := May or um_Connect
              Else if (s1 = 'DISCONNECT') then May := May or um_DisConnect
              Else if (s1 = 'DISCONN') then May := May or um_DisConnect
              Else if (s1 = 'PAUSE') then May := May or um_Pause
              Else if (s1 = 'PASSWORD') then May := May or um_Pwd
              Else if (s1 = 'PWD') then May := May or um_Pwd
              Else if (s1 = 'COMPRESSION') then May := May or um_Compression
              Else if (s1 = 'COMP') then May := May or um_Compression
              Else if (s1 = 'TIC') then May := May or um_Tic
              Else if (s1 = 'NOTIFY') then May := May or um_Notify
              Else if (s1 = 'RESCAN') then May := May or um_Rescan
              Else
                Begin
                LogSetCurLevel(LogHandle, 1);
                LogWriteLn(LogHandle, 'Invalid permission "'+s1+'" for user '+Name+' ('+Addr2Str(Addr)+')');
                End;
              End;
            End;
          End
        Else If s = 'RECEIVES' then
          Begin
          s := UpStr(ReSecEnValue);
          CurUser^.Receives := (s = 'TRUE') or (s = 'ON') or (s = '1') or (Pos('Y', s) <> 0);
          If Debug then WriteLn('Receives: ', CurUser^.Receives);
          End
        Else If s = 'SENDS' then
          Begin
          s := UpStr(ReSecEnValue);
          CurUser^.Sends := (s = 'TRUE') or (s = 'ON') or (s = '1') or (Pos('Y', s) <> 0);
          If Debug then WriteLn('Sends: ', CurUser^.Sends);
          End
        Else If s = 'PACKTICS' then
          Begin
          s := UpStr(ReSecEnValue);
          CurUser^.PackTICs := (s = 'TRUE') or (s = 'ON') or (s = '1') or (Pos('Y', s) <> 0);
          If Debug then WriteLn('PackTICs: ', CurUser^.PackTICs);
          End
        Else If s = 'PACKFILES' then
          Begin
          s := UpStr(ReSecEnValue);
          CurUser^.PackFiles := (s = 'TRUE') or (s = 'ON') or (s = '1') or (Pos('Y', s) <> 0);
          If Debug then WriteLn('PackFiles: ', CurUser^.PackFiles);
          End
        Else If s = 'PACKER' then
          Begin
          Val(ReSecEnValue, CurUser^.Packer, Error);
          If Error <> 0 then
            Begin
            LogWriteLn(LogHandle, 'Illegal Packer: "'+ReSecEnValue+'"');
            End;
          If Debug then WriteLn('Packer: ', CurUser^.Packer);
          End
        Else If s = 'AUTOCREATE' then
          Begin
          Val(ReSecEnValue, CurUser^.ACGroup, Error);
          If Error <> 0 then
            Begin
            LogWriteLn(LogHandle, 'Illegal Group: "'+ReSecEnValue+'"');
            End;
          If Debug then WriteLn('AutoCreate: ', CurUser^.ACGroup);
          End
        Else If s = 'AREA' then
          Begin
          If Pos(',', ReSecEnValue) <> 0 then s := UpStr(Copy(ReSecEnValue, 1, Pos(',', ReSecEnValue) - 1))
          Else s := UpStr(ReSecEnValue);
          CurArea := Cfg^.Areas;
            While (UpStr(CurArea^.Name) <> s) do
              If (CurArea^.Next <> Nil) then CurArea := CurArea^.Next
              Else
                Begin
                LogWriteLn(LogHandle, 'Area '+s+' for User '+CurUser^.Name+' not found');
                Break;
                End;
          If (UpStr(CurArea^.Name) = s) then
            Begin
            If (CurArea^.Users = NIL) then
              Begin
              New(CurArea^.Users);
              CurConnUser := CurArea^.Users;
              CurConnUser^.Next := Nil;
              CurConnUser^.Prev := Nil;
              End
            Else
              Begin
              CurConnUser := CurArea^.Users;
              While (CurConnUser^.Next <> Nil) do CurConnUser := CurConnUser^.Next;
              New(CurConnUser^.Next);
              CurConnUser^.Next^.Prev := CurConnUser;
              CurConnUser := CurConnUser^.Next;
              CurConnUser^.Next := Nil;
              End;
            With CurConnUser^ do
              Begin
              User := CurUser;
              s := UpStr(ReSecEnValue);
              If Pos(',', s) = 0 then
                Begin
                Receive := True;
                Send := False;
                End
              Else
                Begin
                Delete(s, 1, Pos(',', s));
                Receive := (Pos('R', s) <> 0);
                Send := (Pos('S', s) <> 0);
                End;
              End;
            If Debug then
              Begin
              Write('Area ', CurArea^.Name, ': ');
              If CurConnUser^.Send then Write('Send ');
              If CurConnUser^.Receive then Write('Receive ');
              WriteLn;
              End;
            End;
          End
        Else
          Begin
          LogWriteLn(LogHandle, 'Unknown or out of sequence keyword: "'+ ReSecEnName+ '='+ReSecEnValue+'"');
          End;
        If not SetNextOpt then Break;
        End;
      If Debug then WriteLn;
      end;
    If i = 0 then IniError('No Users defined');
    Cfg^.NumUser := i;
    If Debug then
      Begin
      WriteLn('<Return>');
      ReadLn;
      End;
    End;
  End;

Procedure ParseUpLinks;
  Begin
  Cfg^.UpLinks := NIL;
  With Ini do
    Begin
    If GetSecNum('UPLINKS') = 0 then
     Begin
     Cfg^.NumUpLinks := 0;
     Exit;
     End;
    SetSection('UPLINKS');
    I := 0;
    While UpStr(ReSecEnName) = 'UPLINK' do
      begin
      Inc(i);
      If (i > 1) then
        Begin
        New(CurUpLink^.Next);
        CurUpLink^.Next^.Prev := CurUpLink;
        CurUpLink := CurUpLink^.Next;
        CurUpLink^.Next := Nil;
        End
      Else
        Begin
        New(Cfg^.UpLinks);
        CurUpLink := Cfg^.UpLinks;
        CurUpLink^.Next := Nil;
        CurUpLink^.Prev := Nil;
        End;
      s := ReSecEnValue;
      CurUpLink^.Comment := s;
      If Debug then WriteLn('UpLink "', CurUpLink^.Comment, '"');
      With CurUpLink^ do
        Begin
        Name := '';
        Group:=0;
        Level:=0;
        With Addr do
          Begin
          Zone := 0;
          Net := 0;
          Node := 0;
          Point := 0;
          Domain := '';
          End;
        Pwd := '';
        AreaList := '';
        Unconditional := False;
        End;

      If not SetNextOpt then Break;
      While UpStr(ReSecEnName) <> 'UPLINK' do
        Begin
        s := UpStr(ReSecEnName);
        If  s = 'CONFMGR' then
          Begin
          CurUpLink^.Name := ReSecEnValue;
          If Debug then WriteLn('ConfMgr: ', CurUpLink^.Name);
          End
        Else If s = 'GROUP' then
          Begin
          s := ReSecEnValue;
          Val(s, i, Error);
          If Error <> 0 then
            Begin
            LogWriteLn(LogHandle, 'Illegal Group: "'+s+'"');
            End
          Else CurUpLink^.Group := i;
          If Debug then
            Begin
            WriteLn('Group: ', CurUpLink^.Group);
            End;
          End
        Else If s = 'LEVEL' then
          Begin
          Val(ReSecEnValue, CurUpLink^.Level, Error);
{$IfDef FPC}
          If Error > 1 then
{$Else}
          If Error <> 0 then
{$EndIf}
            Begin
            LogWriteLn(LogHandle, 'Illegal Level: "'+ReSecEnValue+'"');
            End;
          If Debug then WriteLn('Level: ', CurUpLink^.Level);
          End
        Else If s = 'ADDR' then
          Begin
          Str2Addr(ReSecEnValue, CurUpLink^.Addr);
          If Debug then WriteLn('Addr: ', Addr2Str(CurUpLink^.Addr));
          End
        Else If s = 'PWD' then
          Begin
          CurUpLink^.Pwd := ReSecEnValue;
          If Debug then WriteLn('Pwd: ', CurUpLink^.Pwd);
          End
        Else If s = 'AREALIST' then
          Begin
          CurUpLink^.AreaList := RepEnv(ReSecEnValue);
          If Debug then WriteLn('AreaList: ', CurUpLink^.AreaList);
          End
        Else If s = 'UNCONDITIONAL' then
          Begin
          s := UpStr(ReSecEnValue);
          CurUser^.Receives := (s = 'TRUE') or (s = 'ON') or (Pos('Y', s) <> 0);
          If Debug then WriteLn('Unconditional: ', CurUser^.Receives);
          End
        Else
          Begin
          LogWriteLn(LogHandle, 'Unknown or out of sequence keyword: '+ ReSecEnName);
          End;
        If not SetNextOpt then Break;
        End;
      If Debug then WriteLn;
      end;
    Cfg^.NumUpLinks := i;
    If Debug then
      Begin
      WriteLn('<Return>');
      ReadLn;
      End;
    End;
  End;

Procedure ParseArcNames;
  Begin
  With Ini do
    Begin
    If GetSecNum('ARCNAMES') = 0 then
     Begin
     Cfg^.NumArcNames := 0;
     Exit;
     End;
    SetSection('ARCNAMES');
    I := 0;
      Repeat
      If UpStr(ReSecEnName) = 'ARCNAME' then
        begin
        Inc(i);
        s := RepEnv(ReSecEnValue);
        Cfg^.ArcNames[i].FileName := Copy(s, 1, Pos(',', s) - 1);
        Val(Copy(s, Pos(',', s) + 1, Length(s) - Pos(',', s)), Cfg^.ArcNames[i].UnPacker, Error);
        If Debug then WriteLn('ArcName: "', Cfg^.ArcNames[i].FileName, ',', Cfg^.ArcNames[i].UnPacker, '"');
        end;
      Until not SetNextOpt;
    Cfg^.NumArcNames := i;

    If Debug then
      Begin
      WriteLn('<Return>');
      ReadLn;
      End;
    End;
  End;

Procedure ParseMgrNames;
  Begin
  With Ini do
    Begin
    If GetSecNum('MGRNAMES') = 0 then IniError('No MgrNames defined');
    SetSection('MGRNAMES');
    I := 0;
      Repeat
      If UpStr(ReSecEnName) = 'MGRNAME' then
        begin
        Inc(i);
        Cfg^.MgrNames[i] := RepEnv(ReSecEnValue);
        If Debug then WriteLn('MgrName: "', Cfg^.MgrNames[i], '"');
        end;
      Until not SetNextOpt;
    If i = 0 then IniError('No MgrNames defined');
    Cfg^.NumMgrNames := i;
    End;
  If Debug then
    Begin
    WriteLn('<Return>');
    ReadLn;
    End;
  End;

Procedure ParseCfg;
  Begin
  Ini.Init(CfgName);
  With Ini do
    Begin
    s := RepEnv(ReadEntry('GENERAL', 'LOG'));
    If (s = '') then
      Begin
      WriteLn('No Log defined!');
      Ini.Done;
      FreeMem(HDesc, 65535);
      Halt(Err_NoLog);
      End;
    LogHandle := OpenLog(Binkley, s, 'PROTICK', 'ProTick'+Version);
    If (LogHandle = 0) then
      Begin
      WriteLn('Couldn''t open Log!');
      Ini.Done;
      FreeMem(HDesc, 65535);
      Halt(Err_NoLog);
      End;
    New(Cfg);
    Cfg^.Areas := Nil;
    Cfg^.Users := Nil;
    Cfg^.UpLinks := Nil;
    Cfg^.CheckDest := True;
    FSplit(CfgName, Cfg^.DataPath, s, s);
    s := RepEnv(ReadEntry('GENERAL', 'LogLevel'));
    If (s = '') then LogSetLogLevel(LogHandle, 5)
    Else
      Begin
      Val(s, i, Error);
      LogSetLogLevel(LogHandle, i);
      End;

    s := RepEnv(ReadEntry('GENERAL', 'DispLevel'));
    If (s = '') then LogSetScrLevel(LogHandle, 5)
    Else
      Begin
      Val(s, i, Error);
      LogSetScrLevel(LogHandle, i);
      End;
    If (ReadEntry('GENERAL', 'CREATEDIRS') <> '') then
      Begin
      s := UpStr(ReadEntry('GENERAL', 'CREATEDIRS'));
      Cfg^.CreateDirs := ((s = 'ON') or (s = 'Y') or (s = 'YES') or (s = '1') or
      (s = 'J') or (s = 'JA'));
      End
    Else Cfg^.CreateDirs := False;

    Cfg^.FlagDir := RepEnv(ReadEntry('GENERAL', 'FLAGDIR'));
    If (Cfg^.FlagDir = '') then IniError('No Semaphore directory defined!');
    If (not DirExist(Cfg^.FlagDir)) then
     Begin
     If Cfg^.CreateDirs then
      Begin
      MakeDir(Cfg^.FlagDir);
      LogSetCurLevel(LogHandle, 2);
      LogWriteLn(LogHandle, 'created semaphore-directory "'+Cfg^.FlagDir+'"');
      End
     Else
      Begin
      LogSetCurLevel(LogHandle, 2);
      LogWriteLn(LogHandle, 'semaphore-directory "'+Cfg^.FlagDir+'" does not exist!');
      End
     End;

    Cfg^.InBound := RepEnv(ReadEntry('GENERAL', 'INBOUND'));
    If (Cfg^.InBound = '') then IniError('No InBound defined!');
    If (not DirExist(Cfg^.Inbound)) then
     Begin
     If Cfg^.CreateDirs then
      Begin
      MakeDir(Cfg^.Inbound);
      LogSetCurLevel(LogHandle, 2);
      LogWriteLn(LogHandle, 'created inbound-directory "'+Cfg^.Inbound+'"');
      End
     Else
      Begin
      LogSetCurLevel(LogHandle, 2);
      LogWriteLn(LogHandle, 'inbound-directory "'+Cfg^.Inbound+'" does not exist!');
      End
     End;

    s := UpStr(ReadEntry('GENERAL', 'OBTYPE'));
    If (s = 'BT') then Cfg^.OBType := OB_BT
    Else If (s = 'FD') then Cfg^.OBType := OB_FD
    Else If (s = 'TMAIL') then Cfg^.OBType := OB_TMail
    Else IniError('invalid outbound-type "'+s+'"!');

    Cfg^.OutBound := RepEnv(ReadEntry('GENERAL', 'OUTBOUND'));
    If ((Cfg^.OutBound = '') and (Cfg^.OBType <> OB_TMail)) then
     IniError('No OutBound defined!');
    If (Cfg^.OBType = OB_BT) then
    If (not DirExist(Cfg^.Outbound)) then
     Begin
     If Cfg^.CreateDirs then
      Begin
      MakeDir(Cfg^.Outbound);
      LogSetCurLevel(LogHandle, 2);
      LogWriteLn(LogHandle, 'created outbound-directory "'+Cfg^.OutBound+'"');
      End
     Else
      Begin
      LogSetCurLevel(LogHandle, 2);
      LogWriteLn(LogHandle, 'outbound-directory "'+Cfg^.Outbound+'" does not exist!');
      End
     End;

    Cfg^.TicOut := RepEnv(ReadEntry('GENERAL', 'TICOUT'));
    If (Cfg^.TicOut = '') then Cfg^.TicOut := Cfg^.OutBound;
    If (not DirExist(Cfg^.TicOut)) then
     Begin
     If Cfg^.CreateDirs then
      Begin
      MakeDir(Cfg^.TicOut);
      LogSetCurLevel(LogHandle, 2);
      LogWriteLn(LogHandle, 'created tic-directory "'+Cfg^.TicOut+'"');
      End
     Else
      Begin
      LogSetCurLevel(LogHandle, 2);
      LogWriteLn(LogHandle, 'tic-directory "'+Cfg^.TicOut+'" does not exist!');
      End
     End;

    Cfg^.NetMail := RepEnv(ReadEntry('GENERAL', 'NETMAIL'));
    If (Cfg^.NetMail = '') then IniError('No NetMail area defined!');

    Cfg^.Bad := RepEnv(ReadEntry('GENERAL', 'BAD'));
    If (Cfg^.Bad = '') then IniError('No BadFiles directory defined!');
    If (not DirExist(Cfg^.Bad)) then
     Begin
     If Cfg^.CreateDirs then
      Begin
      MakeDir(Cfg^.Bad);
      LogSetCurLevel(LogHandle, 2);
      LogWriteLn(LogHandle, 'created badfiles-directory "'+Cfg^.Bad+'"');
      End
     Else
      Begin
      LogSetCurLevel(LogHandle, 2);
      LogWriteLn(LogHandle, 'badfiles-directory "'+Cfg^.Bad+'" does not exist!');
      End
     End;

    Cfg^.PT := RepEnv(ReadEntry('GENERAL', 'PASSTHROUGH'));
    If (Cfg^.PT = '') then IniError('No Passthrough directory defined!');
    If (not DirExist(Cfg^.PT)) then
     Begin
     If Cfg^.CreateDirs then
      Begin
      MakeDir(Cfg^.PT);
      LogSetCurLevel(LogHandle, 2);
      LogWriteLn(LogHandle, 'created passthrough-directory "'+Cfg^.PT+'"');
      End
     Else
      Begin
      LogSetCurLevel(LogHandle, 2);
      LogWriteLn(LogHandle, 'passthrough-directory "'+Cfg^.PT+'" does not exist!');
      End
     End;

    Val(RepEnv(ReadEntry('GENERAL', 'DESCPOS')), Cfg^.DescPos, Error);

    If (ReadEntry('GENERAL', 'LDESCSTRING') <> '') then
     Begin
     s := ReadEntry('GENERAL', 'LDESCSTRING');
     Cfg^.LDescString := s;
     End
    Else Cfg^.LDescString := ' ';

    If (ReadEntry('GENERAL', 'ADDDLCOUNT') <> '') then
     Begin
     s := UpStr(ReadEntry('GENERAL', 'ADDDLCOUNT'));
     Cfg^.AddDLC := ((s = 'ON') or (s = 'Y') or (s = 'YES') or (s = '1') or
     (s = 'J') or (s = 'JA'));
     End
    Else Cfg^.AddDLC := False;

    If (ReadEntry('GENERAL', 'SINGLEDESCLINE') <> '') then
     Begin
     s := UpStr(ReadEntry('GENERAL', 'SINGLEDESCLINE'));
     Cfg^.SingleDescLine := ((s = 'ON') or (s = 'Y') or (s = 'YES') or (s = '1') or
     (s = 'J') or (s = 'JA'));
     End
    Else Cfg^.SingleDescLine := False;

    Val(RepEnv(ReadEntry('GENERAL', 'DLCOUNTDIGITS')), Cfg^.DLCDig, Error);
    If (Cfg^.AddDLC and (Cfg^.DLCDig = 0)) then
     IniError('Invalid DLCountDigits!');

    Val(RepEnv(ReadEntry('GENERAL', 'MAXDUPEAGE')), Cfg^.MaxDupeAge, Error);
    If (Cfg^.MaxDupeAge = 0) then IniError('Invalid MaxDupeAge!');

    If (ReadEntry('GENERAL', 'CHECKDEST') <> '') then
      Begin
      s := UpStr(ReadEntry('GENERAL', 'CHECKDEST'));
      Cfg^.CheckDest := ((s = 'ON') or (s = 'Y') or (s = 'YES') or (s = '1') or
      (s = 'J') or (s = 'JA'));
      End
    Else Cfg^.CheckDest := True;

    If (ReadEntry('GENERAL', 'DELREQ') <> '') then
      Begin
      s := UpStr(ReadEntry('GENERAL', 'DELREQ'));
      Cfg^.DelReq := ((s = 'ON') or (s = 'Y') or (s = 'YES') or (s = '1') or
      (s = 'J') or (s = 'JA'));
      End
    Else Cfg^.DelReq := False;

    If (ReadEntry('GENERAL', 'DELRSP') <> '') then
      Begin
      s := UpStr(ReadEntry('GENERAL', 'DELRSP'));
      Cfg^.DelRsp := ((s = 'ON') or (s = 'Y') or (s = 'YES') or (s = '1') or
      (s = 'J') or (s = 'JA'));
      End
    Else Cfg^.DelRsp := False;

    Cfg^.LocalPwd := ReadEntry('GENERAL', 'LOCALPWD');
    If (Cfg^.LocalPwd = '') then IniError('No LocalPwd defined!');

    If (ReadEntry('GENERAL', 'LONGDIRNAMES') <> '') then
      Begin
      s := UpStr(ReadEntry('GENERAL', 'LONGDIRNAMES'));
      Cfg^.LongDirNames := ((s = 'ON') or (s = 'Y') or (s = 'YES') or (s = '1') or
      (s = 'J') or (s = 'JA'));
      End
    Else Cfg^.LongDirNames := False;

    If (ReadEntry('GENERAL', 'SPLITDIRS') <> '') then
      Begin
      s := UpStr(ReadEntry('GENERAL', 'SPLITDIRS'));
      Cfg^.SplitDirs := ((s = 'ON') or (s = 'Y') or (s = 'YES') or (s = '1') or
      (s = 'J') or (s = 'JA'));
      End
    Else Cfg^.SplitDirs := True;

    Cfg^.AreasLog := RepEnv(ReadEntry('GENERAL', 'AREASLOG'));
    If (Cfg^.AreasLog = '') then Cfg^.AreasLog := Cfg^.DataPath + 'areas.log';

    Cfg^.BBSAreaLog := RepEnv(ReadEntry('GENERAL', 'BBSAREALOG'));
    If (Cfg^.BBSAreaLog = '') then Cfg^.BBSAreaLog := Cfg^.DataPath + 'bbsarea.log';

    Cfg^.LNameLst := RepEnv(ReadEntry('GENERAL', 'LONGNAMELST'));
    If (Cfg^.LNameLst = '') then Cfg^.LNameLst := Cfg^.DataPath + 'longname.lst';

    Cfg^.NewAreasLst := RepEnv(ReadEntry('GENERAL', 'NEWAREASLST'));
    If (Cfg^.NewAreasLst = '') then Cfg^.NewAreasLst := Cfg^.DataPath + 'newareas.pt';

    Cfg^.ArcLst := RepEnv(ReadEntry('GENERAL', 'ARCLST'));
    If (Cfg^.ArcLst = '') then Cfg^.ArcLst := Cfg^.DataPath + 'arc.lst';

    Cfg^.PTLst := RepEnv(ReadEntry('GENERAL', 'PTLST'));
    If (Cfg^.PTLst = '') then Cfg^.PTLst := Cfg^.DataPath + 'pt.lst';

    Cfg^.MsgIDFile := RepEnv(ReadEntry('GENERAL', 'MSGIDFILE'));
    If (Cfg^.MsgIDFile = '') then
     Begin
     If (GetEnv('MSGID') <> '') then Cfg^.MsgIDFile :=
      AddDirSep(GetEnv('MSGID'))+'msgid.dat'
     Else Cfg^.MsgIDFile := Cfg^.DataPath + 'msgid.dat';
     End;

    Cfg^.DupeFile := RepEnv(ReadEntry('GENERAL', 'DUPEFILE'));
    If (Cfg^.DupeFile = '') then Cfg^.DupeFile := Cfg^.DataPath + 'protick.dup';

    If (ReadEntry('GENERAL', 'FILEUMASK') <> '') then
     Begin
     FilePerm := OctalStrToInt(RepEnv(ReadEntry('GENERAL', 'FILEUMASK')));
     FilePerm := 511 and not FilePerm;
     End
    Else FilePerm := 493; {Octal 755}

    If (ReadEntry('GENERAL', 'DIRUMASK') <> '') then
     Begin
     DirPerm := OctalStrToInt(RepEnv(ReadEntry('GENERAL', 'DIRUMASK')));
     DirPerm := 511 and not DirPerm;
     End
    Else DirPerm := FilePerm;

    Cfg^.SysOp := RepEnv(ReadEntry('GENERAL', 'SYSOP'));
    If (Cfg^.SysOp = '') then IniError('No SysOp name defined!');
    Cfg^.BBS := RepEnv(ReadEntry('GENERAL', 'BBS'));
    If (Cfg^.BBS = '') then IniError('No BBS name defined!');

    ParseAddrs;
    ParseDomains;
    ParsePackers;
    ParseUnPackers;
    ParseGroups;
    ParseAnnGroups;
    ParseFileAreas;
    ParseUser;
    ParseUpLinks;
    ParseArcNames;
    ParseMgrNames;

    If Debug then
      Begin
      WriteLn('<Return>');
      ReadLn;
      End;

    end;
  End;

End.
