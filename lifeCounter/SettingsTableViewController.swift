//
//  SettingsTableViewController.swift
//  SettingsInAppExample
//
//  Created by Sakura on 2018/03/07.
//  Copyright © 2018年 Sakura. All rights reserved.
//

import UIKit
import Photos
import MediaPlayer
import CoreData
import UniformTypeIdentifiers
import AVFoundation
import Toast_Swift
import GoogleMobileAds

class SettingsTableViewController: UITableViewController{
    
    @IBOutlet weak var interval: UISlider!
    @IBOutlet weak var intervalLabel: UILabel!
    @IBOutlet weak var interval2: UISlider!
    @IBOutlet weak var intervalLabel2: UILabel!
    @IBOutlet var interval3: UISlider!
    @IBOutlet var opacityLabel: UILabel!
    
    @IBOutlet var bannerView: BannerView!
    weak var delegate: ChildViewControllerDelegate?
    var appDelegate:AppDelegate!
    var viewContext:NSManagedObjectContext!
    
//    var bannerView: GADBannerView!
    var upperLifeP1:Int = 20
    var upperLifeP2:Int = 20
    var bgopacity:Float = 0.8
    
    @IBOutlet weak var saveBtn: UIButton!
    static var defaultLifeChanged = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        viewContext = appDelegate.persistentContainer.viewContext
        
