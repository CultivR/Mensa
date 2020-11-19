//
//  Display.swift
//  Mensa
//
//  Created by Jordan Kay on 6/21/16.
//  Copyright © 2016 Jordan Kay. All rights reserved.
//

/// Type that can display items (model objects) of a given type using a given view type.
public protocol Displaying: class {
    associatedtype Item
    associatedtype View: UIView = UIView
    associatedtype ViewController: UIViewController = UIViewController
}

/// Type (usually a view) that is displayed with an item, which can be updated.
public protocol Displayed: class {
    associatedtype Item
    associatedtype DisplayVariantType: DisplayVariant
    
    func update(with item: Item, variant: DisplayVariantType)
}

public extension Displayed {
    func update(with item: Item) {
        update(with: item, variant: DisplayVariantType.default)
    }
}
