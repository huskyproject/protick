Unit PTFConf; {use fidoconfig as config}
Interface

Uses
  smapi, fidoconf,
  Log, IniFile,
  Types, GeneralP,
  PTRegKey, TickType, TickCons, PTVar, PTProcs;

Procedure ParseCfg;

Implementation

Var
 fconf: Ps_fidoconfig;

Procedure IniError(s: String);
 Begin
 LogSetCurLevel(LogHandle, 1);
 LogWriteLn(LogHandle, s);
 MainDone;
 Halt(Err_Ini);
 End;

Procedure CheckDir(path: String; desc: String);
 Begin
 If (not DirExist(path)) then
  Begin
  If Cfg^.CreateDirs then
   Begin
   If MakeDir(path) then
    Begin
    LogSetCurLevel(LogHandle, 2);
    LogWriteLn(LogHandle, 'created '+desc+' "'+path+'"');
    End
   Else
    Begin
    LogSetCurLevel(LogHandle, 1);
    LogWriteLn(LogHandle, 'Could not create '+desc+' "'+path+'"!');
    End;
   End
  Else
   Begin
   LogSetCurLevel(LogHandle, 1);
   LogWriteLn(LogHandle, desc+' "'+path+'" does not exist!');
   End;
  End;
 End;


Procedure ParseAddrs;
Var
 CurEntry: Ps_addr;
 i: Word;

 Begin
 Cfg^.NumAddrs := fconf^.addrCount;
 For i := 1 to fconf^.addrCount do
  Begin
  CurEntry := fconf^.addr + ((i-1)*sizeof(s_addr));
  Cfg^.Addrs[i].Zone := CurEntry^.Zone;
  Cfg^.Addrs[i].Net := CurEntry^.Net;
  Cfg^.Addrs[i].Node := CurEntry^.Node;
  Cfg^.Addrs[i].Point := CurEntry^.Point;
  Cfg^.Addrs[i].Domain := CurEntry^.Domain;
  End;
 End;

Procedure ParsePackers;
Var
 i: word;
 CurEntry: Ps_pack;

 Begin
 Cfg^.NumPacker := fconf^.packCount;
 For i := 1 to Cfg^.NumPacker do
  Begin
  CurEntry := fconf^.pack + ((i-1)*sizeof(s_pack));
  Cfg^.Packer[i].Index := i;
  Cfg^.Packer[i].Ext := CurEntry^.packer;
  Cfg^.Packer[i].Cmd := CurEntry^.call;
  End;
 End;

Procedure ParseUnPackers;
Var
 i: word;
 CurEntry: Ps_unpack;

 Begin
 Cfg^.NumUnPacker := fconf^.unpackCount;
 For i := 1 to Cfg^.NumUnPacker do
  Begin
  CurEntry := fconf^.unpack + ((i-1)*sizeof(s_unpack));
  Cfg^.UnPacker[i].Index := i;
  Cfg^.UnPacker[i].Ext := '';
  Cfg^.UnPacker[i].Cmd := CurEntry^.Call;
  End;
 End;

