//
//  NibLoading.swift
//  Mensa
//
//  Created by Jordan Kay on 2/9/17.
//  Copyright © 2017 Jordan Kay. All rights reserved.
//

private var templates: [String: [Data]] = [:]
private var sizeTemplates: [String: [CGSize]] = [:]

private var isTargetInterfaceBuilder: Bool {
    guard let identifier = Bundle.main.bundleIdentifier else { return true }
    return identifier.range(of: "com.apple") != nil
}

func loadNibNamed(nibName: String, variantID: Int) -> UIView {
    if isTargetInterfaceBuilder {
        let nib: UINib = .init(nibName: nibName)
        return nib.contents[variantID]
    } else {
        let template = findTemplate(withName: nibName, variantID: variantID)
        let view = NSKeyedUnarchiver.unarchiveObject(with: template) as! UIView
        view.awakeFromNib()
        return view
    }
}
    
func sizeOfNibNamed(nibName: String, variantID: Int) -> CGSize {
    findTemplate(withName: nibName, variantID: variantID)
    return sizeTemplates[nibName]![min(variantID, sizeTemplates[nibName]!.count - 1)]
}

@discardableResult private func findTemplate(withName nibName: String, variantID: Int) -> Data {
    let nib: UINib = .init(nibName: nibName)
    let variants = templates[nibName] ?? {
        if !isTargetInterfaceBuilder {
            UIView.setupCoding(for: nibName)
        }
//        print("Instantiating nib for \(nibName).")
        let contents = nib.contents
        let data = contents.map { NSKeyedArchiver.archivedData(withRootObject: $0) }
        templates[nibName] = data
        sizeTemplates[nibName] = contents.map { $0.bounds.size }
        return data
    }()
    return variants[min(variantID, variants.count - 1)]
}

extension UINib {
    convenience init!(nibName: String) {
        var bundle: Bundle?
        for framework in Bundle.allFrameworks {
            if framework.path(forResource: nibName, ofType: "nib") != nil {
                bundle = framework
                break
            }
        }
        
        if let bundle = bundle {
            self.init(nibName: nibName, bundle: bundle)
        } else {
            return nil
        }
    }
}

private extension UINib {
    var contents: [UIView] {
        return instantiate(withOwner: nil, options: nil).flatMap{ $0 as? UIView }
    }
}
