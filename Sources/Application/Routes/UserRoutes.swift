import Kitura

func initializeUserRoutes(app: App) {
    let router = Router()
    
    //Get all books
    router.get("/books") { request, response, next in
        
        //Needs to be a closure as this call is asynchronous, only call next() when getAllFromDatabase is complete.
        app.getAllFromDatabase(response: response) {
            next()
        }
    }
    
    //Get single book
    router.get("/books/:id") { request, response, next in
        
        guard let idString = request.parameters["id"] else {
            return
        }
        
        guard let id = Int(idString) else {
            return
        }
        
        app.getSingleFromDatabase(id: id, response: response) {
            next()
        }
    }
    
    //So users can sell their own books
    router.post("/books") { request, response, next in
        
        guard let book = try? request.read(as: Book.self) else {
            let _ = response.send(status: .badRequest)
            return next()
        }
        
        //Needs to be a closure as this call is asynchronous, only call next() when saveToDatabase is complete.
        app.saveToDatabase(book: book, response: response) {
            next()
        }
    }
    
    router.put("/books/:id") { request, response, next in
        
        guard let idString = request.parameters["id"] else {
            return
        }
        
        guard let id = Int(idString) else {
            return
        }
        
        guard let book = try? request.read(as: Book.self) else {
            let _ = response.send(status: .badRequest)
            return next()
        }
        
        app.putInDatabase(id: id, book: book, response: response) {
            next()
        }
    }
    
    router.patch("/books/:id") { request, response, next in
        guard let idString = request.parameters["id"] else {
            return
        }
        
        guard let id = Int(idString) else {
            return
        }
        
        guard let book = try? request.read(as: OptionalBook.self) else {
            let _ = response.send(status: .badRequest)
            return next()
        }
        
        app.patchInDatabase(id: id, book: book, response: response) {
            next()
        }
    }
    
    router.delete("/books") { request, response, next in
        app.deleteAllFromDatabase(response: response) {
            next()
        }
    }
    
    router.delete("/books/:id") { request, response, next in
        guard let idString = request.parameters["id"] else {
            return
        }
        
        guard let id = Int(idString) else {
            return
        }
        
        app.deleteSingleFromDatabase(id: id, response: response) {
            next()
        }
    }
    
    app.router.all("/", middleware: router)
}
