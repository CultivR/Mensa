//
//  Navigation.swift
//  Mensa
//
//  Created by Jordan Kay on 9/15/17.
//  Copyright © 2017 Jordan Kay. All rights reserved.
//

public extension NSObject {
    func performFromFirstResponder(_ selector: Selector) {
        UIApplication.shared.sendAction(selector, to: nil, from: self, for: nil)
    }
}
