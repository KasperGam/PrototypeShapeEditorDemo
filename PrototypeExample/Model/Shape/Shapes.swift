//
//  Shapes.swift
//  PrototypeExample
//

import Foundation

class Triangle: Shape {

    var vertices: (v1: Point, v2: Point, v3: Point)

    required init() {
        vertices = (Point(0, 0), Point(50, 0), Point(50, 50))
        super.init()

        shapeID = "Triangle"
        allowableMutations = [.translation, .moveVertex, .extendSegments]
    }

    convenience init(vertices: (Point, Point, Point)) {
        self.init()
        self.vertices = vertices
    }

    override func clone() -> Shape.CloneType {
        return Triangle(vertices: vertices)
    }

    static func ==(lhs: Triangle, rhs: Triangle) -> Bool {
        return (lhs as Shape) == (rhs as Shape) &&
            lhs.vertices.v1 == rhs.vertices.v1 &&
            lhs.vertices.v2 == rhs.vertices.v2 &&
            lhs.vertices.v3 == rhs.vertices.v3
    }

    override func getPath() -> [PathSegment] {
        let l1 = PathSegment(startPoint: vertices.v1, endPoint: vertices.v2)
        let l2 = PathSegment(startPoint: vertices.v2, endPoint: vertices.v3)
        let l3 = PathSegment(startPoint: vertices.v3, endPoint: vertices.v1)

        return [l1, l2, l3]
    }

    override func getCenter() -> Point {
        return getTriangleCenter()
    }

    override func setCenter(_ center: Point) {
        let oldCenter = getTriangleCenter()

        let dx = center.x - oldCenter.x
        let dy = center.y - oldCenter.y

        vertices.v1.translate(dx, dy)
        vertices.v2.translate(dx, dy)
        vertices.v3.translate(dx, dy)
    }

    override func mutatePath(oldPath: PathSegment, newPath: PathSegment) {
        let oldStart = oldPath.start
        let oldEnd = oldPath.end

        let newStart = newPath.start
        let newEnd = newPath.end

        if vertices.v1 == oldStart { vertices.v1 = newStart }
        if vertices.v1 == oldEnd { vertices.v1 = newEnd }

        if vertices.v2 == oldStart { vertices.v2 = newStart }
        if vertices.v2 == oldEnd { vertices.v2 = newEnd }

        if vertices.v3 == oldStart { vertices.v3 = newStart }
        if vertices.v3 == oldEnd { vertices.v3 = newEnd }
    }

    private func getTriangleCenter() -> Point {
        let newX = (vertices.v1.x + vertices.v2.x + vertices.v3.x) / 3
        let newY = (vertices.v1.y + vertices.v2.y + vertices.v3.y) / 3
        return Point(newX, newY)
    }
}

class Rectangle: Shape {

    var center: Point
    var width: Int
    var height: Int

    required init() {
        center = Point()
        width = 50
        height = 30
        super.init()

        shapeID = "Rectangle"
        allowableMutations = [.extendSegments, .translation]
    }

    convenience init(center: Point, width: Int, height: Int) {
        self.init()
        self.center = center
        self.width = width
        self.height = height
    }

    static func ==(lhs: Rectangle, rhs: Rectangle) -> Bool {
        return (lhs as Shape) == (rhs as Shape) &&
            lhs.height == rhs.height &&
            lhs.width == rhs.width
    }

    override func clone() -> Shape.CloneType {
        return Rectangle(center: center, width: width, height: height)
    }

    override func getPath() -> [PathSegment] {
        let xOffset = width / 2
        let yOffset  = height / 2

        let l1 = PathSegment(startPoint: center + (xOffset, yOffset), endPoint: center + (-xOffset, yOffset))
        let l2 = PathSegment(startPoint: center + (-xOffset, yOffset), endPoint: center + (-xOffset, -yOffset))
        let l3 = PathSegment(startPoint: center + (-xOffset, -yOffset), endPoint: center + (xOffset, -yOffset))
        let l4 = PathSegment(startPoint: center + (xOffset, -yOffset), endPoint: center + (xOffset, yOffset))

        return [l1, l2, l3, l4]
    }

    override func getCenter() -> Point {
        return center
    }

    override func setCenter(_ center: Point) {
        self.center = center
    }

    override func mutatePath(oldPath: PathSegment, newPath: PathSegment) {
        let oldLength = oldPath.length

        if oldLength == height {
            let dx = (newPath.start.x - oldPath.start.x) / 2
            center.translate(dx, 0)
            width += dx * 2
        } else if oldLength == width {
            let dy = (newPath.start.y - oldPath.start.y) / 2
            center.translate(0, dy)
            height += dy * 2
        }
    }
}

class Square: Shape {

    var center: Point
    var sideLength: Int

    required init() {
        center = Point()
        sideLength = 50
        super.init()

        shapeID = "Square"
        allowableMutations = [.scale, .translation]
    }

    convenience init(center: Point, sideLength: Int) {
        self.init()
        self.center = center
        self.sideLength = sideLength
    }

    static func ==(lhs: Square, rhs: Square) -> Bool {
        return (lhs as Shape) == (rhs as Shape) &&
            lhs.sideLength == rhs.sideLength
    }

    override func clone() -> Shape.CloneType {
        return Square(center: center, sideLength: sideLength)
    }

    override func getPath() -> [PathSegment] {
        let offset = sideLength / 2
        let l1 = PathSegment(startPoint: center + (offset, offset), endPoint: center + (-offset, offset))
        let l2 = PathSegment(startPoint: center + (-offset, offset), endPoint: center + (-offset, -offset))
        let l3 = PathSegment(startPoint: center + (-offset, -offset), endPoint: center + (offset, -offset))
        let l4 = PathSegment(startPoint: center + (offset, -offset), endPoint: center + (offset, offset))

        return [l1, l2, l3, l4]
    }

    override func getCenter() -> Point {
        return center
    }

    override func setCenter(_ center: Point) {
        self.center = center
    }

    override func mutatePath(oldPath: PathSegment, newPath: PathSegment) {
        sideLength = newPath.length
    }
}

class Circle: Shape {

    var center: Point
    var radius: Int

    required init() {
        center = Point()
        radius = 25
        super.init()

        shapeID = "Circle"
        allowableMutations = [.translation, .scale, .rotation]
    }

    convenience init(center: Point, radius: Int) {
        self.init()
        self.center = center
        self.radius = radius
    }

    static func ==(lhs: Circle, rhs: Circle) -> Bool {
        return (lhs as Shape) == (rhs as Shape) &&
            lhs.radius == rhs.radius
    }

    override func clone() -> Shape.CloneType {
        return Circle(center: center, radius: radius)
    }

    override func getPath() -> [PathSegment] {
        let p1 = CurvedSegment(startPoint: center + (radius, 0), endPoint: center + (-radius, 0), center: center, radius: radius)
        let p2 = CurvedSegment(startPoint: center + (-radius, 0), endPoint: center + (radius, 0), center: center, radius: radius)

        return [p1, p2]
    }

    override func getCenter() -> Point {
        return center
    }

    override func setCenter(_ center: Point) {
        self.center = center
    }

    override func mutatePath(oldPath: PathSegment, newPath: PathSegment) {
        if let radius = (newPath as? CurvedSegment)?.radius {
            self.radius = radius
        }
    }
}
