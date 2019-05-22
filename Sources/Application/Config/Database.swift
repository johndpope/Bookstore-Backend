import SwiftKuery
import LoggerAPI
import SwiftKueryPostgreSQL
import SwiftKueryORM
import Kitura

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
    
    func putInDatabase(table: BookTable, id: Int, book: Book, response: RouterResponse, completion: @escaping () -> Void) {
        
        App.pool.getConnection() { connection, error in
            guard let connection = connection else {
                Log.error("Error connection: \(error?.localizedDescription ?? "Unknown Error")")
                let _ = response.send(status: .internalServerError)
                return
            }
            
            let updateQuery = Update(table, set: [(table.id, book.id), (table.title, book.title), (table.inStock, book.inStock), (table.price, book.price)]).where(table.id == id)
            
            connection.execute(query: updateQuery) { updateResult in
                guard updateResult.success else {
                    Log.error("Error executing query: \(updateResult.asError?.localizedDescription ?? "Unknown Error")")
                    return
                }
                
                response.send(book)
                return
            }
        }
    }
    
    func saveToDatabase(table: BookTable, book: Book, response: RouterResponse, completion: @escaping () -> Void) {
        let rows = [[book.id, book.title, book.inStock, book.price]]
        
        App.pool.getConnection() { connection, error in
            guard let connection = connection else {
                Log.error("Error connection: \(error?.localizedDescription ?? "Unknown Error")")
                let _ = response.send(status: .internalServerError)
                return
            }
            
            let insertQuery = Insert(into: table, rows: rows)
            
            connection.execute(query: insertQuery) { insertResult in
                guard insertResult.success else {
                    Log.error("Error executing query: \(insertResult.asError?.localizedDescription ?? "Unknown Error")")
                    return
                }
                
                response.send(book)
                return
            }
            
            
        }
    }
    
    func getAllFromDatabase(table: BookTable, response: RouterResponse, completion: @escaping () -> Void) {
        App.pool.getConnection() { connection, error in
            guard let connection = connection else {
                Log.error("Error connection: \(error?.localizedDescription ?? "Unknown Error")")
                return
            }
            
            let selectAllQuery = Select(from: table)
            
            connection.execute(query: selectAllQuery) { selectAllResult in
                guard let resultSet = selectAllResult.asResultSet else {
                    Log.error("Error connection: \(error?.localizedDescription ?? "Uknown Error")")
                    let _ = response.send(status: .internalServerError)
                    return
                }
                
                var books = [Book]()
                resultSet.forEach() { row, error in
                    guard let row = row else {
                        if let error = error {
                            Log.error("Error getting row: \(error.localizedDescription)")
                            let _ = response.send(status: .internalServerError)
                            return
                        } else {
                            response.send(books)
                            return
                        }
                    }
                    
                    guard let id = row[0] as? Int32 else {
                        Log.error("Unable to decode id")
                        let _ = response.send(status: .internalServerError)
                        return
                    }
                    guard let title = row[1] as? String else {
                        Log.error("Unable to decode title")
                        let _ = response.send(status: .internalServerError)
                        return
                    }
                    guard let inStock = row[2] as? Bool else {
                        Log.error("Unable to decode inStock")
                        let _ = response.send(status: .internalServerError)
                        return
                    }
                    guard let price = row[3] as? Float else {
                        Log.error("Unable to decode price")
                        let _ = response.send(status: .internalServerError)
                        return
                    }
                    
                    books.append(Book(id: Int(id), title: title, inStock: inStock, price: price))
                }
            }
            
        }
    }
    
    func getSingleFromDatabase(table: BookTable, id: Int32, response: RouterResponse, completion: () -> Void) {
        App.pool.getConnection() { connection, error in
            guard let connection = connection else {
                Log.error("Error connecting: \(error?.localizedDescription ?? "Unknown Error")")
                return
            }
            
            let selectSingleQuery = Select(from: table).where(table.id == "\(id)")
            
            connection.execute(query: selectSingleQuery) { selectSingleResult in
                guard let resultSet = selectSingleResult.asResultSet else {
                    Log.error("Error connection: \(error?.localizedDescription ?? "Uknown Error")")
                    let _ = response.send(status: .internalServerError)
                    return
                }
                
               var books = [Book]()
                
                resultSet.forEach() { row, error in
                    guard let row = row else {
                        if let error = error {
                            Log.error("Error getting row: \(error.localizedDescription)")
                            let _ = response.send(status: .internalServerError)
                            return
                        } else {
                            response.send(books[0])
                            return
                        }
                    }
                    
                    guard let id = row[0] as? Int32 else {
                        Log.error("Unable to decode id")
                        let _ = response.send(status: .internalServerError)
                        return
                    }
                    guard let title = row[1] as? String else {
                        Log.error("Unable to decode title")
                        let _ = response.send(status: .internalServerError)
                        return
                    }
                    guard let inStock = row[2] as? Bool else {
                        Log.error("Unable to decode inStock")
                        let _ = response.send(status: .internalServerError)
                        return
                    }
                    guard let price = row[3] as? Float else {
                        Log.error("Unable to decode price")
                        let _ = response.send(status: .internalServerError)
                        return
                    }
                    
                    books.append(Book(id: Int(id), title: title, inStock: inStock, price: price))
                    
                }
            }
        }
    }
}


