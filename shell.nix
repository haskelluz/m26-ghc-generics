{
  pkgs ? let
    lock = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
    nixpkgs = fetchTarball {
      url = "https://github.com/nixos/nixpkgs/archive/${lock.rev}.tar.gz";
      sha256 = lock.narHash;
    };
  in
    import nixpkgs {overlays = [];},
  hpkgs,
  pre-commit-check,
  ...
}:
pkgs.stdenv.mkDerivation {
  name = "ghc-generics";

  # Build time dependencies
  nativeBuildInputs = with pkgs; [
    git
    nixd
    statix
    deadnix
    alejandra
  ];

  # Runtime dependencies
  buildInputs = [
    hpkgs.cabal-install
    hpkgs.cabal-add
    hpkgs.haskell-language-server
    hpkgs.fourmolu
    hpkgs.hlint
    hpkgs.hpack
    hpkgs.cabal-fmt

    pkgs.just
    pkgs.alejandra
    pkgs.zlib
    pkgs.treefmt
    pkgs.libpq.dev
    pkgs.zlib.dev
    pkgs.libz
    pkgs.pkg-config
    pkgs.xz

    pre-commit-check.enabledPackages

    pkgs.marp-cli
  ];
  shellHook = ''
    ${pre-commit-check.shellHook}
  '';

  NIX_CONFIG = "extra-experimental-features = nix-command flakes";
}
