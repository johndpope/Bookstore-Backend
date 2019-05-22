import SwiftKuery

class BookTable: Table {
    
    let tableName = "BookTable"
    let id = Column("id", Int32.self, primaryKey: true)
    let title = Column("title", String.self)
    let inStock = Column("inStock", Bool.self)
    let price = Column("price", Float.self)
}
