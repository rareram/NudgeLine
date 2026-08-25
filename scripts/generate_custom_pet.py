#!/usr/bin/env python3
"""
NudgeLine Custom Pet Code Generator
------------------------------------
Encodes custom PNG sequences into a Swift source file
that can be compiled directly into NudgeLine.

Usage:
    python3 generate_custom_pet.py \
        --name "TigerPetAsset" \
        --frames-dir ./my_frames/ \
        --output Sources/NudgeLine/Views/Pets/CustomTigerPetView.swift
"""

import os
import sys
import base64
import argparse
from pathlib import Path

def main():
    parser = argparse.ArgumentParser(description="Convert PNG frames to Swift Code")
    parser.add_argument("--input", "-i", required=True, help="Path to folder containing frame_0.png, frame_1.png...")
    parser.add_argument("--name", "-n", required=True, help="Name of the Swift struct (e.g. MyCatPetView)")
    parser.add_argument("--output", "-o", default=None, help="Output Swift file path")
    parser.add_argument("--fps", type=float, default=8.0, help="Frames per second (default: 8.0)")

    args = parser.parse_args()

    input_dir = Path(args.input)
    if not input_dir.exists() or not input_dir.is_dir():
        print(f"❌ Error: Input directory '{input_dir}' not found.")
        sys.exit(1)

    # Collect png files sorted naturally
    png_files = sorted(list(input_dir.glob("*.png")), key=lambda p: p.name)
    if not png_files:
        print(f"Error: No .png files found in '{input_dir}'.")
        sys.exit(1)

    struct_name = args.name
    output_file = Path(args.output) if args.output else Path(f"Sources/NudgeLine/Views/Pets/{struct_name}.swift")

    print(f"Found {len(png_files)} frames in '{input_dir}'")
    print(f"Generating Swift file '{output_file}' for struct '{struct_name}'...")

    frame_base64_list = []
    for p in png_files:
        with open(p, "rb") as f:
            b64 = base64.b64encode(f.read()).decode("utf-8")
            frame_base64_list.append(b64)

    # Generate Swift Code
    interval = 1.0 / args.fps
    swift_code = f"""import SwiftUI
import AppKit

// MARK: - Auto-Generated Custom Pet View: {struct_name}
// Generated with generate_custom_pet.py ({len(png_files)} frames @ {args.fps} FPS)
public struct {struct_name}: View {{
    public let isHorizontal: Bool
    public let isRightEdge: Bool
    public let accentColor: Color

    public init(isHorizontal: Bool = false, isRightEdge: Bool = false, accentColor: Color = .red) {{
        self.isHorizontal = isHorizontal
        self.isRightEdge = isRightEdge
        self.accentColor = accentColor
    }}

    private static let frames: [NSImage] = {{
        let base64Strings = [
"""

    for i, b64 in enumerate(frame_base64_list):
        swift_code += f'            "{b64}", // Frame {i}\n'

    swift_code += f"""        ]
        return base64Strings.compactMap {{ str in
            guard let data = Data(base64Encoded: str) else {{ return nil }}
            return NSImage(data: data)
        }}
    }}()

    public var body: some View {{
        TimelineView(.periodic(from: .now, by: {interval:.3f})) {{ context in
            let frameCount = max(1, Self.frames.count)
            let frameIndex = Int(context.date.timeIntervalSince1970 * {args.fps}) % frameCount

            if let nsImage = Self.frames[safe: frameIndex] {{
                Image(nsImage: nsImage)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .scaleEffect(x: (!isHorizontal && isRightEdge) ? -1.0 : 1.0, y: 1.0)
            }} else {{
                Circle()
                    .fill(accentColor)
                    .frame(width: 8, height: 8)
            }}
        }}
    }}
}}

private extension Array {{
    subscript(safe index: Index) -> Element? {{
        indices.contains(index) ? self[index] : nil
    }}
}}
"""

    output_file.parent.mkdir(parents=True, exist_ok=True)
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(swift_code)

    print(f"✨ Successfully created '{output_file}'!")
    print(f"💡 You can now use '{struct_name}()' anywhere in your SwiftUI code.")

if __name__ == "__main__":
    main()
