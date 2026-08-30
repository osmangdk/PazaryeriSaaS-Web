import os
from PIL import Image, ImageDraw, ImageFont

img_path = 'assets/images/roatech_logo.jpg'
img = Image.open(img_path).convert('RGB')
width, height = img.size
print(f"Original size: {width}x{height}")

# Let's find background color in subtitle region:
# Subtitle is roughly at x in [410, 900], y in [335, 380]
# Let's paint the background over "Marketplace Integration & API"
# We can sample horizontal gradient from (x, y-10) or (x, y+40)
for y in range(330, 385):
    for x in range(400, 950):
        # Sample background from slightly below or above
        sample_y = 390
        color = img.getpixel((x, sample_y))
        img.putpixel((x, y), color)

# Now draw Turkish text: "Pazaryeri Entegrasyon & API"
draw = ImageDraw.Draw(img)
font_path = "C:/Windows/Fonts/segoeui.ttf"
if not os.path.exists(font_path):
    font_path = "C:/Windows/Fonts/arial.ttf"

font = ImageFont.truetype(font_path, 29)
# Text color in original logo is dark slate blue/grey ~ (70, 85, 105)
text_color = (65, 80, 100)
draw.text((412, 338), "Pazaryeri Entegrasyon & API", fill=text_color, font=font)

# Save Turkish version
img.save('assets/images/roatech_logo_tr.png', quality=95)
img.save('public/assets/images/roatech_logo_tr.png', quality=95)
print("Saved roatech_logo_tr.png")

# Extract the emblem for transparent icon/favicon
# Let's crop emblem:
emblem = img.crop((120, 135, 400, 440))
# Let's make background transparent for the emblem:
emblem_rgba = emblem.convert('RGBA')
datas = emblem_rgba.getdata()
new_data = []
for item in datas:
    # If pixel is near white/light grey (r>230, g>235, b>240)
    if item[0] > 230 and item[1] > 232 and item[2] > 235:
        new_data.append((255, 255, 255, 0))
    else:
        new_data.append(item)
emblem_rgba.putdata(new_data)

emblem_rgba.save('assets/images/roatech_emblem.png')
emblem_rgba.save('public/assets/images/roatech_emblem.png')

# Save favicons and app icons:
favicon_32 = emblem_rgba.resize((32, 32), Image.Resampling.LANCZOS)
favicon_32.save('web/favicon.png')
favicon_32.save('public/favicon.png')

icon_192 = emblem_rgba.resize((192, 192), Image.Resampling.LANCZOS)
icon_192.save('web/icons/Icon-192.png')
icon_192.save('public/icons/Icon-192.png')

icon_512 = emblem_rgba.resize((512, 512), Image.Resampling.LANCZOS)
icon_512.save('web/icons/Icon-512.png')
icon_512.save('public/icons/Icon-512.png')

print("All icons and Turkish logos generated successfully!")
