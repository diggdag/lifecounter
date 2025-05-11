//
//  Consts.swift
//  lifeCounter
//
//  Created by 倉知諒 on 2021/09/24.
//  Copyright © 2021 kurachi. All rights reserved.
//
import UIKit
class Consts {
    static let PLAYER1:Int16=0
    static let PLAYER2:Int16=1
    static let LIST_AD_INTERVAL: Int = 2
    static let SETTING_DEFAULT_LIFE_STEP:Float=5
    static let FORMAT_DATE_HIS:String="yyyy/MM/dd' 'HH:mm"
//    static let FORMAT_DATE_HIS:String="yyyy-MM-dd' 'HH:mm:ss"
    static let ADMOB_TEST_DEVICE_ID_SE2: String = "05db8b8bb003e0b96c0467e6e889d6bd"
    
    //AD
    static let ADMOB_UNIT_ID_MAIN: String = "ca-app-pub-5418872710464793/5128065062"
    static let ADMOB_UNIT_ID_BGSELECT: String = "ca-app-pub-5418872710464793/6190902703"
    static let ADMOB_UNIT_ID_SETTING: String = "ca-app-pub-5418872710464793/8292371957"
    
    //テスト広告
//    static let ADMOB_UNIT_ID_MAIN: String = "ca-app-pub-3940256099942544/6300978111"
//    static let ADMOB_UNIT_ID_BGSELECT: String = "ca-app-pub-3940256099942544/6300978111"
//    static let ADMOB_UNIT_ID_SETTING: String = "ca-app-pub-3940256099942544/6300978111"
    
    static let ADMOB_UNIT_ID_INTERSTITIAL_CLEAR: String = "ca-app-pub-5418872710464793/9067310079"
//    static let ADMOB_UNIT_ID_HISTORY: String = "ca-app-pub-3940256099942544/2934735716"//テスト広告
//    static let ADMOB_UNIT_ID_INTERSTITIAL_CLEAR: String = "ca-app-pub-3940256099942544/4411468910"//テスト広告
}
struct AdAccount {
    let name: String
    let adFlg: Bool
}
