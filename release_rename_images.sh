#!/bin/bash

if [ $# -ne 2 -o ! -d "$2" ]; then
  echo "usage: $0 <ident> <folder>"
  echo "E.g. $0 0.5.0 bin/ar71xxx/"
  exit 1
fi

ident="$1"
path="$2"

for path in $(find "$path" -iname "lede*"); do
        dir="${path%/*}"
        file="${path##*/}"
        if [ "$file" != "${file/$ident/}" ]; then
                echo "Already contains '$ident': $path"
                continue
        fi
	new_file="$ident"`echo "$file" | sed -e "s/lede-[^-]*-[^-]*//"`
	mv "$path" "$dir/$new_file"
done

exit 0
