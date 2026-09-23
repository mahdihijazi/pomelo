import AppKit
// Renders the Pomelo dial mark into an .iconset
let sizes = [16, 32, 64, 128, 256, 512, 1024]
let out = CommandLine.arguments[1]
try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
func render(_ px: Int) -> Data {
    let s = CGFloat(px)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    // macOS squircle-ish tile with margin
    let inset = s * 0.1, tile = CGRect(x: inset, y: inset, width: s - 2*inset, height: s - 2*inset)
    let path = CGPath(roundedRect: tile, cornerWidth: tile.width * 0.225, cornerHeight: tile.width * 0.225, transform: nil)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s*0.01), blur: s*0.03, color: NSColor.black.withAlphaComponent(0.35).cgColor)
    ctx.addPath(path); ctx.setFillColor(NSColor(srgbRed: 0.047, green: 0.055, blue: 0.086, alpha: 1).cgColor); ctx.fillPath()
    ctx.restoreGState()
    ctx.addPath(path); ctx.clip()
    // accent glow
    let cs = CGColorSpaceCreateDeviceRGB()
    let g = CGGradient(colorsSpace: cs, colors: [NSColor(srgbRed: 0.2, green: 0.27, blue: 0.88, alpha: 0.55).cgColor, NSColor(srgbRed: 0.2, green: 0.27, blue: 0.88, alpha: 0).cgColor] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(g, startCenter: CGPoint(x: s*0.35, y: s*0.7), startRadius: 0, endCenter: CGPoint(x: s*0.35, y: s*0.7), endRadius: s*0.7, options: [])
    let c = CGPoint(x: s/2, y: s/2), R = tile.width * 0.36
    // ticks
    for i in 0..<60 {
        let a = Double(i)/60 * .pi * 2, major = i % 5 == 0
        if s < 64 && !major { continue }
        let r1 = R, r2 = R - (major ? R*0.13 : R*0.06)
        ctx.move(to: CGPoint(x: c.x + r1*sin(a), y: c.y + r1*cos(a)))
        ctx.addLine(to: CGPoint(x: c.x + r2*sin(a), y: c.y + r2*cos(a)))
        let lit = i < 25
        ctx.setStrokeColor((lit ? NSColor(srgbRed: 0.506, green: 0.565, blue: 1, alpha: 1) : NSColor(white: 1, alpha: 0.28)).cgColor)
        ctx.setLineWidth(max(1, (major ? 0.022 : 0.011) * s)); ctx.setLineCap(.round); ctx.strokePath()
    }
    // wedge (25 of 60 minutes), clockwise from 12
    let wr = R * 0.8
    ctx.move(to: c)
    ctx.addArc(center: c, radius: wr, startAngle: .pi/2, endAngle: .pi/2 - 25.0/60 * .pi * 2, clockwise: true)
    ctx.closePath()
    ctx.setFillColor(NSColor(srgbRed: 0.506, green: 0.565, blue: 1, alpha: 1).cgColor); ctx.fillPath()
    // hub
    let hr = R * 0.5
    ctx.setFillColor(NSColor(srgbRed: 0.082, green: 0.094, blue: 0.153, alpha: 1).cgColor)
    ctx.fillEllipse(in: CGRect(x: c.x-hr, y: c.y-hr, width: hr*2, height: hr*2))
    let dr = R * 0.08
    ctx.setFillColor(NSColor(white: 0.92, alpha: 1).cgColor)
    ctx.fillEllipse(in: CGRect(x: c.x-dr, y: c.y-dr, width: dr*2, height: dr*2))
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}
for sz in sizes {
    let d = render(sz)
    if sz <= 512 { try! d.write(to: URL(fileURLWithPath: "\(out)/icon_\(sz)x\(sz).png")) }
    if sz >= 32 { try! d.write(to: URL(fileURLWithPath: "\(out)/icon_\(sz/2)x\(sz/2)@2x.png")) }
}
