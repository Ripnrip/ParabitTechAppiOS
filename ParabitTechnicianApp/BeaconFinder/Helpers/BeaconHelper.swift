//
//  BeaconHelper.swift
//  ParabitTechnicianApp
//
//  Created by Gurinder Singh on 10/12/17.
//  Copyright © 2017 Gurinder Singh. All rights reserved.
//

//import Foundation
//import CoreBluetooth
//
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

