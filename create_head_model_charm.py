from pathlib import Path
import subprocess

# Replace this with your local CHARM directory before running the script.
# Example: Path("/path/to/charm_folder")
base_dir = Path("path/to/your/charm_folder")

# Stop early if the base directory does not exist.
if not base_dir.exists():
    raise FileNotFoundError(f"Base directory not found: {base_dir}")

# Iterate through all subject folders inside the CHARM directory.
for subject_dir in base_dir.iterdir():
    # Skip anything that is not a directory.
    if not subject_dir.is_dir():
        print(f"Skipping non-directory: {subject_dir.name}")
        continue

    subject_id = subject_dir.name
    org_path = subject_dir / "org"

    # Check whether the org folder exists.
    if not org_path.is_dir():
        print(f"Org folder not found for ID: {subject_id}")
        continue

    # Build the expected T1 and T2 input file paths.
    t1_file = org_path / f"{subject_id}_T1w.nii.gz"
    t2_file = org_path / f"{subject_id}_T2w.nii.gz"

    # Check whether both input files exist.
    if not t1_file.exists() or not t2_file.exists():
        print(f"Input files not found for ID: {subject_id}")
        continue

    # Build the CHARM command using relative paths from the subject directory.
    command = [
        "charm",
        subject_id,
        f"org/{subject_id}_T1w.nii.gz",
        f"org/{subject_id}_T2w.nii.gz",
        "--forceqform",
    ]

    print(f"Processing ID: {subject_id}")

    try:
        # Run the command inside the current subject folder.
        subprocess.run(command, cwd=subject_dir, check=True)
        print(f"Successfully processed ID: {subject_id}")
    except subprocess.CalledProcessError as e:
        print(f"Error processing ID {subject_id}: {e}")
