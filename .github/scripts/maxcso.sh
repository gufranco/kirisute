#!/bin/sh
set -eu

prefix="${1:?usage: sh .github/scripts/maxcso.sh <install prefix>}"
version=1.13.0
sum=af9c05add1a1d199ec184d3471081af1b91d591b2473800ea989c882fb632730
work="$(mktemp -d)"
trap 'rm -rf "${work:?}"' EXIT

curl -fsSL -o "${work}/maxcso.tar.gz" "https://github.com/unknownbrackets/maxcso/archive/refs/tags/v${version}.tar.gz"
if command -v sha256sum >/dev/null 2>&1; then
  printf '%s  %s\n' "${sum}" "${work}/maxcso.tar.gz" | sha256sum -c - >/dev/null
else
  printf '%s  %s\n' "${sum}" "${work}/maxcso.tar.gz" | shasum -a 256 -c - >/dev/null
fi
tar -xzf "${work}/maxcso.tar.gz" -C "${work}"
paths="$(pkg-config --cflags --libs-only-L libuv liblz4)"
make -C "${work}/maxcso-${version}" -j4 CFLAGS="-O2 -w ${paths}" CXXFLAGS="-O2 -w ${paths}" >/dev/null
make -C "${work}/maxcso-${version}" install PREFIX="${prefix}" >/dev/null
test -x "${prefix}/bin/maxcso"
