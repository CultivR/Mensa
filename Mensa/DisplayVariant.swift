//
//  DisplayVariant.swift
//  Mensa
//
//  Created by Jordan Kay on 5/8/17.
//  Copyright © 2017 Jordan Kay. All rights reserved.
//

/// Values that conform can be used to differentiate between different ways to display a given item.
public protocol DisplayVariant {
    init?(rawValue: Int)
    var rawValue: Int { get }
}

extension DisplayVariant {
    public static var `default`: Self {
        return Self(rawValue: 0)!
    }
}

public struct DisplayInvariant {
    public init() {}
}

extension DisplayInvariant: DisplayVariant {
    public init?(rawValue: Int) {}
    
    public var rawValue: Int {
        return 0
    }
}
