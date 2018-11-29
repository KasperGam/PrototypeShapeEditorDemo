//
//  CanvasView.swift
//  PrototypeExample
//

import Cocoa

class CanvasView: NSView {

    @IBInspectable var pointDrawRadius: CGFloat = 3.0
    @IBInspectable var highlightedPointDrawRadius: CGFloat = 5.0

    @IBInspectable var segmentDrawWidth: CGFloat = 2.0
    @IBInspectable var highlightedSegmentDrawWidth: CGFloat = 4.0

    @IBInspectable var pointDrawColor: CGColor = .black
    @IBInspectable var highlightedDrawColor: CGColor = CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
    @IBInspectable var segmentDrawColor: CGColor = .black

    @IBInspectable var mouseBoundBoxSize: Int = 5

    var shapes: [Shape] = []

    var highlightedShape: Shape?

    // Used for whole shapes or side adjustment
    var highlightedSegments: [PathSegment] = [] {
        didSet {
            setNeedsDisplay(bounds)
        }
    }

    // Used for vertex adjustment
    var oldVertex: Point?
    var highlightedVertex: Point? {
        didSet {
            setNeedsDisplay(bounds)
        }
    }

    // Used for scaling
    var previousScale: Float = 1.0

    var canvasTool: CanvasTool?

    var trackingRectTag: TrackingRectTag?

    // Mouse track vars
    var mousedxdy: CGFloat = 0
    let neededUpdateDistance: CGFloat = 2.0
    var mouseDownPoint: Point?

    override var acceptsFirstResponder: Bool {
        return true
    }

    override var frame: NSRect {
        didSet {
            if let tag = trackingRectTag {
                removeTrackingRect(tag)
            }

            trackingRectTag = addTrackingRect(bounds, owner: self, userData: nil, assumeInside: false)
        }
    }

