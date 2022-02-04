import XCTest
@testable
import dgca_bloomfilter_ios

final class dgca_bloomfilter_iosTests: XCTestCase {
	var testDataLoader: TestDataLoader!
	
	func testReadTestData() throws {
		self.testDataLoader = try TestDataLoader()
	}
	
	func readTestData() throws -> [TestData] {
		self.testDataLoader = try TestDataLoader()
		guard let dataSets = self.testDataLoader.testData else { throw TestError.unknown }
		return dataSets
	}
	
	func testWithTestData() throws {
		let dataSets = try self.readTestData()
		for (index, element) in dataSets.enumerated() {
			print("TEST (\(index)) START")
			// guard let data = element.data else { throw FilterError.unknownError }
			let filter = try BloomFilter(numElems: UInt16(element.data.count), probRate: element.p)
			for addIndex in 0..<element.data.count {
				if element.written[addIndex] == 1 {
					guard let elemToAdd = element.data[addIndex].data(using: .utf8) else { throw FilterError.unknownError }
					try filter.add(element: elemToAdd)
				}
			}
			// get base64 string of filter after all elems have been added
			guard let dataFromArray = arrayToData(intArray: filter.getData()) else { throw FilterError.unknownError } /// Seems to be broken!
			let base64String = dataFromArray.base64EncodedString()
			print("Swift Filter: \(base64String) vs. Java: \(element.filter)")
			if base64String.elementsEqual(element.filter) {
				print("FILTER COMPARE: SUCCESS!")
			} else {
				print("FILTER COMPARE: FAILURE!")
			}
			var exists: [Int32] = [Int32](repeating: 0, count: element.data.count)
			//var exists: [Int32] = [Int32(element.data.count)]
			for x in 0..<element.data.count {
				let mightContain = try filter.mightContain(element: element.data[x].data(using: .utf8)!) ? 1 : 0
				exists[x] = Int32(mightContain)
				print("Filter reported element \(element.data[x]) \(mightContain == 1 ? "exists" : "not exist") at index \(x)")
			}
			// compare written and exist arrays
			let base64Exist = arrayToData(intArray: exists)!.base64EncodedString()
			let base64Written = array2ToData(intArray: element.written)!.base64EncodedString()
			if base64Exist.elementsEqual(base64Written) {
				print("BASE64TEST: SUCCESS!")
			} else {
				print("BASE64TEST: FAILURE!")
			}
			print("TEST (\(index)) END")
		}
		
	}
	
	func stringArrayToData(stringArray: [String]) -> Data? {
	  return try? JSONSerialization.data(withJSONObject: stringArray, options: [])
	}
	
	func arrayToData(intArray: [Int32]) -> Data? {
		return try? JSONSerialization.data(withJSONObject: intArray, options: [])
	}
    
	func array2ToData(intArray: [Int]) -> Data? {
		return try? JSONSerialization.data(withJSONObject: intArray, options: [])
	}
	
    func testRunBasicBloom() throws {
        let impl = try BloomFilter(size: 1, nHash: 1,numElems: 1);
        try impl.add(element: Data([0, 5, 33, 44]));
        XCTAssert(try !impl.mightContain(element:Data( [0, 5, 88, 44])));
        XCTAssert(try impl.mightContain(element:Data( [0, 5, 33, 44])));
        XCTAssert(impl.getData().count == 1);
        XCTAssert(impl.getData()[0] == (Int32.min >>> 26));
    }
    
    func testBigInteger() throws {
        var val = try BloomFilter.calcIndex(element: Data([11]), index: 1, numberOfBits: 100).asInt()
        XCTAssert(val == 75)
        val = try BloomFilter.calcIndex(element: Data([1]), index: 1, numberOfBits: 1).asInt();
        XCTAssert( val == 0);
    }
    
    func testHash() throws {
        let hash = try BloomFilter.hash(data: Data([11]), hashFunction: HashFunctions.SHA256, seed: 1)
        XCTAssert(hash.base64EncodedString() == "G2lkA9iYJ1bCNq+8WwnA9U3QaC7lNKddxLcKXV7Quo8=" )
    }
    
    func testRandom() throws {
        let filter = try BloomFilter(numElems:62,probRate:0.01)
        
        
        try filter.add(element: Data([16, 43, 72, 132, 157, 34, 143, 179, 78, 151, 143, 30, 166, 231, 218, 70, 76, 109, 164, 229, 241, 65, 36, 143, 3, 141, 252, 207, 175, 255, 69, 131, 234, 53, 207, 65, 31, 65, 18, 60, 200, 239, 16, 5, 245, 5, 253, 207, 4, 208, 122, 31, 219, 143, 54, 221, 173, 142, 62, 57, 125, 120, 230, 106 ]))
    }
}

private enum TestError: Error {
	case unknown
}
