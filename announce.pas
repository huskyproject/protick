Unit Announce;

Interface

{
- add File
  - AddFile(Area: PArea; Name: PChar; Desc: PChar; From: TNetAddr)
- write Announces
  - WriteAnnounces
- NetMail-Announces
- EchoMail-Announces
  - Announce-Groups
- using Templates (MsgHeader, MsgFooter, GroupHeader, GroupFooter, File)
- using charset conversion
- reformat descriptions
}

Implementation

Begin
End.

