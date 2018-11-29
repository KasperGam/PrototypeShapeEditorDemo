//
//  ShapeCache.swift
//  PrototypeExample
//

import Foundation

class ShapeCache {

    static var shared: ShapeCache = ShapeCache()

    private var map: [String: Shape] = [:]

    init() {
        loadCache()
    }

    func loadCache() {
        // Pull shape prototypes at run time

        let trianglePrototype = Triangle()
        let squarePrototype = Square()
        let rectanglePrototype = Rectangle()
        let circlePrototype = Circle()

        map[trianglePrototype.shapeID] = trianglePrototype
        map[rectanglePrototype.shapeID] = rectanglePrototype
        map[squarePrototype.shapeID] = squarePrototype
        map[circlePrototype.shapeID] = circlePrototype

        // Example of registering prototypes at run time
        /*
         /// Lets say this is a costly call! We only want to make it once!
         let shapes = someRegistry.allShapePrototypes()
         for shape in shapes{
            map[shape.shapeID] = shape
         }
         */
    }

    func registeredShapeIDs() -> [String] {
        return Array(map.keys)
    }

    // Now our shape creation is class agnostic and much quicker than calling to database (for example)
    func newShape(id: String) -> Shape? {
        return map[id]?.clone()
    }
}
