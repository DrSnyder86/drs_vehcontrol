from pathlib import Path
from PIL import Image, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "html" / "img" / "classes"
TARGET_SIZE = (1000, 300)

SOURCES = {
    "class_00_compacts.png": r"C:\Users\drsny\.codex\generated_images\019fb707-d49c-7e81-a01c-b05e3b13ca3f\call_Rav5HOO5mLhgmpJWlKbruP60.png",
    "class_01_sedans.png": r"C:\Users\drsny\.codex\generated_images\019fb707-d49c-7e81-a01c-b05e3b13ca3f\call_6uyPS1YEHsAwf2s2eLbAtg5D.png",
    "class_02_suvs.png": r"C:\Users\drsny\.codex\generated_images\019fb707-d49c-7e81-a01c-b05e3b13ca3f\call_uiTXlNmlkf0sTMui1pBAOq3y.png",
    "class_03_coupes.png": r"C:\Users\drsny\.codex\generated_images\019fb707-d49c-7e81-a01c-b05e3b13ca3f\call_xNtBSxR41FrCg0BPFiIFJL5b.png",
    "class_04_muscle.png": r"C:\Users\drsny\.codex\generated_images\019fb707-d49c-7e81-a01c-b05e3b13ca3f\call_i5VjoDC0tQCpWedfX6APhcbr.png",
    "class_05_sports_classics.png": r"C:\Users\drsny\.codex\generated_images\019fb707-d49c-7e81-a01c-b05e3b13ca3f\call_ful44Na58YEUnngBI8FkWO75.png",
    "class_06_sports.png": r"C:\Users\drsny\.codex\generated_images\019fb707-d49c-7e81-a01c-b05e3b13ca3f\call_bidTemkXr67XoY812kpW0Hnw.png",
    "class_07_super.png": r"C:\Users\drsny\.codex\generated_images\019fb707-d49c-7e81-a01c-b05e3b13ca3f\call_z8gMEk4IsJCJMtyE79O8dEob.png",
    "class_08_motorcycles.png": r"C:\Users\drsny\.codex\generated_images\019fb707-d49c-7e81-a01c-b05e3b13ca3f\call_hWZGzd6CAEYOdC97WLezxK9S.png",
    "class_09_offroad.png": r"C:\Users\drsny\.codex\generated_images\019fb707-d49c-7e81-a01c-b05e3b13ca3f\call_f6B2F4ACJC6GRnKfpiTL6X2A.png",
    "class_10_industrial.png": r"C:\Users\drsny\.codex\generated_images\019fb707-d49c-7e81-a01c-b05e3b13ca3f\call_VmQQQXjOiC1cG7kgaEHXjxtc.png",
    "class_11_utility.png": r"C:\Users\drsny\.codex\generated_images\019fb707-d49c-7e81-a01c-b05e3b13ca3f\call_ns8zWf5nB5FOBf3U0kBCam20.png",
    "class_12_vans.png": r"C:\Users\drsny\.codex\generated_images\019fb707-d49c-7e81-a01c-b05e3b13ca3f\call_Kmuvynj8EKG27etj9ZrJtrX6.png",
    "class_13_cycles.png": r"C:\Users\drsny\.codex\generated_images\019fb707-d49c-7e81-a01c-b05e3b13ca3f\call_f8JFl5jd4ouSzkOasJl9V1yf.png",
    "class_14_boats.png": r"C:\Users\drsny\.codex\generated_images\019fb707-d49c-7e81-a01c-b05e3b13ca3f\call_mzNuEvELsLjR70GTuQPbulmy.png",
    "class_15_helicopters.png": r"C:\Users\drsny\.codex\generated_images\019fb707-d49c-7e81-a01c-b05e3b13ca3f\call_UgsWF6Hh4xZKIHzZ1XzljbrD.png",
    "class_16_planes.png": r"C:\Users\drsny\.codex\generated_images\019fb707-d49c-7e81-a01c-b05e3b13ca3f\call_y8ftcW8SlgQ50mGH33K2xud5.png",
    "class_17_service.png": r"C:\Users\drsny\.codex\generated_images\019fb707-d49c-7e81-a01c-b05e3b13ca3f\call_wnfGuVIRTw42SihjevARiNfL.png",
    "class_18_emergency.png": r"C:\Users\drsny\.codex\generated_images\019fb707-d49c-7e81-a01c-b05e3b13ca3f\call_Y4wEmOQ4efK18R8lGVMcriAa.png",
    "class_19_military.png": r"C:\Users\drsny\.codex\generated_images\019fb707-d49c-7e81-a01c-b05e3b13ca3f\call_RBjBoHuwaOtr6CKU0wJ4qhko.png",
    "class_20_commercial.png": r"C:\Users\drsny\.codex\generated_images\019fb707-d49c-7e81-a01c-b05e3b13ca3f\call_NhYgnRm7i2tTG7b0IHwYhK8W.png",
    "class_21_trains.png": r"C:\Users\drsny\.codex\generated_images\019fb707-d49c-7e81-a01c-b05e3b13ca3f\call_cNZ2I20vKp0RuDeud4mp98EU.png",
    "class_22_open_wheel.png": r"C:\Users\drsny\.codex\generated_images\019fb707-d49c-7e81-a01c-b05e3b13ca3f\call_f4meuf3iDwIKEYjoGUv91VHR.png",
}