        // In this case, we instantiate the banner with desired ad size.
//        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
//        bannerView = GADBannerView()
        bannerView.adUnitID = Consts.ADMOB_UNIT_ID_SETTING
//        bannerView.adUnitID = "ca-app-pub-5418872710464793/9454905695"
        bannerView.rootViewController = self
//        bannerView.backgroundColor=UIColor.green
//        addBannerViewToView(bannerView)
//        bannerView.load(GADRequest())
        if let localizedTitle = NSLocalizedString("SaveBtnTitle", comment: "") as String? {
            saveBtn.setTitle(localizedTitle, for: .normal)
        }
    }
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        
////        interval.isEnabled = false
////        intervalLabel.isEnabled = false
////        intervalTitleLabel.isEnabled = false
//    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let request: NSFetchRequest<Setting> = Setting.fetchRequest()
        do {
            let fetchResults = try viewContext.fetch(request)
            if let setting = fetchResults.first {
//                screenRotate = Rotate(rawValue: setting.rotateDirection) ?? .normal
                let step = Consts.SETTING_DEFAULT_LIFE_STEP
                if setting.defaultLifeP1 != 0 {
                    let roundedP1 = Int(round(Float(setting.defaultLifeP1) / step) * step)
                    upperLifeP1 = roundedP1
                    intervalLabel.text = "\(upperLifeP1)"
                    interval.setValue(Float(upperLifeP1), animated: false)
                }
                if setting.defaultLifep2 != 0 {
                    let roundedP2 = Int(round(Float(setting.defaultLifep2) / step) * step)
                    upperLifeP2 = roundedP2
                    intervalLabel2.text = "\(upperLifeP2)"
                    interval2.setValue(Float(upperLifeP2), animated: false)
                }
                if setting.bgopacity != 0 {
                    bgopacity=setting.bgopacity
                    opacityLabel.text = "\(bgopacity)"
                    interval3.setValue(bgopacity, animated: false)
                }
            } else {
//                screenRotate = .normal
                print("設定なし”")
            }
        } catch {
            print("Error fetching data: \(error)")
        }
        //ad
        loadBannerAd()
    }
    
    override func viewWillTransition(to size: CGSize,
                            with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to:size, with:coordinator)
        //ad start
        coordinator.animate(alongsideTransition: { _ in
            self.loadBannerAd()
        })
        //ad end
    }
    //ad
    func loadBannerAd() {
        print("loadBannerAd called")
        let frame = { () -> CGRect in
        if #available(iOS 11.0, *) {
            return view.frame.inset(by: view.safeAreaInsets)
        } else {
            return view.frame
        }
        }()
        let viewWidth = frame.size.width
        let viewHeight = frame.size.height
        let aspect = viewHeight/viewWidth
        print("aspect:\(aspect)")
        bannerView.adSize = inlineAdaptiveBanner(width: viewWidth,maxHeight: 50*aspect)
        let request: Request = Request()
        bannerView.load(request)
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        // セクションの数を返します
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // それぞれのセクション毎に何行のセルがあるかを返します
        switch section {
        case 0: // 「設定」のセクション
            return 8
        case 1: // 「その他」のセクション
            return 0//要らないから表示しない
        default: // ここが実行されることはないはず
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if indexPath.section == 0 {
//            if indexPath.row == 0 {
//                //画像
//                callPhotoLibrary()
//            }
//            else if indexPath.row == 2 {
//                let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.wav,UTType.mp3])
//                documentPicker.delegate = self
//                self.present(documentPicker, animated: true, completion: nil)
//                // クルクルスタート
//                ActivityIndicator.startAnimating()
//            }
//        }
    }
    
    func addBannerViewToView(_ bannerView: BannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        view.addConstraints(
          [NSLayoutConstraint(item: bannerView,
                              attribute: .bottom,
                              relatedBy: .equal,
                              toItem: bottomLayoutGuide,
                              attribute: .top,
                              multiplier: 1,
                              constant: 0),
           NSLayoutConstraint(item: bannerView,
                              attribute: .centerX,
                              relatedBy: .equal,
                              toItem: view,
                              attribute: .centerX,
                              multiplier: 1,
                              constant: 0)
          ])
       }
    @IBAction func touchDown_save(_ sender: Any) {
//        var adCount = 0
//        var dataCount = 0
//        let request: NSFetchRequest<SoineData> = SoineData.fetchRequest()
//        let request_ad: NSFetchRequest<SoineData> = SoineData.fetchRequest()
//        do {
//            request.predicate = NSPredicate(format: "adFlg = true")
//            request_ad.predicate = NSPredicate(format: "adFlg = false")
//            var fetchResults = try viewContext.fetch(request)
//            adCount = fetchResults.count
//            fetchResults = try viewContext.fetch(request_ad)
//            dataCount = fetchResults.count
//        }
//        catch  let e as NSError{
//            print("error !!! : \(e)")
//        }
//        
//        if (addAd(dataCount: dataCount, adCount: adCount))
//        {
//            save(adFlag: true)//add ad
//        }
        save(adFlag: false)
        
        //toast start
        let screenSizeWidth = UIScreen.main.bounds.width
        let screenSizeHeight = UIScreen.main.bounds.height
        let offsetY = self.tableView.contentOffset.y
        var hosei = offsetY
        if hosei < 0 {
            hosei = 0
        }
        print("tableview offset y : \(offsetY)")
        self.view.makeToast(String(format: NSLocalizedString("dialog_setting_finished", comment: "")), point: CGPoint(x: screenSizeWidth/2, y: screenSizeHeight/2+hosei), title: nil, image: nil, completion: nil)
        //toast end
        
        delegate?.didPerformAction(from: self)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.dismiss(animated: true, completion: nil)
        }
    }
