//
//  ViewController.swift
//  soine
//
//  Created by 倉知諒 on 2022/04/22.
//

import UIKit
import Photos
import CoreData
import Toast_Swift
import GoogleMobileAds

class ViewController_image: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    var datas: [Any] = []
    
    var appDelegate:AppDelegate!
    var viewContext:NSManagedObjectContext!
    var existNonCategorize = false
    
    weak var delegate: ChildViewControllerDelegate?
    
    @IBOutlet var bannerHeight: NSLayoutConstraint!
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ViewController viewDidLoad")
        
        //写真アクセス許可
        if #available(iOS 14, *) {
            let accessLebel:PHAccessLevel = .readWrite
            PHPhotoLibrary.requestAuthorization(for: accessLebel){status in
                DispatchQueue.main.async() {
                }
            }
            //            PHPhotoLibrary.authorizationStatus(for: accessLebel)
        }
        else {
            // Fallback on earlier versions
            PHPhotoLibrary.requestAuthorization(){status in
                DispatchQueue.main.async() {
                }
            }
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        presentationController?.delegate=self
        
        let backButton = UIBarButtonItem()
        //        backButton.title = "もどる"
        navigationItem.backBarButtonItem = backButton
        
        // In this case, we instantiate the banner with desired ad size.
        //        settingAd()
//        bannerView.backgroundColor=UIColor.green
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("ViewController viewWillAppear")
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        viewContext = appDelegate.persistentContainer.viewContext
        refreshData()
    }
    
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to:size, with:coordinator)
    }
    func refreshData() {
        datas = []
        
        let request: NSFetchRequest<Background> = Background.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        
        do {
            let fetchResults = try viewContext.fetch(request)
            datas.append(contentsOf: fetchResults) // Core Data のデータを取得
        } catch {
            print("error !!! : \(error)")
        }
        
        // 広告用データ（AdAccount の struct を使用）
        let adBackground = AdAccount(name: "PR", adFlg: true)
        
        // 一定間隔ごとに広告を追加
        var count = 0
        var updatedDatas: [Any] = []
        
        updatedDatas.append(adBackground)
        for data in datas {
            updatedDatas.append(data)
            count += 1
            if count % Consts.LIST_AD_INTERVAL == 0 {
                updatedDatas.append(adBackground)
            }
        }
        
        datas = updatedDatas
        tableView.reloadData()
    }

    @IBAction func touchDown_add(_ sender: Any) {
        //画像を追加するピッカーを起動する
        self.callPhotoLibrary()
    }
    //グローバル変数の画像の配列をアップデートする（画像が選択されていない状態にする）
    //　player1:player1に選択されていない状態にしたい場合true
    func dataUpdate_noItem(player1:Bool) {
        for data in self.datas {
            if data is Background {
                let _data = data as! Background
                if player1 {
                    if _data.player == 1 || _data.player == 3 {
                        _data.player -= 1
                    }
                }
                else{
                    if _data.player == 2 || _data.player == 3 {
                        _data.player -= 2
                    }
                }
            }
        }
    }
    @IBAction func touchDown_apply(_ sender: Any) {
        delegate?.didPerformAction(from: self)
        self.dismiss(animated: true, completion: nil)
    }
}
///////////////////////////
///extentions
/////////////////////////
extension ViewController_image:UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if datas[indexPath.row] is Background {
            let background: Background = datas[indexPath.row] as! Background
            let cell: TableViewCell_list = tableView.dequeueReusableCell(withIdentifier: "TableViewCell_list") as! TableViewCell_list
            let image:UIImage = background.picture == nil ? UIImage() : UIImage(data: background.picture!)!
            let p1On = background.player == 1 || background.player == 3
            let p2On = background.player == 2 || background.player == 3
            var dataList = Data_list(category: image, scale: CGFloat(background.scale), p1: p1On, p2: p2On)
            cell.setCell(data: dataList) { index, p1, p2 in
                print("Row \(index) - player1: \(p1), player2: \(p2)")
                let p1valueChanged = p1On == !p1
                let p2valueChanged = p2On == !p2
                print("p1On: \(p1On), p2On: \(p2On)")
                print("p1valueChanged: \(p1valueChanged), p2valueChanged: \(p2valueChanged)")
                if p1valueChanged{
                    //一旦リセット
                    self.dataUpdate_noItem(player1: true)
                    if p1 {
                        background.player += 1
                    }
                }
                if p2valueChanged{
                    //一旦リセット
                    self.dataUpdate_noItem(player1: false)
                    if p2 {
                        background.player += 2
                    }
                }
                self.tableView.reloadData()
                //                        self.dataList[index].p1 = p1
                //                        self.dataList[index].p2 = p2
            }
            cell.backgroundColor = UIColor.clear
            cell.contentView.backgroundColor = UIColor.clear
            
