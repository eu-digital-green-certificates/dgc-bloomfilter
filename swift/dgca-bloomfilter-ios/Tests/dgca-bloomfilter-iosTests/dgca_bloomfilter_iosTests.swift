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
        XCTAssert(impl.getData()[0] == (Int32.min >>> 25));
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
}