//    func addAd(dataCount:Int,adCount:Int) -> Bool {
//        let interval = 5
//        let tekiseisu = Int(dataCount/interval)
//        print("adCount : \(adCount),tekiseisu : \(tekiseisu)")
//        return adCount < tekiseisu
//    }
    func save(adFlag:Bool){
//        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
//        let viewContext = appDelegate.persistentContainer.viewContext
        let request: NSFetchRequest<Setting> = Setting.fetchRequest()
        do {
            let fetchResults = try viewContext.fetch(request)
            if let text = intervalLabel.text,
               let integerValue = Int(text),
               let int16Value = Int16(exactly: integerValue) ,
               let text2 = intervalLabel2.text,
               let integerValue2 = Int(text2),
               let int16Value2 = Int16(exactly: integerValue2) {
                if fetchResults.isEmpty {
                    //insert
                    let entity = NSEntityDescription.entity(forEntityName: "Setting", in: viewContext)
                    if let entity = entity {
                        let record = Setting(entity: entity, insertInto: viewContext)
                        record.defaultLifeP1=int16Value
                        record.defaultLifep2=int16Value2
                        record.bgopacity=bgopacity
                    }
                }
                else{
                    //edit
                    for record in fetchResults {
                        if record.defaultLifeP1 != int16Value {
                            SettingsTableViewController.defaultLifeChanged = true
                            record.defaultLifeP1=int16Value
                        }
//                        else{
//                            print("プレイヤー１のデフォルトライフは変わっていない")
//                        }
                        if record.defaultLifep2 != int16Value2 {
                            SettingsTableViewController.defaultLifeChanged = true
                            record.defaultLifep2=int16Value2
                        }
//                        else{
//                            print("プレイヤー２のデフォルトライフは変わっていない")
//                        }
                        record.bgopacity=bgopacity
                    }
                }
            } else {
                // 変換に失敗した場合の処理
                print("Int16への変換に失敗しました")
            }
            try viewContext.save()
            //            appDelegate.saveContext()
        } catch {
        }
//        let request: NSFetchRequest<SoineData> = SoineData.fetchRequest()
//        let request_cat: NSFetchRequest<CategoryData> = CategoryData.fetchRequest()
//        if targetId != nil {
////                request.predicate = NSPredicate(format: "id = \(targetId)")
//            request.predicate = NSPredicate(format: "id = %d", targetId!)
//        }
//        
//        var change = false
//        //create voice data
//        let entity_voice = NSEntityDescription.entity(forEntityName: "VoiceData", in: viewContext)
//        let record_voice = NSManagedObject(entity: entity_voice!, insertInto: viewContext) as! VoiceData
////                record_voice.id = targetId!
//        record_voice.fileData = fileData
//        
//        if selectedRow != 0 {
//            request_cat.predicate = NSPredicate(format: "categoryId = %d", categories[selectedRow - 1].categoryId)
//        }
//        if adFlag && categories.count != 0 {
//            //広告を入れるカテゴリをランダムに決定する
//            var rand = 0
//            
//            do {
//                //フェールセーフ
//                var limit = 30//ランダム値取得制限（データが存在しない）
//                var limit_notExistAd = 10//ランダム値取得制限（広告が存在する）
//                while limit > 0 && limit_notExistAd > 0{
//                    rand = Int.random(in: 0...(categories.count - 1))
//                    let request = SoineData.fetchRequest()
//                    request.predicate = NSPredicate(format: "categoryData.categoryId = %d", categories[rand].categoryId)
//                    let fetchResults = try viewContext.fetch(request)
//                    //データが存在するカテゴリを対象にする
//                    if fetchResults.count != 0 {
//                        let request2: NSFetchRequest<SoineData> = SoineData.fetchRequest()
//                        request2.predicate = NSPredicate(format: "categoryData.categoryId = %d and adFlg = true", categories[rand].categoryId)
//                        let fetchResults2 = try viewContext.fetch(request2)
//                        //広告が存在しないカテゴリを対象にする
//                        if fetchResults2.count == 0 {
//                            break
//                        }
//                        //なければupperを減らして最終的なランダム値が採用される（広告が存在する）
//                        else{
//                            print("loop not exist ad - rand : \(rand)")
//                            limit_notExistAd = limit_notExistAd - 1
//                        }
//                    }
//                    else{
//                        print("loop - rand : \(rand)")
//                        limit = limit - 1
//                    }
//                }
//                if limit <= 0 {
//                    print("ループ上限")
//                }
//                if limit_notExistAd <= 0 {
//                    print("ループ上限　adなし")
//                }
//            } catch  let e as NSError{
//                print("error !!! : \(e)")
//            }
////            rand = Int.random(in: 0...(categories.count - 1))
//            print("rand : \(rand)")
//            request_cat.predicate = NSPredicate(format: "categoryId = %d", categories[rand].categoryId)
//        }
//        do {
//            let fetchResults = try viewContext.fetch(request)
//            let fetchResults_cat = try viewContext.fetch(request_cat)
//            //change
//            if(fetchResults.count != 0 && targetId != nil && !adFlag){
//                change=true
//                for result: AnyObject in fetchResults {
//                    let record = result as! SoineData
//                    record.id = targetId!
//                    
//                    //image
//                    record.picture = imageData
//                    if scale != nil {
//                        record.scale = Float(scale!)
//                    }
//                    
//                    //voice
//                    record.voiceName = fileName
//                    record.voiceFileExtention = fileExtention
//                    record_voice.id = targetId!
//                    record.voiceData = record_voice
//                    record.voiceLoopFlg = loopFlag.isOn
//                    record.voiceLoopCount = Int16(voiceLoopCount)
//                    
//                    //category
//                    if selectedRow == 0 {
//                        record.categoryData = nil
//                    }
//                    else{
//                        record.categoryData = fetchResults_cat[0]
//                    }
//                    
//                }
//                try viewContext.save()
//            }
//            
//            //add
//            //ad - add
//            //ad - change
//            if !change || adFlag {
//                let next_id = Utilities.getNextId(viewContext: viewContext)
//                let soineData = NSEntityDescription.entity(forEntityName: "SoineData", in: viewContext)
//                let record = NSManagedObject(entity: soineData!, insertInto: viewContext) as! SoineData
//                record.id = next_id
//                
//                //image
//                record.picture = imageData
//                if scale != nil {
//                    record.scale = Float(scale!)
//                }
//                
//                //voice
//                record.voiceName = fileName
//                record.voiceFileExtention = fileExtention
//                record_voice.id = next_id
//                record.voiceData = record_voice
//                record.voiceLoopFlg = loopFlag.isOn
//                record.voiceLoopCount = Int16(voiceLoopCount)
//                
//                //category
//                //新規かつ広告でない
//                if selectedRow == 0 && !adFlag {
//                    record.categoryData = nil
//                }
//                else if categories.count != 0 {
//                    record.categoryData = fetchResults_cat[0]
//                }
//                else{
//                    record.categoryData = nil
//                }
//                
//                //ad
//                record.adFlg = adFlag
//                
//                appDelegate.saveContext()
//                
//                if !adFlag {
//                    targetId = next_id
//                }
//            }
//        } catch let e as NSError{
//            print("error !!! : \(e)")
//        }
    }
