PKG = --pkg libsoup-2.4 --pkg json-glib-1.0 --pkg gee-1.0
VAPI = ../oauth/oauth.vapi ../oauth-twitter/oauth-twitter.vapi
LIB = --library=twitter
H = -H twitter.h
SRC = twitter.vala
X = -X -fPIC -X -shared -X -I../oauth -X -I../oauth-twitter
O = -o twitter.so

all:
	valac $(PKG) $(VAPI) $(LIB) $(H) $(SRC) $(X) $(O)

clean:
	rm -f *.vapi *.h *.so
