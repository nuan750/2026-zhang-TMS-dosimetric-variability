import csv
from pathlib import Path
from simnibs import sim_struct, run_simnibs

# A very large value used here to define the coil y-direction.
# Replace this with a more explicit anatomical or electrode reference if needed.
HUGE_FLOAT = 1e100

# Replace this with your local CHARM directory before running the script.
# Example: Path("/path/to/charm/hcp")
charm_path = Path("path/to/charm/hcp")

# Relative path to the coil model file.
# Update this if your coil file is stored elsewhere.
coil_file = Path("Drakaki_BrainStim_2022") / "MagVenture_Cool-B65.ccd"

# Output directory for simulation results.
output_root = Path("simulation_outputs")


def get_coords(subject_path):
    """
    Read C3 and F3 coordinates from the subject-specific EEG position file.

    Parameters
    ----------
    subject_path : Path
        Path to the subject's m2m directory.

    Returns
    -------
    tuple
        ((c3_x, c3_y, c3_z), (f3_x, f3_y, f3_z))
    """
    csv_file = subject_path / "eeg_positions" / "EEG10-10_UI_jurak_2007.csv"

    with csv_file.open(newline="") as csvfile:
        reader = csv.reader(csvfile)
        rows = list(reader)

        # C3 coordinates (row 34, index 33)
        c3_x = float(rows[33][1])
        c3_y = float(rows[33][2])
        c3_z = float(rows[33][3])

        # F3 coordinates (row 12, index 11)
        f3_x = float(rows[11][1])
        f3_y = float(rows[11][2])
        f3_z = float(rows[11][3])

    return (c3_x, c3_y, c3_z), (f3_x, f3_y, f3_z)


# Create the output directory if it does not already exist.
output_root.mkdir(exist_ok=True)

# Automatically detect subject folders inside the CHARM directory.
subjects = [folder.name for folder in charm_path.iterdir() if folder.is_dir()]

# Run one TMS session per subject.
for sub in subjects:
    print(f"Running simulation for subject: {sub}")

    # Initialize a new SimNIBS session for the current subject.
    s = sim_struct.SESSION()
    s.map_to_surf = True
    s.map_to_fsavg = True
    s.map_to_vol = True
    s.map_to_MNI = True
    s.fields = "eEjJ"

    # Path to the subject-specific head model directory.
    s.subpath = str(charm_path / sub / f"m2m_{sub}")

    # Subject-specific output directory.
    s.pathfem = str(output_root / sub)
    s.open_in_gmsh = False

    # Create a TMS simulation list and assign the coil model.
    tmslist = s.add_tmslist()
    tmslist.fnamecoil = str(coil_file)

    # Read C3 and F3 coordinates from the EEG file.
    (c3_x, c3_y, c3_z), (f3_x, f3_y, f3_z) = get_coords(Path(s.subpath))

    # Add TMS position at C3.
    pos_c3 = tmslist.add_position()
    pos_c3.centre = [c3_x, c3_y, c3_z]
    pos_c3.pos_ydir = [HUGE_FLOAT, HUGE_FLOAT, 0.0]
    pos_c3.didt = 75e6

    # Add TMS position at F3.
    pos_f3 = tmslist.add_position()
    pos_f3.centre = [f3_x, f3_y, f3_z]
    pos_f3.pos_ydir = [HUGE_FLOAT, HUGE_FLOAT, 0.0]
    pos_f3.didt = 89e6

    # Run the simulation for the current subject.
    run_simnibs(s)

    print(f"Finished simulation for subject: {sub}")
