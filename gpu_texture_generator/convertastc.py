import os
import subprocess
import argparse
from PIL import Image
import sys
import numpy as np

def get_astcenc_path():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    exe_name = "astcenc.exe" if os.name == "nt" else "astcenc"
    astcenc_path = os.path.join(script_dir, exe_name)
    if not os.path.isfile(astcenc_path):
        print(f"Error: '{exe_name}' not found. Please install it from https://github.com/ARM-software/astc-encoder/releases")
        sys.exit(1)
    return astcenc_path

def run_command(command):
    try:
        subprocess.run(command, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error running command: {e}")

def parse_args():
    parser = argparse.ArgumentParser(description="Compress images in a folder using astcenc.")
    parser.add_argument('-i', '--input', required=True, help="Input folder containing PNG images.")
    parser.add_argument('-o', '--output', required=True, help="Output folder for ASTC compressed images.")
    return parser.parse_args()

def compute_edge_energy(img):
    gray = img.convert("L")
    arr = np.array(gray, dtype=np.int16)
    diff_h = np.abs(np.diff(arr, axis=0))
    diff_v = np.abs(np.diff(arr, axis=1))
    return np.mean(diff_h) + np.mean(diff_v)

def pick_block_size(width, height, edge_energy):
    """Pick ASTC block size based on image dimensions and detail level (edge energy)."""
    max_dim = max(width, height)

    if max_dim <= 64:
        return "4x4"

    if max_dim <= 512:
        return "4x4" if edge_energy > 5 else "6x6"

    if max_dim <= 2048:
        return "6x6" if edge_energy > 10 else "8x8"

    if max_dim <= 8192:
        return "8x8" if edge_energy > 10 else "10x10"

    return "12x12"

def main():
    args = parse_args()
    input_folder = args.input
    output_folder = args.output

    if not os.path.isdir(input_folder):
        print(f"The input folder '{input_folder}' does not exist.")
        return

    os.makedirs(output_folder, exist_ok=True)
    astcenc_tool = get_astcenc_path()

    for root, dirs, files in os.walk(input_folder):
        for file in files:
            if not file.lower().endswith(".png"):
                continue

            input_path = os.path.join(root, file)
            rel_path = os.path.relpath(root, input_folder)
            output_dir = os.path.join(output_folder, rel_path)
            os.makedirs(output_dir, exist_ok=True)
            output_path = os.path.join(output_dir, file.replace(".png", ".astc"))

            with Image.open(input_path) as img:
                width, height = img.size
                edge_energy = compute_edge_energy(img)

            block_size = pick_block_size(width, height, edge_energy)

            command = [
                astcenc_tool,
                "-cl",
                input_path,
                output_path,
                block_size,
                "-verythorough",
                "-silent",
                "-pp-premultiply",
                "-perceptual"
            ]

            print(f"Compressing {file} ({width}x{height}, edge={edge_energy:.2f}) "
                  f"to {output_path} with block size {block_size}...")
            run_command(command)

    print("Processing complete.")

if __name__ == "__main__":
    main()
