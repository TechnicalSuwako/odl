# odl - オンライン・ダウンロード

## インストールする方法
### OpenBSD
```sh
doas pkg_add curl
make
doas make install
```

### Void Linux
```sh
doas xbps-install curl bmake
bmake
doas bmake install
```

### FreeBSD
```sh
doas pkg install curl
make
doas make install
```

### NetBSD
```sh
doas pkgin install curl
make
doas make install
```

### CRUX Linux
```sh
doas prt-get depinst curl bmake
bmake
doas bmake install
```

### Minix
```sh
su
pkgin install curl clang bmake
bmake
bmake install
```

### Haiku
```sh
pkgman install curl curl_devel bmake
bmake
bmake install
```

### macOS
```sh
brew install curl bmake
bmake
doas bmake install
```