Procedure ParseUser;
Var
 i, j: LongInt;
 CurEntry: Ps_link;
 CurChar: PChar;

 Begin
 Cfg^.NumUser := fconf^.linkCount;
 For i := 1 to Cfg^.NumUser do
  Begin
  If (i = 1) then
   Begin
   New(Cfg^.Users);
   CurUser := Cfg^.Users;
   FillChar(CurUser^, SizeOf(TUser), 0);
   CurUser^.Next := Nil;
   CurUser^.Prev := Nil;
   End
  Else
   Begin
   New(CurUser^.Next);
   FillChar(CurUser^.Next^, SizeOf(TUser), 0);
   CurUser^.Next^.Prev := CurUser;
   CurUser := CurUser^.Next;
   CurUser^.Next := Nil;
   End;

  CurEntry := fconf^.links + ((i-1)*sizeof(s_link));

  CurUser^.Name := CurEntry^.Name;
  CurUser^.Addr.Zone := CurEntry^.hisAka.Zone;
  CurUser^.Addr.Net := CurEntry^.hisAka.Net;
  CurUser^.Addr.Node := CurEntry^.hisAka.Node;
  CurUser^.Addr.Point := CurEntry^.hisAka.Point;
  CurUser^.Addr.Domain := CurEntry^.hisAka.Domain;
  CurUser^.OwnAddr.Zone := CurEntry^.ourAka^.Zone;
  CurUser^.OwnAddr.Net := CurEntry^.ourAka^.Net;
  CurUser^.OwnAddr.Node := CurEntry^.ourAka^.Node;
  CurUser^.OwnAddr.Point := CurEntry^.ourAka^.Point;
  CurUser^.OwnAddr.Domain := CurEntry^.ourAka^.Domain;
  CurUser^.Active := (CurEntry^.Pause = 0);
  CurUser^.Pwd := CurEntry^.ticPwd;
  CurUser^.Level := CurEntry^.Level;

  CurUser^.Groups := [];
  If (CurEntry^.AccessGrp <> NIL) then
   Begin
   For j := 1 to strlen(CurEntry^.AccessGrp) do
    Begin
    CurChar := CurEntry^.AccessGrp+j;
    CurUser^.Groups := CurUser^.Groups + [Byte(CurChar^)];
    End;
   End
  Else If (CurEntry^.OptGrp <> NIL) then
   Begin
   For j := 1 to strlen(CurEntry^.OptGrp) do
    Begin
    CurChar := CurEntry^.OptGrp+j;
    CurUser^.Groups := CurUser^.Groups + [Byte(CurChar^)];
    End;
   End;

  Case CurEntry^.EchoMailFlavour of
   normal: CurUser^.MailFlags := ml_normal;
   hold: CurUser^.MailFlags := ml_hold;
   crash: CurUser^.MailFlags := ml_crash;
   direct: CurUser^.MailFlags := ml_direct;
   immediate: CurUser^.MailFlags := ml_imm;
  Else
   Begin
   LogSetCurLevel(loghandle, 1);
   LogWriteLn(LogHandle, 'Unknown flavour for user '+CurUser^.Name+
    ' ('+Addr2Str(CurUser^.Addr)+')!');
   CurUser^.MailFlags := ml_normal;
   End;
  End;
{} CurUser^.Flags := uf_SendTIC + uf_Notify +
    (uf_AutoCreate * CurEntry^.AutoFileCreate) + uf_NMAnn;
  If (CurEntry^.Import <> NIL) then CurUser^.Receives := (Byte(CurEntry^.Import^) > 0)
  Else CurUser^.Receives := True;
  If (CurEntry^.Export <> NIL) then CurUser^.Sends := (Byte(CurEntry^.Export^) > 0)
  Else CurUser^.Sends := False;
  CurUser^.Packer := 0;
  For j := 1 to Cfg^.NumPacker do
   Begin
   If (CurEntry^.PackerDef^.Packer = Cfg^.Packer[j].Ext) then
     CurUser^.Packer := j;
   End;
  If (CurUser^.Packer = 0) then
   Begin
   LogSetCurLevel(loghandle, 1);
   LogWriteLn(loghandle, 'Unknown Packer "'+CurEntry^.PackerDef^.Packer+
    '" for user '+CurUser^.Name+' ('+Addr2Str(CurUser^.Addr)+')!');
   End;

  CurUser^.ArcAddr := CurUser^.Addr;
  CurUser^.May := um_Connect + um_Disconnect + um_Pause + um_Pwd +
    um_Compression + um_TIC + um_Notify + um_Rescan;
  CurUser^.PackTICs := False;
  CurUser^.PackFiles := False;
  CurUser^.ACGroup := 1;
  End;
 End;

