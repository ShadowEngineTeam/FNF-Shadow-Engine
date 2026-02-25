import os
import subprocess
import argparse
import shutil
import sys
from PIL import Image
import numpy as np

temp_output = "temp_dds"
temp_premult = "temp_premult"

def get_compressonator_path():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    exe_name = "compressonatorcli.exe" if os.name == "nt" else "compressonatorcli"
    compressonator_path = os.path.join(script_dir, "compressonatorcli", exe_name)
    if not os.path.isfile(compressonator_path):
        print("Error: '{exe_name}' not found. Please install it from https://github.com/GPUOpen-Tools/compressonator/releases")
        sys.exit(1)

    return compressonator_path

def premultiply_alpha(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    arr = np.array(img).astype("float32")

    alpha = arr[:, :, 3:4] / 255.0
    arr[:, :, :3] *= alpha

    arr = np.clip(arr, 0, 255).astype("uint8")
    Image.fromarray(arr, "RGBA").save(output_path)

def run_command(command):
    try:
        if os.name != "nt":
            command = ["bash", "-c", " ".join(command)]
        subprocess.run(command, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error running command: {e}")

def parse_args():
    parser = argparse.ArgumentParser(
        description="Compress PNG images using Compressonator BC7 with premultiplied alpha."
    )
    parser.add_argument('-i', '--input', required=True, help="Input folder containing PNG images.")
    parser.add_argument('-o', '--output', required=True, help="Output folder for DDS compressed images.")
    return parser.parse_args()

def main():
    args = parse_args()
    input_folder = args.input
    output_folder = args.output

    if not os.path.isdir(input_folder):
        print(f"The input folder '{input_folder}' does not exist.")
        return

    os.makedirs(output_folder, exist_ok=True)
    os.makedirs(temp_output, exist_ok=True)
    os.makedirs(temp_premult, exist_ok=True)

    compressonator_tool = get_compressonator_path()

    for root, dirs, files in os.walk(input_folder):
        for file in files:
            if file.lower().endswith(".png"):
                input_path = os.path.join(root, file)

                rel_path = os.path.relpath(root, input_folder)
                output_dir = os.path.join(output_folder, rel_path)
                os.makedirs(output_dir, exist_ok=True)

                premult_path = os.path.join(temp_premult, file)
                premultiply_alpha(input_path, premult_path)

                final_dds_path = os.path.join(
                    output_dir,
                    os.path.splitext(file)[0] + ".dds"
                )

                temp_dds_path = os.path.join(
                    temp_output,
                    os.path.splitext(file)[0] + ".dds"
                )

                command = [
                    compressonator_tool,
                    "-fd", "BC7",
                    "-miplevels", "1",
                    premult_path,
                    temp_dds_path
                ]

                run_command(command)

                if os.path.exists(temp_dds_path):
                    shutil.move(temp_dds_path, final_dds_path)
                else:
                    print(f"Warning: output DDS not found for {file}")

    try:
        if os.path.exists(temp_output):
            shutil.rmtree(temp_output)
        if os.path.exists(temp_premult):
            shutil.rmtree(temp_premult)
    except Exception as e:
        print(f"Could not remove temp folders: {e}")

    print("Processing complete.")

if __name__ == "__main__":
    main()
