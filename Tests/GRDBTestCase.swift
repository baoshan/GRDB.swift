import XCTest
#if SQLITE_HAS_CODEC
    import GRDBCipher
#else
    import GRDB
#endif

class GRDBTestCase: XCTestCase {
    // The default configuration for tests
    var dbConfiguration: Configuration!
    
    // Builds a database queue based on dbConfiguration
    func makeDatabaseQueue(filename: String = "db.sqlite") throws -> DatabaseQueue {
        try NSFileManager.defaultManager().createDirectoryAtPath(dbDirectoryPath, withIntermediateDirectories: true, attributes: nil)
        let dbPath = (dbDirectoryPath as NSString).stringByAppendingPathComponent(filename)
        let dbQueue = try DatabaseQueue(path: dbPath, configuration: dbConfiguration)
        try setUpDatabase(dbQueue)
        return dbQueue
    }
    
    // Builds a database pool based on dbConfiguration
    func makeDatabasePool(filename: String = "db.sqlite") throws -> DatabasePool {
        try NSFileManager.defaultManager().createDirectoryAtPath(dbDirectoryPath, withIntermediateDirectories: true, attributes: nil)
        let dbPath = (dbDirectoryPath as NSString).stringByAppendingPathComponent(filename)
        let dbPool = try DatabasePool(path: dbPath, configuration: dbConfiguration)
        try setUpDatabase(dbPool)
        return dbPool
    }
    
    // Subclasses can override
    // Default implementation is empty.
    func setUpDatabase(dbWriter: DatabaseWriter) throws {
    }
    
    // The default path for database pool directory
    private var dbDirectoryPath: String!
    
    // Populated by default configuration
    var sqlQueries: [String]!   // TODO: protect against concurrent accesses
    
    // Populated by default configuration
    var lastSQLQuery: String!   // TODO: protect against concurrent accesses
    
    override func setUp() {
        super.setUp()
        
        let dbPoolDirectoryName = "GRDBTestCase-\(NSProcessInfo.processInfo().globallyUniqueString)"
        dbDirectoryPath = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent(dbPoolDirectoryName)
        do { try NSFileManager.defaultManager().removeItemAtPath(dbDirectoryPath) } catch { }
        
        dbConfiguration = Configuration()
        dbConfiguration.trace = { (sql) in
            self.sqlQueries.append(sql)
            self.lastSQLQuery = sql
            // LogSQL(sql) // Uncomment for verbose tests
        }
        
        #if GRDBCIPHER_USE_ENCRYPTION
            // We are testing encrypted databases.
            dbConfiguration.passphrase = "secret"
        #endif
        
        sqlQueries = []
        lastSQLQuery = nil
    }
    
    override func tearDown() {
        super.tearDown()
        do { try NSFileManager.defaultManager().removeItemAtPath(dbDirectoryPath) } catch { }
    }
    
    func assertNoError(file: StaticString = #file, line: UInt = #line, @noescape test: (Void) throws -> Void) {
        do {
            try test()
        } catch {
            XCTFail("unexpected error at \(file):\(line): \(error)")
        }
    }
    
    func sql<T>(databaseReader: DatabaseReader, _ request: FetchRequest<T>) -> String {
        return databaseReader.read { db in
            _ = Row.fetchOne(db, request)
            return self.lastSQLQuery
        }
    }
}