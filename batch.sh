#!/bin/bash

basedir="/Users/rorden/dcm_qa"
exenam="/Users/rorden/Documents/cocoa/dcm2niix/console/dcm2niix"

#### no need to edit subsequent lines

#folder paths
indir=${basedir}/In
outdir=${basedir}/Out
refdir=${basedir}/Ref

#check inputs
if [ ! -f $exenam ]; then
 echo "Error: Unable to find $exenam"
 exit 1
fi
if [ ! -d $indir ]; then
 echo "Error: Unable to find $indir"
 exit 1
fi
if [ ! -d $outdir ]; then
 echo "Error: Unable to find $outdir"
 exit 1
fi
if [ ! -d $refdir ]; then
 echo "Error: Unable to find $refdir"
 exit 1
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

