//
//  ExampleTableViewController.swift
//  Mensa
//
//  Created by Jordan Kay on 6/21/16.
//  Copyright © 2016 Jordan Kay. All rights reserved.
//

import Mensa

final class ExampleTableViewController: UIViewController {
    let dataSource = ExampleDataSource(itemCount: .itemCount)

    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        setDisplayContext()
    }
}

extension ExampleTableViewController: DataDisplaying {
    typealias Item = NumberOrPrimeFlag
    typealias View = UIView
    typealias DataViewType = UITableView
    
    var displayContext: DataDisplayContext {
        return .tableView(separatorInset: nil, separatorPlacement: .default)
    }
        
    func use(_ viewController: UIViewController, with view: UIView, for item: Item, at indexPath: IndexPath, variant: DisplayVariant, displayed: Bool) {
        if let number = item as? Number, let numberView = view as? NumberView {
            let size = CGFloat(.maxFontSize - number.value)
            numberView.valueLabel.font = UIFont.systemFont(ofSize: size)
        }
    }
    
    func variant(for item: Item, at indexPath: IndexPath) -> DisplayVariant {
        if item is PrimeFlag {
            return PrimeFlagView.Context.regular
        }
        return DisplayInvariant()
    }
}

private extension Int {
    static let itemCount = 100
    static let maxFontSize = 114
}
