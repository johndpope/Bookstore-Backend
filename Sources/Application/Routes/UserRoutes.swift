import KituraContracts
import SwiftKueryPostgreSQL
import SwiftKuery
import LoggerAPI
import Kitura

func initializeUserRoutes(app: App) {
    let router = Router()
    
    let bookTable = BookTable()
    
    //Get all books
    router.get("/books") { request, response, next in
        
        //Needs to be a closure as this call is asynchronous, only call next() when getAllFromDatabase is complete.
        getAllFromDatabase(table: bookTable, response: response) {
            next()
        }
        // next() is calling a failure due to getAllFronDatabase being asynchronous
//        next()
    }
    
    //Get single book
    router.get("/books:id") { request, response, next in
        next()
    }
    
    //So users can sell their own books
    router.post("/books") { request, response, next in
        
        guard let book = try? request.read(as: Book.self) else {
            let _ = response.send(status: .badRequest)
            return next()
        }
        
        saveToDatabase(table: bookTable, book: book, response: response)
        next()
    }
    
    router.put("/books:id") { request, response, next in
        next()
    }
    
    router.patch("/books:id") { request, response, next in
        next()
    }
    
    app.router.all("/", middleware: router)
}

func saveToDatabase(table: BookTable, book: Book, response: RouterResponse) {
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
        }
        
        response.send(book)
        return
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
