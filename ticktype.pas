Unit TickType;
Interface
{$IfDef FPC}
 {$PackRecords 1}
{$EndIf}

Uses
{$IfDef SPEED}
  OS2Def,
{$EndIf}
  Types, MKGlobT, GeneralP;

Type
     TChar = Array[0..65534] of Char;
     PChar2 = ^TChar;
     PNetAddr = ^TNetAddr;
     PArea = ^TArea;
     PTick = ^TTick;
     PConnectedUser = ^TConnectedUser;
     PUser = ^TUser;
     PTickCfg = ^TTickCfg;
     PPacker = ^TPacker;
     PUnPacker = ^TUnPacker;
     PGroup = ^TGroup;
     PAnnGroup = ^TAnnGroup;
     PUpLink = ^TUpLink;
     PDupeEntry = ^TDupeEntry;
     PArcListEntry = ^TArcListEntry;
     PArcList = ^TArcList;
     PPTListEntry = ^TPTListEntry;
     PPTList = ^TPTList;
     PAnnAreaEntry = ^TAnnAreaEntry;
     PAnnFileEntry = ^TAnnFileEntry;
     PAreaList = ^TAreaList;
     PString80List = ^TString80List;

     FileStr = String[20];
     DirStr = String[150];

     TNetAddr = {29 Byte}
       Record
       Zone, Net, Node, Point: Word;
       Domain: String[20];
       end;

     TDomain = {41b}
      Record
      Domain: String[20];
      Abbrev: String[20];
      End;

     TTick = {28861 Byte}
       Record
       Area: String[30];
       AreaDesc: String[80];
       ReleaseTime: ULong; {Unix format}
       Replaces: FileStr;
       Name: FileStr;
       Desc: String[255];
       LDesc: Array[1..100] of String[80];
       NumLDesc: Byte;
       Size: ULong;
       Date: ULong; {Unix format}
       CRC: ULong;
       Origin: TNetAddr;
       From: TNetAddr;
       _To: TNetAddr;
       ToName: String[40];
       Pwd: String[20];
       CreatedBy: String;
       SeenBy: Array[1..500] of TNetAddr;
       NumSB: Byte;
       App: Array[1..20] of String[150];
       NumApp: Byte;
       Path: Array[1..20] of String128;
       NumPath: Byte;
       Bad: Byte;
       End;

     TConnectedUser =
       Record
       Prev: PConnectedUser;
       Next: PConnectedUser;
       User: PUser;
       Receive: Boolean;
       Send: Boolean;
       End;

     TArea = {614 Byte}
       Record
       Prev: PArea;
       Next: PArea;
       Name: String[40];
       Desc: String[80];
       BBSArea: String[40];
       Path: DirStr;
       MoveTo: DirStr;
       ReplaceExt: String[10];
       Group: Byte;
       Level: ULong;
       Addr: TNetAddr;
       Flags: ULong;
         {Bit Desc
           0  PassThrough
           1  DupeCheck
           2  CRC-Check
           3  Touch
           4  not used
           5  Manual
           6  No %Pause
           7  NewFiles-Hatch
           8  Costsharing
           9  Hidden
          10  RemoteChange
         }
       LastHatch : ULong;
       CostPerMB: ULong;
       AnnGroups: Set of Byte;
       Users: PConnectedUser;
       End;

     TUser = {217 Byte}
       Record
       Prev: PUser;
       Next: PUser;
       Name: String[40];
       Addr: TNetAddr;
       ArcAddr: TNetAddr;
       OwnAddr: TNetAddr;
       Active: Boolean;
       Level: ULong;
       Groups: Set of Byte;
       Pwd: String[20];
       MailFlags: Byte;
         { Value  Desc
             1    Normal
             2    Direct
             3    Hold
             4    Crash
         }
       Sends: Boolean;
       Receives: Boolean;
       Flags: ULong;
         {Bit Desc
           0  Send TIC
           1  Notify
           2  may AutoCreate
           3  Admin
           4  NMAnn
         }
       Packer: Byte;
       PackTICs: Boolean;
       PackFiles: Boolean;
       May: ULong;
         {Bit Desc
           0  connect areas
           1  disconnect areas
           2  %Pause
           3  %Pwd
           4  %Compression
           5  %Tic
           6  %Notify
           7  %Rescan
         }
       ACGroup: Byte;
       End;

     TPacker = {85 Byte}
       Record
       Index: Byte;
       Ext: String[3];
       Cmd: String[80];
       End;

     TUnPacker = {85 Byte}
       Record
       Index: Byte;
       Ext: String[3];
       Cmd: String[80];
       End;

     TGroup = {42 Byte}
       Record
       Index: Byte;
       Name: String[40];
       End;

     TAnnGroup = {587b}
       Record
       Next: PAnnGroup;
       Prev: PAnnGroup;
       Index: Byte;
       Name: String[40];
       Area: DirStr;
       Subj: String[72];
       FromName: String[30];
       ToName: String[30];
       FromAddr: TNetAddr;
       ToAddr: TNetAddr;
       Typ: Byte;
       HeaderFile: DirStr;
       FooterFile: DirStr;
       End;

     TArcName = {22b}
       Record
       FileName: String20;
       UnPacker: Byte;
       End;

     TMgrName = String20; {22b}

     TTickCfg =
       Record
       SysOp: String[40];                              {    41b}
       BBS: String[40];                                {    41b}
       Addrs: Array[1..100] of TNetAddr;               {  2900b}
       NumAddrs: Word;                                 {     2b}
       Domains: Array[1..50] of TDomain;               {  2050b}
       NumDomains: Byte;                               {     1b}
       Areas: PArea;                                   {     4b}
       NumAreas: ULong;                                {     1b}
       Users: PUser;                                   {     4b}
       NumUser: ULong;                                 {     1b}
       InBound: DirStr;                                {   151b}
       OBType: Byte;                                   {     1b}
       OutBound: DirStr;                               {   151b}
       TicOut: DirStr;                                 {   151b}
       NetMail: DirStr;                                {   151b}
       Bad: DirStr;                                    {   151b}
       PT: DirStr;                                     {   151b}
       FlagDir: DirStr;                                {   151b}
       Packer: Array[1..50] of TPacker;                {  4250b}
       UnPacker: Array[1..50] of TUnPacker;            {  4250b}
       NumPacker: Byte;                                {     1b}
       NumUnPacker: Byte;                              {     1b}
       Groups: Array[1..255] of TGroup;                { 10710b}
       NumGroups: Byte;                                {     1b}
       AnnGroups: PAnnGroup;                           {     4b}
       NumAnnGroups: Byte;                             {     1b}
       UpLinks: PUpLink;                               {     4b}
       NumUpLinks: Byte;                               {     1b}
       ArcNames: Array[1..50] of TArcName;             {  1100b}
       NumArcNames: Byte;                              {     1b}
       MgrNames: Array[1..20] of TMgrName;             {   440b}
       NumMgrNames: Byte;                              {     1b}
       DescPos: Byte;                                  {     1b}
       LDescString: String[10];                        {    11b}
       AddDLC: Boolean;                                {     1b}
       DLCDig: Byte;                                   {     1b}
       SingleDescLine: Boolean;                        {     1b}
       CheckDest: Boolean;                             {     1b}
       DelReq: Boolean;                                {     1b}
       DelRsp: Boolean;                                {     1b}
       LocalPwd: String[20];                           {    21b}
       LongDirNames: Boolean;                          {     1b}
       SplitDirs: Boolean;                             {     1b}
       MaxDupeAge: Word;                               {     2b}
       DataPath: DirStr;                               {   151b}
       AreasLog: DirStr;                               {   151b}
       BBSAreaLog: DirStr;                             {   151b}
       MsgIDFile: DirStr;                              {   151b}
       DupeFile: DirStr;                               {   151b}
       LNameLst: DirStr;                               {   151b}
       NewAreasLst: DirStr;                            {   151b}
       ArcLst: DirStr;                                 {   151b}
       PTLst: DirStr;                                  {   151b}
       CreateDirs: Boolean;                            {     1b}
       end;                                            {-------}
                                                       { 15391b}

     TUpLink =
       Record
       Prev: PUpLink;
       Next: PUpLink;
       Comment: String[40];
       Name: String[20];     {Name of ConfMgr, e.g. "FileFix"}
       Addr: TNetAddr;       {Address of ConfMgr, e.g. "2:2435/40"}
       Level: ULong;         {Min DownLink Level required to forward requests}
       Group: Byte;
       Pwd: String[20];      {Pwd for ConfMgr, e.g. "secret"}
       AreaList: DirStr;     {List of areas available from this UpLink}
       Unconditional: Boolean; {Forward request even if area is not in AreaList}
       end;

     TDupeEntry =        {80b}
       Record
       Area: String[40];
       Name: String[30];
       CRC: ULong;
       Date: LongInt; {UnixDate}
       End;

     TArcListEntry =     {332b}
       Record
       Addr: TNetAddr;
       FileName: DirStr;
       Del: Boolean;
       PTFN: DirStr; {PassThrough FileName}
       End;

     TArcList =          {349b}
       Record
       Prev: PArcList;
       Next: PArcList;
       a: TArcListEntry;
       IsDone: Boolean;
       End;

     TPTListEntry =      {172b}
       Record
       TICName: DirStr;
       FileName: FileStr;
       End;

     TPTList =           {188b}
       Record
       Prev: PPTList;
       Next: PPTList;
       a: TPTListEntry;
       End;

     TAnnAreaEntry =
       Record
       Prev: PAnnAreaEntry;
       Next: PAnnAreaEntry;
       Area: String[40];
       AnnGroups: Set of Byte;
       Desc: String[40];
       Files: PAnnFileEntry;
       End;

     TAnnFileEntry =
       Record
       Prev: PAnnFileEntry;
       Next: PAnnFileEntry;
       Name: String[40];
       Desc: PChar2;
       Size: LongInt;
       Date: TimeTyp;
       Sender: TNetAddr;
       End;

     TAreaList =
       Record
       Prev: PAreaList;
       Next: PAreaList;
       Name: String[40];
       BBSArea: String[40];
       End;

     TString80List =
      Record
      s: String80;
      next: PString80List;
      End;


