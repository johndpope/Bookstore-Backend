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
        app.getAllFromDatabase(table: bookTable, response: response) {
            next()
        }
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
        
        //Needs to be a closure as this call is asynchronous, only call next() when saveToDatabase is complete.
        app.saveToDatabase(table: bookTable, book: book, response: response) {
            next()
        }
    }
    
    router.put("/books:id") { request, response, next in
        next()
    }
    
    router.patch("/books:id") { request, response, next in
        next()
    }
    
    app.router.all("/", middleware: router)
}
