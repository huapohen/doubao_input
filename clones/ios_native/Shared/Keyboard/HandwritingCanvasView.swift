import UIKit

final class HandwritingCanvasView: UIView {
    var onRecognized: (([String]) -> Void)?
    var theme: KeyboardTheme = .current(dark: false)

    private var strokes: [[CGPoint]] = []
    private var currentStroke: [CGPoint] = []
    private var recognizeTimer: Timer?
    private let hintLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isMultipleTouchEnabled = false
        hintLabel.text = "在此手写"
        hintLabel.font = .systemFont(ofSize: 15)
        hintLabel.textColor = theme.secondaryText
        hintLabel.textAlignment = .center
        addSubview(hintLabel)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        hintLabel.frame = CGRect(x: 0, y: bounds.midY - 40, width: bounds.width, height: 24)
        hintLabel.isHidden = !strokes.isEmpty
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        theme.panel.setFill()
        context.fill(bounds)
        let grid = UIBezierPath()
        grid.move(to: CGPoint(x: bounds.midX, y: 0))
        grid.addLine(to: CGPoint(x: bounds.midX, y: bounds.height))
        grid.move(to: CGPoint(x: 0, y: bounds.midY))
        grid.addLine(to: CGPoint(x: bounds.width, y: bounds.midY))
        theme.divider.setStroke()
        grid.lineWidth = 1
        grid.stroke()

        theme.text.setStroke()
        for stroke in strokes + [currentStroke] {
            guard stroke.count > 1 else { continue }
            let path = UIBezierPath()
            path.move(to: stroke[0])
            for point in stroke.dropFirst() { path.addLine(to: point) }
            path.lineWidth = 5
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.stroke()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        currentStroke = [point]
        recognizeTimer?.invalidate()
        setNeedsDisplay()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        currentStroke.append(point)
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !currentStroke.isEmpty {
            strokes.append(currentStroke)
            currentStroke = []
        }
        scheduleRecognition()
        setNeedsDisplay()
        hintLabel.isHidden = true
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentStroke = []
        scheduleRecognition()
        setNeedsDisplay()
    }

    private func scheduleRecognition() {
        recognizeTimer?.invalidate()
        recognizeTimer = Timer.scheduledTimer(withTimeInterval: 0.42, repeats: false) { [weak self] _ in
            self?.recognize()
        }
        RunLoop.main.add(recognizeTimer!, forMode: .common)
    }

    func recognize() {
        guard !strokes.isEmpty else { return }
        let results = HandwritingRecognizer.shared.recognize(strokes: strokes)
        onRecognized?(results)
    }

    func undo() {
        if !strokes.isEmpty {
            strokes.removeLast()
            setNeedsDisplay()
        }
        if strokes.isEmpty {
            onRecognized?([])
        } else {
            recognize()
        }
        hintLabel.isHidden = !strokes.isEmpty
    }

    func clear() {
        strokes = []
        currentStroke = []
        onRecognized?([])
        setNeedsDisplay()
        hintLabel.isHidden = false
    }
}