Function Addr2Str(Addr: TNetAddr): String;
Function Addr2StrND(Addr: TNetAddr): String;
Procedure Str2Addr(s: String; var Addr: TNetAddr);
Function CompAddr(A1, A2: TNetAddr): Boolean;
Procedure CopyAddr(var A1:TNetAddr; A2: TNetAddr);
Procedure MKAddr2TNetAddr(MKAddr: AddrType; Var A1: TNetAddr);
Procedure TNetAddr2MKAddr(A1: TNetAddr; Var MKAddr: AddrType);

Implementation

Function Addr2Str(Addr: TNetAddr): String;
Var
  s: String;

  Begin
  With Addr do
    Begin
    s := IntToStr(Zone) + ':' + IntToStr(Net) + '/' + IntToStr(Node);
    If (Point <> 0) then s := s + '.' + IntToStr(Point);
    If (Domain <> '') then s := s + '@' + Domain;
    Addr2Str := s;
    End;
  End;

{without domain, e.g. for origin}
Function Addr2StrND(Addr: TNetAddr): String;
Var
  s: String;

  Begin
  With Addr do
    Begin
    s := IntToStr(Zone) + ':' + IntToStr(Net) + '/' + IntToStr(Node);
    If (Point <> 0) then s := s + '.' + IntToStr(Point);
    Addr2StrND := s;
    End;
  End;

