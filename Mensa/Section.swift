//
//  Section.swift
//  Mensa
//
//  Created by Jordan Kay on 6/21/16.
//  Copyright © 2016 Jordan Kay. All rights reserved.
//

/// Section of data that can be displayed in a data view.
public struct Section<Item, Identifier: SectionIdentifier> {
    let identifier: Identifier?
    let title: String?
    let subtitle: String?
    let summary: String?
    
    private let items: [Item]
    
    var count: Int {
        return items.count
    }
    
    public init(_ items: [Item], identifier: Identifier? = nil, title: String? = nil, subtitle: String? = nil, summary: String? = nil) {
        self.identifier = identifier
        self.items = items
        self.title = title
        self.subtitle = subtitle
        self.summary = summary
    }
    
    public subscript(index: Int) -> Item {
        return items[index]
    }
}

extension Section: Sequence {
    public func makeIterator() -> AnyIterator<Item> {
        var index = 0
        return AnyIterator {
            if index < self.items.count {
                let object = self.items[index]
                index += 1
                return object
            }
            return nil
        }
    }
}

public protocol SectionIdentifier: RawRepresentable where RawValue == String {
    func name(forWidth width: CGFloat) -> String
}

extension SectionIdentifier {
    public func name(forWidth width: CGFloat) -> String {
        return rawValue.capitalized
    }
}

public enum DefaultSection: String, SectionIdentifier {
    case section
}
