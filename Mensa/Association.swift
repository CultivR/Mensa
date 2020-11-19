//
//  Association.swift
//  Mensa
//
//  Created by Jordan Kay on 6/22/16.
//  Copyright © 2016 Jordan Kay. All rights reserved.
//

extension NSObject {
    func associatedObject(for key: UnsafeRawPointer) -> Any? {
        return objc_getAssociatedObject(self, key)
    }
    
    func setAssociatedObject(_ object: Any?, for key: UnsafeRawPointer) {
        objc_setAssociatedObject(self, key, object, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
