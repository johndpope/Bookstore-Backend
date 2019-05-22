import Foundation
import SwiftKueryORM

struct Book: Codable {
    let id: Int
    let title: String
    let inStock: Bool
    let price: Float
}

extension Book: Model {
    static let tableName = "BookTable"
}