#!/usr/bin/env python3
import base64

# Minimal 1x1 pixel PNG image in base64
png_data = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChAI9jU77zgAAAABJRU5ErkJggg=="

# Decode and save as PNG file
with open("test-image.png", "wb") as f:
    f.write(base64.b64decode(png_data))

print("Created test-image.png")
