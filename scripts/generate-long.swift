// SPDX-License-Identifier: MIT
import Foundation
import CoreGraphics
import CoreText
import ImageIO

let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let output = root.appendingPathComponent("images", isDirectory: true)
let fontURL = root.appendingPathComponent("fonts/NotoSansCJKsc-Regular.otf")
let fontProvider = CGDataProvider(url: fontURL as CFURL)!
let sourceFont = CGFont(fontProvider)!
precondition(sourceFont.postScriptName as String? == "NotoSansCJKsc-Regular", "Unexpected font")
let width = 1080, height = 24000, page = 2400
func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor {
    CGColor(srgbRed: r, green: g, blue: b, alpha: 1)
}
let ink = rgb(0.08, 0.12, 0.18)
func canvas(_ w: Int, _ h: Int) -> CGContext {
    let c = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.translateBy(x: 0, y: CGFloat(h)); c.scaleBy(x: 1, y: -1)
    return c
}
func box(_ c: CGContext, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: CGColor) {
    c.setFillColor(color); c.fill(CGRect(x: x, y: y, width: w, height: h))
}
func text(_ c: CGContext, _ value: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat = 36, _ color: CGColor = ink) {
    c.saveGState(); c.translateBy(x: x, y: y + size); c.scaleBy(x: 1, y: -1)
    let font = CTFontCreateWithGraphicsFont(sourceFont, size, nil, nil)
    let characters = Array(value.utf16)
    var glyphs = [CGGlyph](repeating: 0, count: characters.count)
    precondition(CTFontGetGlyphsForCharacters(font, characters, &glyphs, characters.count), "Font lacks glyphs: \(value)")
    let attrs: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): color
    ]
    c.textPosition = .zero
    CTLineDraw(CTLineCreateWithAttributedString(NSAttributedString(string: value, attributes: attrs)), c)
    c.restoreGState()
}
func save(_ image: CGImage, _ name: String, png: Bool) {
    let target = CGImageDestinationCreateWithURL(output.appendingPathComponent(name) as CFURL,
        (png ? "public.png" : "public.jpeg") as CFString, 1, nil)!
    CGImageDestinationAddImage(target, image, [kCGImageDestinationLossyCompressionQuality: 0.97] as CFDictionary)
    precondition(CGImageDestinationFinalize(target))
}

struct LongSpec: Decodable {
    let id: Int
    let filename: String
    let width: Int
    let height: Int
}
let specs = try JSONDecoder().decode([LongSpec].self, from: Data(contentsOf: root.appendingPathComponent("cases.json")))
let titles = ["长图文字阅读测试", "长图清晰度与网格测试", "长图色彩与位置测试", "长图连续画面测试"]

