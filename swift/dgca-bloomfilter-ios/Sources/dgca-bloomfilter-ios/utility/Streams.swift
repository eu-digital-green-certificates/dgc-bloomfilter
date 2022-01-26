//
//  File.swift
//  
//
//  Created by Paul Ballmann on 26.01.22.
//

import Foundation

extension InputStream {
	func readData(withLength length: Int) throws -> Data {
		var offset = [UInt8](repeating: 0, count: length)
		let result = self.read(&offset, maxLength: offset.count)
		if result < 0 {
			throw self.streamError ?? POSIXError(.EIO)
		} else {
			return Data(offset.prefix(result))
		}
	}
}

extension OutputStream {
	func writeData<DataType: DataProtocol>(_ data: DataType) throws -> Int {
		var bfr = Array(data)
		let result = self.write(&bfr, maxLength: bfr.count)
		if result < 0 {
			throw self.streamError ?? POSIXError(.EIO)
		} else {
			return result
		}
	}
}
                                                                                                            
