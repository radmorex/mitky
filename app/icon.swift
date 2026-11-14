// Малює іконку застосунку (1024×1024 PNG): небо на заході сонця + сакура. Запускається з build.sh.
import Cocoa

let size = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

let box = NSRect(x: 100, y: 100, width: 824, height: 824) // поля, як у системних іконок macOS
let shape = NSBezierPath(roundedRect: box, xRadius: 186, yRadius: 186)
NSGradient(colors: [NSColor(red: 1.00, green: 0.82, blue: 0.56, alpha: 1),
                    NSColor(red: 0.96, green: 0.50, blue: 0.62, alpha: 1),
                    NSColor(red: 0.42, green: 0.30, blue: 0.66, alpha: 1),
                    NSColor(red: 0.16, green: 0.16, blue: 0.42, alpha: 1)])!.draw(in: shape, angle: 90)

shape.addClip()
NSColor(red: 0.20, green: 0.34, blue: 0.30, alpha: 1).setFill() // пагорб
NSBezierPath(ovalIn: NSRect(x: 0, y: -240, width: 1024, height: 560)).fill()

let flower = "🌸" as NSString
let font = NSFont.systemFont(ofSize: 470)
let fs = flower.size(withAttributes: [.font: font])
flower.draw(at: NSPoint(x: (CGFloat(size) - fs.width) / 2, y: (CGFloat(size) - fs.height) / 2 + 30), withAttributes: [.font: font])

NSGraphicsContext.current?.flushGraphics()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
