Unit Outbound;

Interface
{
- supported outbounds:
  - Binkley Domain
  - new FD
  - T-Mail fileboxes
- interface:
  - CheckBusy, SetBusy, UnSetBusy
  - SendFile, CheckFileSent
  - ArchiveName (BT: in outbound, TMail: in filebox, FD: subdirs in TicDir)
  - PurgeArchs (remove archives with zero length)
}

Implementation

Begin
End.

