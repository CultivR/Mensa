//
//  Displaying.swift
//  Mensa
//
//  Created by Jordan Kay on 6/21/16.
//  Copyright © 2016 Jordan Kay. All rights reserved.
//

/// Displays a single item using a view, updating the view based on the item’s properties.
public protocol ItemDisplaying: Displaying {
    associatedtype DisplayVariantType = DisplayInvariant

    func update(with item: Item, at indexPath: IndexPath, variant: DisplayVariantType, displayed: Bool)
    func updateForResting(with item: Item)
    func select(_ item: Item)
    func canSelect(_ item: Item) -> Bool
    func canRemove(_ item: Item) -> Bool
    func canMove(_ item: Item) -> Bool
    func canDisplace(_ item: Item) -> Bool
    func updateHighlight(for item: Item, highlighted: Bool, animated: Bool)
    func hostsWithConstraints(displayedWith variant: DisplayVariantType) -> Bool
    func isItemHeightBasedOnTemplate(displayedWith variant: DisplayVariantType) -> Bool
    func itemSizingStrategy(for item: Item, displayedWith variant: DisplayVariantType) -> ItemSizingStrategy
}

public extension ItemDisplaying where DisplayVariantType: DisplayVariant {
    func select(_ item: Item) {}
    func updateForResting(with item: Item) {}
    func canSelect(_ item: Item) -> Bool { return true }
    func canRemove(_ item: Item) -> Bool { return false }
    func canMove(_ item: Item) -> Bool { return true }
    func canDisplace(_ item: Item) -> Bool { return true }
    func updateHighlight(for item: Item, highlighted: Bool, animated: Bool) {}
    func hostsWithConstraints(displayedWith variant: DisplayVariantType) -> Bool { return false }
    func isItemHeightBasedOnTemplate(displayedWith variant: DisplayVariantType) -> Bool { return false }
    
    func itemSizingStrategy(for item: Item, displayedWith variant: DisplayVariantType) -> ItemSizingStrategy {
        return ItemSizingStrategy(widthReference: .constraints, heightReference: .constraints)
    }
}

public extension ItemDisplaying where Self: UIViewController {
    var view: View {
        return view as! View
    }
}

public extension ItemDisplaying where Self: UIViewController, View: Displayed, Item == View.Item, DisplayVariantType == View.DisplayVariantType {
    func update(with item: Item, at indexPath: IndexPath, variant: DisplayVariantType, displayed: Bool) {
        (view as? Preparable)?.prepare()
        if displayed {
            view.update(with: item, variant: variant)
        }
    }
}

public extension BasicMockable where Self: UIViewController, Self: ItemDisplaying, Self.View: VariantMockable {
    static var mock: Self {
        let mock = self.init()
        mock.view = View.mock
        return mock
    }
}