    override var bounds: NSRect {
        didSet {
            if let tag = trackingRectTag {
                removeTrackingRect(tag)
            }

            trackingRectTag = addTrackingRect(bounds, owner: self, userData: nil, assumeInside: false)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        NSColor.white.setFill()
        dirtyRect.fill()

        context.translateBy(x: bounds.width / 2, y: bounds.height / 2)

        for shape in shapes {
            let path = shape.getPath()
            drawShape(path: path, inContext: context)
            draw(shape.getCenter(), inContext: context)
        }

        for segment in highlightedSegments {
            draw(segment, inContext: context, highlighted: true)
        }

        if let vertex = highlightedVertex {
            draw(vertex, inContext: context, highlighted: true)
        }

        context.translateBy(x: -bounds.width / 2, y: -bounds.height / 2)
    }

    private func drawShape(path: [PathSegment], inContext context: CGContext) {
        context.beginPath()
        for segment in path {
            context.move(to: CGPoint(segment.start))
            if let curve = segment as? CurvedSegment {
                context.addArc(center: CGPoint(curve.center), radius: CGFloat(curve.radius), startAngle: CGFloat(curve.startAngle), endAngle: CGFloat(curve.endAngle), clockwise: false)
            } else {
                context.addLine(to: CGPoint(segment.end))
            }
        }
        context.setStrokeColor(.black)
        context.setLineWidth(2.0)
        context.strokePath()
    }

    private func draw(_ vertex: Point, inContext context: CGContext, highlighted: Bool = false) {
        if highlighted {
            context.move(to: CGPoint(vertex + (Int(highlightedPointDrawRadius), 0)))
            context.addArc(center: CGPoint(vertex), radius: highlightedPointDrawRadius, startAngle: 0, endAngle: CGFloat(2 * Float.pi), clockwise: false)
            context.closePath()
            context.setFillColor(highlightedDrawColor)
            context.fillPath()
        } else {
            context.move(to: CGPoint(vertex + (Int(pointDrawRadius), 0)))
            context.addArc(center: CGPoint(vertex), radius: pointDrawRadius, startAngle: 0, endAngle: CGFloat(2 * Float.pi), clockwise: false)
            context.closePath()
            context.setFillColor(pointDrawColor)
            context.fillPath()
        }
    }

    private func draw(_ segment: PathSegment, inContext context: CGContext, highlighted: Bool = false) {
        context.move(to: CGPoint(segment.start))
        if let curve = segment as? CurvedSegment {
            context.addArc(center: CGPoint(curve.center), radius: CGFloat(curve.radius), startAngle: CGFloat(curve.startAngle), endAngle: CGFloat(curve.endAngle), clockwise: false)
        } else {
            context.addLine(to: CGPoint(segment.end))
        }

        if highlighted {
            context.setStrokeColor(highlightedDrawColor)
            context.setLineWidth(highlightedSegmentDrawWidth)
        } else {
            context.setStrokeColor(segmentDrawColor)
            context.setLineWidth(segmentDrawWidth)
        }

        context.strokePath()
    }

    private func hitcheckShapes(center: Point) -> Shape? {
        guard let tool = canvasTool else { return nil }

        var mutation: ShapeMutation?
        switch tool {
        case .extendSegment:
            mutation = .extendSegments
        case .move:
            mutation = .translation
        case .moveVertex:
            mutation = .moveVertex
        case .scale:
            mutation = .scale
        case .delete, .clone:
            mutation = nil
        }

        for shape in shapes {
            if let current = mutation {
                guard shape.allowableMutations.contains(current) else { continue }
                if shape.pointIsInside(center) {
                    return shape
                }
            } else if tool == .delete || tool == .clone {
                if shape.pointIsInside(center) {
                    return shape
                }
            }
        }

        return nil
    }

    private func hitcheckSegments(center: Point) -> (Shape, PathSegment)? {
        for shape in shapes where shape.allowableMutations.contains(.extendSegments) {
            for segment in shape.getPath() {
                if segment.hitBox(boxCenter: center, length: mouseBoundBoxSize) {
                    return (shape, segment)
                }
            }
        }

        return nil
    }

    private func hitcheckVertices(center: Point) -> (Shape, Point)? {
        for shape in shapes where shape.allowableMutations.contains(.moveVertex) {
            for segment in shape.getPath() {
                if segment.start.isInside(circleWithCenter: center, andRadius: mouseBoundBoxSize) {
                    return (shape, segment.start)
                } else if segment.end.isInside(circleWithCenter: center, andRadius: mouseBoundBoxSize) {
                    return (shape, segment.end)
                }
            }
        }

        return nil
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        trackingRectTag = addTrackingRect(bounds, owner: self, userData: nil, assumeInside: false)
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)

        let dx = abs(event.deltaX)
        let dy = abs(event.deltaY)

        mousedxdy += dx + dy

        // We don't want to run expensive operations on sub pixel level
        guard mousedxdy > neededUpdateDistance else { return }

        // We also don't benefit from slowwing down and calculating hits on a fast moving mouse
        guard mousedxdy <= 10 else { mousedxdy = 0; return }

        let xPos = event.locationInWindow.x - 88.0 - bounds.width / 2
        let yPos = event.locationInWindow.y - bounds.height / 2

        if let tool = canvasTool {
            switch tool {
            case .extendSegment:
                if let (shape, highlighted) = hitcheckSegments(center: Point(Int(xPos), Int(yPos))) {
                    highlightedShape = shape
                    if !highlightedSegments.contains(where: { $0 == highlighted }) {
                        highlightedSegments = [highlighted]
                    }
                } else {
                    if highlightedSegments.count > 0 {
                        highlightedSegments = []
                    }
                    highlightedShape = nil
                }
            case .move, .delete, .scale, .clone:
                if let shape = hitcheckShapes(center: Point(Int(xPos), Int(yPos))) {
                    if shape != highlightedShape {
                        highlightedShape = shape
                        highlightedSegments = shape.getPath()
                    }
                } else {
                    highlightedShape = nil
                    highlightedSegments = []
                }
            case .moveVertex:
                if let (shape, vertex) = hitcheckVertices(center: Point(Int(xPos), Int(yPos))) {
                    if vertex != highlightedVertex {
                        highlightedVertex = vertex
                        oldVertex = highlightedVertex
                        highlightedShape = shape
                    }
                } else if highlightedVertex != nil {
                    highlightedVertex = nil
                    highlightedShape = nil
                }
            }
        }

        mousedxdy = 0
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)

        let xPos = event.locationInWindow.x - 88.0 - bounds.width / 2
        let yPos = event.locationInWindow.y - bounds.height / 2

