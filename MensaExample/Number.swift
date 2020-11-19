//
//  Number.swift
//  Mensa
//
//  Created by Jordan Kay on 6/21/16.
//  Copyright © 2016 Jordan Kay. All rights reserved.
//

import Darwin

struct Number {
    let value: Int
    
    lazy var prime: Bool = {
        self.factors.count == 2
    }()
    
    lazy var factors: [Int] = {
        var factors = Set<Int>()
        var divisor = 1
        let max = Int(sqrt(Double(self.value)))
        while divisor <= max {
            if self.value % divisor == 0 {
                factors.insert(divisor)
                factors.insert(self.value / divisor)
            }
            divisor += 1
        }
        return factors.sorted()
    }()
    
    init(_ value: Int) {
        self.value = value
    }
}