            return cell
        }
        else{
            
            let cell: TableViewCell_list_ad = tableView.dequeueReusableCell(withIdentifier: "TableViewCell_list_ad") as! TableViewCell_list_ad
            cell.setCell(unitId: Consts.ADMOB_UNIT_ID_BGSELECT, rootViewController: self)
            return cell
        }
    }
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let swipeCell = UITableViewRowAction(style: .default, title: NSLocalizedString("deleteBtn_title", comment: "")) { (action: UITableViewRowAction, index: IndexPath) in
            
            let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
            let viewContext = appDelegate.persistentContainer.viewContext
            
            let alert: UIAlertController = UIAlertController(title: NSLocalizedString("confirm_title", comment: ""),
                                                             message: String(format: NSLocalizedString("confirm_sentence_delete", comment: "")),
                                                             preferredStyle: UIAlertController.Style.alert)
            let cancelAction: UIAlertAction = UIAlertAction(
                title: "No",
                style: UIAlertAction.Style.cancel,
                handler: {
                    (action: UIAlertAction!) -> Void in
                }
            )
            let defaultAction: UIAlertAction = UIAlertAction(
                title: "Yes",
                style: UIAlertAction.Style.default,
                handler: {
                    (action: UIAlertAction!) -> Void in
                    self.deleteItem(at: index)
                }
            )
            alert.addAction(cancelAction)
            alert.addAction(defaultAction)
            self.present(alert, animated: true, completion: nil)
        }
        swipeCell.backgroundColor = .red
        return [swipeCell]
    }
    func deleteItem(at indexPath: IndexPath) {
        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let viewContext = appDelegate.persistentContainer.viewContext

        let request: NSFetchRequest<Background> = Background.fetchRequest()
        request.predicate = NSPredicate(format: "id = %d", (self.datas[indexPath.row] as! Background).id)

        do {
            let fetchResults = try viewContext.fetch(request)
            if let target = fetchResults.first {
                viewContext.delete(target)
                try viewContext.save()
            }
        } catch let e as NSError {
            print("error !!! : \(e)")
        }

        let screenSizeWidth = UIScreen.main.bounds.width
        let screenSizeHeight = UIScreen.main.bounds.height
        self.view.makeToast(NSLocalizedString("dialog_delete_finished", comment: ""),
                            point: CGPoint(x: screenSizeWidth/2, y: screenSizeHeight/2),
                            title: nil,
                            image: nil,
                            completion: nil)

        refreshData()
    }

}
extension ViewController_image:UITableViewDelegate{
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if tableView.isEditing {
            return .delete
        }
        return .none
    }
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.deleteItem(at: indexPath)
        }
    }
}
extension ViewController_image:UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    
    //フォトライブラリを呼び出すメソッド
    func callPhotoLibrary(){
        //権限の確認
        self.requestAuthorizationOn()
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
            
            let picker = UIImagePickerController()
            picker.modalPresentationStyle = UIModalPresentationStyle.popover
            picker.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
            picker.sourceType = UIImagePickerController.SourceType.photoLibrary
            //以下を設定することで、写真選択後にiOSデフォルトのトリミングViewが開くようになる
            picker.allowsEditing = true
            if let popover = picker.popoverPresentationController {
                popover.sourceView = self.view
                popover.sourceRect = self.view.frame // ポップオーバーの表示元となるエリア
                popover.permittedArrowDirections = UIPopoverArrowDirection.any
            }
            self.present(picker, animated: true, completion: nil)
        }
    }
    // 写真へのアクセスがOFFのときに使うメソッド
    func requestAuthorizationOn(){
        var status:PHAuthorizationStatus
        if #available(iOS 14, *) {
            let accessLebel:PHAccessLevel = .addOnly
            status = PHPhotoLibrary.authorizationStatus(for: accessLebel)
        } else {
            // Fallback on earlier versions
            status = PHPhotoLibrary.authorizationStatus()
        }
        // authorization
        if (status != .authorized) {
            //            if (status == PHAuthorizationStatus.denied) {
            //アクセス不能の場合。アクセス許可をしてもらう。snowなどはこれを利用して、写真へのアクセスを禁止している場合は先に進めないようにしている。
            //アラートビューで設定変更するかしないかを聞く
            let alert = UIAlertController(title: NSLocalizedString("PhotoAuthAlert_title", comment: ""),
                                          message: NSLocalizedString("PhotoAuthAlert_messsage", comment: ""),
                                          preferredStyle: .alert)
            let settingsAction = UIAlertAction(title: NSLocalizedString("PhotoAuthAlert_button_1", comment: ""), style: .default) { (_) -> Void in
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString ) else {
                    return
                }
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            }
            alert.addAction(settingsAction)
            alert.addAction(UIAlertAction(title: NSLocalizedString("PhotoAuthAlert_button_cancel", comment: ""), style: .cancel) { _ in
                // ダイアログがキャンセルされた。つまりアクセス許可は得られない。
            })
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
        //        let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
        //        let viewContext = appDelegate.persistentContainer.viewContext
        if let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            let request: NSFetchRequest<Background> = Background.fetchRequest()
            var predicate:NSPredicate
            //            // スクリーンの縦横サイズを取得
            //            let playerViewWidth:CGFloat = playerView.frame.size.width
            //            let playerViewHeight:CGFloat = playerView.frame.size.height
            //
            //            // 画像の縦横サイズを取得
            //            let imgWidth:CGFloat = setImage.size.width
            //            let imgHeight:CGFloat = setImage.size.height
            // スクリーンの縦横サイズを取得
            let scale:CGFloat
            if let someVC = AppManager.shared.viewController {
                //                let playerViewWidth:CGFloat = p1bg.frame.size.width
                let playerViewWidth:CGFloat = someVC.p1bg.frame.width
                //            let playerViewHeight:CGFloat = player1view.frame.size.height
                
                // 画像の縦横サイズを取得
                let imgWidth:CGFloat = pickedImage.size.width
                //            let imgHeight:CGFloat = pickedImage.size.height
                
                scale = playerViewWidth / imgWidth
            } else {
                scale = 1.0
            }
            let background = NSEntityDescription.entity(forEntityName: "Background", in: viewContext)
            let newRecord = NSManagedObject(entity: background!, insertInto: viewContext)
            let next_id = Utilities.getNextId(viewContext: viewContext)
            print("nextId:\(next_id)")
            newRecord.setValue(next_id, forKey: "id")
            newRecord.setValue(pickedImage.pngData(), forKey: "picture")
            newRecord.setValue(scale, forKey: "scale")
            appDelegate.saveContext()
            self.dismiss(animated: true, completion: nil)
            refreshData()
        }
    }
}
extension ViewController_image:UIAdaptivePresentationControllerDelegate{
    // モーダルが閉じられたときに呼ばれるメソッド
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        print("モーダルビューが閉じられました")
        // ここで閉じられた後の処理を行う
        delegate?.didPerformAction(from: self)
    }
}
