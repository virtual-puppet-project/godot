{ stdenv
, lib
, fetchFromGitHub
, scons
, pkg-config
, udev
, libX11
, libXcursor
, libXinerama
, libXrandr
, libXrender
, libpulseaudio
, libXi
, libXext
, libXfixes
, freetype
, openssl
, alsa-lib
, libGLU
, zlib
, yasm
, withUdev ? true
, extraModules ? []
, python3
}:

let
  options = {
    touch = libXi != null;
    pulseaudio = false;
    udev = withUdev;
  };
in
stdenv.mkDerivation rec {
  pname = "godot";
  version = "3.5.1";

  src = ./.;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    scons
    udev
    libX11
    libXcursor
    libXinerama
    libXrandr
    libXrender
    libXi
    libXext
    libXfixes
    freetype
    openssl
    alsa-lib
    libpulseaudio
    libGLU
    zlib
    yasm
  ];

  enableParallelBuilding = true;

  sconsFlags = "target=release_debug platform=x11 tools=yes";

  inherit extraModules;

  prePatch = ''
    declare -a patches=()
    for mod in $extraModules
    do
      patches+=($mod/patches/*)
      [[ -e $mod/modules ]] && cp -r $mod/modules .
      [[ -e $mod/thirdparty ]] && cp -r $mod/thirdparty .
      [[ -e $mod/helper_script.py ]] && ${python3}/bin/python3 $mod/helper_script.py
    done
    chmod -R u+rw .
    echo $patches # ok why this make the build progress?????????
  '';

  preConfigure = ''
    sconsFlags+=" ${
      lib.concatStringsSep " "
      (lib.mapAttrsToList (k: v: "${k}=${builtins.toJSON v}") options)
    }"
  '';

  outputs = [ "out" "dev" "man" ];

  installPhase = ''
    mkdir -p "$out/bin"
    cp bin/godot.* $out/bin/godot

    mkdir "$dev"
    cp -r modules/gdnative/include $dev

    mkdir -p "$man/share/man/man6"
    cp misc/dist/linux/godot.6 "$man/share/man/man6/"

    mkdir -p "$out"/share/{applications,icons/hicolor/scalable/apps}
    cp misc/dist/linux/org.godotengine.Godot.desktop "$out/share/applications/"
    cp icon.svg "$out/share/icons/hicolor/scalable/apps/godot.svg"
    cp icon.png "$out/share/icons/godot.png"
    substituteInPlace "$out/share/applications/org.godotengine.Godot.desktop" \
      --replace "Exec=godot" "Exec=$out/bin/godot"
  '';

  meta = with lib; {
    homepage = "https://godotengine.org";
    description = "Free and Open Source 2D and 3D game engine";
    license = licenses.mit;
    platforms = [ "i686-linux" "x86_64-linux" ];
    maintainers = with maintainers; [ twey ];
  };
}
