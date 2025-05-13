{ pkgs, ... }:

with pkgs;
stdenv.mkDerivation {
  name = "glslang";
  installPhase = ''
    mkdir -p $out
  '';
  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "glslang";
    rev = "c34bb3b6c55f6ab084124ad964be95a699700d34";
    sha256 = "IMROcny+b5CpmzEfvKBYDB0QYYvqC5bq3n1S4EQ6sXc=";
  };
}
