//
//  Configure.swift
//  QuickSpeechMemo
//
//  Created by Naoki Nishiya on 10/22/16.
//  Copyright © 2016 Naoki Nishiyama. All rights reserved.
//

import Foundation
import Log

/// ログ出力
let log: Logger? = {
    #if DEBUG
        let Log = Logger(formatter: .detailed)
        return Log
    #else
        return nil
    #endif
}()

struct Configure {
    static func start() {
    }
}
