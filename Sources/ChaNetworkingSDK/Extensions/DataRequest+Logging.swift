//
//  DataRequest+Logging.swift
//  ChaNetworkingSDK
//
//  Created by cha on 11/10/25.
//

import Foundation
import Alamofire

extension DataRequest {
    internal func log(dataResponse: DataResponse<Data, AFError>, logging: Bool) {
        guard logging else { return }
        print("===== REQUEST =====")
        print(self.cURLDescription())
        print("===== RESPONSE =====")
        print(dataResponse.debugDescription)
    }
}
