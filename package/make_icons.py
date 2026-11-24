#!/usr/bin/env python3
"""Generate Djehuty's icons from the Egyptian hieroglyph font.

  resources/DjehutyIcon.icns  app icon: gold ibis sign on a lapis-blue rounded square
  resources/djehuty.pdf       input-menu icon: black vector outline of the same sign

Requirements (for regenerating only; the outputs are committed):
  pip3 install fonttools pillow

Usage: make_icons.py <font.ttf> [sign=G026] [project_root]
"""
import io
import pathlib
import struct
import sys

from fontTools.pens.basePen import BasePen
from fontTools.pens.boundsPen import BoundsPen
from fontTools.ttLib import TTFont
from PIL import Image, ImageDraw, ImageFilter, ImageFont

STROKE_FILTER = 3  # odd size; 7 was too heavy

GARDINER_CODEPOINTS = {"G025": 0x1315C, "G026": 0x1315D}  # the Unicode hieroglyph names


def glyph_name(font, codepoint):
    cmap = font.getBestCmap()
    if codepoint not in cmap:
        sys.exit(f"font has no glyph for U+{codepoint:X}")
    return cmap[codepoint]


def make_app_icon(font_path, codepoint, out_path, size=1024):
    radius = int(size * 0.22)
    base = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    # background: vertical lapis-blue gradient in a rounded square
    grad = Image.new("RGBA", (size, size))
    gd = ImageDraw.Draw(grad)
    top, bottom = (28, 62, 130), (9, 22, 52)
    for y in range(size):
        t = y / (size - 1)
        col = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,)
        gd.line([(0, y), (size, y)], fill=col)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    base.paste(grad, (0, 0), mask)
    # gold inset border
    border = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    inset = int(size * 0.035)
    ImageDraw.Draw(border).rounded_rectangle(
        [inset, inset, size - 1 - inset, size - 1 - inset],
        radius=radius - inset, outline=(201, 162, 39, 255), width=int(size * 0.011))
    base = Image.alpha_composite(base, border)

    # the sign: render the glyph, crop to its ink, scale to fit, thicken the strokes
    font = ImageFont.truetype(font_path, 900)
    ink = Image.new("L", (1400, 1400), 0)
    ImageDraw.Draw(ink).text((200, 100), chr(codepoint), font=font, fill=255)
    bbox = ink.getbbox()
    ink = ink.crop(bbox)
    target_h = int(size * 0.62)
    scale = target_h / ink.height
    ink = ink.resize((int(ink.width * scale), target_h), Image.LANCZOS)
    # MaxFilter(size) thickens strokes; keep it small so the sign stays fine-lined
    ink = ink.point(lambda v: 255 if v > 96 else 0).filter(ImageFilter.MaxFilter(STROKE_FILTER))
    x = (size - ink.width) // 2
    y = (size - ink.height) // 2 - int(size * 0.01)

    # drop shadow, then gold fill with a light-to-dark gradient
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sh = Image.new("L", (size, size), 0)
    sh.paste(ink, (x + 8, y + 14))
    sh = sh.filter(ImageFilter.GaussianBlur(10))
    shadow.paste((0, 0, 0, 150), (0, 0), sh)
    base = Image.alpha_composite(base, shadow)

    gold = Image.new("RGBA", (ink.width, ink.height))
    gg = ImageDraw.Draw(gold)
    hi, lo = (255, 226, 130), (196, 140, 40)
    for yy in range(ink.height):
        t = yy / max(1, ink.height - 1)
        col = tuple(int(hi[i] + (lo[i] - hi[i]) * t) for i in range(3)) + (255,)
        gg.line([(0, yy), (ink.width, yy)], fill=col)
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    layer.paste(gold, (x, y), ink)
    base = Image.alpha_composite(base, layer)
    base.save(out_path)
    return base


