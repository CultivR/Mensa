//
//  DataDisplaying.swift
//  Mensa
//
//  Created by Jordan Kay on 6/21/16.
//  Copyright © 2016 Jordan Kay. All rights reserved.
//

/// Protocol for view controllers to adopt in order to display data (sections of items) in a table or collection view.
public protocol DataDisplaying: Displaying {
    associatedtype DataViewType: DataView
    associatedtype DataSourceType: DataSource where DataSourceType.Item == Item
    
    // The source of the data to display.
    var dataSource: DataSourceType! { get }
    
    // The context (table or collection view and its properties) for displaying the data.
    var displayContext: DataDisplayContext { get }
    
    var statusBarBackgroundColor: UIColor? { get }
    
    var displaysDebugBackgrounds: Bool { get }

    // Implementors should call `register` for each view controller type that they want to represent each item type displayed.
    func registerItemTypeViewControllerTypePairs()
    
    // Optionally specify data view properties.
    func setupDataView()
    
    // Optional functionality implementors can specify to modify a view that will be used to display a given item.
    func use(_ viewController: ViewController, with view: View, for item: Item, at indexPath: IndexPath, variant: DisplayVariant, displayed: Bool)
    
    // Specify which display variant should be used for the given item, other than the default.
    func variant(for item: Item, at indexPath: IndexPath) -> DisplayVariant
    
    func tableViewCellSelectionStyle(for item: Item, at indexPath: IndexPath) -> UITableViewCellSelectionStyle
    
    // How the given section is inset, if at all.
    func sectionInsets(forSection section: Int) -> UIEdgeInsets?
    
    // How the size of the item at the given index path is inset.
    func sizeInsets(for indexPath: IndexPath) -> UIEdgeInsets
    
    // Handle scroll events.
    func handle(_ scrollEvent: ScrollEvent)
    
    //
    func handleDeletion(of item: Item, at indexPath: IndexPath)
    
    //
    func handleMove(of item: Item, fromIndexPath: IndexPath, toIndexPath: IndexPath)
    
    //
    func canEditSection(_ section: Int) -> Bool
    
    // Specify additional behavior to be executed when the data is reset.
    func reset()
}

public extension DataDisplaying {
    var statusBarBackgroundColor: UIColor? { return nil }
    var displaysDebugBackgrounds: Bool { return false }
    func registerItemTypeViewControllerTypePairs() {}
    func setupDataView() {}
    func variant(for item: Item, at indexPath: IndexPath) -> DisplayVariant { return DisplayInvariant() }
    func tableViewCellSelectionStyle(for item: Item, at indexPath: IndexPath) -> UITableViewCellSelectionStyle { return .default }
    func use(_ viewController: ViewController, with view: View, for item: Item, at indexPath: IndexPath, variant: DisplayVariant, displayed: Bool) {}
    func sectionInsets(forSection section: Int) -> UIEdgeInsets? { return nil }
    func sizeInsets(for indexPath: IndexPath) -> UIEdgeInsets { return .zero }
    func handle(_ scrollEvent: ScrollEvent) {}
    func handleDeletion(of item: Item, at indexPath: IndexPath) {}
    func handleMove(of item: Item, fromIndexPath: IndexPath, toIndexPath: IndexPath) {}
    func canEditSection(_ section: Int) -> Bool { return true }
    func reset() {}
}

public extension DataDisplaying where Self: UIViewController {
    private(set) var dataView: DataViewType {
        get {
            return associatedObject(for: &dataViewKey) as! DataViewType
        }
        set {
            setAssociatedObject(newValue, for: &dataViewKey)
        }
    }
}

public extension DataDisplaying where Self: UIViewController {
    // Reference the current number of sections of data.
    var sectionCount: Int {
        return dataMediator?.sectionCount ?? 0
    }
    
