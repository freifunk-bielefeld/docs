#!/bin/bash

if [ $# -ne 2 -o ! -d "$2" ]; then
  echo "usage: $0 <ident> <folder>"
  exit 1
fi

#.e.g "ffbi-0.5.0"
ident="$1"
path="$2"

for path in $(find "$path" -iname "openwrt*"); do
        dir="${path%/*}"
        file="${path##*/}"
        if [ "$file" != "${file/$ident/}" ]; then
                echo "Already contains '$ident': $path"
                continue
        fi
        new_file=`echo "$file" | sed -e "s/openwrt/openwrt-$ident/g"`
        mv "$path" "$dir/$new_file"
done

exit 0
