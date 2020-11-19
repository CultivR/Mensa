//
//  Scrolling.swift
//  Mensa
//
//  Created by Jordan Kay on 7/22/16.
//  Copyright © 2016 Jordan Kay. All rights reserved.
//

public enum ScrollEvent {
    case canScroll
    case didScroll
    case willBeginDragging
    case willEndDragging(velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
    case didEndDragging(decelerate: Bool)
    case willBeginDecelerating
    case didEndDecelerating
    case didEndScrollingAnimation
    case willScrollToTop
    case didScrollToTop
}