    // Call this method to set up a display context in a view controller by adding an appropriate data view as a subview.
    func setDisplayContext() {
        var tableViewCellSeparatorInset: CGFloat? = nil
        var hidesLastTableViewCellSeparator = false
        
        switch displayContext {
        case let .tableView(separatorInset, separatorPlacement):
            let tableView = (DataViewType.self as! UITableView.Type).init()
            tableViewCellSeparatorInset = separatorInset
            hidesLastTableViewCellSeparator = (separatorPlacement == .allCellsButLast)
            if separatorPlacement == nil {
                tableView.separatorStyle = .none
            } else if separatorPlacement != .default {
                tableView.tableFooterView = UIView()
                if separatorPlacement == .allCellsAndTop {
                    let frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 1 / UIScreen.main.scale)
                    tableView.tableHeaderView = UIView(frame: frame)
                    tableView.tableHeaderView?.backgroundColor = tableView.separatorColor
                }
            }
            self.dataView = tableView as! DataViewType
        case let .collectionView(layout):
            let collectionView = (DataViewType.self as! UICollectionView.Type).init(frame: .zero, collectionViewLayout: layout)
            collectionView.backgroundColor = .clear
            if #available (iOS 10, *) {
                collectionView.isPrefetchingEnabled = false
            }
            self.dataView = collectionView as! DataViewType
        }
        
        view.insertSubview(dataView, at: 0)
        dataView.frame = view.bounds
        dataView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if #available (iOS 11, *) {} else {
            dataView.contentInset.top = navigationController?.navigationBar.frame.maxY ?? 0
            dataView.contentInset.bottom = tabBarController?.tabBar.bounds.height ?? 0
            dataView.scrollIndicatorInsets = dataView.contentInset
            automaticallyAdjustsScrollViewInsets = false
        }
        setupDataView()
        
        if let backgroundColor = statusBarBackgroundColor {
            let statusBarView = UIView(frame: UIApplication.shared.statusBarFrame)
            statusBarView.backgroundColor = backgroundColor
            view.addSubview(statusBarView)
        }
        
        let dataMediator = DataMediator<Self, DataSourceType.Identifier>(displayer: self, parentViewController: self, tableViewCellSeparatorInset: tableViewCellSeparatorInset, hidesLastTableViewCellSeparator: hidesLastTableViewCellSeparator)
        setAssociatedObject(dataMediator, for: &dataMediatorKey)
        
        if let tableView = dataView as? UITableView {
            tableView.delegate = dataMediator
            tableView.dataSource = dataMediator
            tableView.estimatedRowHeight = .defaultRowHeight
            tableView.rowHeight = UITableViewAutomaticDimension
        } else if let collectionView = dataView as? UICollectionView {
            collectionView.delegate = dataMediator
            collectionView.dataSource = dataMediator
        }
        
        registerItemTypeViewControllerTypePairs()
    }
    
    // Register a view controller type to use to display an item type.
    func register<Item>(_ itemType: Item.Type, conformedToBy conformingTypes: [Any.Type] = [], with viewControllerType: ViewController.Type) where Item == ViewController.Item, ViewController: ItemDisplaying {
        dataMediator?.register(itemType, conformedToBy: conformingTypes, with: viewControllerType)
    }
    
    //
    func prefetchContent(at indexPaths: [IndexPath], inScrollView scrollView: UIScrollView) {
        DispatchQueue.main.async {
            self.dataMediator?.prefetchContent(at: indexPaths, in: scrollView)
        }
    }
    
    // Call this method from the view controller to reload the data view.
    func reloadData() {
        resetData()
        dataView.reloadData()
    }
    
    func resetData() {
        reset()
        dataMediator?.reset()
    }
    
    func reloadItem(at indexPath: IndexPath, animated: Bool = false) {
        reloadItems(at: [indexPath], animated: animated)
    }
    
    // Call this method from the view controller to reload the data at specific index paths in the data view.
    func reloadItems(at indexPaths: [IndexPath], animated: Bool = false) {
        resetData()
        var reload = {}
        if let tableView = dataView as? UITableView {
            reload = { tableView.reloadRows(at: indexPaths, with: .fade) }
        } else if let collectionView = dataView as? UICollectionView {
            reload = { collectionView.reloadItems(at: indexPaths) }
        }
        if animated {
            reload()
        } else {
            UIView.performWithoutAnimation(reload)
        }
    }
    
    func insertItem(at indexPath: IndexPath, animated: Bool = false) {
        insertItems(at: [indexPath], animated: animated)
    }
    
    // Call this method from the view controller to insert items into the data view.
    func insertItems(at indexPaths: [IndexPath], animated: Bool = false) {
        resetData()
        var insert = {}
        if let tableView = dataView as? UITableView {
            insert = { tableView.insertRows(at: indexPaths, with: .fade) }
        } else if let collectionView = dataView as? UICollectionView {
            insert = { collectionView.insertItems(at: indexPaths) }
        }
        if animated {
            insert()
        } else {
            UIView.performWithoutAnimation(insert)
        }
    }
    
    // Call this method to
    func insertSections(_ sections: IndexSet, animated: Bool = false) {
        resetData()
        var insert = {}
        if let tableView = dataView as? UITableView {
            insert = { tableView.insertSections(sections, with: .fade) }
        } else if let collectionView = dataView as? UICollectionView {
            insert = { collectionView.insertSections(sections) }
        }
        if animated {
            insert()
        } else {
            UIView.performWithoutAnimation(insert)
        }
    }
    
    func removeItem(at indexPath: IndexPath, animated: Bool = false) {
        removeItems(at: [indexPath], animated: animated)
    }
    
    // Call this method from the view controller to remove items from the data view.
    func removeItems(at indexPaths: [IndexPath], animated: Bool = false) {
        resetData()
        var remove = {}
        if let tableView = dataView as? UITableView {
            remove = { tableView.deleteRows(at: indexPaths, with: .left) }
        } else if let collectionView = dataView as? UICollectionView {
            remove = { collectionView.deleteItems(at: indexPaths) }
        }
        if animated {
            dataView.batchUpdate(remove, completion: reloadData)
        } else {
            UIView.performWithoutAnimation(remove)
            reloadData()
        }
    }
}

private var dataViewKey = "displayViewKey"
private var dataMediatorKey = "dataMediatorKey"

private extension DataDisplaying where Self: UIViewController {
    var dataMediator: DataMediator<Self, DataSourceType.Identifier>? {
        return (dataView as? UITableView)?.dataSource as? DataMediator<Self, DataSourceType.Identifier> ?? (dataView as? UICollectionView)?.dataSource as? DataMediator<Self, DataSourceType.Identifier>
    }
}

private extension CGFloat {
    static let defaultRowHeight: CGFloat = 44
}
