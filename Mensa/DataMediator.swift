//
//  DataMediator.swift
//  Mensa
//
//  Created by Jordan Kay on 6/21/16.
//  Copyright © 2016 Jordan Kay. All rights reserved.
//

final class DataMediator<Displayer: DataDisplaying, Identifier>: NSObject, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    typealias Item = Displayer.Item
    typealias View = Displayer.View
    typealias ViewController = Displayer.ViewController
    typealias IdentifierType = Displayer.DataSourceType.Identifier
    
    private let tableViewCellSeparatorInset: CGFloat?
    private let hidesLastTableViewCellSeparator: Bool
    
    private var currentSections: [Section<Item, IdentifierType>]
    private var registeredIdentifiers = Set<String>()
    private var registeredHeaderFooterViewIdentifiers = Set<String>()
    private var registeredSupplementaryViewIdentifiers = Set<String>()
    private var viewControllerTypes: [String: () -> ItemDisplayingViewController] = Registration.viewControllerTypes
    private var metricsViewControllers: [String: ItemDisplayingViewController] = [:]
    private var sizes: [IndexPath: CGSize] = [:]
    private var heightCache: [String: CGFloat] = [:]
    private var prefetchedCells: [IndexPath: HostingCell]?
    private var needsHandleResting = true
    
    private weak var displayer: Displayer!
    private weak var parentViewController: UIViewController!
    
    init(displayer: Displayer, parentViewController: UIViewController, tableViewCellSeparatorInset: CGFloat?, hidesLastTableViewCellSeparator: Bool) {
        self.displayer = displayer
        self.parentViewController = parentViewController
        self.tableViewCellSeparatorInset = tableViewCellSeparatorInset
        self.hidesLastTableViewCellSeparator = hidesLastTableViewCellSeparator
        self.currentSections = displayer.dataSource.sections
        super.init()
    }
    
    var sectionCount: Int {
        return currentSections.count
    }
    
    func register<Item, ViewController: UIViewController>(_ itemType: Item.Type, conformedToBy conformingTypes: [Any.Type] = [], with viewControllerType: ViewController.Type) where Item == ViewController.Item, ViewController: ItemDisplaying {
        let types = [itemType] + conformingTypes
        for type in types {
            let key = String(describing: type)
            viewControllerTypes[key] = {
                let viewController = viewControllerType.init()
                return ItemDisplayingViewController(viewController)
            }            
        }
    }
    
    func prefetchContent(at indexPaths: [IndexPath], in scrollView: UIScrollView) {
        if prefetchedCells == nil {
            prefetchedCells = [:]
            for indexPath in indexPaths {
                guard currentSections.count > indexPath.section, currentSections[indexPath.section].count > indexPath.row else { return }
                if let tableView = scrollView as? UITableView {
                    prefetchedCells?[indexPath] = self.tableView(tableView, cellForRowAt: indexPath) as? HostingCell
                } else if let collectionView = scrollView as? UICollectionView {
                    prefetchedCells?[indexPath] = self.collectionView(collectionView, cellForItemAt: indexPath) as? HostingCell
                }
            }
        }
    }
    
    func reset() {
        sizes = [:]
        heightCache = [:]
        currentSections = displayer.dataSource.sections
        needsHandleResting = true
    }

    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return currentSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentSections[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let (item, variant, identifier) = info(for: indexPath)
        if let cell = prefetchedCells?[indexPath] as? UITableViewCell {
            prefetchedCells?[indexPath] = nil
            return cell
        }
        
        let hostingCell: HostingCell? = tableView.dequeueReusableCell(withIdentifier: identifier) as? HostingCell ?? {
            let hostedViewController = self.viewController(for: type(of: item as Any))
            let cell = TableViewCell<Item>(parentViewController: parentViewController, hostedViewController: hostedViewController, variant: variant, reuseIdentifier: identifier)
            if let inset = tableViewCellSeparatorInset {
                cell.separatorInset.left = inset
                cell.layoutMargins.left = inset
            }
            return cell
        }()
        
        guard let cell = hostingCell else { return .init() }
        let view = cell.hostedViewController.view as! View
        let viewController = cell.hostedViewController.viewController as! ViewController
        displayer.use(viewController, with: view, for: item, at: indexPath, variant: variant, displayed: false)

        cell.hostedViewController.update(with: item, at: indexPath, variant: variant, displayed: true)
        cell.hostedViewController.view.layoutIfNeeded()
        return cell as! UITableViewCell
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let (item, variant, _) = info(for: indexPath)
        let type = Swift.type(of: item as Any)
        let key = String(describing: type)
        return heightCache[key] ?? {
            let height: CGFloat
            let controller = viewController(for: type)
            if controller.isItemHeightBasedOnTemplate(displayedWith: variant) {
                controller.loadViewFromNib(for: variant)
                height = controller.view.bounds.height
            } else {
                height = UITableViewAutomaticDimension
            }
            heightCache[key] = height
            return height
        }()
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let (item, variant, identifier) = info(for: indexPath)
        let metricsViewController = metricsViewControllers[identifier] ?? {
            let viewController = self.viewController(for: type(of: item as Any))
            metricsViewControllers[identifier] = viewController
            return viewController
        }()
        let strategy = metricsViewController.itemSizingStrategy(for: item, displayedWith: variant)
        if case let .average(height) = strategy.heightReference {
            return height
        }
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return headerFooterView(in: tableView, forSection: section, ofType: .header)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return headerFooterView(in: tableView, forSection: section, ofType: .footer)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return heightForHeaderFooterView(ofType: .header, forWidth: tableView.bounds.width, inSection: section)
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return heightForHeaderFooterView(ofType: .footer, forWidth: tableView.bounds.width, inSection: section)
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.backgroundColor = .clear
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        view.backgroundColor = .clear
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        cell?.hostedViewController.select(item)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let cell = tableView.cellForRow(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        return cell?.hostedViewController.canSelect(item) ?? false
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        cell?.hostedViewController.updateHighlight(for: item, highlighted: true, animated: false)
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        let animated = !tableView.isTracking
        cell?.hostedViewController.updateHighlight(for: item, highlighted: false, animated: animated)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let (item, _, _) = info(for: indexPath)
        if editingStyle == .delete {
            displayer.handleDeletion(of: item, at: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let cell = tableView.cellForRow(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        guard displayer.canEditSection(indexPath.section) else { return false }
        return cell?.hostedViewController.canRemove(item) ?? false
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let (item, variant, _) = info(for: indexPath)
        let hostedViewController = (cell as! TableViewCell<Item>).hostedViewController!
        let view = hostedViewController.view as! View
        let viewController = hostedViewController.viewController as! ViewController
        displayer.use(viewController, with: view, for: item, at: indexPath, variant: variant, displayed: true)
        
        cell.backgroundColor = tableView.backgroundColor
        cell.selectionStyle = displayer.tableViewCellSelectionStyle(for: item, at: indexPath)
        if hidesLastTableViewCellSeparator {
            let isLastCell = (indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1)
            if isLastCell {
                cell.separatorInset.left = cell.bounds.width
            }
        }
        
        if needsHandleResting {
            needsHandleResting = false
            DispatchQueue.main.async {
                self.handleResting(for: tableView)
            }
        }
        if displayer.displaysDebugBackgrounds {
            cell.backgroundColor = .magenta
        }
    }
    
    // MARK: UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return currentSections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentSections[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let (item, variant, identifier) = info(for: indexPath)
        if let cell = prefetchedCells?[indexPath] as? UICollectionViewCell {
            prefetchedCells?[indexPath] = nil
            return cell
        }
        
        if !registeredIdentifiers.contains(identifier) {
            collectionView.register(CollectionViewCell<Item>.self, forCellWithReuseIdentifier: identifier)
            registeredIdentifiers.insert(identifier)
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! CollectionViewCell<Item>
        if !cell.hostingContent {
            let hostedViewController = viewController(for: type(of: item as Any))
            cell.setup(parentViewController: parentViewController, hostedViewController: hostedViewController, variant: variant)
//            print("Setting up cell at \(indexPath) in \(hostedViewController.parent!) for \(type(of: item as Any)).")
        }
        
        cell.hostedViewController.update(with: item, at: indexPath, variant: variant, displayed: true)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let type = SectionViewType(collectionElementKind: kind), let supplementaryView = self.supplementaryView(in: collectionView, for: indexPath, ofType: type) else {
            return (nil as UICollectionReusableView?)!
        }
        return supplementaryView
    }
    
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let (item, variant, _) = info(for: indexPath)
        let hostedViewController =  (cell as! CollectionViewCell<Item>).hostedViewController!
        let view = hostedViewController.view as! View
        let viewController = hostedViewController.viewController as! ViewController
        displayer.use(viewController, with: view, for: item, at: indexPath, variant: variant, displayed: true)
        
        if needsHandleResting {
            needsHandleResting = false
            DispatchQueue.main.async {
                self.handleResting(for: collectionView)
            }
        }
        if displayer.displaysDebugBackgrounds {
            cell.backgroundColor = .magenta
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let cell = collectionView.cellForItem(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        return cell?.hostedViewController.canSelect(item) ?? false
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        cell?.hostedViewController.select(item)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        let cell = collectionView.cellForItem(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        return cell?.hostedViewController.canSelect(item) ?? false
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        cell?.hostedViewController.updateHighlight(for: item, highlighted: true, animated: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        let animated = !collectionView.isTracking
        cell?.hostedViewController.updateHighlight(for: item, highlighted: false, animated: animated)
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        let cell = collectionView.cellForItem(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        return cell?.hostedViewController.canMove(item) ?? false
    }

    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let (item, _, _) = info(for: sourceIndexPath)
        displayer?.handleMove(of: item, fromIndexPath: sourceIndexPath, toIndexPath: destinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        let cell = collectionView.cellForItem(at: proposedIndexPath) as? HostingCell
        let (item, _, _) = info(for: proposedIndexPath)
        if cell?.hostedViewController.canDisplace(item) ?? false {
            return proposedIndexPath
        }
        return originalIndexPath
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var sectionInsets: UIEdgeInsets = .zero
        let defaultSize = CGSize(width: 50, height: 50)
        let sizeInsets = displayer.sizeInsets(for: indexPath)
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            guard flowLayout.itemSize == defaultSize else {
                let size = flowLayout.itemSize
                return CGSize(width: size.width - sizeInsets.left - sizeInsets.right, height: size.height - sizeInsets.top - sizeInsets.bottom)
            }
            sectionInsets = collectionViewSectionInset(forSection: indexPath.section, with: flowLayout)
        }
        
        return sizes[indexPath] ?? {
            let containerSize = UIEdgeInsetsInsetRect(collectionView.superview!.bounds, sectionInsets).size
            let scrollViewSize = UIEdgeInsetsInsetRect(collectionView.bounds, collectionView.scrollIndicatorInsets).size
            let size = viewSize(at: indexPath, withContainerSize: containerSize, scrollViewSize: scrollViewSize)
            let insetSize = CGSize(width: size.width - sizeInsets.left - sizeInsets.right, height: size.height - sizeInsets.top - sizeInsets.bottom)
            sizes[indexPath] = insetSize
            return insetSize
        }()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            return collectionViewSectionInset(forSection: section, with: flowLayout)
        }
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return sizeForSupplementaryView(ofType: .header, forWidth: collectionView.bounds.width, inSection: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return sizeForSupplementaryView(ofType: .footer, forWidth: collectionView.bounds.width, inSection: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        view.backgroundColor = .clear
    }
    
    // MARK: UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) { displayer?.handle(.didScroll) }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { displayer.handle(.willBeginDragging) }
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) { displayer.handle(.willEndDragging(velocity: velocity, targetContentOffset: targetContentOffset)) }
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) { displayer.handle(.willBeginDecelerating) }
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool { displayer.handle(.willScrollToTop); return true }
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) { displayer.handle(.didScrollToTop) }
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) { displayer.handle(.didEndScrollingAnimation) }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        handleResting(for: scrollView)
        displayer.handle(.didEndDecelerating)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            handleResting(for: scrollView)
        }
        displayer.handle(.didEndDragging(decelerate: decelerate))
    }
}

private extension DataMediator {
    func info(for indexPath: IndexPath) -> (Item, DisplayVariant, String) {
        let item = currentSections[indexPath.section][indexPath.row]
        let key = String(describing: type(of: item as Any))
        let variant = displayer.variant(for: item, at: indexPath)
        let identifier = key + String(variant.rawValue)
        return (item, variant, identifier)
    }
    
    func identifier(for type: SectionViewType, inSection section: Int, withWidth width: CGFloat) -> String {
        var identifier = "\(type.rawValue.capitalized)View"
        if let sectionIdentifierName = currentSections[section].identifier?.name(forWidth: width) {
            identifier = sectionIdentifierName + identifier
        }
        return identifier
    }
    
    func text(for type: SectionViewType, inSection section: Int) -> String? {
        let section = currentSections[section]
        switch type {
        case .header:
            return section.title
        case .footer:
            return section.summary
        }
    }
    
    func detailText(forSection section: Int) -> String? {
        let section = currentSections[section]
        return section.subtitle
    }
    
    func viewController(for type: Any) -> ItemDisplayingViewController {
        let key = String(describing: type)
        return viewControllerTypes[key]!()
    }
    
    func hostedViewController(for cell: UITableViewCell) -> UIViewController? {
        return (cell as? HostingCell)?.hostedViewController
    }
    
    func collectionViewSectionInset(forSection section: Int, with layout: UICollectionViewFlowLayout) -> UIEdgeInsets {
        return displayer.sectionInsets(forSection: section) ?? layout.sectionInset
    }
    
    func viewSize(at indexPath: IndexPath, withContainerSize containerSize: CGSize, scrollViewSize: CGSize) -> CGSize {
        let (item, variant, identifier) = info(for: indexPath)
        let metricsViewController = metricsViewControllers[identifier] ?? {
            let viewController = self.viewController(for: type(of: item as Any))
            metricsViewControllers[identifier] = viewController
            return viewController
        }()
        
        var size: CGSize = .zero
        let strategy = metricsViewController.itemSizingStrategy(for: item, displayedWith: variant)
        
        var fittedSize: CGSize? = nil
        switch (strategy.widthReference, strategy.heightReference) {
        case (.constraints, _), (_, .constraints):
            metricsViewController.loadViewFromNib(for: variant)
            let metricsView = metricsViewController.view as! View
            let viewController = metricsViewController.viewController as! ViewController
            displayer.use(viewController, with: metricsView, for: item, at: indexPath, variant: variant, displayed: false)
            metricsViewController.update(with: item, at: indexPath, variant: variant, displayed: false)
            
            if case .constraints = strategy.heightReference {
                switch strategy.widthReference {
                case .containerView:
                    metricsView.frame.size.width = containerSize.width
                case .scrollView:
                    metricsView.frame.size.width = scrollViewSize.width
                default:
                    break
                }
            } else {
                switch strategy.heightReference {
                case .containerView:
                    metricsView.frame.size.height = containerSize.height
                case .scrollView:
                    metricsView.frame.size.height = scrollViewSize.height
                default:
                    break
                }
            }
            
            metricsView.setNeedsLayout()
            metricsView.layoutIfNeeded()
            fittedSize = metricsView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        default:
            break
        }
        
        var templateSize: CGSize? = nil
        switch (strategy.widthReference, strategy.heightReference) {
        case (.template, _), (_, .template):
            templateSize = metricsViewController.sizeOfNib(for: variant)
        default:
            break
        }

        switch strategy.widthReference {
        case .constraints, .average:
            size.width = fittedSize!.width
        case .containerView:
            size.width = containerSize.width
        case .scrollView:
            size.width = scrollViewSize.width
        case .template:
            size.width = templateSize!.width
        }

        switch strategy.heightReference {
        case .constraints, .average:
            size.height = fittedSize!.height
        case .containerView:
            size.height = containerSize.height
        case .scrollView:
            size.height = scrollViewSize.height
        case .template:
            size.height = templateSize!.height
        }
        
        if let margin = strategy.maxContainerMargin {
            size.width = min(size.width, containerSize.width - margin * 2)
        }

        return size
    }
    
    func headerFooterView(in tableView: UITableView, forSection section: Int, ofType type: SectionViewType) -> HeaderFooterView? {
        let identifier = self.identifier(for: type, inSection: section, withWidth: tableView.bounds.width)
        guard let nib = UINib(nibName: identifier) else { return nil }
        
        let text = self.text(for: type, inSection: section)
        let detailText = self.detailText(forSection: section)
        if !registeredHeaderFooterViewIdentifiers.contains(identifier) {
            tableView.register(nib, forHeaderFooterViewReuseIdentifier: identifier)
            registeredHeaderFooterViewIdentifiers.insert(identifier)
        }
        
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: identifier) as? HeaderFooterView else { return nil }
        view.label?.text = text
        view.detailLabel?.text = detailText
        if case let .tableView(_, separatorPlacement) = displayer.displayContext, type == .header, separatorPlacement == .allCellsAndTop {
            let height = 1 / UIScreen.main.scale
            let y = view.bounds.height - height
            let frame = CGRect(x: 0, y: y, width: view.bounds.width, height: height)
            let separatorView = UIView.create {
                $0.frame = frame
                $0.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
                $0.backgroundColor = tableView.separatorColor
            }
            view.addSubview(separatorView)
            tableView.tableHeaderView = nil
        }
        return view
    }
    
    func heightForHeaderFooterView(ofType type: SectionViewType, forWidth width: CGFloat, inSection section: Int) -> CGFloat {
        let identifier = self.identifier(for: type, inSection: section, withWidth: width)
        guard let nib = UINib(nibName: identifier) else { return 0 }
        
        let text = self.text(for: type, inSection: section)
        let detailText = self.detailText(forSection: section)
        return heightCache[identifier] ?? {
            let view = nib.instantiate(withOwner: nil, options: nil).first as! HeaderFooterView
            view.frame.size.width = width
            view.label?.text = text
            view.detailLabel?.text = detailText
            view.setNeedsLayout()
            view.layoutIfNeeded()
            
            let size = view.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
            let height = (size.height == 0) ? view.bounds.height : size.height
            heightCache[identifier] = height
            return height
        }()
    }
    
    func supplementaryView(in collectionView: UICollectionView, for indexPath: IndexPath, ofType type: SectionViewType) -> SupplementaryView? {
        let section = indexPath.section
        let identifier = self.identifier(for: type, inSection: section, withWidth: collectionView.bounds.width)
        guard let nib = UINib(nibName: identifier) else { return nil }
        
        let text = self.text(for: type, inSection: section)
        let detailText = self.detailText(forSection: section)
        let kind = type.collectionElementKind
        if !registeredSupplementaryViewIdentifiers.contains(identifier) {
            collectionView.register(nib, forSupplementaryViewOfKind: type.collectionElementKind, withReuseIdentifier: identifier)
            registeredSupplementaryViewIdentifiers.insert(identifier)
        }
        
        guard let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: indexPath) as? SupplementaryView else { return nil }
        view.label?.text = text
        view.detailLabel?.text = detailText
        return view
    }
    
    func sizeForSupplementaryView(ofType type: SectionViewType, forWidth width: CGFloat, inSection section: Int) -> CGSize {
        let identifier = self.identifier(for: type, inSection: section, withWidth: width)
        guard let nib = UINib(nibName: identifier) else { return .zero }

        let text = self.text(for: type, inSection: section)
        let detailText = self.detailText(forSection: section)
        let height = heightCache[identifier] ?? {
            let view = nib.instantiate(withOwner: nil, options: nil).first as! SupplementaryView
            view.frame.size.width = width
            view.label?.text = text
            view.detailLabel?.text = detailText
            view.setNeedsLayout()
            view.layoutIfNeeded()
            
            var height: CGFloat = view.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
            if view.detailLabel?.text?.isEmpty == false {
                height += SupplementaryView.marging
            }
            
            let finalHeight = ((height == 0) ? view.bounds.height : height) //+ 25
            heightCache[identifier] = finalHeight
            return finalHeight
        }()
        return CGSize(width: 0, height: height)
    }
    
    func handleResting(for scrollView: UIScrollView) {
        var cells: [HostingCell] = []
        var indexPaths: [IndexPath] = []
        if let tableView = scrollView as? UITableView {
            cells = tableView.visibleCells.map { $0 as! TableViewCell<Item> }
            indexPaths = tableView.indexPathsForVisibleRows!
        } else if let collectionView = scrollView as? UICollectionView {
            cells = collectionView.visibleCells.map { $0 as! CollectionViewCell<Item> }
            indexPaths = collectionView.indexPathsForVisibleItems
        }
        
        for (cell, indexPath) in zip(cells, indexPaths) {
            let (item, _, _) = info(for: indexPath)
            cell.hostedViewController.updateForResting(with: item)
        }
    }
}

private enum SectionViewType: String {
    case header
    case footer
}

private extension SectionViewType {
    init?(collectionElementKind: String) {
        switch collectionElementKind {
        case UICollectionElementKindSectionHeader:
            self = .header
        case UICollectionElementKindSectionFooter:
            self = .footer
        default:
            return nil
        }
    }
    
    var collectionElementKind: String {
        switch self {
        case .header:
            return UICollectionElementKindSectionHeader
        case .footer:
            return UICollectionElementKindSectionHeader
        }
    }
}
