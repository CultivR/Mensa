//
//  DataSource.swift
//  Mensa
//
//  Created by Jordan Kay on 5/8/17.
//  Copyright © 2017 Jordan Kay. All rights reserved.
//

/// Protocol to adopt in order to provide sections of data.
public protocol DataSource {
    associatedtype Item
    associatedtype Identifier: SectionIdentifier = DefaultSection
    
    var sections: [Section<Item, Identifier>] { get }
}

public protocol ListHolder: DataSource {
    associatedtype T
    
    var items: [T] { get set }
    
    mutating func update(with items: [T])
    mutating func add(_ item: T) -> IndexPath
    mutating func remove(at index: Int)
    mutating func replace(at index: Int, with item: T) -> IndexPath
}

extension ListHolder {
    public var addIndex: Int {
        return items.count
    }
    
    public var sections: [Section<T, Identifier>] {
        return [Section(items)]
    }
    
    public mutating func update(with items: [T]) {
        self.items = items
    }
    
    public mutating func add(_ item: T) -> IndexPath {
        items.append(item)
        return IndexPath(row: items.count - 1, section: 0)
    }
    
    public mutating func remove(at index: Int) {
        items.remove(at: index)
    }
    
    public mutating func replace(at index: Int, with item: T) -> IndexPath {
        items[index] = item
        return IndexPath(row: index, section: 0)
    }
}

public struct ListDataSource<T>: ListHolder {
    public var items: [T]
    
    public init(_ items: [T]) {
        self.items = items
    }
    
    public init(_ initialItem: T) {
        items = [initialItem]
    }
}

public extension ListDataSource where T: Initializable {
    public var count: Int {
        get {
            return items.count
        }
        set {
            items = Array(repeating: T(), count: newValue)
        }
    }
}
