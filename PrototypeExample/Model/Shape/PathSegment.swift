//
//  PathSegment.swift
//  PrototypeExample
//

import Foundation

class PathSegment: Equatable {

    var start: Point
    var end: Point

    var length: Int {
        return Int(start.distance(to: end))
    }

    init(startPoint: Point, endPoint: Point) {
        start = startPoint
        end = endPoint
    }

    static func == (lhs: PathSegment, rhs: PathSegment) -> Bool {
        return lhs.start == rhs.start && lhs.end == rhs.end
    }
}

extension PathSegment {
    var dx: Float {
        return Float(end.x - start.x)
    }

    var dy: Float {
        return Float(end.y - start.y)
    }

    var slope: Float {
        if dx == 0 {
            return Float.greatestFiniteMagnitude
        }
        return Float(dy) / Float(dx)
    }

    func scale(center: Point, by scale: Float, previous: Float) {
        let sdx = Float(start.x - center.x) * scale / previous
        let sdy = Float(start.y - center.y) * scale / previous
        let edx = Float(end.x - center.x) * scale / previous
        let edy = Float(end.y - center.y) * scale / previous

        start = center + (Int(sdx.rounded()), Int(sdy.rounded()))
        end = center + (Int(edx.rounded()), Int(edy.rounded()))
    }

    func pointInside(point: Point, center: Point) -> Bool {
        if dx == 0 {
            // Vertical line
            let x = start.x
            if center.x <= x {
                return point.x <= x
            } else if center.x >= x {
                return point.x >= x
            }

            return false

        } else if dy == 0 {
            // Horizontal line
            let y = start.y
            if center.y <= y {
                return point.y <= y
            } else if center.y >= y {
                return point.y >= y
            }

            return false
        }

        let m = slope
        let intercept = Float(start.y) - m * Float(start.x)

        let yval = m * Float(point.x) + intercept
        let cyval = m * Float(center.x) + intercept

        let py = Float(point.y)
        let cy = Float(center.y)

        return (py <= yval && cy <= cyval) ||
            (py >= yval && cy >= cyval)
    }

    func hitBox(boxCenter: Point, length: Int) -> Bool {
        if  dx == 0 {
            // Vertical line
            let x = start.x
            let minY = dy > 0 ? start.y : end.y
            let maxY = dy > 0 ? end.y : start.y

            let inX = x <= boxCenter.x + length / 2 && x >= boxCenter.x - length / 2
            let inY = boxCenter.y >= minY && boxCenter.y <= maxY

            return inX && inY
        } else if dy == 0 {
            // Horizontal line
            let y = start.y
            let minX = dx > 0 ? start.x : end.x
            let maxX = dx > 0 ? end.x : start.x

            let inY = y <= boxCenter.y + length / 2 && y >= boxCenter.y - length / 2
            let inX = boxCenter.x >= minX && boxCenter.x <= maxX

            return inY && inX
        }

        let m = slope
        let intercept = Float(start.y) - m * Float(start.x)

        let yval = m * Float(boxCenter.x) + intercept

        let hitMinY = Float(boxCenter.y - length / 2)
        let hitMaxY = Float(boxCenter.y + length / 2)

        let minY = dy > 0 ? start.y : end.y
        let maxY = dy > 0 ? end.y : start.y

        guard Int(hitMinY) >= minY && Int(hitMaxY) <= maxY else {
            return false
        }

        let invm = 1.0 / m
        let invIntercept = Float(start.x) - invm * Float(start.y)

        let xval = invm * Float(boxCenter.y) + invIntercept

        let hitMinX = Float(boxCenter.x - length / 2)
        let hitMaxX = Float(boxCenter.x + length / 2)

        let minX = dx > 0 ? start.x : end.x
        let maxX = dx > 0 ? end.x : start.x

        guard Int(hitMinX) >= minX && Int(hitMaxX) <= maxX else {
            return false
        }

        return yval >= hitMinY && yval <= hitMaxY && xval >= hitMinX && xval <= hitMaxX
    }
}

extension Shape {
    func pointIsInside(_ point: Point) -> Bool {
        let segments = getPath()
        for segment in segments {
            if let curve = segment as? CurvedSegment {
                if !curve.pointInside(point: point) {
                    return false
                }
            } else if !segment.pointInside(point: point, center: getCenter()) {
                return false
            }
        }

        return true
    }
}

class CurvedSegment: PathSegment {
    var center: Point
    var radius: Int

    override var length: Int {
        let angle = endAngle - startAngle
        return Int(angle * Float(radius))
    }

    override init(startPoint: Point, endPoint: Point) {
        center = Point.center(startPoint, endPoint)
        radius = 0
        super.init(startPoint: startPoint, endPoint: endPoint)
    }

    init(startPoint: Point, endPoint: Point, center: Point, radius: Int) {
        self.center = center
        self.radius = radius
        super.init(startPoint: startPoint, endPoint: endPoint)
    }

    static func == (lhs: CurvedSegment, rhs: CurvedSegment) -> Bool {
        return lhs.start == rhs.start && lhs.end == rhs.end && lhs.center == rhs.center && lhs.radius == rhs.radius
    }
}

extension CurvedSegment {
    var startAngle: Float {
        return Point.angle(from: center, to: start)
    }

    var endAngle: Float {
        return Point.angle(from: center, to: end)
    }

    func pointInside(point: Point) -> Bool {
        if center.distance(to: point) <= Double(radius) {
            // let angle = Point.angle(from: center, to: point)
            // return angle >= startAngle && angle <= endAngle
            return true
        } else {
            return false
        }
    }

    func scale(by scale: Float, previous: Float) {
        super.scale(center: center, by: scale, previous: previous)

        radius = Int(Float(radius) * scale / previous)
    }
}
