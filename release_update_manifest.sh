#!/bin/sh

if [ $# -ne 2 -o ! -f "$2" ]; then
  echo "usage: $0 <new_version> <old_manifest>"
fi

manifest="$2"
version_new="$1"

echo > manifest_new

do_hash()
{
  local hash="" path="$1"
  split() { hash="$1"; }
  local OLDIFS=$IFS
  IFS=" "
  split $(sha512sum $path)
  IFS="$OLDIFS"
  echo $hash
}

write_line()
{
  local n=0 ident version hash filename
  split() { n="$#" ident="$1" version="$2" hash="$3" filename="$4"; }
  local OLDIFS=$IFS
  IFS=" "
  split $line
  IFS="$OLDIFS"

  if [ $n -eq 4 ]; then
    if [ ! -f  "$filename" ]; then
      echo "Error: Cannot find file: $filename"
      exit 1
    fi
    local hash_new=$(do_hash $filename)
    echo "$ident $version_new $hash_new $filename" >> manifest_new
  else
    echo $line >> manifest_new
  fi
}

OLDIFS=$IFS
IFS="
"
for line in $(cat "$manifest"); do
  if [ "$line" = "---" ]; then
	echo $line >> manifest_new
	exit 0
  fi

  write_line $line
done
IFS="$OLDIFS"

echo "Wrote manifest_new"

exit 0
