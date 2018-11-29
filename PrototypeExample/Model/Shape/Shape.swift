//
//  Shape.swift
//  PrototypeExample
//

import Foundation

protocol ShapePrototype {
    var shapeID: String { get set }
    var allowableMutations: [ShapeMutation] { get set }

    func getPath() -> [PathSegment]
    func setCenter(_ center: Point)
    func getCenter() -> Point
    func mutatePath(oldPath: PathSegment, newPath: PathSegment)
}

class Shape: Prototype, ShapePrototype, Initializable, Equatable {

    typealias CloneType = Shape

    // Shape variables
    var shapeID: String
    var allowableMutations: [ShapeMutation] = []

    /// Initializable required init
    required init() {
        shapeID = "Shape"
    }

    /// Convenience init
    convenience init(shapeID: String) {
        self.init()
        self.shapeID = shapeID
    }

    /// Prototype clone method
    func clone() -> Shape.CloneType {
        return Shape(shapeID: shapeID)
    }

    // Shape methods
    func getPath() -> [PathSegment] {
        return []
    }

    func getCenter() -> Point { return Point() }
    func setCenter(_ center: Point) {}

    func mutatePath(oldPath: PathSegment, newPath: PathSegment) {}

    static func == (lhs: Shape, rhs: Shape) -> Bool {
        return lhs.shapeID == rhs.shapeID && lhs.getCenter() == rhs.getCenter()
    }
}
