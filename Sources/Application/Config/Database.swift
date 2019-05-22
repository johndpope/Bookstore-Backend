import SwiftKuery
import LoggerAPI
import SwiftKueryPostgreSQL
import SwiftKueryORM

extension App {
    static let pool = PostgreSQLConnection.createPool(host: "localhost", port: 5432, options: [.databaseName("bookstore")], poolOptions: ConnectionPoolOptions(initialCapacity: 10, maxCapacity: 50))
    
    static func createTable() {
        Database.default = Database(App.pool)
        
        //Check to see if table exists and only create one if it doesn't.
        let table = try? Book.getTable()
        
        if table == nil {
            do {
                try Book.createTableSync()
            } catch {
                Log.error("Error: \(error.localizedDescription)")
            }
        }
    }
}


