#!/usr/bin/make -f
PASOPT = -dLinux

all: debug

protick: protick.pas mkglobt.pas mkmisc.pas mkmsgabs.pas mkmsgfid.pas \
 mkmsgezy.pas mkmsgjam.pas mkmsghud.pas mkmsgsqu.pas types.pas generalp.pas \
 crc.pas log.pas inifile.pas ptregkey.pas tickcons.pas ticktype.pas \
 ptprocs.pas ptvar.pas ptmsg.pas ptcfg.pas ptout.pas
	ppc386 $(PASOPT) protick.pas

debug:
	ppc386 $(PASOPT) -dDEBUG protick.pas

release:
	ppc386 $(PASOPT) -dRELEASE protick.pas

clean:
	-rm *.o *.ppu *.a *~

distclean: clean
	-rm protick genkey

