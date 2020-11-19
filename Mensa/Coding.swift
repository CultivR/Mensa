//
//  Coding.swift
//  Mensa
//
//  Created by Jordan Kay on 2/13/17.
//  Copyright © 2017 Jordan Kay. All rights reserved.
//

private var swizzledClasses = Set<String>()

extension UIView {
    static func setupCoding(for name: String) {
        if swizzledClasses.count == 0 {
            let originalDecode = class_getInstanceMethod(UIView.self, #selector(UIView.init(coder:)))!
            let swizzledDecode = class_getInstanceMethod(UIView.self, #selector(UIView.initForDuplicationWithCoder(_:)))!
            method_exchangeImplementations(originalDecode, swizzledDecode)
            
            let originalEncode = class_getInstanceMethod(UIView.self, #selector(UIView.encode(with:)))!
            let swizzledEncode = class_getInstanceMethod(UIView.self, #selector(UIView.encodeForDuplicationWithCoder(_:)))!
            method_exchangeImplementations(originalEncode, swizzledEncode)
        }
        swizzledClasses.insert(name)
    }
    
    @objc func initForDuplicationWithCoder(_ coder: NSCoder) -> UIView {
        let view = initForDuplicationWithCoder(coder)
        let name = String(describing: type(of: self))
        guard swizzledClasses.contains(name) else { return view }
        decodeProperties(from: coder)
        return view
    }
    
    @objc func encodeForDuplicationWithCoder(_ coder: NSCoder) {
        encodeForDuplicationWithCoder(coder)
        let name = String(describing: type(of: self))
        guard swizzledClasses.contains(name) else { return }
        encodeProperties(with: coder)
    }
    
    open override func value(forUndefinedKey key: String) -> Any? { return nil }
    open override func setValue(_ value: Any?, forUndefinedKey key: String) {}
}
