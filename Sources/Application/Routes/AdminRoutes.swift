import KituraContracts
import SwiftKueryORM
import Credentials
import CredentialsHTTP
import Kitura
import KituraOpenAPI

struct AdminAuth: TypeSafeHTTPBasic {
    
    static let tempCredentials = ["admin": "password"]
    
    static func verifyPassword(username: String, password: String, callback: @escaping (AdminAuth?) -> Void) {
        if let storedPassword = tempCredentials["admin"], storedPassword == password {
            return callback(AdminAuth(id: username))
        }
        callback(nil)
    }
    
    var id: String
    
}

func initializeAdminRoutes(app: App) {
    
    let router = Router()
    
    App.createTable()
    
    router.get("/books", handler: getAllBooks)
    router.get("/books:id", handler: getSingleBook)
    
    router.delete("/books:id", handler: deleteSingleBook)
    router.delete("/books", handler: deleteAllBooks)
    
    router.post("/books", handler: postBook)
    
    router.put("/books:id", handler: putBook)
    
    router.patch("/books:id", handler: patchBook)
    
    KituraOpenAPI.addEndpoints(to: router)
    
    app.router.all("/admin", middleware: router)
}

fileprivate func getAllBooks(user: AdminAuth, completion: @escaping ([Book]?, RequestError?) -> Void) {
    Book.findAll(completion)
}

fileprivate func getSingleBook(user: AdminAuth, id: Int, completion: @escaping (Book?, RequestError?) -> Void) {
    Book.find(id: id, completion)
}

fileprivate func deleteSingleBook(user: AdminAuth, id: Int, completion: @escaping (RequestError?) -> Void) {
    Book.delete(id: id, completion)
}

fileprivate func deleteAllBooks(user: AdminAuth, completion: @escaping (RequestError?) -> Void) {
    Book.deleteAll(completion)
}

fileprivate func postBook(user: AdminAuth, book: Book, completion: @escaping (Book?, RequestError?) -> Void) {
    book.save(completion)
}

fileprivate func putBook(user: AdminAuth, id: Int, book: Book, completion: @escaping (Book?, RequestError?) -> Void) {
    book.update(id: id, completion)
}

fileprivate func patchBook(user: AdminAuth, id: Int, book: Book, completion: @escaping (Book?, RequestError?) -> Void) {
    book.update(id: id, completion)
}
