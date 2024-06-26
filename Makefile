UNAME_S!=uname -s
UNAME_M!=uname -m

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
.elif ${UNAME_S} == "Linux"
PREFIX=/usr
MANPREFIX=${PREFIX}/share/man
.elif ${UNAME_S} == "NetBSD"
CFLAGS+=-I/usr/pkg/include
LDFLAGS+=-L/usr/pkg/lib
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

release-openbsd:
	mkdir -p release/bin
	${CC} ${CFLAGS} -o release/bin/${NAME}-${VERSION}-openbsd-${UNAME_M} \
		${FILES} ${LDFLAGS} \
		-static -lcurl -lc -lnghttp3 -lngtcp2_crypto_quictls -lngtcp2 -lssl \
		-lcrypto -lnghttp2 -lz -lpthread
	strip release/bin/${NAME}-${VERSION}-openbsd-${UNAME_M}

release-netbsd:
	mkdir -p release/bin
	${CC} ${CFLAGS} -o release/bin/${NAME}-${VERSION}-netbsd-${UNAME_M} \
		${FILES} ${LDFLAGS} \
		-static -lcurl -lnghttp2 -lc -lidn2 -lunistring -lgssapi -lkrb5 -lhx509 -lintl \
		-lssl -lcrypto -lcrypt -lasn1 -lcom_err -lroken -lutil -lwind -lheimbase \
		-lheimntlm -lz -lpthread
	strip release/bin/${NAME}-${VERSION}-netbsd-${UNAME_M}

release-freebsd:
	mkdir -p release/bin
	${CC} ${CFLAGS} -o release/bin/${NAME}-${VERSION}-freebsd-${UNAME_M} \
		${FILES} ${LDFLAGS} \
		-static -lcurl -liconv -lc -lnghttp2 -lssh2 -lpsl -lssl -lheimntlm -lhx509 \
		-lcom_err -lcrypto -lasn1 -lwind -lheimbase -lroken -lcrypt -lz -lkrb5 -lgssapi \
		-lgssapi_krb5 -lthr -lidn2 -lunistring -lprivateheimipcc
	strip release/bin/${NAME}-${VERSION}-freebsd-${UNAME_M}

release-linux:
	mkdir -p release/bin
	${CC} ${CFLAGS} -o release/bin/${NAME}-${VERSION}-linux-${UNAME_M} \
		${FILES} ${LDFLAGS} \
		-static -lcurl -lc -lnghttp2 -lidn2 -lssh2 -lpsl -lssl -lcrypto -lzstd -lz \
		-lunistring
	strip release/bin/${NAME}-${VERSION}-linux-${UNAME_M}

dist:
	mkdir -p ${NAME}-${VERSION} release/src
	cp -R LICENSE.txt Makefile README.md CHANGELOG.md ${NAME}.1 \
		*.c ${NAME}-${VERSION}
	tar zcfv ${NAME}-${VERSION}.tar.gz ${NAME}-${VERSION}
	mv ${NAME}-${VERSION}.tar.gz release/src
	rm -rf ${NAME}-${VERSION}

install:
	mkdir -p ${DESTDIR}${PREFIX}/bin
	cp -f ${NAME} ${DESTDIR}${PREFIX}/bin
	sed "s/VERSION/${VERSION}/g" < ${NAME}.1 > ${DESTDIR}${MANPREFIX}/man1/${NAME}.1
	chmod 755 ${DESTDIR}${PREFIX}/bin/${NAME}

uninstall:
	rm -f ${DESTDIR}${MANPREFIX}/man1/${NAME}.1
	rm -f ${DESTDIR}${PREFIX}/bin/${NAME}

.PHONY: all clean install uninstall
