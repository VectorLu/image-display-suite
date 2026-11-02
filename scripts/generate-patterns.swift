// SPDX-License-Identifier: MIT
import Foundation
import CoreGraphics
import CoreText
import ImageIO
import CryptoKit

let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let sourceFont = CGFont(CGDataProvider(url: root.appendingPathComponent("fonts/NotoSansCJKsc-Regular.otf") as CFURL)!)!
precondition(sourceFont.postScriptName as String? == "NotoSansCJKsc-Regular")
func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: r, green: g, blue: b, alpha: a)
}
let ink = rgb(0.07,0.12,0.19)
func canvas(_ w: Int, _ h: Int) -> CGContext {
    let c = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.translateBy(x: 0, y: CGFloat(h)); c.scaleBy(x: 1, y: -1)
    return c
}
func box(_ c: CGContext, _ rect: CGRect, _ color: CGColor) { c.setFillColor(color); c.fill(rect) }
func label(_ c: CGContext, _ value: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, _ maxWidth: CGFloat, _ color: CGColor = ink) {
    var fontSize = size
    func line(_ s: CGFloat) -> CTLine {
        let font = CTFontCreateWithGraphicsFont(sourceFont, s, nil, nil)
        let chars = Array(value.utf16)
        var glyphs = [CGGlyph](repeating: 0, count: chars.count)
        precondition(CTFontGetGlyphsForCharacters(font, chars, &glyphs, chars.count), "Missing glyphs: \(value)")
        return CTLineCreateWithAttributedString(NSAttributedString(string: value, attributes: [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): color]))
    }
    var l = line(fontSize)
    let actual = CGFloat(CTLineGetTypographicBounds(l, nil, nil, nil))
    if actual > maxWidth { fontSize *= maxWidth / actual; l = line(fontSize) }
    c.saveGState();c.translateBy(x: x,y: y+fontSize);c.scaleBy(x: 1,y: -1);c.textPosition = .zero
    CTLineDraw(l,c);c.restoreGState()
}
func save(_ image: CGImage, _ url: URL, png: Bool) {
    let d = CGImageDestinationCreateWithURL(url as CFURL,(png ? "public.png":"public.jpeg") as CFString,1,nil)!
    CGImageDestinationAddImage(d,image,[kCGImageDestinationLossyCompressionQuality:0.97] as CFDictionary)
    precondition(CGImageDestinationFinalize(d))
}
struct Spec: Decodable {
    let id: Int
    let filename: String
    let width: Int
    let height: Int
    let title: String
    let purpose: String
    let ratio: String
    let group: String
}
let specs = try JSONDecoder().decode([Spec].self,from:Data(contentsOf:root.appendingPathComponent("cases.json")))
let infoFont = CTFontCreateWithGraphicsFont(sourceFont,32,nil,nil)
let fontInfo: [String:String] = [
    "postscript_name": CTFontCopyPostScriptName(infoFont) as String,
    "copyright": CTFontCopyName(infoFont,kCTFontCopyrightNameKey) as String? ?? "",
    "version": CTFontCopyName(infoFont,kCTFontVersionNameKey) as String? ?? "",
    "license": CTFontCopyName(infoFont,kCTFontLicenseNameKey) as String? ?? ""
]
try JSONSerialization.data(withJSONObject:fontInfo,options:[.prettyPrinted,.sortedKeys]).write(to:root.appendingPathComponent(".build/font-info.json"))

