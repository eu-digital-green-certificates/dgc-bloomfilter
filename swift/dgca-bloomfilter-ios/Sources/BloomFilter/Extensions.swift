//
//  Extensions.swift
//  
//
//  Created by Igor Khomiak on 03.02.2022.
//

import Foundation


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
