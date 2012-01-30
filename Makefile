PKG = --pkg gtk+-3.0 --pkg gee-1.0 --pkg libsoup-2.4 --pkg json-glib-1.0
VAPI = lib/oauth/oauth.vapi lib/twitter/twitter.vapi lib/oauth-twitter/oauth-twitter.vapi
SRC = gewitter.vala
X = -X lib/oauth/oauth.so -X lib/twitter/twitter.so -X lib/oauth-twitter/oauth-twitter.so -X -Ilib/oauth -X -Ilib/twitter -X -Ilib/oauth-twitter
O = -o gewitter

all:
	valac $(PKG) $(VAPI) $(SRC) $(X) $(O)

clean:
	rm -f gewitter
