import os

# Use your specific directory
target_directory = "/home/tanishq/Documents/app_2/lib"

# Output text file
output_file = "all_dart_code.txt"

with open(output_file, 'w', encoding='utf-8') as out_file:
    for folder, _, files in os.walk(target_directory):
        for file in files:
            if file.endswith(".dart"):
                file_path = os.path.join(folder, file)
                out_file.write(f"=== Directory: {folder} ===\n")
                out_file.write(f"--- File: {file} ---\n")
                try:
                    with open(file_path, 'r', encoding='utf-8') as dart_file:
                        out_file.write(dart_file.read())
                except Exception as e:
                    out_file.write(f"[Error reading file: {e}]\n")
                out_file.write("\n\n")

print(f"✅ All .dart code from {target_directory} written to {output_file}")
