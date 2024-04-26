UNAME_S!=uname -s

NAME!=cat main.c | grep "const char\* sofname" | awk '{print $$5}' | \
	sed "s/\"//g" | sed "s/;//"
VERSION!=cat main.c | grep "const char\* version" | awk '{print $$5}' | \
	sed "s/\"//g" | sed "s/;//"
PREFIX=/usr/local
MANPREFIX=${PREFIX}/man
CFLAGS=-Wall -Wextra -g -I/usr/include -I/usr/local/include
LDFLAGS=-L/usr/lib -L/usr/local/lib

.if ${UNAME_S} == "FreeBSD"
MANPREFIX=${PREFIX}/share/man
.elif ${UNAME_S} == "OpenBSD"
.elif ${UNAME_S} == "Linux"
PREFIX=/usr
MANPREFIX=${PREFIX}/share/man
.elif ${UNAME_S} == "NetBSD"
PREFIX=/usr/pkg
CFLAGS+= -I/usr/pkg/include
LDFLAGS+= -L/usr/pkg/lib
MANPREFIX=${PREFIX}/share/man
.endif

CC=cc
FILES=main.c
LIBS=-lcurl

all:
	${CC} ${CFLAGS} -o ${NAME} ${FILES} ${LDFLAGS} ${LIBS}
	strip ${NAME}

clean:
	rm -f ${NAME}

release-openbsd-i386:
	mkdir -p release/bin
	${CC} ${CFLAGS} -o release/bin/${NAME}-${VERSION}-openbsd-i386 ${FILES} ${LDFLAGS} \
		-static -lcurl -lc -lnghttp3 -lngtcp2_crypto_quictls -lngtcp2 -lssl \
		-lcrypto -lnghttp2 -lz -lpthread
	strip release/bin/${NAME}-${VERSION}-openbsd-i386

release-openbsd:
	mkdir -p release/bin
	${CC} ${CFLAGS} -o release/bin/${NAME}-${VERSION}-openbsd-amd64 ${FILES} ${LDFLAGS} \
		-static -lcurl -lc -lnghttp3 -lngtcp2_crypto_quictls -lngtcp2 -lssl \
		-lcrypto -lnghttp2 -lz -lpthread
	strip release/bin/${NAME}-${VERSION}-openbsd-amd64

release-netbsd:
	mkdir -p release/bin
	${CC} ${CFLAGS} -o release/bin/${NAME}-${VERSION}-netbsd-amd64 ${FILES} ${LDFLAGS} \
		-static -lcurl -lnghttp2 -lc -lidn2 -lunistring -lgssapi -lkrb5 -lhx509 -lintl \
		-lssl -lcrypto -lcrypt -lasn1 -lcom_err -lroken -lutil -lwind -lheimbase \
		-lheimntlm -lz -lpthread
	strip release/bin/${NAME}-${VERSION}-netbsd-amd64

release-freebsd:
	mkdir -p release/bin
	${CC} ${CFLAGS} -o release/bin/${NAME}-${VERSION}-freebsd-amd64 ${FILES} ${LDFLAGS} \
		-static -lcurl -lnghttp2 -lssh2 -lpsl -lssl -lheimntlm \
		-lhx509 -lcom_err -lcrypto -lasn1 -lwind -lheimbase \
		-lroken -lcrypt -lz -lkrb5 -lgssapi -lgssapi_krb5 -lthr \
		-lidn2 -lunistring -lprivateheimipcc
	strip release/bin/${NAME}-${VERSION}-freebsd-amd64

release-linux:
	mkdir -p release/bin
	${CC} ${CFLAGS} -o release/bin/${NAME}-${VERSION}-linux-amd64 ${FILES} ${LDFLAGS} \
		-static -lcurl -lc -lnghttp2 -lidn2 -lssh2 -lpsl -lssl -lcrypto -lzstd -lz \
		-lunistring
	strip release/bin/${NAME}-${VERSION}-linux-amd64

dist:
	mkdir -p ${NAME}-${VERSION} release/src
	cp -R LICENSE.txt Makefile README.md CHANGELOG.md \
		*.c ${NAME}-${VERSION}
	tar zcfv ${NAME}-${VERSION}.tar.gz ${NAME}-${VERSION}
	mv ${NAME}-${VERSION}.tar.gz release/src
	rm -rf ${NAME}-${VERSION}

install:
	mkdir -p ${DESTDIR}${PREFIX}/bin
	cp -f ${NAME} ${DESTDIR}${PREFIX}/bin
	chmod 755 ${DESTDIR}${PREFIX}/bin/${NAME}

uninstall:
	rm -f ${DESTDIR}${PREFIX}/bin/${NAME}

.PHONY: all clean install uninstall