Procedure ParseFileAreas;
Var
 i, j: LongInt;
 CurEntry: Ps_fileareatype;
 CurLink: Ps_arealink;
 LinkAddr: TNetAddr;

 Begin
 Cfg^.NumAreas := fconf^.fileAreaCount;
 For i := 1 to Cfg^.NumAreas do
  Begin
  If (i = 1) then
   Begin
   New(Cfg^.Areas);
   CurArea := Cfg^.Areas;
   FillChar(CurArea^, SizeOf(TArea), 0);
   CurArea^.Next := Nil;
   CurArea^.Prev := Nil;
   End
  Else
   Begin
   New(CurArea^.Next);
   FillChar(CurArea^.Next^, SizeOf(TArea), 0);
   CurArea^.Next^.Prev := CurArea;
   CurArea := CurArea^.Next;
   CurArea^.Next := Nil;
   End;

  CurEntry := fconf^.fileareas + ((i-1)*sizeof(s_fileareatype));
  CurArea^.Name := CurEntry^.areaName;
  CurArea^.BBSArea := CurArea^.Name;
  CurArea^.Addr.Zone := CurEntry^.useAka^.Zone;
  CurArea^.Addr.Net := CurEntry^.useAka^.Net;
  CurArea^.Addr.Node := CurEntry^.useAka^.Node;
  CurArea^.Addr.Point := CurEntry^.useAka^.Point;
  CurArea^.Addr.Domain := CurEntry^.useAka^.Domain;
  CurArea^.Level := CurEntry^.levelread;
  CurArea^.Group := Byte(CurEntry^.group);
  CurArea^.Desc := CurEntry^.Description;
  CurArea^.Path := CurEntry^.PathName;
{}  CurArea^.Flags := (fa_PT * CurEntry^.pass) + fa_Dupe + fa_CRC +
    (fa_Touch * 0) + (fa_Mandatory * 0) +
    (fa_NoPause * byte(CurEntry^.noPause)) + (fa_NewFilesHatch * 0) +
    (fa_Hidden * byte(CurEntry^.Hide)) +
    (fa_RemoteChange * byte(CurEntry^.manual));

  CurArea^.CostPerMB := 0;
  CurArea^.LastHatch := 0;
  CurArea^.MoveTo := '/husky/files/old/';
  CurArea^.ReplaceExt := '';
  CurArea^.AnnGroups := [];

  CheckDir(CurArea^.Path, 'directory for area "'+CurArea^.Name+'"');
  CheckDir(CurArea^.MoveTo, 'Oldfiles-directory for area "'+CurArea^.Name+'"');

  For j := 1 to CurEntry^.DownLinkCount do
   Begin
   CurLink := (CurEntry^.downlinks + ((i-1)*sizeof(s_arealink)))^;

   CurUser := Cfg^.Users;
   LinkAddr.Zone := CurLink^.Link^.hisAKA.Zone;
   LinkAddr.Net := CurLink^.Link^.hisAKA.Net;
   LinkAddr.Node := CurLink^.Link^.hisAKA.Node;
   LinkAddr.Point := CurLink^.Link^.hisAKA.Point;
   LinkAddr.Domain := CurLink^.Link^.hisAKA.Domain;
   While ((CurUser <> NIL) and (not CompAddr(CurUser^.Addr, LinkAddr))) do
    CurUser := CurUser^.Next;
   If (CurUser <> NIL) then
    Begin
    If (CurArea^.Users = NIL) then
     Begin
     New(CurArea^.Users);
     CurConnUser := CurArea^.Users;
     CurConnUser^.Next := NIL;
     CurConnUser^.Prev := NIL;
     End
    Else
     Begin
     CurConnUser := CurArea^.Users;
     While (CurConnUser^.Next <> NIL) do CurConnUser := CurConnUser^.Next;
     New(CurConnUser^.Next);
     CurConnUser^.Next^.Prev := CurConnUser;
     CurConnUser := CurConnUser^.Next;
     CurConnUser^.Next := NIL;
     End;

    CurConnUser^.User := CurUser;
    CurConnUser^.Receive := (Byte(CurLink^.Import) > 0);
    CurConnUser^.Send := (Byte(CurLink^.Export) > 0);
    End
   Else
    Begin
    LogSetCurLevel(loghandle, 1);
    LogWriteLn(loghandle, 'User '+Addr2Str(LinkAddr)+' linked to area "'+
     CurArea^.Name+'" not found!');
    End;
   End;
  End;
 End;