Procedure Str2Addr(s: String; var Addr: TNetAddr);
Var
{$IfDef VIRTUALPASCAL}
  i: LongInt;
{$Else}
  i: Integer;
{$EndIf}

  Begin
  If (Pos(':', s) = 0) then Addr.Zone := 0
  Else
    Begin
    Val(Copy(s, 1, Pos(':', s) - 1), Addr.Zone, i);
    Delete(s, 1, Pos(':', s));
    End;
  If (Pos('/', s) = 0) then Addr.Net := 0
  Else
    Begin
    Val(Copy(s, 1, Pos('/', s) - 1), Addr.Net, i);
    Delete(s, 1, Pos('/', s));
    End;
  If (Pos('.', s) = 0) or
   ((Pos('.', s) > Pos('@', s)) and (Pos('@', s) > 0)) then
    Begin
    Addr.Point := 0;
    If (Pos('@', s) = 0) then
      Begin
      Val(s, Addr.Node, i);
      Addr.Domain := '';
      End
    Else
      Begin
      Val(Copy(s, 1, Pos('@', s) - 1), Addr.Node, i);
      Delete(s, 1, Pos('@', s));
      Addr.Domain := UpStr(s);
      End;
    End
  Else
    Begin
    Val(Copy(s, 1, Pos('.', s) - 1), Addr.Node, i);
    Delete(s, 1, Pos('.', s));
    If (Pos('@', s) = 0) then
      Begin
      Val(s, Addr.Point, i);
      Addr.Domain := '';
      End
    Else
      Begin
      Val(Copy(s, 1, Pos('@', s) - 1), Addr.Point, i);
      Delete(s, 1, Pos('@', s));
      Addr.Domain := UpStr(s);
      End;
    End;
  End;

Function CompAddr(A1, A2: TNetAddr): Boolean;
Var
  C: Boolean;

  Begin
  c := ((A1.Zone = 0) or (A2.Zone = 0) or (A1.Zone = A2.Zone));
  c := c and ((A1.Net = 0) or (A2.Net = 0) or (A1.Net = A2.Net));
  c := c and (A1.Node = A2.Node);
  c := c and (A1.Point = A2.Point);
  c := c and ((A1.Domain = '') or (A2.Domain = '') or (UpStr(A1.Domain) = UpStr(A2.Domain)));
  CompAddr := c;
  End;

Procedure CopyAddr(var A1:TNetAddr; A2: TNetAddr);
  Begin
  A1.Zone := A2.Zone;
  A1.Net := A2.Net;
  A1.Node := A2.Node;
  A1.Point := A2.Point;
  A1.Domain := A2.Domain;
  End;

Procedure MKAddr2TNetAddr(MKAddr: AddrType; Var A1: TNetAddr);
  Begin
  A1.Zone := MKAddr.Zone;
  A1.Net := MKAddr.Net;
  A1.Node := MKAddr.Node;
  A1.Point := MKAddr.Point;
  A1.Domain := MKAddr.Domain;
  End;

Procedure TNetAddr2MKAddr(A1: TNetAddr; Var MKAddr: AddrType);
  Begin
  MKAddr.Zone := A1.Zone;
  MKAddr.Net := A1.Net;
  MKAddr.Node := A1.Node;
  MKAddr.Point := A1.Point;
  MKAddr.Domain := A1.Domain;
  End;

end.

