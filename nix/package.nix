{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "helix-fcitx-focus";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ../Cargo.lock
      ../Cargo.toml
      ../cog.scm
      ../cogs
      ../src
    ];
  };

  cargoLock = {
    lockFile = ../Cargo.lock;
    outputHashes = {
      "steel-core-0.8.2" = "sha256-lqtx1q/AHntbZvF3rpWbicvxE3NGZU+VPMueECaVdSA=";
    };
  };

  doCheck = false;

  installPhase = ''
    runHook preInstall

    dylib="$(find target -name libhelix_fcitx_focus.so -type f | head -n 1)"
    install -Dm755 "$dylib" $out/lib/libhelix_fcitx_focus.so
    install -Dm644 cog.scm $out/share/steel/cogs/helix-fcitx-focus/cog.scm
    cp -r cogs $out/share/steel/cogs/helix-fcitx-focus/cogs

    runHook postInstall
  '';

  meta = {
    description = "Steel native module for Helix fcitx5 focus and mode switching";
    homepage = "https://github.com/mtul0729/helix-fcitx-focus";
    license = with lib.licenses; [
      mit
      asl20
    ];
    platforms = lib.platforms.linux;
  };
}
