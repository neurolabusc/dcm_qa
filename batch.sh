#!/bin/bash

#exenam is executable
# we assume it is in the users path
# however, this could be set explicitly, e.g.
#  exenam="/Users/rorden/Documents/cocoa/dcm2niix/console/dcm2niix"
exenam="dcm2niix"

#basedir is folder with "Ref" and "In" subfolders.
# we assume it is the same same folder as the script
# however, this could be set explicitly, e.g.
#   basedir="/Users/rorden/dcm_qa"
basedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#### no need to edit subsequent lines

#folder paths
indir=${basedir}/In
outdir=${basedir}/Out
refdir=${basedir}/Ref

#check inputs
command -v $exenam >/dev/null 2>&1 || { echo >&2 "I require $exenam but it's not installed.  Aborting."; exit 1; }
if [ ! -d $indir ]; then
 echo "Error: Unable to find $indir"
 exit 1
fi
if [ ! -d $refdir ]; then
 echo "Error: Unable to find $refdir"
 exit 1
fi
if [ ! -d $outdir ]; then
 mkdir $outdir
fi
if [ ! -z "$(ls $outdir)" ]; then
 echo "Error: Please delete files in $outdir"
 exit 1
fi

#convert images
cmd="$exenam -b y -z n -f %p_%s -o $outdir $indir"
echo "Running command:"
echo $cmd
$cmd

#check differences
cmd="diff -bur $outdir $refdir"
echo "Running command:"
echo $cmd
$cmd