def write_icns(master, out_path):
    chunks = {b"ic07": 128, b"ic08": 256, b"ic09": 512, b"ic10": 1024,
              b"ic11": 32, b"ic12": 64, b"ic13": 256, b"ic14": 512}
    body = b""
    for tag, px in chunks.items():
        buf = io.BytesIO()
        master.resize((px, px), Image.LANCZOS).save(buf, format="PNG")
        data = buf.getvalue()
        body += tag + struct.pack(">I", 8 + len(data)) + data
    out_path.write_bytes(b"icns" + struct.pack(">I", 8 + len(body)) + body)


class PdfPen(BasePen):
    """Collects glyph outlines as PDF path operators (quadratics converted to cubics)."""

    def __init__(self, glyph_set, transform):
        super().__init__(glyph_set)
        self.ops = []
        self.transform = transform
        self.last = (0, 0)

    def _pt(self, p):
        x, y = self.transform(p)
        return f"{x:.3f} {y:.3f}"

    def _moveTo(self, p):
        self.ops.append(f"{self._pt(p)} m")
        self.last = p

    def _lineTo(self, p):
        self.ops.append(f"{self._pt(p)} l")
        self.last = p

    def _curveToOne(self, p1, p2, p3):
        self.ops.append(f"{self._pt(p1)} {self._pt(p2)} {self._pt(p3)} c")
        self.last = p3

    def _qCurveToOne(self, p1, p2):
        l = self.last
        c1 = (l[0] + 2 / 3 * (p1[0] - l[0]), l[1] + 2 / 3 * (p1[1] - l[1]))
        c2 = (p2[0] + 2 / 3 * (p1[0] - p2[0]), p2[1] + 2 / 3 * (p1[1] - p2[1]))
        self.ops.append(f"{self._pt(c1)} {self._pt(c2)} {self._pt(p2)} c")
        self.last = p2

    def _closePath(self):
        self.ops.append("h")

    def _endPath(self):
        pass


def make_menu_pdf(font, gname, out_path, height=16.0):
    """Menu-bar icon: the sign alone, scaled to `height` points, with a page exactly its size.

    No margin: macOS scales the whole PDF page to the menu row, so padding makes the sign
    look small and sit off-centre.
    """
    glyph_set = font.getGlyphSet()
    bounds = BoundsPen(glyph_set)
    glyph_set[gname].draw(bounds)
    x0, y0, x1, y1 = bounds.bounds
    scale = height / (y1 - y0)
    width = (x1 - x0) * scale
    pen = PdfPen(glyph_set, lambda p: ((p[0] - x0) * scale, (p[1] - y0) * scale))
    glyph_set[gname].draw(pen)
    content = "0 g\n" + "\n".join(pen.ops) + "\nf\n"
    stream = content.encode("ascii")
    objects = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        f"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 {width:.3f} {height:g}] /Contents 4 0 R >>".encode(),
        b"<< /Length " + str(len(stream)).encode() + b" >>\nstream\n" + stream + b"endstream",
    ]
    out = bytearray(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n")
    offsets = []
    for i, obj in enumerate(objects, 1):
        offsets.append(len(out))
        out += f"{i} 0 obj\n".encode() + obj + b"\nendobj\n"
    xref = len(out)
    out += f"xref\n0 {len(objects) + 1}\n0000000000 65535 f \n".encode()
    for off in offsets:
        out += f"{off:010d} 00000 n \n".encode()
    out += f"trailer\n<< /Size {len(objects) + 1} /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF\n".encode()
    out_path.write_bytes(bytes(out))


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    font_path = sys.argv[1]
    sign = sys.argv[2] if len(sys.argv) > 2 else "G026"
    root = pathlib.Path(sys.argv[3]).resolve() if len(sys.argv) > 3 else pathlib.Path(__file__).resolve().parent.parent
    codepoint = GARDINER_CODEPOINTS[sign]
    res = root / "resources"
    font = TTFont(font_path, lazy=True)
    gname = glyph_name(font, codepoint)
    master = make_app_icon(font_path, codepoint, res / "DjehutyIcon-1024.png")
    write_icns(master, res / "DjehutyIcon.icns")
    make_menu_pdf(font, gname, res / "djehuty.pdf")
    print(f"sign {sign} (U+{codepoint:X}, glyph {gname}) -> DjehutyIcon.icns, djehuty.pdf")


if __name__ == "__main__":
    main()