for spec in specs where (1...4).contains(spec.id) {
    precondition(spec.width == width && spec.height == height, "PT001–004 use a fixed 1080x24000 layout")
    let kind = spec.id - 1
    autoreleasepool {
        let c = canvas(width, height)
        for p in 0..<10 {
            let y = CGFloat(p * page)
            let colors = [rgb(0.94,0.97,0.94),rgb(0.93,0.96,1),rgb(1,0.95,0.90),rgb(0.97,0.94,1)]
            box(c, 0, y, 1080, 2400, colors[(p + kind) % 4])
            box(c, 0, y, 1080, 160, ink)
            text(c, String(format: "%02d / 10", p + 1), 44, y + 32, 56, rgb(1,1,1))
            text(c, "Y = \(p * page) px", 620, y + 54, 32, rgb(0.78,0.86,0.96))
            text(c, titles[kind], 48, y + 205, 52)
            text(c, "1080 × 24000 px  |  手机长边 × 10", 48, y + 285, 30)
            if kind == 0 {
                let sizes: [CGFloat] = [16, 24, 32, 48, 64]
                var ty = y + 400
                for size in sizes {
                    let sample = size >= 48 ? "\(Int(size)) px 清晰度 Aa 012345" : "\(Int(size)) px  文字清晰度 AaBb 0123456789"
                    text(c, sample, 48, ty, size)
                    ty += size + 54
                }
                let lines = ["这是一张用于测试照片浏览体验的长图。", "放大以后，观察文字边缘是否仍然清楚。", "上下移动时，检查是否有空白、跳动或裁切。", "每一段都带有序号，可以核对当前的位置。", "到达最后一段时，请确认底部的 END 标记。"]
                for row in 0..<14 {
                    text(c, lines[row % lines.count], 48, y + 1110 + CGFloat(row * 67), 35)
                }
                for i in 0..<6 { box(c, 48, y + 2150 + CGFloat(i * 18), 984, CGFloat(i + 1), ink) }
            } else if kind == 1 {
                text(c, "原始像素标尺：1 / 2 / 4 / 8 px", 48, y + 385, 32)
                for (index, step) in [1,2,4,8].enumerated() {
                    let top = y + 455 + CGFloat(index * 300)
                    text(c, "\(step) px 条纹", 48, top, 28)
                    box(c, 48, top + 60, 984, 180, rgb(1,1,1))
                    for x in stride(from: 48, to: 1032, by: step * 2) {
                        box(c, CGFloat(x), top + 60, CGFloat(step), 180, ink)
                    }
                }
                for gy in 0..<10 {
                    for gx in 0..<24 {
                        box(c, 48 + CGFloat(gx * 41), y + 1710 + CGFloat(gy * 41), 41, 41,
                            (gx + gy) % 2 == 0 ? ink : rgb(1,1,1))
                    }
                }
                text(c, "16 px: ABCDEFG abcdefg 0123456789", 48, y + 2180, 16)
                text(c, "32 px: 细节检查 / DETAIL CHECK", 48, y + 2240, 32)
            } else if kind == 2 {
                let palette = [rgb(0.98,0.27,0.27),rgb(1,0.65,0.17),rgb(0.96,0.84,0.20),rgb(0.20,0.68,0.45),rgb(0.15,0.55,0.94),rgb(0.55,0.35,0.85)]
                for i in 0..<6 {
                    let top = y + 410 + CGFloat(i * 260)
                    box(c, 0, top, 1080, 240, palette[(i+p)%6])
                    text(c, "\(p+1).\(i+1)  COLOR / 色块位置", 48, top + 70, 45, rgb(1,1,1))
                }
                for i in 0..<1080 {
                    let gray = CGFloat(i)/1079
                    box(c, CGFloat(i), y + 2040, 1, 180, rgb(gray,gray,gray))
                }
                text(c, "左黑 → 右白 / GRAYSCALE", 48, y + 2245, 34)
            } else {
                for tile in 0..<3 {
                    let top = y + 400 + CGFloat(tile * 605)
                    let hue = CGFloat((p + tile) % 10) / 10
                    box(c, 48, top, 984, 555, rgb(0.18 + hue * 0.3, 0.4 + hue * 0.3, 0.72))
                    c.setFillColor(rgb(1,0.84,0.46))
                    c.fillEllipse(in: CGRect(x: 735 - tile * 110, y: Int(top) + 50, width: 160, height: 160))
                    for layer in 0..<3 {
                        c.beginPath(); c.move(to: CGPoint(x: 48,y: top+555))
                        c.addLine(to: CGPoint(x: 48,y: top + CGFloat(250 + layer * 65)))
                        c.addLine(to: CGPoint(x: CGFloat(300 + layer * 170),y: top + CGFloat(130 + layer * 80)))
                        c.addLine(to: CGPoint(x: CGFloat(680 + layer * 50),y: top + CGFloat(310 + layer * 45)))
                        c.addLine(to: CGPoint(x: 1032,y: top + CGFloat(170 + layer * 90)))
                        c.addLine(to: CGPoint(x: 1032,y: top+555)); c.closePath()
                        c.setFillColor(rgb(0.12 + CGFloat(layer)*0.06,0.25 + CGFloat(layer)*0.12,0.3 + CGFloat(layer)*0.05));c.fillPath()
                    }
                    text(c, String(format: "FRAME %02d / 30", p * 3 + tile + 1), 80, top + 480, 32, rgb(1,1,1))
                }
            }
            // Edge rulers expose horizontal clipping and provide exact vertical positions.
            for mark in 0..<24 {
                box(c, 0, y + CGFloat(mark * 100), mark % 5 == 0 ? 28 : 12, 2, rgb(0.94,0.17,0.34))
                box(c, 1068, y + CGFloat(mark * 100), 12, 2, rgb(0.94,0.17,0.34))
            }
            text(c, p == 9 ? "END / 已到最底部 / Y = 23999 px" : "继续向下 / NEXT SECTION ↓", 48, y + 2310, 38)
        }
        let image = c.makeImage()!
        save(image, spec.filename, png: spec.filename.hasSuffix(".png"))
        print("Created \(spec.filename): \(image.width) × \(image.height)")
    }
}
