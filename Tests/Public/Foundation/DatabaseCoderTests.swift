import XCTest
#if SQLITE_HAS_CODEC
    import GRDBCipher
#else
    import GRDB
#endif

class DatabaseCoderTests: GRDBTestCase {
    
    func testDatabaseCoder() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                try db.execute("CREATE TABLE arrays (array BLOB)")
                
                let array = [1,2,3]
                try db.execute("INSERT INTO arrays VALUES (?)", arguments: [DatabaseCoder(array)])
                
                let row = Row.fetchOne(db, "SELECT * FROM arrays")!
                let fetchedArray = ((row.value(named: "array") as DatabaseCoder).object as! NSArray).map { $0 as! Int }
                XCTAssertEqual(array, fetchedArray)
            }
        }
    }
}