        if let tool = canvasTool {
            switch tool {
            case .extendSegment:
                if highlightedShape != nil {
                    if let segment = highlightedSegments.first {
                        let newCenter = Point(Int(xPos), Int(yPos))
                        if let curve = segment as? CurvedSegment {
                            let newSegment = CurvedSegment(startPoint: segment.start, endPoint: segment.end, center: curve.center, radius: curve.radius)
                            let dx = newCenter.x - curve.center.x
                            let dy = newCenter.y - curve.center.y

                            newSegment.start.translate(dx, dy)
                            newSegment.end.translate(dx, dy)
                            newSegment.center.translate(dx, dy)

                            highlightedShape!.mutatePath(oldPath: curve, newPath: newSegment)
                            highlightedSegments = [newSegment]
                        } else {
                            let newSegment = PathSegment(startPoint: segment.start, endPoint: segment.end)
                            let center = Point.center(segment.start, segment.end)

                            let dx = newCenter.x - center.x
                            let dy = newCenter.y - center.y

                            newSegment.start.translate(dx, dy)
                            newSegment.end.translate(dx, dy)

                            highlightedShape!.mutatePath(oldPath: segment, newPath: newSegment)
                            highlightedSegments = [newSegment]
                        }
                    }
                }
            case .move:
                if highlightedShape != nil {
                    highlightedShape!.setCenter(Point(Int(xPos), Int(yPos)))
                    highlightedSegments = highlightedShape!.getPath()
                }
            case .moveVertex:
                if highlightedVertex != nil {
                    highlightedVertex!.x = Int(xPos)
                    highlightedVertex!.y = Int(yPos)
                }
            case .scale:
                if highlightedShape != nil {
                    guard let mouseDownPoint = self.mouseDownPoint else { break }

                    let center = highlightedShape!.getCenter()
                    let newPoint = Point(Int(xPos), Int(yPos))
                    var dist = mouseDownPoint.distance(to: newPoint)
                    if newPoint.x < mouseDownPoint.x { dist *= -1 }
                    let scale = Float(1 + (dist / 100.0))

                    var newSegments: [PathSegment] = []

                    for segment in highlightedSegments {
                        if let curve = segment as? CurvedSegment {
                            let newSegment = CurvedSegment(startPoint: curve.start, endPoint: curve.end, center: curve.center, radius: curve.radius)
                            newSegment.scale(by: Float(scale), previous: previousScale)
                            highlightedShape!.mutatePath(oldPath: curve, newPath: newSegment)
                            newSegments.append(newSegment)
                        } else {
                            let newSegment = PathSegment(startPoint: segment.start, endPoint: segment.end)
                            newSegment.scale(center: center, by: Float(scale), previous: previousScale)
                            highlightedShape?.mutatePath(oldPath: segment, newPath: newSegment)
                            newSegments.append(newSegment)
                        }
                    }

                    highlightedSegments = newSegments
                    previousScale = scale
                }
            case .delete, .clone:
                return
            }
        }
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)

        window?.acceptsMouseMovedEvents = true
        becomeFirstResponder()
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)

        window?.acceptsMouseMovedEvents = false
        becomeFirstResponder()
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)

        if let tool = canvasTool {
            switch tool {
            case .move, .scale:
                highlightedShape = nil
                highlightedSegments = []
            case .moveVertex:
                if highlightedVertex != nil && highlightedShape != nil {
                    let path = highlightedShape!.getPath()

                    for segment in path where !(segment is CurvedSegment) {
                        if segment.start == oldVertex {
                            highlightedShape?.mutatePath(oldPath: segment, newPath: PathSegment(startPoint: highlightedVertex!, endPoint: segment.end))
                        } else if segment.end == oldVertex {
                            highlightedShape?.mutatePath(oldPath: segment, newPath: PathSegment(startPoint: segment.start, endPoint: highlightedVertex!))
                        }
                    }
                }
            case .delete:
                if highlightedShape != nil {
                    if let index = shapes.firstIndex(of: highlightedShape!) {
                        shapes.remove(at: index)
                    }
                }
            case .extendSegment:
                return
            case .clone:
                if highlightedShape != nil {
                    let newShape = highlightedShape!.clone()
                    let center = newShape.getCenter()
                    newShape.setCenter(center + (10, 10))
                    shapes.insert(newShape, at: 0)
                    highlightedShape = nil
                    highlightedSegments = []
                }
            }
        }

        highlightedShape = nil
        highlightedSegments = []
        highlightedVertex = nil
        oldVertex = nil
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)

        mousedxdy = 0

        let xPos = event.locationInWindow.x - 88.0 - bounds.width / 2
        let yPos = event.locationInWindow.y - bounds.height / 2

        previousScale = 1.0
        mouseDownPoint = Point(Int(xPos), Int(yPos))
    }
}

extension CGPoint {
    init(_ point: Point) {
        self.init()
        self.x = CGFloat(point.x)
        self.y = CGFloat(point.y)
    }
}
