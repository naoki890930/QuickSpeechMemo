//
//  Location.swift
//  QuickSpeechMemo
//
//  Created by Naoki Nishiya on 10/27/16.
//  Copyright © 2016 Naoki Nishiyama. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftLocation
import RxSwift

extension LocationManager {
    func rxGetLocation(
        withAccuracy accuracy: Accuracy,
        frequency: UpdateFrequency = .oneShot,
        timeout: TimeInterval? = nil) -> Observable<CLLocation>
    {
        return Observable<CLLocation>.create { observer in
            let request = Location.getLocation(
                withAccuracy: accuracy,
                frequency: frequency,
                timeout: timeout,
                onSuccess: { location in
                    observer.onNext(location)
                    observer.onCompleted()
                }, onError: { _, error in
                    observer.onError(error)
                }
            )
            
            return Disposables.create {
                request.cancel()
            }
        }
    }
}
