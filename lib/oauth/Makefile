PKG = --pkg gee-1.0 --pkg libsoup-2.4
LIB = --library=oauth
H = -H oauth.h
SRC = oauth.vala
X = -X -fPIC -X -shared
O = -o oauth.so

all:
	valac --pkg gee-1.0 --pkg libsoup-2.4 --library=oauth -H oauth.h oauth.vala -X -fPIC -X -shared -o oauth.so

clean:
	rm *.vapi *.h *.so