Procedure ParseCfg;
 Begin
 fconf := readConfig;
 If (fconf = NIL) then IniError('Could not read fidoconfig!');

 LogHandle := OpenLog(Binkley, fconf^.logFileDir+'pt.log', 'PROTICK', 'ProTick'+Version);
 If (LogHandle = 0) then
  Begin
  WriteLn('Couldn''t open Log!');
  FreeMem(HDesc, 65535);
  Halt(Err_NoLog);
  End;

 New(Cfg);
 Cfg^.Areas := NIL;
 Cfg^.Users := NIL;
 Cfg^.UpLinks := NIL;
 Cfg^.CheckDest := True;

 LogSetLogLevel(LogHandle, 4);
 LogSetScrLevel(LogHandle, 4);
 Cfg^.OBType := OB_BT;
 Cfg^.Netmail := 'F/husky/netmail';
 Cfg^.DataPath := '/husky/work/pt/';
 Cfg^.BBSAreaLog := '';
 Cfg^.NumDomains := 0;
 Cfg^.NumGroups := 0;
 Cfg^.NumAnnGroups := 0;
 Cfg^.NumUplinks := 0;
 Cfg^.NumArcNames := 0;
 Cfg^.NumMgrNames := 0;

 Cfg^.Inbound := fconf^.protinbound;
 Cfg^.Outbound := fconf^.Outbound;
 Cfg^.TicOut := fconf^.ticOutbound;
 Cfg^.FlagDir := fconf^.semaDir;
 Cfg^.Bad := fconf^.badFilesDir;
 Cfg^.PT := fconf^.passFileAreaDir;
 Cfg^.DelReq := (fconf^.filefixKillRequests > 0);
 Cfg^.DelRsp := (fconf^.filefixKillReports > 0);
 Cfg^.SysOp := fconf^.SysOp;
 Cfg^.BBS := fconf^.Name;
 Cfg^.CreateDirs := (fconf^.createDirs > 0);
 Cfg^.DescPos := fconf^.fileDescPos;
 Cfg^.LDescString := fconf^.fileLDescString;
 Cfg^.AddDLC := (fconf^.addDLC > 0);
 Cfg^.SingleDescLine := (fconf^.fileSingleDescLine > 0);
 Cfg^.DLCDig := fconf^.DLCDigits;
 Cfg^.MaxDupeAge := fconf^.fileMaxDupeAge;
 Cfg^.CheckDest := (fconf^.fileCheckDest > 0);
 Cfg^.LocalPwd := fconf^.fileLocalPwd;
 Cfg^.LongDirNames := (fconf^.longDirNames > 0);
 Cfg^.SplitDirs := (fconf^.SplitDirs > 0);
 Cfg^.AreasLog := fconf^.fileAreasLog;
 Cfg^.LNameLst := fconf^.longNameList;
 Cfg^.NewAreasLst := fconf^.fileNewAreasLog;
 Cfg^.ArcLst := fconf^.fileArcList;
 Cfg^.PTLst := fconf^.filePassList;
 Cfg^.DupeFile := fconf^.fileDupeList;
 Cfg^.MsgIDFile := fconf^.msgidfile;
 FilePerm := 511 and not fconf^.fileFileUMask; { 511 dec. = 0777}
 DirPerm := 511 and not fconf^.fileDirUMask;

 {check if dirs exist}
 CheckDir(Cfg^.FlagDir, 'semaphore-directory');
 CheckDir(Cfg^.Inbound, 'inbound');
 CheckDir(Cfg^.Outbound, 'outbound');
 CheckDir(Cfg^.TicOut, 'tic-outbound');
 CheckDir(Cfg^.Bad, 'badfiles-directory');
 CheckDir(Cfg^.PT, 'passthrough-directory');

 ParseAddrs;
{ ParseDomains; }
 ParsePackers;
 ParseUnPackers;
{ ParseGroups; }
{ ParseAnnGroups; }
 ParseUser;
 ParseFileAreas;
{ ParseUpLinks; }
{ ParseArcNames; }
{ ParseMgrNames; }
 End;

Begin
End.
