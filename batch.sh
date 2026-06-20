#!/bin/bash

# Fail if anything not planned to go wrong, goes wrong
set -eu

PS4="Running: "

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
flags='-b y -z n -f %p_%s'

help_message="usage: batch.sh -i <in dir> -o <out dir> -f <ref dir> -f <dcm2niix flags>\n
default in dir : ${indir}\n
default out dir: ${outdir}\n
default ref dir: ${refdir}\n
default dcm2niix flags: ${flags}"

while getopts i:o:r:f:h option
do 
    case "${option}"
        in
        i)indir=${OPTARG};;
        o)outdir=${OPTARG};;
        r)refdir=${OPTARG};;
        f)flags=${OPTARG};;
        h)echo -e ${help_message}
          exit 1;;
        ?)echo -e ${help_message}
          exit 1;;
    esac
done

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
 mkdir ${outdir}
fi

if [ ! -z "$(ls $outdir)" ]; then
 echo "Cleaning output directory: $outdir"
 rm ${outdir}/*
fi

# Convert images.
set -x
$exenam ${flags} -o "$outdir" "$indir"
set +x

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
[ -e $dsstore ] && rm "$dsstore"
dsstore=${outdir}/.DS_Store
[ -e "$dsstore" ] && rm "$dsstore"

#check differences

set -x
diff -x '.*' -br "$refdir" "$outdir" -I ConversionSoftwareVersion -I BidsGuess
set +x

