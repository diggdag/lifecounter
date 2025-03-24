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
    var datas: [Background] = []
    
    var appDelegate:AppDelegate!
    var viewContext:NSManagedObjectContext!
    var existNonCategorize = false
    
    weak var delegate: ChildViewControllerDelegate?
    @IBOutlet var bannerView: BannerView!
    
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
        //ad start
        bannerView.adUnitID = Consts.ADMOB_UNIT_ID_BGSELECT
        bannerView.rootViewController = self
        //ad end
//        bannerView.backgroundColor=UIColor.green
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("ViewController viewWillAppear")
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        viewContext = appDelegate.persistentContainer.viewContext
        refreshData()
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
        bannerHeight.constant=50*aspect
        bannerView.adSize = inlineAdaptiveBanner(width: viewWidth,maxHeight: 50*aspect)
        let request: Request = Request()
        bannerView.load(request)
    }
    
    func refreshData() {
        datas = []
        let request: NSFetchRequest<Background> = Background.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        let sortDescriptors = [sortDescriptor]
        request.sortDescriptors = sortDescriptors
        do {
            let fetchResults = try viewContext.fetch(request)
            for result: AnyObject in fetchResults {
                let soineData = result as! Background
                datas.append(soineData)
            }
        } catch let e as NSError{
            print("error !!! : \(e)")
        }
        tableView.reloadData()
    }
    @IBAction func touchDown_add(_ sender: Any) {
        //画像を追加するピッカーを起動する
        self.callPhotoLibrary()
    }
}
///////////////////////////
///extentions
/////////////////////////
extension ViewController_image:UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count+1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row==0 {
            let cell: TableViewCell_list_ad = tableView.dequeueReusableCell(withIdentifier: "TableViewCell_list_ad") as! TableViewCell_list_ad
            cell.setCell(unitId: Consts.ADMOB_UNIT_ID_BGSELECT, rootViewController: self)
            return cell
        }
        else{
            let soineData: Background = datas[indexPath.row-1]
            let cell: TableViewCell_list = tableView.dequeueReusableCell(withIdentifier: "TableViewCell_list") as! TableViewCell_list
            let image:UIImage = soineData.picture == nil ? UIImage() : UIImage(data: soineData.picture!)!
            cell.setCell(data: Data_list(category: image, scale: CGFloat(soineData.scale)))//\(String(soineData.id)):
            cell.backgroundColor = UIColor.clear
            cell.contentView.backgroundColor = UIColor.clear
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
                    let request: NSFetchRequest<Background> = Background.fetchRequest()
                    request.predicate = NSPredicate(format: "id = %d", self.datas[indexPath.row-1].id)
                    do{
                        let fetchResults = try viewContext.fetch(request)
                        viewContext.delete(fetchResults[0])
                        try viewContext.save()
                    } catch let e as NSError{
                        print("error !!! : \(e)")
                    }
                    
                    let screenSizeWidth = UIScreen.main.bounds.width
                    let screenSizeHeight = UIScreen.main.bounds.height
                    self.view.makeToast("削除しました", point: CGPoint(x: screenSizeWidth/2, y: screenSizeHeight/2), title: nil, image: nil, completion: nil)
                    
                    self.refreshData()
                }
            )
            alert.addAction(cancelAction)
            alert.addAction(defaultAction)
            self.present(alert, animated: true, completion: nil)
        }
        swipeCell.backgroundColor = .red
        return [swipeCell]
    }
}
extension ViewController_image:UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        let request: NSFetchRequest<Background> = Background.fetchRequest()
        let p1selected = (Player.player1 == ViewController.selected)
        do {
            let fetchResults = try viewContext.fetch(request)
            if(fetchResults.count != 0){
                for result: AnyObject in fetchResults {
                    let record = result as! Background
                    var newPlayer = record.player
                    let pNum:Int16 = (p1selected ? 1 : 2)
                    let pNumReverse:Int32 = (p1selected ? 2 : 1)
                    
                    if record.id == datas[indexPath.row-1].id {
                        if record.player == 0{//nil
                            newPlayer += pNum
                        }
                        else if record.player == pNum{//me
                        }
                        else if record.player == pNumReverse{//you
                            newPlayer = 3
                        }
                        else if record.player == 3{//both
                        }
                    }
                    else{
                        if record.player == 0{//nil
                        }
                        else if record.player == pNum{//me
                            newPlayer -= pNum
                        }
                        else if record.player == pNumReverse{//you
                        }
                        else if record.player == 3{//both
                            newPlayer -= pNum
                        }
                    }
                    print("id:\(record.id) newPlayer:\(newPlayer)")
                    record.setValue(newPlayer, forKey: "player")
                    
                    try viewContext.save()
                }
            }
        } catch {
        }
        delegate?.didPerformAction(from: self)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.dismiss(animated: true, completion: nil)
        }
    }
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
            let request: NSFetchRequest<Background> = Background.fetchRequest()
            request.predicate = NSPredicate(format: "id = %d", datas[indexPath.row-1].id)
            do{
                let fetchResults = try viewContext.fetch(request)
                viewContext.delete(fetchResults[0])
                try viewContext.save()
            } catch let e as NSError{
                print("error !!! : \(e)")
            }
            
            let screenSizeWidth = UIScreen.main.bounds.width
            let screenSizeHeight = UIScreen.main.bounds.height
            self.view.makeToast(String(format: NSLocalizedString("dialog_delete_finished", comment: "")), point: CGPoint(x: screenSizeWidth/2, y: screenSizeHeight/2), title: nil, image: nil, completion: nil)
            
            refreshData()
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
