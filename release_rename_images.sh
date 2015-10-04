#!/bin/bash

ident="ffbi-0.5.0"

if [ ! -d "$1" ]; then
  echo "usage: $0 <folder>"
  exit 1
fi

for path in $(find "$1" -iname "openwrt*"); do
        dir="${1%/*}"
        file="${path##*/}"
        if [ "$file" != "${file/$ident/}" ]; then
                echo "Already contains '$ident': $path"
                continue
        fi
        new_file=`echo "$file" | sed -e "s/openwrt/openwrt-$ident/g"`
        mv "$path" "$dir/$new_file"
done
