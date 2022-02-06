//
//  Streams.swift
//  
//
//  Created by Paul Ballmann on 26.01.22.
//

import Foundation

extension InputStream {
	func readData(withLength length: Int) throws -> Data {
		var offset = [UInt8](repeating: 0, count: length)
		let result = self.read(&offset, maxLength: offset.count)
        guard result >= 0 else { throw self.streamError ?? POSIXError(.EIO) }
        return Data(offset.prefix(result))
	}
}

extension OutputStream {
	func writeData<DataType: DataProtocol>(_ data: DataType) throws -> Int {
		var bfr = Array(data)
		let result = self.write(&bfr, maxLength: bfr.count)
        guard result >= 0 else { throw self.streamError ?? POSIXError(.EIO) }
        
        return result
	}
}
