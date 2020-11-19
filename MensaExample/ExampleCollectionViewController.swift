//
//  ExampleCollectionViewController.swift
//  Mensa
//
//  Created by Jordan Kay on 6/21/16.
//  Copyright © 2016 Jordan Kay. All rights reserved.
//

import Mensa

final class ExampleCollectionViewController: UIViewController {
    let dataSource = ExampleDataSource(itemCount: .itemCount)
    
    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        setDisplayContext()
        view.backgroundColor = .black
    }
}

extension ExampleCollectionViewController: DataDisplaying {
    typealias Item = NumberOrPrimeFlag
    typealias View = UIView
    typealias DataViewType = UICollectionView
    
    var displayContext: DataDisplayContext {
        let layout = UICollectionViewFlowLayout()
        return .collectionView(layout: layout)
    }
    
    func setupDataView() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleGesture))
        dataView.addGestureRecognizer(gestureRecognizer)
    }
    
    func use(_ viewController: UIViewController, with view: UIView, for item: Item, at indexPath: IndexPath, variant: DisplayVariant, displayed: Bool) {
        if let number = item as? Number, let numberView = view as? NumberView {
            let size = CGFloat(.maxFontSize - number.value)
            numberView.valueLabel.font = UIFont.systemFont(ofSize: size)
        }
    }

    func variant(for item: Item, at indexPath: IndexPath) -> DisplayVariant {
        if item is PrimeFlag {
            return PrimeFlagView.Context.compact
        }
        return DisplayInvariant()
    }
}

private extension ExampleCollectionViewController {
    @objc func handleGesture(gestureRecognizer: UILongPressGestureRecognizer) {
        guard #available(iOS 9, *) else { return }
        switch(gestureRecognizer.state) {
        case .began:
            let location = gestureRecognizer.location(in: dataView)
            guard let indexPath = dataView.indexPathForItem(at: location) else {
                break
            }
            dataView.beginInteractiveMovementForItem(at: indexPath)
        case .changed:
            let position = gestureRecognizer.location(in: gestureRecognizer.view!)
            dataView.updateInteractiveMovementTargetPosition(position)
        case .ended:
            dataView.endInteractiveMovement()
        default:
            dataView.cancelInteractiveMovement()
        }
    }
}

private extension Int {
    static let itemCount = 100
    static let maxFontSize = 114
}
