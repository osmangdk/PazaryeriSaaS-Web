from PIL import Image
import os

emblem = Image.open('assets/images/roatech_emblem.png')

# Android mipmap dimensions:
sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192
}

res_path = 'android/app/src/main/res'
for folder, size in sizes.items():
    dir_path = os.path.join(res_path, folder)
    if os.path.exists(dir_path):
        resized = emblem.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(os.path.join(dir_path, 'ic_launcher.png'))
        print(f"Updated {folder}/ic_launcher.png ({size}x{size})")

print("Android launcher icons updated successfully!")
