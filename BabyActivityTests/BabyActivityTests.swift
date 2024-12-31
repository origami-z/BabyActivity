//
//  BabyActivityTests.swift
//  BabyActivityTests
//
//  Created by Zhihao Cui on 19/12/2024.
//

import Testing
import Foundation
@testable import BabyActivity

struct BabyActivityTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        let duration = await DataController.averageDurationPerDay([PlotDuration(start: Date(), end: Date().addingTimeInterval(60), id: UUID())])
    }

}
