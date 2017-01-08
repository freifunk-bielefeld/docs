#!/bin/sh

# This script creates a new manifest based on an old one.

if [ $# -ne 3 ]; then
  echo "Usage: $0 <release-version> <old_manifest> <new_manifest>"
  echo
  echo "Example:"
  echo "  cd <images_dir>"
  echo "  $0 ffbi-0.6.5 manifest new_manifest"
  exit 1
fi

version="$1"
manifest_old="$2"
manifest_new="$3"


if [ ! -e "$manifest_old" ]; then
  echo "Source file does not exist: $manifest_old"
  exit 1
fi

if [ -e "$manifest_new" ]; then
  echo "Target file already exists: $manifest_new"
  exit 1
fi


# Extract all models from the old manifest
models="$(cat $manifest_old | awk '/^[a-z]/{print $1}' | sort | uniq)"

find_image_heuristic() {
  local id="$1"

  # Find image file using an heuristic
  local max_occ=$(ls *sysupgrade* 2> /dev/null | wc -l)
  local wparts=""
  for part in $(echo $id | tr '-' ' '); do
    local occ=$(ls *-$part-* 2> /dev/null | grep sysupgrade | wc -l)
    if [ $occ -gt 0 ]; then
      # Map of file name part and occurences
      wparts="$wparts $part:$(( 1000 * $max_occ / occ ))"
    fi
  done

  local rate_found=0
  local file_found=""
  for file in *sysupgrade*; do
    local rate=0
    for wp in $wparts; do
      local weight=${wp#*:}
      local part=${wp%%:*}
      if [ $weight -gt 0 -a "${file#*$-$part-}" != "$file" ]; then
        rate=$((rate + weight * ${#part} * ${#part} ))
      fi
    done

    # Rating must be higher or the file name must be shorter if the rate is the same.
    if [ $rate -gt $rate_found ] || [ $rate -eq $rate_found -a ${#file} -lt ${#file_found} ]; then
      rate_found=$rate
      file_found=$file
    fi
  done

  echo $file_found
}


# Find the image file that matches the model.
# Searches in the old manifest first, then try an heuristic.
find_file() {
  local manifest_old="$1"
  local model="$2"

  # Find filename in old manifest
  for file in $(cat $manifest_old | awk  '/^'$model'/{if(NF > 3) print($NF) }'); do
   file=$(find_image_heuristic "$file")
   if [ -n "$file" ]; then
     echo $file
     return
   fi
  done

  # Try heuristic on model.
  find_image_heuristic "$model"
}


# Write the new manifest file.
echo "BRANCH=stable" > $manifest_new
echo > $manifest_new
echo "# model version sha512sum filename " >> $manifest_new

for model in $models; do
  file=$(find_file "$manifest_old" "$model")
  if [ -e "$file" ]; then
    hash=$(sha512sum $file | awk '{print $1}')
    echo "$model $version $hash $file" >> $manifest_new
  else
    echo "Failed to find image file for '$model': $file"
  fi
done

echo >> $manifest_new
echo "# after three dashes follow the ecdsa signatures of everything above the dashes" >> $manifest_new
# Put only along with signatures
#echo "---" >> $manifest_new

echo "Wrote: $manifest_new"
