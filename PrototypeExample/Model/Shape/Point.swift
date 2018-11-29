//
//  Point.swift
//  PrototypeExample
//

import Foundation

struct Point {
    var x: Int
    var y: Int

    init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }

    init() {
        self.x = 0
        self.y = 0
    }
}

extension Point: Equatable {
    static func +(lhs: Point, rhs: (Int, Int)) -> Point {
        let newX = lhs.x + rhs.0
        let newY = lhs.y + rhs.1

        return Point(newX, newY)
    }

    static func +(lhs: (Int, Int), rhs: Point) -> Point {
        let newX = rhs.x + lhs.0
        let newY = rhs.y + lhs.1

        return Point(newX, newY)
    }

    static func ==(lhs: Point, rhs: Point) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}

extension Point {
    static func center(_ p1: Point, _ p2: Point) -> Point {
        let midx = (p1.x + p2.x) / 2
        let midy = (p1.y + p2.y) / 2

        return Point(midx, midy)
    }

    func distance(to point: Point) -> Double {
        let dx = point.x - x
        let dy = point.y - y

        return sqrt(Double(dx*dx + dy*dy))
    }

    static func angle(from center: Point, to dest: Point) -> Float {
        let dx = dest.x - center.x
        let dy = dest.y - center.y

        if dx == 0 {
            return dy > 0 ? Float.pi / 2 : 3 * Float.pi / 2
        } else if dy == 0 {
            return dx > 0 ? 0 : Float.pi
        }

        let angle = atan(Float(dy) / Float(dx))

        return angle < 0 ? angle + 2 * Float.pi : angle
    }

    mutating func translate(_ dx: Int, _ dy: Int) {
        x += dx
        y += dy
    }

    func isInside(circleWithCenter center: Point, andRadius radius: Int) -> Bool {
        return distance(to: center) <= Double(radius)
    }
}
