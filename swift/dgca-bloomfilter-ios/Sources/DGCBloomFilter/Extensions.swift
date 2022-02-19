//
//  Extensions.swift
//  
//
//  Created by Igor Khomiak on 03.02.2022.
//

import Foundation
import BigInt

extension Double {
   var bytes: [UInt8] {
       withUnsafeBytes(of: self, Array.init)
   }
}

extension UInt16 {
   var bytes: [UInt8] {
       withUnsafeBytes(of: self, Array.init)
   }
}

extension UInt32 {
   var bytes: [UInt8] {
       withUnsafeBytes(of: self, Array.init)
   }
}

extension Int32 {
   var bytes: [UInt8] {
       withUnsafeBytes(of: self, Array.init)
   }
}

public extension Bytes {

      func toLong() -> UInt32 {
         let diff = 4-self.count
         var array: [UInt8] = [0, 0, 0, 0]

          for idx in diff...3 {
              array[idx] = self[idx-diff]
          }

         return  UInt32(bigEndian: Data(array).withUnsafeBytes { $0.pointee })
     }
	
	func toDouble() -> Double {
	   let diff = 8 - self.count
	   var array: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0]

		for idx in diff...7 {
			array[idx] = self[idx-diff]
		}

	   return Double(array)!
   }
}
/*
extension FloatingPoint {
	init?(_ bytes: [UInt8]) {
			guard bytes.count == MemoryLayout<Self>.size else { return nil }
			self = bytes.withUnsafeBytes {
				return $0.load(fromByteOffset: 0, as: Self.self)
			}
		}
}
*/