//    @IBAction func editingChanged_interval(_ sender: Any) {
//    }
//    @IBAction func valueChanged_loopFlg(_ sender: Any) {
//        interval.setNeedsLayout()
//        interval.isEnabled = !loopFlag.isOn
//        intervalLabel.isEnabled = !loopFlag.isOn
//        intervalTitleLabel.isEnabled = !loopFlag.isOn
//        
////        let indexPath = IndexPath(row: 5, section: 0)
////        tableView.reloadRows(at: [indexPath], with: .none)
//    }
    @IBAction func touchDown_close(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func valueChanged_interval(_ sender: Any) {
        let step = Consts.SETTING_DEFAULT_LIFE_STEP
        let roundedValue = round(interval.value / step) * step
        interval.value = roundedValue // スライダーの見た目も補正
        upperLifeP1 = Int(roundedValue)
        intervalLabel.text = "\(upperLifeP1)"
        print("interval value (rounded to 10) : \(roundedValue)")
    }

    @IBAction func valueChanged_interval2(_ sender: Any) {
        let step = Consts.SETTING_DEFAULT_LIFE_STEP
        let roundedValue = round(interval2.value / step) * step
        interval2.value = roundedValue // スライダーの見た目も補正
        upperLifeP2 = Int(roundedValue)
        intervalLabel2.text = "\(upperLifeP2)"
        print("interval2 value (rounded to 10) : \(roundedValue)")
    }
    @IBAction func valueChanged_opacity(_ sender: Any) {
        print("interval2 value : \(interval3.value)")
        bgopacity = Float(round(interval3.value * 10) / 10)
        opacityLabel.text="\(bgopacity)"
    }
    //    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        print("touchesEnded")
//    }
    
//    deinit {
//    // UserDefaultsの変更の監視を解除する
//        NotificationCenter.default.removeObserver(self, name: UserDefaults.didChangeNotification, object: nil)
//    }
}
