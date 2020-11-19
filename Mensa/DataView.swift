//
//  DataView.swift
//  Mensa
//
//  Created by Jordan Kay on 6/21/16.
//  Copyright © 2016 Jordan Kay. All rights reserved.
//

/// UITableView or UICollectionView, used for displaying data.
public protocol DataView where Self: UIScrollView {
    func reloadData()
    func batchUpdate(_ update: () -> Void, completion: @escaping () -> Void)
}

public extension DataView {
    var topInset: CGFloat {
        let inset: UIEdgeInsets
        if #available(iOS 11.0, *) {
            inset = adjustedContentInset
        } else {
            inset = contentInset
        }
        return inset.top
    }
    
    var isScrolledToTop: Bool {
        return contentOffset.y == -topInset
    }
    
    func scrollToTop(animated: Bool) {
        let offset = CGPoint(x: contentOffset.x, y: -topInset)
        if animated {
            if delegate?.scrollViewShouldScrollToTop?(self) ?? false {
                setContentOffset(offset, animated: true)
            }
        } else {
            contentOffset = offset
        }
    }
}

extension UITableView: DataView {
    public func batchUpdate(_ update: () -> Void, completion: @escaping () -> Void) {
        performBatchUpdates(update) { _ in
            completion()
        }
    }
}

extension UICollectionView: DataView {
    public func batchUpdate(_ update: () -> Void, completion: @escaping () -> Void) {
        performBatchUpdates(update) { _ in
            completion()
        }
    }
}
