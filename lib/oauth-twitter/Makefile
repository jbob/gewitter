PKG = --pkg gee-1.0 --pkg libsoup-2.4
VAPI = ../oauth/oauth.vapi
LIB = --library=oauth-twitter
H = -H oauth-twitter.h
SRC = oauth-twitter.vala
X = -X -fPIC -X -shared -X -I../oauth
O = -o oauth-twitter.so

all:
	valac $(PKG) $(VAPI) $(LIB) $(H) $(SRC) $(X) $(O)

clean:
	rm -f *.vapi *.so *.h
