//
//  TableViewCell_list.swift
//  soine
//
//  Created by 倉知諒 on 2022/04/30.
//

import UIKit

class TableViewCell_list: UITableViewCell {
    @IBOutlet weak var bkImg: UIImageView!
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var player1: UISwitch!
    @IBOutlet weak var player2: UISwitch!
    // スイッチ変更時のコールバッククロージャ
    var switchChanged: ((Int, Bool, Bool) -> Void)?
    func setCell(data: Data_list, switchChanged: @escaping (Int, Bool, Bool) -> Void) {
        // 画像の縦横サイズを取得
        let imgWidth: CGFloat = data.soineImg.size.width
        let imgHeight: CGFloat = data.soineImg.size.height
        // 画像サイズをスクリーン幅に合わせる
        let width = imgWidth * data.scale
        let height = imgHeight * data.scale
        let rect: CGRect = CGRect(
            x: 0, y: -(height / 4), width: width, height: height)
        let myImageView = UIImageView(image: data.soineImg)
        myImageView.frame = rect
        myImageView.alpha = 0.3
        //背景画像
        for subView in bkImg.subviews {
            subView.removeFromSuperview()
        }
        bkImg.addSubview(myImageView)
        thumbnail.image = data.soineImg
        player1.isOn = data.p1
        player2.isOn = data.p2
        self.switchChanged = switchChanged
    }
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        // 自分がどの indexPath のセルかを取得
        if let tableView = self.superview as? UITableView,
           let indexPath = tableView.indexPath(for: self) {
            switchChanged?(indexPath.row, player1.isOn, player2.isOn)
        }
    }
}

class Data_list {
    var soineImg: UIImage
    var scale: CGFloat
    var p1: Bool
    var p2: Bool

    init(category: UIImage, scale: CGFloat, p1: Bool, p2: Bool) {
        self.soineImg = category
        self.scale = scale
        self.p1 = p1
        self.p2 = p2
    }
}
