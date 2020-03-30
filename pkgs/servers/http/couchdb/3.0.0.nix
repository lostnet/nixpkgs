{ stdenv, fetchurl, erlang, icu, openssl, spidermonkey
, coreutils, bash, makeWrapper, python3 }:

stdenv.mkDerivation rec {
  pname = "couchdb";
  version = "3.0.0";


  # when updating this, please consider bumping the OTP version
  # in all-packages.nix
  src = fetchurl {
    url = "mirror://apache/couchdb/source/${version}/apache-${pname}-${version}.tar.gz";
    sha256 = "1nbz2vafzhp9jv8xna8cfnf99jwn22xs4ydzm426qx7yf0dbn2fi";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ erlang icu openssl spidermonkey (python3.withPackages(ps: with ps; [ requests ]))];
  patches = [ ];
  postPatch = ''
    substituteInPlace src/couch/rebar.config.script --replace '/usr/include/mozjs-60' "${spidermonkey.dev}/include/mozjs-60"

    patch bin/rebar <<EOF
    1c1
    < #!/usr/bin/env escript
    ---
    > #!${coreutils}/bin/env escript
    EOF

  '';

  configurePhase = ''
    ./configure --spidermonkey-version 60
  '';

  buildPhase = ''
    make release
  '';

  installPhase = ''
    mkdir -p $out
    cp -r rel/couchdb/* $out
    wrapProgram $out/bin/couchdb --suffix PATH : ${bash}/bin
  '';

  meta = with stdenv.lib; {
    description = "A database that uses JSON for documents, JavaScript for MapReduce queries, and regular HTTP for an API";
    homepage = http://couchdb.apache.org;
    license = licenses.asl20;
    platforms = platforms.all;
    maintainers = with maintainers; [ lostnet ];
  };
}
