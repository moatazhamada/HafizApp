import os
from PIL import Image, ImageEnhance
import sys

def tint_image(src_path, dest_path):
    print(f"Processing {src_path} -> {dest_path}")
    try:
        img = Image.open(src_path).convert("RGBA")
        r, g, b, a = img.split()
        
        # Simple golden tint: increase red and green, decrease blue
        # This gives a nice warm Ramadani feel
        r = r.point(lambda i: min(255, int(i * 1.15)))
        g = g.point(lambda i: min(255, int(i * 1.10)))
        b = b.point(lambda i: int(i * 0.85))
        
        out = Image.merge("RGBA", (r, g, b, a))
        
        # Increase contrast slightly
        enhancer = ImageEnhance.Contrast(out)
        out = enhancer.enhance(1.2)
        
        out.save(dest_path)
    except Exception as e:
        print(f"Error processing {src_path}: {e}")

def main():
    res_dir = "android/app/src/main/res"
    if not os.path.exists(res_dir):
        print("res dir not found!")
        return
        
    for root, dirs, files in os.walk(res_dir):
        if "mipmap-" in root:
            for file in files:
                if file in ["ic_launcher.png", "round_launcher.png"]:
                    src = os.path.join(root, file)
                    base, ext = os.path.splitext(file)
                    dest = os.path.join(root, f"{base}_ramadan{ext}")
                    tint_image(src, dest)

if __name__ == "__main__":
    main()
