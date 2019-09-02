#!/bin/bash

# Fail if anything not planed to go wrong, goes wrong
set -eu

# Test if command exists.
exists() {
    test -x "$(command -v "$1")"
}

#exenam is executable
# we assume it is in the users path
# however, this could be set explicitly, e.g.
#  exenam="/Users/rorden/Documents/cocoa/dcm2niix/console/dcm2niix" batch.sh
exenam=${examnam:-dcm2niix}

#basedir is folder with "Ref" and "In" subfolders.
# we assume it is the same same folder as the script
# however, this could be set explicitly, e.g.
#   basedir="/Users/rorden/dcm_qa" batch.sh
if [ -z ${basedir:-} ]; then
    basedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
fi

#### no need to edit subsequent lines

#folder paths
indir=${basedir}/In
outdir=${basedir}/Out
refdir=${basedir}/Ref

# Check inputs.
exists $exenam ||
    {
        echo >&2 "I require $exenam but it's not installed.  Aborting."
        exit 1
    }

if [ ! -d "$indir" ]; then
 echo "Error: Unable to find $indir"
 exit 1
fi

if [ ! -d "$refdir" ]; then
 echo "Error: Unable to find $refdir"
 exit 1
fi

if [ ! -d "$outdir" ]; then
 mkdir $outdir
fi

if [ ! -z "$(ls $outdir)" ]; then
 echo "Cleaning output directory: $outdir"
 rm $outdir/*
fi

# detect big endian https://github.com/rordenlab/dcm2niix/issues/333
littleEndian=$(echo I | tr -d [:space:] | od -to2 | head -n1 | awk '{print $2}' | cut -c6)
if [[ $littleEndian == "1" ]]; then
  #echo "little-endian hardware: retaining little-endian"
  #return blank so we are compatible with earlier versions of dcm2niix
  endian=""
else
  echo "big-endian hardware: forcing little-endian NIfTIs"
  endian="--big-endian n"
fi

# Convert images.
cmd="$exenam $endian -b y -z n -f %p_%s -o $outdir $indir"

echo "Running command:"
echo $cmd
exit 1

$cmd


# Validate JSON.
exists python &&
    {
        printf "\n\n\nValidating JSON files.\n\n\n"
        for file in $outdir/*.json; do
            echo -n "$file "
            ! python -m json.tool "$file" > /dev/null || echo " --  Valid."
        done
        printf "\n\n\n"
    }

#remove macOS hidden files if they exist
dsstore=${refdir}/.DS_Store
[ -e $dsstore ] && rm $dsstore
dsstore=${outdir}/.DS_Store
[ -e $dsstore ] && rm $dsstore

#check differences

cmd="diff -x '.*' -br $refdir $outdir -I ConversionSoftwareVersion"
echo "Running command:"
echo $cmd
$cmd

