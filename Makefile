#!/usr/bin/make -f

# include Husky-Makefile-Config
include ../huskymak.cfg

ifeq ($(DEBUG), 1)
  POPT = -d$(OSTYPE) -Fu$(INCDIR) -dDEBUG
else
  POPT = -d$(OSTYPE) -Fu$(INCDIR) -dRELEASE
endif

all: protick$(EXE)

PASFILES= protick.pas mkglobt.pas mkmisc.pas mkmsgabs.pas mkmsgfid.pas \
 mkmsgezy.pas mkmsgjam.pas mkmsghud.pas mkmsgsqu.pas types.pas generalp.pas \
 crc.pas log.pas inifile.pas ptregkey.pas tickcons.pas ticktype.pas \
 ptprocs.pas ptvar.pas ptmsg.pas ptcfg.pas ptout.pas

protick$(EXE): $(PASFILES)
	$(PC) $(POPT) protick.pas

clean:
	-$(RM) *$(OBJ)
	-$(RM) *$(TPU)
	-$(RM) *$(LIB)
	-$(RM) *~

distclean: clean
	-$(RM) protick$(EXE) genkey$(EXE)

install: protick$(EXE)
	$(INSTALL) $(IBOPT) protick$(EXE) $(BINDIR)

uninstall:
	-$(RM) $(BINDIR)$(DIRSEP)protick$(EXE)

