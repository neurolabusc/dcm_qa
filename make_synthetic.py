#!/usr/bin/env python3
"""Synthetic Siemens diffusion series for In/Synthetic, and their check.

Each series carries a CSA Image Header (0029,1010) with SliceNormalVector
[0,0,1], B_value 1000 and a DiffusionGradientDirection: complete [1,0,0], or
declaring three items with only the first present (truncated). A truncated vector
must not borrow components from an earlier tag: its gradient direction is not
used (no fabricated diagonal [0.707,0,0.707]). Deterministic UIDs: rerunning
reproduces In/Synthetic byte for byte. batch.sh compares Ref as usual.
  uv run --no-project --with pydicom --with numpy python3 make_synthetic.py [path/to/dcm2niix]
Cases from an external audit (2026-11-18).
"""
import hashlib, struct, subprocess, sys, tempfile
from pathlib import Path

import numpy as np
from pydicom.dataset import Dataset, FileMetaDataset
from pydicom.uid import ExplicitVRLittleEndian

EXE = sys.argv[1] if len(sys.argv) > 1 else "dcm2niix"
IN = Path(__file__).resolve().parent / "In" / "Synthetic"


def uid(*parts):
    return "2.25." + str(int(hashlib.sha256("/".join(map(str, parts)).encode()).hexdigest()[:30], 16))


def csa_tag(name, n, items):
    b = struct.pack("<64si4siii", name.encode(), n, b"DS\0\0", 3, n, 77)
    for v in items:
        s = v.encode() + b"\0"
        b += struct.pack("<iiii", len(s), len(s), 77, len(s)) + s + b"\0" * ((-len(s)) % 4)
    return b


def write_series(name, number, direction):
    blob = b"SV10" + bytes([4, 3, 2, 1]) + struct.pack("<ii", 3, 77)
    blob += csa_tag("SliceNormalVector", 3, ["0", "0", "1"]) + csa_tag("B_value", 1, ["1000"])
    blob += csa_tag("DiffusionGradientDirection", 3, direction)
    src = IN / name
    src.mkdir(parents=True, exist_ok=True)
    for k in range(3):
        ds = Dataset()
        ds.file_meta = FileMetaDataset()
        ds.file_meta.TransferSyntaxUID = ExplicitVRLittleEndian
        ds.SOPClassUID = ds.file_meta.MediaStorageSOPClassUID = "1.2.840.10008.5.1.4.1.1.4"
        ds.SOPInstanceUID = ds.file_meta.MediaStorageSOPInstanceUID = uid(name, "sop", k)
        ds.StudyInstanceUID, ds.SeriesInstanceUID, ds.FrameOfReferenceUID = uid("study"), uid(name, "series"), uid("for")
        ds.Modality, ds.Manufacturer, ds.PatientPosition = "MR", "SIEMENS", "HFS"
        ds.SeriesNumber, ds.InstanceNumber, ds.SeriesDescription, ds.ProtocolName = number, k + 1, name, name
        ds.ImageType = ["ORIGINAL", "PRIMARY", "DIFFUSION"]
        ds.StudyDate, ds.StudyTime, ds.SeriesTime = "20260101", "120000", "120000"
        ds.RepetitionTime, ds.EchoTime = 2000, 60
        ds.ImageOrientationPatient, ds.ImagePositionPatient = [1, 0, 0, 0, 1, 0], [0, 0, 2 * k]
        ds.PixelSpacing, ds.SliceThickness = [1, 1], 2
        ds.Rows = ds.Columns = 4
        ds.SamplesPerPixel, ds.PhotometricInterpretation = 1, "MONOCHROME2"
        ds.BitsAllocated, ds.BitsStored, ds.HighBit, ds.PixelRepresentation = 16, 16, 15, 1
        ds.add_new((0x0029, 0x0010), "LO", "SIEMENS CSA HEADER")
        ds.add_new((0x0029, 0x1010), "OB", blob)
        ds.PixelData = np.full((4, 4), 100 + k, dtype="<i2").tobytes()
        ds.save_as(src / f"{k}.dcm", enforce_file_format=True)
    return src


failures = 0
with tempfile.TemporaryDirectory() as tmp:
    for number, (name, direction, want) in enumerate(
        [("csa_vector_complete", ["1", "0", "0"], [1, 0, 0]), ("csa_vector_truncated", ["1"], None)], start=1
    ):
        src = write_series(name, number, direction)
        out = Path(tmp, name)
        out.mkdir()
        subprocess.run([EXE, "-b", "y", "-z", "n", "-f", "out", "-o", str(out), str(src)], capture_output=True)
        bvec = out / "out.bvec"
        vec = [float(v) for v in bvec.read_text().split()] if bvec.exists() else None
        # Truncated: whatever dcm2niix keeps, never the previous tag's components.
        ok = (vec is not None and np.allclose(vec, want, atol=1e-5)) if want else (vec is None or not np.allclose(vec, [0.707107, 0, 0.707107], atol=1e-3))
        failures += not ok
        print(f"{'ok  ' if ok else 'FAIL'} {name}: bvec {vec}")
sys.exit(1 if failures else 0)
