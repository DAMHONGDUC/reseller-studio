"""Draws the sample bottles in this folder: a bottle with a scannable label.

Run from the repo root after changing a bottle in `sample_bottles.dart`:

    python3 test/support/fixtures/sample_bottles/generate.py

`sample_bottles_test.dart` decodes every label's bars back to digits, so a
label that drifts from the fixture fails a test rather than a scan.
"""

from pathlib import Path

BOTTLES = [
    ("perfume", "Santal 33 eau de parfum", "50 ml", "5901234123457"),
    ("flask", "Hydro Flask wide mouth", "32 oz", "036000291452"),
    ("cola", "Coca-Cola glass bottle", "1960s", "96385074"),
    ("water", "Unlisted water bottle", "750 ml", "4006381333931"),
]

L = ["0001101", "0011001", "0010011", "0111101", "0100011",
     "0110001", "0101111", "0111011", "0110111", "0001011"]
R = ["".join("1" if b == "0" else "0" for b in code) for code in L]
G = [code[::-1] for code in R]
PARITY = ["LLLLLL", "LLGLGG", "LLGGLG", "LLGGGL", "LGLLGG",
          "LGGLLG", "LGGGLL", "GLLLGG", "GLGLLG", "GGLLLG"]

MODULE = 3
BAR_HEIGHT = 96
QUIET = 11


def modules(digits: str) -> str:
    """The 95 (EAN-13 / UPC-A) or 67 (EAN-8) modules of a code."""
    if len(digits) == 12:
        digits = "0" + digits
    if len(digits) == 13:
        parity = PARITY[int(digits[0])]
        left = "".join(
            (L if parity[i] == "L" else G)[int(d)] for i, d in enumerate(digits[1:7])
        )
        right = "".join(R[int(d)] for d in digits[7:])
        return "101" + left + "01010" + right + "101"
    if len(digits) == 8:
        left = "".join(L[int(d)] for d in digits[:4])
        right = "".join(R[int(d)] for d in digits[4:])
        return "101" + left + "01010" + right + "101"
    raise ValueError(digits)


def svg(name: str, size: str, digits: str) -> str:
    bits = modules(digits)
    code_width = (len(bits) + 2 * QUIET) * MODULE
    label_w = code_width + 24
    width = label_w + 120
    cx = width / 2
    label_x = (width - label_w) / 2
    origin = label_x + 12 + QUIET * MODULE

    rects = []
    i = 0
    while i < len(bits):
        if bits[i] == "1":
            j = i
            while j < len(bits) and bits[j] == "1":
                j += 1
            rects.append(
                f'<rect x="{origin + i * MODULE}" y="300" '
                f'width="{(j - i) * MODULE}" height="{BAR_HEIGHT}"/>'
            )
            i = j
        else:
            i += 1

    body_x = label_x - 30
    body_w = label_w + 60
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="560" viewBox="0 0 {width} 560">
  <rect width="{width}" height="560" fill="#eef1f5"/>
  <rect x="{cx - 34}" y="20" width="68" height="46" rx="8" fill="#2f3542"/>
  <rect x="{cx - 26}" y="62" width="52" height="58" fill="#c8d6e5"/>
  <path d="M{cx - 26} 120 C{cx - 26} 160 {body_x} 170 {body_x} 210 L{body_x} 520 Q{body_x} 545 {body_x + 25} 545 L{body_x + body_w - 25} 545 Q{body_x + body_w} 545 {body_x + body_w} 520 L{body_x + body_w} 210 C{body_x + body_w} 170 {cx + 26} 160 {cx + 26} 120 Z" fill="#c8d6e5" stroke="#8395a7" stroke-width="3"/>
  <rect x="{label_x}" y="220" width="{label_w}" height="250" rx="10" fill="#ffffff"/>
  <text x="{cx}" y="256" font-family="Helvetica, Arial, sans-serif" font-size="20" font-weight="700" text-anchor="middle" fill="#222f3e">{name}</text>
  <text x="{cx}" y="284" font-family="Helvetica, Arial, sans-serif" font-size="16" text-anchor="middle" fill="#576574">{size}</text>
  <g id="barcode" fill="#000000" data-origin="{origin}" data-module="{MODULE}" data-modules="{len(bits)}">
    {chr(10).join("    " + r for r in rects).strip()}
  </g>
  <text x="{cx}" y="424" font-family="Menlo, Courier, monospace" font-size="20" text-anchor="middle" fill="#000000">{digits}</text>
</svg>
"""


if __name__ == "__main__":
    here = Path(__file__).parent
    for slug, name, size, digits in BOTTLES:
        (here / f"{slug}.svg").write_text(svg(name, size, digits))