var pairHashes: [String:String] = [:]
for s in specs where s.id >= 5 {
    autoreleasepool {
        let c = canvas(s.width,s.height)
        let vertical = s.height >= s.width
        let short = CGFloat(min(s.width,s.height)), long = CGFloat(max(s.width,s.height))
        let u = short/1080, padding = 36*u
        let sections = max(1,Int(ceil(long / (short * 2.3))))
        let segment = long / CGFloat(sections)
        let alpha = s.id == 19
        let pair = s.id == 20 || s.id == 21
        for section in 0..<sections {
            let start = CGFloat(section)*segment
            let frame = vertical ? CGRect(x:0,y:start,width:CGFloat(s.width),height:segment)
                : CGRect(x:start,y:0,width:segment,height:CGFloat(s.height))
            c.saveGState();c.clip(to:frame)
            let x = frame.minX, y = frame.minY, w = frame.width, h = frame.height
            if !alpha { box(c,frame,section%2 == 0 ? rgb(0.95,0.97,1):rgb(0.98,0.95,0.90)) }
            let header = CGRect(x:x,y:y,width:w,height:220*u)
            box(c,header,ink)
            let code = pair ? "PT020 / PT021" : String(format:"PT%03d",s.id)
            label(c,"\(code)  |  \(pair ? "格式对照" : s.title)",x+padding,y+24*u,44*u,w-padding*2,rgb(1,1,1))
            label(c,"\(s.width) x \(s.height) px  |  \(s.ratio)",x+padding,y+92*u,30*u,w-padding*2,rgb(0.78,0.86,0.98))
            label(c,"SECTION \(section+1)/\(sections)  |  \(vertical ? "Y":"X") = \(Int(start)) px",x+padding,y+148*u,30*u,w-padding*2,rgb(0.78,0.86,0.98))
            let top = y+260*u
            let available = max(1,h-440*u)
            let band = min(available*0.22,180*u)
            for (index,step) in [1,2,4,8].enumerated() {
                let left = x+padding+CGFloat(index)*(w-padding*2)/4
                let span = (w-padding*2)/4-12*u
                box(c,CGRect(x:left,y:top,width:span,height:band),rgb(1,1,1,alpha ? 0.7:1))
                for xx in stride(from: Int(left),to:Int(left+span),by:step*2) {
                    box(c,CGRect(x:CGFloat(xx),y:top,width:CGFloat(step),height:band),ink)
                }
                label(c,"\(step) px",left,top+band+10*u,24*u,span)
            }
            let contentY = top+band+70*u
            let contentH = max(24*u, min(available*0.42,720*u))
            let grid = max(1,Int(40*u))
            for yy in stride(from:Int(contentY),to:Int(contentY+contentH),by:grid) {
                for xx in stride(from:Int(x+padding),to:Int(x+w-padding),by:grid) {
                    let isDark = ((xx-Int(x+padding))/grid+(yy-Int(contentY))/grid)%2 == 0
                    box(c,CGRect(x:xx,y:yy,width:grid,height:grid),isDark ? rgb(0.18,0.55,0.72,alpha ? 0.45:1):rgb(0.90,0.96,0.99,alpha ? 0:1))
                }
            }
            if alpha {
                label(c,"透明 / 半透明 / 不透明",x+padding,contentY+contentH+35*u,34*u,w-padding*2)
            } else {
                label(c,"文字清晰度  AaBb 0123456789",x+padding,contentY+contentH+35*u,34*u,w-padding*2)
                label(c,"缩放、边缘与完整显示 / TEST",x+padding,contentY+contentH+98*u,28*u,w-padding*2)
            }
            box(c,CGRect(x:x,y:y,width:6*u,height:h),rgb(0.95,0.2,0.3))
            box(c,CGRect(x:x+w-6*u,y:y,width:6*u,height:h),rgb(0.1,0.65,0.45))
            label(c,section == sections-1 ? "END / 最后一个分段":"NEXT / 下一段",x+padding,y+h-85*u,34*u,w-padding*2)
            c.restoreGState()
        }
        // A center cross and colored edge markers help expose clipping.
        c.setStrokeColor(rgb(0.8,0.1,0.6));c.setLineWidth(max(1,u*2))
        c.move(to:CGPoint(x:CGFloat(s.width)/2-18*u,y:CGFloat(s.height)/2));c.addLine(to:CGPoint(x:CGFloat(s.width)/2+18*u,y:CGFloat(s.height)/2));c.strokePath()
        c.move(to:CGPoint(x:CGFloat(s.width)/2,y:CGFloat(s.height)/2-18*u));c.addLine(to:CGPoint(x:CGFloat(s.width)/2,y:CGFloat(s.height)/2+18*u));c.strokePath()
        let image = c.makeImage()!
        if pair {
            let bytes = image.dataProvider!.data! as Data
            pairHashes[String(s.id)] = SHA256.hash(data:bytes).map { String(format:"%02x",$0) }.joined()
        }
        save(image,root.appendingPathComponent("images/\(s.filename)"),png:s.filename.hasSuffix(".png"))
        print("Created \(s.filename)")
    }
}
precondition(pairHashes["20"] == pairHashes["21"], "Format controls must share identical source pixels")
try JSONSerialization.data(withJSONObject:pairHashes,options:[.prettyPrinted,.sortedKeys]).write(to:root.appendingPathComponent(".build/format-pair-source-sha256.json"))
for s in specs {
    let src = CGImageSourceCreateWithURL(root.appendingPathComponent("images/\(s.filename)") as CFURL,nil)!
    let props = CGImageSourceCopyPropertiesAtIndex(src,0,nil)! as NSDictionary
    precondition(props[kCGImagePropertyPixelWidth] as? Int == s.width)
    precondition(props[kCGImagePropertyPixelHeight] as? Int == s.height)
    if s.id == 19 { precondition(props[kCGImagePropertyHasAlpha] as? Bool == true) }
}

let overviewHeight = 60 + 300 * ((specs.count + 3) / 4)
let overview = canvas(1260, overviewHeight)
box(overview,CGRect(x:0,y:0,width:1260,height:CGFloat(overviewHeight)),rgb(0.93,0.95,0.97))
label(overview,"Image Display Suite / \(specs.count) 张图片显示测试素材",24,12,32,1200)
for (i,s) in specs.enumerated() {
    autoreleasepool {
        let src = CGImageSourceCreateWithURL(root.appendingPathComponent("images/\(s.filename)") as CFURL,nil)!
        let thumb = CGImageSourceCreateThumbnailAtIndex(src,0,[kCGImageSourceCreateThumbnailFromImageAlways:true,kCGImageSourceThumbnailMaxPixelSize:240] as CFDictionary)!
        let x = CGFloat((i%4)*315),y = CGFloat(60+(i/4)*300)
        let area = CGRect(x:x+12,y:y+12,width:291,height:215)
        for gy in 0..<11 { for gx in 0..<15 {
            box(overview,CGRect(x:area.minX+CGFloat(gx*20),y:area.minY+CGFloat(gy*20),width:20,height:20),(gx+gy)%2 == 0 ? rgb(1,1,1):rgb(0.83,0.85,0.88))
        } }
        let scale = min(area.width/CGFloat(thumb.width),area.height/CGFloat(thumb.height))
        let w = CGFloat(thumb.width)*scale,h = CGFloat(thumb.height)*scale
        overview.saveGState();overview.clip(to:area);overview.translateBy(x:area.midX-w/2,y:area.midY+h/2);overview.scaleBy(x:1,y:-1)
        overview.draw(thumb,in:CGRect(x:0,y:0,width:w,height:h));overview.restoreGState()
        label(overview,String(format:"PT%03d",s.id)+"  "+s.title,x+12,y+235,22,291)
        label(overview,"\(s.width) x \(s.height)  /  \(s.ratio)",x+12,y+267,18,291)
    }
}
save(overview.makeImage()!,root.appendingPathComponent("docs/preview.jpg"),png:false)
print("Font: \(fontInfo["postscript_name"]!) / \(fontInfo["version"]!)")
