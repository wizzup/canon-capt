{
  stdenv, fetchzip,
  autoconf,
  automake,
  libtool,
  glib,
  gnome2,
  pkgconfig,
  libxml2,
  cndrvcups-common
}:

stdenv.mkDerivation rec {
  name = "${pname}-${version}";
  pname = "cndrvcups-capt";
  version = "2.71";

  src = fetchzip {
    url = "http://gdlp01.c-wss.com/gds/6/0100004596/05/linux-capt-drv-v271-uken.tar.gz";
    sha256 = "0agpai89vvqmjkkkk2gpmxmphmdjhiq159b96r9gybvd1c1l0dds";
  };

  patches = [ ./0001-patch-missing-include.patch ];

  unpackPhase = ''
    mkdir -p ${name}

    tar -xzf $src/Src/${name}-1.tar.gz \
      -C ${name} --strip-components=1

    sourceRoot=${name}
  '';

  buildInputs = [
    autoconf
    automake
    glib
    gnome2.gtk
    gnome2.libglade
    libtool
    pkgconfig

    cndrvcups-common
  ];

  # install directions based on arch PKGBUILD file
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=capt-src

  configurePhase = ''
    for _dir in driver ppd backend pstocapt pstocapt2 pstocapt3
    do
        pushd $_dir
          autoreconf -fi
          ./autogen.sh --prefix=$out --enable-progpath=$out/bin --disable-static
        popd
    done

    pushd statusui
      autoreconf -fi
      CPPFLAGS=$(pkg-config --cflags libxml-2.0) \
        LIBS='-lpthread -lgdk-x11-2.0 -lgobject-2.0 -lglib-2.0 -latk-1.0 -lgdk_pixbuf-2.0' \
        ./autogen.sh --prefix=$out --disable-static
    popd

    pushd cngplp
      autoreconf -fi
      ./autogen.sh --prefix=$out --libdir=$out/lib
    popd

    pushd cngplp/files
      autoreconf -fi
      ./autogen.sh
    popd
  '';

  buildPhase = ''
    make
  '';

  installPhase = ''
    mkdir -p $out

    for _dir in driver ppd backend pstocapt pstocapt2 pstocapt3 statusui cngplp
    do
        pushd $_dir
          make install DESTDIR=$out
        popd
    done

    ##HACK: `make install` install files to wrong directory
    cp -rv $out/$out/* $out
    rm -r $out/nix

    ##HACK: move files from $out/usr to $out
    cp -rv $out/usr/* $out
    rm -r $out/usr

    install -dm755 $out/lib
    install -c libs/libcaptfilter.so.1.0.0  $out/lib
    install -c libs/libcaiocaptnet.so.1.0.0 $out/lib
    install -c libs/libcncaptnpm.so.2.0.1   $out/lib
    install -c -m 755 libs/libcnaccm.so.1.0 $out/lib

    pushd $out/lib
      ln -s libcaptfilter.so.1.0.0 libcaptfilter.so.1
      ln -s libcaptfilter.so.1.0.0 libcaptfilter.so
      ln -s libcaiocaptnet.so.1.0.0 libcaiocaptnet.so.1
      ln -s libcaiocaptnet.so.1.0.0 libcaiocaptnet.so
      ln -s libcncaptnpm.so.2.0.1 libcncaptnpm.so.2
      ln -s libcncaptnpm.so.2.0.1 libcncaptnpm.so
      ln -s libcnaccm.so.1.0 libcnaccm.so.1
      ln -s libcnaccm.so.1.0 libcnaccm.so
    popd

    install -dm755 $out/bin
    install -c libs/captdrv            $out/bin
    install -c libs/captfilter         $out/bin
    install -c libs/captmon/captmon    $out/bin
    install -c libs/captmon2/captmon2  $out/bin
    install -c libs/captemon/captmon*  $out/bin

    ##FIXME: currently install x64 only, find the way to choose
    install -c libs64/ccpd       $out/bin
    install -c libs64/ccpdadmin  $out/bin
    # install -c libs/ccpd       $out/bin
    # install -c libs/ccpdadmin  $out/bin

    install -dm755 $out/etc
    install -c samples/ccpd.conf  $out/etc

    install -dm755 $out/share/ccpd
    install -c libs/ccpddata/CNA*L.BIN    $out/share/ccpd
    install -c libs/ccpddata/CNA*LS.BIN   $out/share/ccpd
    install -c libs/ccpddata/cnab6cl.bin  $out/share/ccpd
    install -c libs/captemon/CNAC*.BIN    $out/share/ccpd

    install -dm755 $out/share/captfilter
    install -c libs/CnA*INK.DAT $out/share/captfilter

    install -dm755 $out/share/captmon
    install -c libs/captmon/msgtable.xml    $out/share/captmon
    install -dm755 $out/share/captmon2
    install -c libs/captmon2/msgtable2.xml  $out/share/captmon2
    install -dm755 $out/share/captemon
    install -c libs/captemon/msgtablelbp*   $out/share/captemon
    install -c libs/captemon/msgtablecn*    $out/share/captemon
    install -dm755 $out/share/caepcm
    install -c -m 644 data/C*   $out/share/caepcm
    install -dm755 $out/share/doc/capt-src
    install -c -m 644 *capt*.txt $out/share/doc/capt-src
  '';

  meta = with stdenv.lib; {
    description = "Canon CAPT driver - capt module";
  };
}
