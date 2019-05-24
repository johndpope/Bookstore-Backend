import Foundation
import SwiftKueryORM

struct OptionalBook: Codable {
    let id: Int
    let title: String?
    let inStock: Bool?
    let price: Float?
}

extension OptionalBook: Model {
    //Set the table name to something we know for SwiftKuery
    static let tableName = "BookTable"
}
