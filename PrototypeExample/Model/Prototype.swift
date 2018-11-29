//
//  Prototype.swift
//  PrototypeExample
//

import Foundation

protocol Prototype {
    associatedtype CloneType: Initializable

    func clone() -> CloneType
}

protocol Initializable {
    init()
}
