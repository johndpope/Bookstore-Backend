import KituraSession

func initializeCartRoutes(app: App) {
    
    let session = Session(secret: "password", cookie: [CookieParameter.name("cart-cookie")])
    
    app.router.all(middleware: session)
    app.router.get("/cart") { request, response, next in
        guard let session = request.session else {
            return try response.status(.internalServerError).end()
        }
        
        let books: [Book] = session["books"] ?? []
        response.send(books)
        next()
    }
    
    app.router.post("/cart") { request, response, next in
        guard let session = request.session else {
            return try response.status(.internalServerError).end()
        }
        
        guard let book = try? request.read(as: Book.self) else {
            let _ = response.send(status: .badRequest)
            return next()
        }
        
        var books: [Book] = session["books"] ?? []
        
        books.append(book)
        session["books"] = books
        
        response.status(.created)
        response.send(book)
        next()
    }
}
