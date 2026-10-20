import UIKit
import CoreText

/// Clean-room, demo-grade handwriting recognizer. User strokes and single-character
/// templates are rasterized to a 48x48 grayscale canvas, normalized to their bounding
/// box, then compared with a 16x16 ink histogram. It recognises common characters and
/// digits roughly; the UI offers a "换一种写法" hint plus handwriting lookup.
final class HandwritingRecognizer {
    static let shared = HandwritingRecognizer()

    static let characters: [Character] = Array("的一是在不了有和人这中大为上个国我以要他时来用们生到作地于出就分对成会可主发年动同工也能下过子说产种面而方后多定行学法所民得经十三之进着等部度家电力里如水化高自二理起小物现实加量都两体制机当使点从业本去把性好应开它合还因由其些然前外天政四日那社义事平形相全表间样与关各重新线内数正心反你明看原又么利比或但质气第向道命此变条只没结解问意建月公无系军很情者最立代想已通并提直题党程展五果料象员革位入常文总次品式活设及管特件长求老头基资边流路级少图山统接知较将组见计别她手角期根论运农指几九区强放决西被干做必战先回则任取据处队南给色光门即保治北造百规热领七海口东导器压志世金增争济阶油思术极交受联什认六共权收证改清己美再采转更单风切打白教速花带安场身车例真务具万每目至达走积示议声报斗完类八离华名确才科张信马节话米整空元况今集温传土许步群广石记需段研界拉林律叫且究观越织装影算低持音众书布复容儿须际商非验连断深难近矿千周委素技备半办青省列习响约支般史感劳便团往酸历市克何除消构府称太准精值号率族维划选标写存候毛亲快效斯院查江型眼王按格养易置派层片始却专状育厂京识适属圆包火住调满县局照参红细引听该铁价严龙飞0123456789")

    private let canvas = 48
    private let featureGrid = 16
    private var templateFeatures: [(Character, [Double])] = []
    private var prepared = false

    private init() {}

    func recognize(strokes: [[CGPoint]], limit: Int = 8) -> [String] {
        guard !strokes.isEmpty else { return [] }
        prepareIfNeeded()
        guard let user = featureVector(strokes: strokes) else { return [] }
        var scored: [(Character, Double)] = []
        for (character, vector) in templateFeatures {
            let score = cosine(user, vector)
            scored.append((character, score))
        }
        scored.sort { $0.1 > $1.1 }
        guard let best = scored.first, best.1 > 0.30 else { return [] }
        return scored.prefix(limit).map { String($0.0) }
    }

    private func prepareIfNeeded() {
        guard !prepared else { return }
        prepared = true
        var generated: [(Character, [Double])] = []
        for character in Self.characters {
            if let points = templateStrokes(character), let vector = featureVector(strokes: points) {
                generated.append((character, vector))
            }
        }
        templateFeatures = generated
    }

    private func templateStrokes(_ character: Character) -> [[CGPoint]]? {
        // Rasterize the glyph, then sample ink pixels grouped into pseudo-strokes by
        // scanning rows. The feature vector only needs the ink distribution, so one
        // "stroke" of every ink pixel is enough.
        let size = canvas
        guard let ctx = makeContext(size: size) else { return nil }
        let font = CTFontCreateWithName("PingFangSC-Regular" as CFString, CGFloat(size) * 0.80, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]
        let string = NSAttributedString(string: String(character), attributes: attributes)
        let line = CTLineCreateWithAttributedString(string)
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        ctx.textPosition = CGPoint(x: (CGFloat(size) - bounds.width) / 2 - bounds.origin.x,
                                   y: (CGFloat(size) - bounds.height) / 2 - bounds.origin.y)
        CTLineDraw(line, ctx)
        return inkPoints(ctx: ctx, size: size)
    }

    private func featureVector(strokes: [[CGPoint]]) -> [Double]? {
        let all = strokes.flatMap { $0 }
        guard all.count > 2 else { return nil }
        let minX = all.map { $0.x }.min()!
        let maxX = all.map { $0.x }.max()!
        let minY = all.map { $0.y }.min()!
        let maxY = all.map { $0.y }.max()!
        let width = max(maxX - minX, 1)
        let height = max(maxY - minY, 1)
        let margin: CGFloat = 5
        let target = CGFloat(canvas) - margin * 2
        let scale = min(target / width, target / height)
        let offsetX = (CGFloat(canvas) - width * scale) / 2 - minX * scale
        let offsetY = (CGFloat(canvas) - height * scale) / 2 - minY * scale
        let normalized = strokes.map { stroke in
            stroke.map { point in
                let yDown = point.y * scale + offsetY
                return CGPoint(x: point.x * scale + offsetX, y: CGFloat(canvas) - yDown)
            }
        }
        guard let ctx = makeContext(size: canvas) else { return nil }
        ctx.setStrokeColor(gray: 0, alpha: 1)
        ctx.setLineWidth(3.2)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        for stroke in normalized where stroke.count > 1 {
            ctx.beginPath()
            ctx.move(to: stroke[0])
            for point in stroke.dropFirst() { ctx.addLine(to: point) }
            ctx.strokePath()
        }
        guard let points = inkPoints(ctx: ctx, size: canvas) else { return nil }
        return histogram(points.flatMap { $0 })
    }

    private func makeContext(size: Int) -> CGContext? {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        ctx.setFillColor(gray: 1, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
        ctx.setShouldAntialias(true)
        return ctx
    }

    private func inkPoints(ctx: CGContext, size: Int) -> [[CGPoint]]? {
        guard let data = ctx.data else { return nil }
        let bytes = data.bindMemory(to: UInt8.self, capacity: size * size)
        var points: [CGPoint] = []
        for y in 0..<size {
            for x in 0..<size {
                let value = bytes[y * size + x]
                if value < 150 {
                    points.append(CGPoint(x: CGFloat(x), y: CGFloat(size - y)))
                }
            }
        }
        return points.isEmpty ? nil : [points]
    }

    private func histogram(_ points: [CGPoint]) -> [Double] {
        var bins = [Double](repeating: 0, count: featureGrid * featureGrid)
        for point in points {
            let x = min(featureGrid - 1, max(0, Int(point.x / CGFloat(canvas) * CGFloat(featureGrid))))
            let y = min(featureGrid - 1, max(0, Int(point.y / CGFloat(canvas) * CGFloat(featureGrid))))
            bins[y * featureGrid + x] += 1
        }
        // Blur slightly so small offsets do not destroy similarity.
        var blurred = [Double](repeating: 0, count: bins.count)
        for y in 0..<featureGrid {
            for x in 0..<featureGrid {
                var total = 0.0
                for dy in -1...1 {
                    for dx in -1...1 {
                        let nx = x + dx
                        let ny = y + dy
                        if nx >= 0, nx < featureGrid, ny >= 0, ny < featureGrid {
                            total += bins[ny * featureGrid + nx]
                        }
                    }
                }
                blurred[y * featureGrid + x] = total
            }
        }
        let norm = sqrt(blurred.reduce(0) { $0 + $1 * $1 })
        return norm > 0 ? blurred.map { $0 / norm } : blurred
    }

    private func cosine(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count else { return 0 }
        var dot = 0.0
        for i in 0..<a.count { dot += a[i] * b[i] }
        return dot
    }
}
