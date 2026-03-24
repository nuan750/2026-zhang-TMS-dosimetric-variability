# 2026-zhang-TMS-dosimetric-variability

This repository contains Python and MATLAB scripts for subject-specific TMS electric field modeling and structural feature extraction based on SimNIBS/CHARM outputs.

The workflow in this repository includes:
- CHARM head model generation
- TMS electric field simulation
- extraction of ROI-based electric field metrics
- extraction of magnE percentiles for C3 and F3 conditions
- extraction of mesh and tissue-related summary measures

## Requirements

The scripts in this repository may require:

- Python 3
- MATLAB
- SimNIBS
- CHARM outputs
- Gmsh/mesh-related SimNIBS MATLAB functions
- Subject-specific log files and mesh files generated during simulation

## General note

Local data paths are **not** included in this repository.

Most scripts are written so that users either:
- select folders at runtime, or
- replace placeholder paths with their own local directories before running.

Please update local paths as needed on your own system.

## Repository contents

### Python scripts

#### `creat_head_model_charm.py`
Creates subject-specific head models in batch using CHARM.

This script:
- loops through subject folders
- checks whether T1w and T2w files exist
- runs CHARM for each valid subject

#### `run_efield_modeling.py`
Runs batch TMS electric field simulations using SimNIBS.

This script:
- reads subject folders from a CHARM directory
- extracts C3 and F3 coordinates from EEG position files
- sets TMS coil positions
- runs electric field simulations
- saves outputs to a results directory

### MATLAB scripts

#### `Extract_avg_ROI.m`
Extracts average electric field values within ROI spheres centered on predefined target coordinates.

This script:
- loads subject-specific field meshes
- converts MNI coordinates to subject space
- computes area-weighted average field strength inside ROI masks
- exports summary results

#### `extract_edge_length.m`
Extracts mesh edge-length summary values from `charm_log.html`.

This script:
- scans CHARM log files for the final edge-length report
- extracts average, minimum, and maximum edge length
- extracts the percentage of edges within a specified range
- saves a summary table

#### `extract_magnE_c3_f3.m`
Extracts gray matter magnE percentiles for both C3 and F3 stimulation conditions.

This script:
- loads subject-specific field meshes
- extracts gray matter elements
- computes 95th, 99th, and 99.9th percentiles of magnE
- saves combined C3/F3 summary results

#### `extract_tissue_thickness.m`
Extracts scalp-to-cortex distance (SCD) or related distance-based measures from subject log files.

This script:
- reads subject log files
- extracts coil-cortex distance values
- computes C3 and F3 distances
- calculates the F3/C3 ratio
- exports the results table

#### `get_intracranial_volume.m`
Computes white matter, gray matter, CSF, and intracranial volume from subject meshes.

This script:
- loads subject-specific head meshes
- extracts tissue regions
- computes tissue volumes
- converts volumes to cm³
- exports the final table

#### `simnibs_SCD_extraction.m`
Runs additional SimNIBS-based extraction steps for scalp-cortex or structural distance measures.

Please check the script directly for implementation details and expected inputs.

## Expected folder structure

A typical local directory structure may look like this:

```text
root_data/
├── charm/
│   ├── subject_01/
│   │   └── m2m_subject_01/
│   └── subject_02/
├── fields/
│   ├── subject_01/
│   └── subject_02/
