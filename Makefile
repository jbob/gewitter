PKG = --pkg gtk+-3.0 --pkg gee-1.0 --pkg libsoup-2.4 --pkg json-glib-1.0
VAPI = twitter.vapi
SRC = gewitter.vala
X = -X twitter.so -X -I. -X -Wl,-R.
O = -o gewitter

TPKG = --pkg libsoup-2.4 --pkg json-glib-1.0 --pkg gee-1.0
TVAPI = oauth.vapi oauth-twitter.vapi
TLIB = --library=twitter
TH = -H twitter.h
TSRC = twitter.vala
TX = -X -fPIC -X -shared -X oauth.so -X oauth-twitter.so -X -I. -X -Wl,-R.
TO = -o twitter.so

OTPKG = --pkg gee-1.0 --pkg libsoup-2.4
OTVAPI = oauth.vapi
OTLIB = --library=oauth-twitter
OTH = -H oauth-twitter.h
OTSRC = oauth-twitter.vala
OTX = -X -fPIC -X -shared -X -I. -X -Wl,-R.
OTO = -o oauth-twitter.so

OPKG = --pkg gee-1.0 --pkg libsoup-2.4
OLIB = --library=oauth
OH = -H oauth.h
OSRC = oauth.vala
OX = -X -fPIC -X -shared
OO = -o oauth.so

all: twitter
	valac $(PKG) $(VAPI) $(SRC) $(X) $(O)

twitter: oauth-twitter
	valac $(TPKG) $(TVAPI) $(TLIB) $(TH) $(TSRC) $(TX) $(TO)

oauth-twitter: oauth
	valac $(OTPKG) $(OTVAPI) $(OTLIB) $(OTH) $(OTSRC) $(OTX) $(OTO)

oauth:
	valac $(OPKG) $(OLIB) $(OH) $(OSRC) $(OX) $(OO)

clean:
	rm -f gewitter *.vapi *.h *.so core.*
