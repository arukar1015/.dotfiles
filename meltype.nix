{
  lib,
  stdenv,
  fetchurl,
  unzip,
  autoPatchelfHook,
  makeWrapper,
  python3,
  ibus,
  glib,
  gobject-introspection,
  zlib,
  openssl,
  icu,
  krb5,
}:

let
  pythonEnv = python3.withPackages (ps: [ ps.pygobject3 ]);
in
stdenv.mkDerivation rec {
  pname = "meltype";
  version = "1.2.1";

  src = fetchurl {
    url = "https://github.com/yksr-melt/Meltype/releases/download/v${version}/Meltype-${version}-linux.zip";
    sha256 = "e377ebd4a9acef4d9790241c72d996e25c564d49b89da5c03995002b4df4b358";
  };

  sourceRoot = "Meltype-linux";

  nativeBuildInputs = [
    unzip
    autoPatchelfHook
    makeWrapper
    gobject-introspection
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    zlib
    openssl
    icu
    krb5
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    dir=$out/lib/meltype
    mkdir -p $dir $out/share/ibus/component

    # zip の中身 (libMeltypeNative.so, ibus-engine-meltype, mozc/ など) をそのまま置く
    cp -r . $dir/
    rm -f $dir/install.sh $dir/uninstall.sh $dir/TESTER-README.txt
    rm -rf $dir/__pycache__ $dir/fcitx5
    chmod -R u+w $dir
    chmod +x $dir/ibus-engine-meltype
    [ -f $dir/mozc/meltype_mozc_helper ] && chmod +x $dir/mozc/meltype_mozc_helper || true

    # python3 のシェバンを Nix の python (pygobject 入り) に置き換え
    patchShebangs $dir/ibus-engine-meltype

    # IBus のコンポーネント定義 (@DIR@ をインストール先に置換)
    substituteInPlace $dir/meltype.xml --replace-fail "@DIR@" "$dir"
    mv $dir/meltype.xml $out/share/ibus/component/meltype.xml

    wrapProgram $dir/ibus-engine-meltype \
      --prefix GI_TYPELIB_PATH : "${ibus}/lib/girepository-1.0:${glib}/lib/girepository-1.0" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ ibus glib ]}"

    runHook postInstall
  '';

  # python は pygobject 入りのものを使う
  postPatch = ''
    sed -i '1s|.*|#!${pythonEnv}/bin/python3|' ibus-engine-meltype
  '';

  meta = {
    isIbusEngine = true;
    description = "Meltype: 半角/全角 を押さずに日本語と英語を打ち分ける日本語入力 (Linux プレビュー版 / IBus)";
    homepage = "https://github.com/yksr-melt/Meltype";
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}

