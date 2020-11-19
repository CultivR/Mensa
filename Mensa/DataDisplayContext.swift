//
//  DataDisplayContext.swift
//  Mensa
//
//  Created by Jordan Kay on 5/8/17.
//  Copyright © 2017 Jordan Kay. All rights reserved.
//

/// Context in which to display data. UITableView and UICollectionView are the default views used.
public enum DataDisplayContext {
    case tableView(separatorInset: CGFloat?, separatorPlacement: SeparatorPlacement?)
    case collectionView(layout: UICollectionViewLayout)
    
    /// Placement of cell separators specified with the table view context.
    public enum SeparatorPlacement {
        case `default`
        case allCells
        case allCellsButLast
        case allCellsAndTop
    }
}
