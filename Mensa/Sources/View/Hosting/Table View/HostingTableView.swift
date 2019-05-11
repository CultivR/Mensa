//
//  HostingTableView.swift
//  Mensa
//
//  Created by Jordan Kay on 4/12/19.
//  Copyright © 2019 CultivR. All rights reserved.
//

final class HostingTableView: UITableView {
    let retainedDelegate: UIScrollViewDelegate
    
    init(frame: CGRect, delegate: UITableViewDelegate) {
        retainedDelegate = delegate
        super.init(frame: frame, style: .plain)
        self.delegate = delegate
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}

// MARK: -
extension HostingTableView: DataDisplaying {
    // MARK: DataDisplaying
    func register(_ hostingViewType: HostingView.Type, reuseIdentifier: String) {
        register(hostingViewType, forCellReuseIdentifier: reuseIdentifier)
    }
    
    func register(_ headerFooterViewType: HostingHeaderFooterView.Type, reuseIdentifier: String) {
        register(headerFooterViewType, forHeaderFooterViewReuseIdentifier:  reuseIdentifier)
    }
    
    func register(_ supplementaryViewType: HostingSupplementaryView.Type, reuseIdentifier: String) {
        return
    }
}
