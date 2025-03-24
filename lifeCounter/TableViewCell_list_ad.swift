//
//  TableViewCell_list_ad.swift
//  soine
//
//  Created by 倉知諒 on 2022/07/06.
//

import UIKit
import GoogleMobileAds
class TableViewCell_list_ad: UITableViewCell {
    @IBOutlet weak var ad: BannerView!
    @IBOutlet weak var id: UILabel!
    func setCell(unitId:String,rootViewController:UIViewController) {
//        if Consts.DEBUG_FLG {
//            id.text = String(_id)
//        }
        ad.adUnitID = unitId
        ad.rootViewController = rootViewController
        ad.load(Request())
    }
}
