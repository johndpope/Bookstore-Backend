import SwiftKuery
import LoggerAPI
import SwiftKueryPostgreSQL
import SwiftKueryORM
import Kitura

extension App {
    static let pool = PostgreSQLConnection.createPool(host: "localhost", port: 5432, options: [.databaseName("bookstore")], poolOptions: ConnectionPoolOptions(initialCapacity: 10, maxCapacity: 50))
    
    static let bookTable = BookTable()
    
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
    
    func deleteSingleFromDatabase(id: Int, response: RouterResponse, completion: @escaping () -> Void) {
        
        App.pool.getConnection() { connection, error in
            guard let connection = connection else {
                Log.error("Error connecting: \(error?.localizedDescription ?? "Unkown Error")")
                let _ = response.send(status: .internalServerError)
                return
            }
            
            let deleteSingleQuery = Delete(from: App.bookTable).where(App.bookTable.id == id)
            
            connection.execute(query: deleteSingleQuery) { deleteSingleResult in
                guard deleteSingleResult.success else {
                    Log.error("Error executing query: \(deleteSingleResult.asError?.localizedDescription ?? "Unknown Error")")
                    return
                }
                Log.info("Book with id \(id) has been successfully deleted.")
                response.status(.OK)
                return
            }
        }
        
    }
    
    func deleteAllFromDatabase(response: RouterResponse, completion: @escaping () -> Void) {
        App.pool.getConnection() { connection, error in
            guard let connection = connection else {
                Log.error("Error connecting: \(error?.localizedDescription ?? "Unkown Error")")
                let _ = response.send(status: .internalServerError)
                return
            }
            
            let deleteAllQuery = Delete(from: App.bookTable)
            
            connection.execute(query: deleteAllQuery) { deleteAllResult in
                guard deleteAllResult.success else {
                    Log.error("Error executing query: \(deleteAllResult.asError?.localizedDescription ?? "Unknown Error")")
                    return
                }
                Log.info("All books were successfully deleted.")
                response.status(.OK)
                return
            }
        }
    }
    
    func patchInDatabase(id: Int, book: OptionalBook, response: RouterResponse, completion: @escaping () -> Void) {
        App.pool.getConnection() { connection, error in
            guard let connection = connection else {
                Log.error("Error connection: \(error?.localizedDescription ?? "Unknown Error")")
                let _ = response.send(status: .internalServerError)
                return
            }
            var set: [(Column, Any)] = []
            
            if let bookTitle = book.title {
                set.append((App.bookTable.title, bookTitle))
            }
            if let bookInStock = book.inStock {
                set.append((App.bookTable.inStock, bookInStock))
            }
            if let bookPrice = book.price {
                set.append((App.bookTable.price, bookPrice))
            }
            
            let updateQuery = Update(App.bookTable, set: set).where(App.bookTable.id == id)
            
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
    
    func putInDatabase(id: Int, book: Book, response: RouterResponse, completion: @escaping () -> Void) {
        
        App.pool.getConnection() { connection, error in
            guard let connection = connection else {
                Log.error("Error connection: \(error?.localizedDescription ?? "Unknown Error")")
                let _ = response.send(status: .internalServerError)
                return
            }
            
            let updateQuery = Update(App.bookTable, set: [(App.bookTable.id, book.id), (App.bookTable.title, book.title), (App.bookTable.inStock, book.inStock), (App.bookTable.price, book.price)]).where(App.bookTable.id == id)
            
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
    
    func saveToDatabase(book: Book, response: RouterResponse, completion: @escaping () -> Void) {
        let rows = [[book.id, book.title, book.inStock, book.price]]
        
        App.pool.getConnection() { connection, error in
            guard let connection = connection else {
                Log.error("Error connection: \(error?.localizedDescription ?? "Unknown Error")")
                let _ = response.send(status: .internalServerError)
                return
            }
            
            let insertQuery = Insert(into: App.bookTable, rows: rows)
            
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
    
    func getAllFromDatabase(response: RouterResponse, completion: @escaping () -> Void) {
        App.pool.getConnection() { connection, error in
            guard let connection = connection else {
                Log.error("Error connection: \(error?.localizedDescription ?? "Unknown Error")")
                return
            }
            
            let selectAllQuery = Select(from: App.bookTable)
            
            connection.execute(query: selectAllQuery) { selectAllResult in
                guard let resultSet = selectAllResult.asResultSet else {
                    //This error handling is poor, and is outputted when no Books are found. We need to improve this, and in the guides as well.
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
    
    func getSingleFromDatabase(id: Int, response: RouterResponse, completion: () -> Void) {
        App.pool.getConnection() { connection, error in
            guard let connection = connection else {
                Log.error("Error connecting: \(error?.localizedDescription ?? "Unknown Error")")
                return
            }
            
            let selectSingleQuery = Select(from: App.bookTable).where(App.bookTable.id == "\(id)")
            
            connection.execute(query: selectSingleQuery) { selectSingleResult in
                guard let resultSet = selectSingleResult.asResultSet else {
                    //This error handling is poor, and is outputted when a Book isn't found. We need to improve this, and in the guides as well.
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
                            //This will crash the server if nothing if array is empty.
                            response.send(books[0])
                            return
                        }
                    }
                    
                    //Should we be updating the ID as well?
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


