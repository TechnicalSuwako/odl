UNAME_S != uname -s
UNAME_M != uname -m
OS = ${UNAME_S}

.if ${UNAME_S} == "OpenBSD"
OS = openbsd
.elif ${UNAME_S} == "NetBSD"
OS = netbsd
.elif ${UNAME_S} == "FreeBSD"
OS = freebsd
.elif ${UNAME_S} == "Linux"
OS = linux
.endif

NAME != cat main.c | grep "const char\* sofname" | awk '{print $$5}' | \
	sed "s/\"//g" | sed "s/;//"
VERSION != cat main.c | grep "const char\* version" | awk '{print $$5}' | \
	sed "s/\"//g" | sed "s/;//"
PREFIX = /usr/local
.if ${UNAME_S} == "Linux"
PREFIX = /usr
.elif ${UNAME_S} == "Haiku"
PREFIX = /boot/home/config/non-packaged
.elif ${UNAME_S} == "Darwin"
.endif

MANPREFIX = ${PREFIX}/share/man
.if ${UNAME_S} == "OpenBSD"
MANPREFIX = ${PREFIX}/man
.elif ${UNAME_S} == "Haiku"
MANPREFIX = ${PREFIX}/documentation/man
.endif

CFLAGS = -Wall -Wextra -g -I/usr/include -I/usr/local/include
LDFLAGS = -L/usr/lib -L/usr/local/lib

.if ${UNAME_S} == "NetBSD" || ${UNAME_S} == "Minix"
CFLAGS += -I/usr/pkg/include
LDFLAGS += -L/usr/pkg/lib
.elif ${UNAME_S} == "Haiku"
CFLAGS += -I/boot/system/develop/headers
LDFLAGS += -L/boot/system/develop/lib
.elif ${UNAME_S} == "Darwin"
CFLAGS += -I/opt/local/include
LDFLAGS += -L/opt/local/lib
.endif

CC = cc
.if ${UNAME_S} == "Minix"
CC = clang
.endif

FILES = main.c
LIBS = -lcurl

STATIC = -static ${LIBS}
.if ${UNAME_S} == "OpenBSD"
STATIC += -lc -lnghttp3 -lngtcp2_crypto_quictls -lngtcp2 -lssl -lcrypto -lnghttp2\
					-lz -lpthread
.elif ${UNAME_S} == "FreeBSD"
STATIC += -liconv -lc -lnghttp2 -lssh2 -lpsl -lssl -lheimntlm -lhx509 -lcom_err\
					-lcrypto -lasn1 -lwind -lheimbase -lroken -lcrypt -lz -lkrb5 -lgssapi\
					-lgssapi_krb5 -lthr -lidn2 -lunistring -lprivateheimipcc
.elif ${UNAME_S} == "NetBSD"
STATIC += -lnghttp2 -lc -lidn2 -lunistring -lgssapi -lkrb5 -lhx509 -lintl -lssl\
					-lcrypto -lcrypt -lasn1 -lcom_err -lroken -lutil -lwind -lheimbase\
					-lheimntlm -lz -lpthread
.elif ${UNAME_S} == "Linux"
STATIC += -lc -lnghttp2 -lidn2 -lssh2 -lpsl -lssl -lcrypto -lzstd -lz -lunistring
.endif

all:
	${CC} ${CFLAGS} -o ${NAME} ${FILES} ${LDFLAGS} ${LIBS}
	strip ${NAME}

clean:
	rm -f ${NAME}

dist:
	mkdir -p ${NAME}-${VERSION} release/src
	cp -R LICENSE.txt Makefile README.md CHANGELOG.md\
		${NAME}.1 ${FILES} ${NAME}-${VERSION}
	tar zcfv release/src/${NAME}-${VERSION}.tar.gz ${NAME}-${VERSION}
	rm -rf ${NAME}-${VERSION}

man:
	mkdir -p release/man/${VERSION}
	sed "s/VERSION/${VERSION}/g" < ${NAME}.1 > release/man/${VERSION}/${NAME}.1

release:
	mkdir -p release/bin/${VERSION}/${OS}/${UNAME_M}
	${CC} ${CFLAGS} -o release/bin/${VERSION}/${OS}/${UNAME_M}/${NAME}\
		${FILES} ${STATIC}
	strip release/bin/${VERSION}/${OS}/${UNAME_M}/${NAME}

install:
	mkdir -p ${DESTDIR}${PREFIX}/bin
	cp -f ${NAME} ${DESTDIR}${PREFIX}/bin
	sed "s/VERSION/${VERSION}/g" < ${NAME}.1 > ${DESTDIR}${MANPREFIX}/man1/${NAME}.1
	chmod 755 ${DESTDIR}${PREFIX}/bin/${NAME}

uninstall:
	rm -f ${DESTDIR}${MANPREFIX}/man1/${NAME}.1
	rm -f ${DESTDIR}${PREFIX}/bin/${NAME}

.PHONY: all clean dist man release install uninstall
