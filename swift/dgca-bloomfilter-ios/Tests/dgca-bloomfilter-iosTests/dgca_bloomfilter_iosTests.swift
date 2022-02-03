import XCTest
@testable
import dgca_bloomfilter_ios

final class dgca_bloomfilter_iosTests: XCTestCase {
    
    func testRunBasicBloom() throws {
        let impl =  try BloomFilter(size: 1, nHash: 1,numElems: 1);
        try impl.add(element: Data([0, 5, 33, 44]));
        XCTAssert(try !impl.mightContain(element:Data( [0, 5, 88, 44])));
        XCTAssert(try impl.mightContain(element:Data( [0, 5, 33, 44])));
        XCTAssert(impl.getData().count == 1);
        XCTAssert(impl.getData()[0] == (Int32.min >>> 26));
    }
    
    func testBigInteger() throws
    {
        var val = try BloomFilter.calcIndex(element: Data([11]), index: 1, numberOfBits: 100).asInt()
        XCTAssert(val == 75)
        val = try BloomFilter.calcIndex(element: Data([1]), index: 1, numberOfBits: 1).asInt();
        XCTAssert( val == 0);
    }
    
    func testHash() throws
    {
        let hash = try BloomFilter.hash(data: Data([11]), hashFunction: HashFunctions.SHA256, seed: 1)
        XCTAssert(hash.base64EncodedString() == "G2lkA9iYJ1bCNq+8WwnA9U3QaC7lNKddxLcKXV7Quo8=" )
    }
    
    func testRandom() throws
    {
        let filter = try BloomFilter(numElems:62,probRate:0.01)
        
        
        try filter.add(element: Data([16, 43, 72, 132, 157, 34, 143, 179, 78, 151, 143, 30, 166, 231, 218, 70, 76, 109, 164, 229, 241, 65, 36, 143, 3, 141, 252, 207, 175, 255, 69, 131, 234, 53, 207, 65, 31, 65, 18, 60, 200, 239, 16, 5, 245, 5, 253, 207, 4, 208, 122, 31, 219, 143, 54, 221, 173, 142, 62, 57, 125, 120, 230, 106 ]))
    }
}
