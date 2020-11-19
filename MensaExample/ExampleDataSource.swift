//
//  ExampleDataSource.swift
//  Mensa
//
//  Created by Jordan Kay on 5/5/17.
//  Copyright © 2017 Jordan Kay. All rights reserved.
//

import Mensa

protocol NumberOrPrimeFlag {}

extension Number: NumberOrPrimeFlag {}
extension PrimeFlag: NumberOrPrimeFlag {}

struct ExampleDataSource {
    let itemCount: Int
}

extension ExampleDataSource: DataSource {
    var sections: [Section<NumberOrPrimeFlag, DefaultSection>] {
        return [Section(items(count: itemCount))]
    }
}

private extension ExampleDataSource {
    func items(count: Int) -> [NumberOrPrimeFlag] {
        var items: [NumberOrPrimeFlag] = []
        for index in (1...count) {
            var number = Number(index)
            items.append(number)
            if number.prime {
                items.append(PrimeFlag(number: number))
            }
        }
        return items
    }
}
