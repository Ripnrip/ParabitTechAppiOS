//
//  BeaconHelper.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/12/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

import Foundation
import CoreBluetooth


extension String {
    
    /// Create `Data` from hexadecimal string representation
    ///
    /// This takes a hexadecimal representation and creates a `Data` object. Note, if the string has any spaces or non-hex characters (e.g. starts with '<' and with a '>'), those are ignored and only hex characters are processed.
    ///
    /// - returns: Data represented by this hexadecimal string.
    
    func hexadecimal() -> Data? {
        var data = Data(capacity: characters.count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, range: NSMakeRange(0, utf16.count)) { match, flags, stop in
            let byteString = (self as NSString).substring(with: match!.range)
            var num = UInt8(byteString, radix: 16)!
            data.append(&num, count: 1)
        }
        
        guard data.count > 0 else { return nil }
        
        return data
        
    }
    
}

extension Data {
    
    /// Create hexadecimal string representation of `Data` object.
    ///
    /// - returns: `String` representation of this `Data` object.
    
    func hexadecimal() -> String {
        return map { String(format: "%02x", $0) }
            .joined(separator: "")
    }
}

//func readCharacteristic(characteristic:CBCharacteristic, completionHandler:@escaping (Bool) -> (String) ){
//    //read a value from the characteristic
//    let readFuture = self.dataCharacteristic?.read(timeout: 5)
//    readFuture?.onSuccess { (_) in
//        //the value is in the dataValue property
//        let s = String(data:(self.dataCharacteristic?.dataValue)!, encoding: .utf8)
//        DispatchQueue.main.async {
//            self.valueLabel.text = "Read value is \(s)"
//            print(self.valueLabel.text!)
//        }
//    }
//    readFuture?.onFailure { (_) in
//        self.valueLabel.text = "read error"
//    }
//}
//func write(){
//    self.valueToWriteTextField.resignFirstResponder()
//    guard let text = self.valueToWriteTextField.text else{
//        return;
//    }
//    //write a value to the characteristic
//    let writeFuture = self.dataCharacteristic?.write(data:text.data(using: .utf8)!)
//    writeFuture?.onSuccess(completion: { (_) in
//        print("write succes")
//    })
//    writeFuture?.onFailure(completion: { (e) in
//        print("write failed")
//    })
//}

