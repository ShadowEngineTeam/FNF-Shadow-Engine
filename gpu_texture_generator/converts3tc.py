import os
import subprocess
import argparse
import shutil
import sys
import requests

temp_output = "temp_dds"
TEXCONV_LINK = "https://github.com/microsoft/DirectXTex/releases/latest/download/texconv.exe"

def download_texconv(dest_path):
    print("texconv.exe not found, attempting download...")
    try:
        response = requests.get(TEXCONV_LINK, stream=True)
        response.raise_for_status()
        with open(dest_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        print("Downloaded texconv.exe successfully.")
    except Exception as e:
        print(f"Failed to download texconv.exe: {e}")
        sys.exit(1)

def get_texconv_path():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    exe_name = "texconv.exe"
    texconv_path = os.path.join(script_dir, exe_name)
    if not os.path.isfile(texconv_path):
        download_texconv(texconv_path)
    return texconv_path

def check_wine():
    if shutil.which("wine") is None:
        print("Error: 'wine' not found on this system. Please install wine to run texconv.exe.")
        sys.exit(1)
    return "wine"

def run_command(command, use_wine=False):
    env = os.environ.copy()
    if use_wine:
        env["WINEDEBUG"] = "-all"
    try:
        subprocess.run(command, check=True, env=env)
    except subprocess.CalledProcessError as e:
        print(f"Error running command: {e}")

def parse_args():
    parser = argparse.ArgumentParser(description="Compress images in a folder using texconv.")
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

    texconv_tool = get_texconv_path()
    if os.name != "nt":
        wine_cmd = check_wine()
    else:
        wine_cmd = None

    for root, dirs, files in os.walk(input_folder):
        for file in files:
            if file.lower().endswith(".png"):
                input_path = os.path.join(root, file)

                rel_path = os.path.relpath(root, input_folder)
                output_dir = os.path.join(output_folder, rel_path)
                os.makedirs(output_dir, exist_ok=True)

                final_dds_path = os.path.join(output_dir, os.path.splitext(file)[0] + ".dds")
                temp_dds_path = os.path.join(temp_output, os.path.splitext(file)[0] + ".dds")

                command = [
                    texconv_tool,
                    "-f", "BC3_UNORM",
                    "-m", "1",
                    "-if", "CUBIC",
                    "-bc", "u",
                    "-srgb",
					"-nologo",
                    "-pmalpha",
                    "-y",
                    "-o", temp_output,
                    input_path
                ]
                if wine_cmd:
                    command = [wine_cmd] + command

                run_command(command, use_wine=bool(wine_cmd))

                if os.path.exists(temp_dds_path):
                    shutil.move(temp_dds_path, final_dds_path)
                else:
                    print(f"Warning: output DDS not found for {file}")

    try:
        if os.path.exists(temp_output):
            shutil.rmtree(temp_output)
    except Exception as e:
        print(f"Could not remove temp folder: {e}")

    print("Processing complete.")

if __name__ == "__main__":
    main()
