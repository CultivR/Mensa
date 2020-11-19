//
//  Registration.swift
//  Mensa
//
//  Created by Jordan Kay on 5/5/17.
//  Copyright © 2017 Jordan Kay. All rights reserved.
//

public enum Registration {
    private(set) static var viewTypes: [String: UIView.Type] = [:]
    private(set) static var viewControllerTypes: [String: () -> ItemDisplayingViewController] = [:]
    
    // Globally register a view controller type to use to display an item type.
    public static func register<Item, ViewController: UIViewController>(_ itemType: Item.Type, conformedToBy conformingTypes: Any.Type..., with viewControllerType: ViewController.Type) where Item == ViewController.Item, ViewController: ItemDisplaying {
        let types = [itemType] + conformingTypes
        for type in types {
            let key = String(describing: type)
            viewTypes[key] = ViewController.View.self
            viewControllerTypes[key] = {
                let viewController = viewControllerType.init()
                return ItemDisplayingViewController(viewController)
            }
        }
    }
}
