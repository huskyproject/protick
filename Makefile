#!/usr/bin/make -f
PASOPT = -dUNIX -dDEBUG -Fu../fidoconfig -Fu../smapi -k'-L/husky/lib'

all: protick pttoss ptffix ptnfh ptunpack ptpack pthatch ptmaint ptffind

protick: protick.pas
	ppc386 $(PASOPT) protick.pas

pttoss: pttoss.pas log.pas
	ppc386 $(PASOPT) pttoss.pas

ptffix: ptffix.pas log.pas
	ppc386 $(PASOPT) ptffix.pas

ptnfh: ptnfh.pas log.pas
	ppc386 $(PASOPT) ptnfh.pas

ptunpack: ptunpack.pas log.pas
	ppc386 $(PASOPT) ptunpack.pas

ptpack: ptpack.pas log.pas
	ppc386 $(PASOPT) ptpack.pas

pthatch: pthatch.pas log.pas
	ppc386 $(PASOPT) pthatch.pas

ptmaint: ptmaint.pas log.pas
	ppc386 $(PASOPT) ptmaint.pas

ptffind: ptffind.pas log.pas
	ppc386 $(PASOPT) ptffind.pas

clean:
	-rm *.o *.ppu *.a *~

distclean: clean
	-rm protick pttoss ptffix ptnfh ptunpack ptpack pthatch ptmaint ptffind

