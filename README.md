
## About

dcm_qa is a simple DICOM to NIfTI validator script and dataset. The DICOM dataset includes images that exhibit various features such as variation in [TotalReadoutTime](https://github.com/rordenlab/dcm2niix/issues/98), Slice Orientation and [Transfer Syntax](https://www.nitrc.org/plugins/mwiki/index.php/dcm2nii:MainPage#Transfer_Syntaxes_and_Compressed_Images) that might disrupt conversion (specific features described in the text file). The current code validates [dcm2niix](https://github.com/rordenlab/dcm2niix), but could be easily adapted for other tools.

This validator script converts DICOM images in the "In" folders and saves the results in the "Out" folder. It then reports any differences between the "Out" folder and the "Ref" folder of reference files. It will report ANY differences between these files. This allows the script to check both [NIfTI](https://brainder.org/2012/09/23/the-nifti-file-format/) and [BIDS](http://bids.neuroimaging.io) format files. Note that just because their is a difference does not mean a conversion is incorrect. For example, the BIDS file contains the version of dcm2niix used for conversion, and one expects this to change with new versions. What this script does is report ALL changes, and the user can determine if they reflect regressions.

## License

This software and images are open source and were acquired by Chris Rorden. The the code is covered by the [2-clause BSD license](https://opensource.org/licenses/BSD-2-Clause) and released in June 2017.

## Versions

21-June-2017
 - Initial public release

## Running

Edit the first few lines of the `batch.sh` script so that `basedir` reports the location of the `dcm_qa` folder on your computer and `exenam` reports the location of dcm2niix. Next, make sure the script is executable (`chmod +x batch.sh`). Then run the script.