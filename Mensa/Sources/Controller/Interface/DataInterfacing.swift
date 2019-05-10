//
//  DataInterfacing.swift
//  Mensa
//
//  Created by Jordan Kay on 4/10/19.
//  Copyright © 2019 CultivR. All rights reserved.
//

public protocol DataInterfacing: UIViewController {
    typealias Item = DataSourceType.Item
    
    associatedtype View: UIView = UIView
    associatedtype DataSourceType: DataSource
    
    var displayContext: DataDisplayContext { get }
    
    func displayVariant(for item: Item) -> Variant?
    func prepareAndAddDataView(_ dataView: UIScrollView)
    func supportInterfacingWithData()
}

public extension DataInterfacing {
    func useData(from dataSource: DataSourceType) {
        if let dataView = dataView {
            dataMediator.dataSource = dataSource
            dataView.reloadData()
        } else {
            setupDataView()
            supportInterfacingWithData()
            
            dataView!.registerIdentifiers(for: displayContext, using: dataMediator)
            dataMediator.dataSource = dataSource
        }
    }
    
    func supportInterfacing<Item, Interface: ItemInterfacing>(with itemType: Item.Type, using interfaceType: Interface.Type) where Item == Interface.View.Item {
        dataMediator.supportInterfacing(with: itemType, using: interfaceType)
    }
}

public extension DataInterfacing {
    func displayVariant(for item: Item) -> Variant? {
        return nil
    }
}

private extension DataInterfacing {
    var dataView: DataDisplaying? {
        get {
            return objc_getAssociatedObject(self, &key) as? DataDisplaying
        }
        set {
            objc_setAssociatedObject(self, &key, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    var dataMediator: DataMediator<Self>! {
        return (dataView as? UITableView)?.delegate as? DataMediator<Self> ?? (dataView as? UICollectionView)?.delegate as? DataMediator<Self>
    }
    
    func setupDataView() {
        let dataMediator = DataMediator(dataInterface: self)
        
        switch displayContext {
        case .tableView:
            setupTableView(with: dataMediator)
        case let .collectionView(layout):
            setupCollectionViewWith(dataMediator: dataMediator, layout: layout)
        }
    }
    
    func setupTableView(with dataMediator: DataMediator<Self>) {
        let tableView = HostingTableView(frame: view.bounds, delegate: dataMediator)
        tableView.dataSource = dataMediator
        dataView = tableView
        prepareAndAddDataView(tableView)
    }
    
    func setupCollectionViewWith(dataMediator: DataMediator<Self>, layout: UICollectionViewLayout) {
        let collectionView = HostingCollectionView(frame: view.bounds, layout: layout, delegate: dataMediator)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = dataMediator
        dataView = collectionView
        prepareAndAddDataView(collectionView)
    }
}

private extension DataDisplaying {
    func registerIdentifiers<T>(for displayContext: DataDisplayContext, using dataMediator: DataMediator<T>) {
        let identifiers = dataMediator.itemTypeVariantIdentifiers
        identifiers.forEach { register($0, for: displayContext) }
    }
    
    func register(_ identifier: ItemTypeVariantIdentifier, for displayContext: DataDisplayContext) {
        let reuseIdentifier = identifier.value
        switch displayContext {
        case .tableView:
            register(HostingTableViewCell.self, reuseIdentifier: reuseIdentifier)
        case .collectionView:
            register(HostingCollectionViewCell.self, reuseIdentifier: reuseIdentifier)
        }
    }
}

// MARK: -
private var key: Void?
