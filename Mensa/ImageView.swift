//
//  ImageView.swift
//  Mensa
//
//  Created by Jordan Kay on 5/22/17.
//  Copyright © 2017 Jordan Kay. All rights reserved.
//

open class ImageView: UIImageView {
    // MARK: NSCoding
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        let gestureRecognizers = coder.decodeObject(forKey: "gestureRecognizers") as? [UIGestureRecognizer]
        gestureRecognizers?.forEach { addGestureRecognizer($0) }
    }
    
    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(gestureRecognizers, forKey: "gestureRecognizers")
    }
}