def center_crop(image, ratio):
    width, height = image.size
    current = width / height

    if current > ratio:
        new_width = int(height * ratio)
        left = (width - new_width) // 2
        return image.crop((left, 0, left + new_width, height))

    new_height = int(width / ratio)
    top = max(0, (height - new_height) // 2)
    return image.crop((0, top, width, top + new_height))


def add_menu_grade(image):
    image = ImageEnhance.Color(image).enhance(0.88)
    image = ImageEnhance.Contrast(image).enhance(1.08)
    image = ImageEnhance.Brightness(image).enhance(0.8)

    overlay = Image.new("RGBA", image.size, (3, 9, 16, 46))
    image = Image.alpha_composite(image.convert("RGBA"), overlay)

    width, height = image.size
    vignette = Image.new("RGBA", image.size, (0, 0, 0, 0))
    pixels = vignette.load()

    for y in range(height):
        for x in range(width):
            dx = abs((x / width) - 0.56) * 1.55
            dy = abs((y / height) - 0.5) * 1.1
            alpha = int(min(92, max(0, (dx * dx + dy * dy - 0.18) * 135)))
            pixels[x, y] = (0, 0, 0, alpha)

    image = Image.alpha_composite(image, vignette)

    haze = Image.new("RGBA", image.size, (0, 0, 0, 0))
    h = ImageDrawLike(haze)
    h.rectangle((0, 0, int(width * 0.42), height), fill=(2, 10, 18, 96))
    haze = haze.filter(ImageFilter.GaussianBlur(34))
    return Image.alpha_composite(image, haze)


class ImageDrawLike:
    def __init__(self, image):
        from PIL import ImageDraw

        self.draw = ImageDraw.Draw(image)

    def rectangle(self, *args, **kwargs):
        self.draw.rectangle(*args, **kwargs)


def process():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    ratio = TARGET_SIZE[0] / TARGET_SIZE[1]

    for output_name, source in SOURCES.items():
        src = Path(source)
        if not src.exists():
            raise FileNotFoundError(src)

        image = Image.open(src).convert("RGB")
        image = center_crop(image, ratio)
        image = image.resize(TARGET_SIZE, Image.Resampling.LANCZOS)
        image = add_menu_grade(image)
        image.save(OUT_DIR / output_name, optimize=True)
        print(f"wrote html/img/classes/{output_name}")


if __name__ == "__main__":
    process()
