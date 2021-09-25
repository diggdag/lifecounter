//
//  ViewController.swift
//  lifeCounter
//
//  Created by 倉知諒 on 2019/06/04.
//  Copyright © 2019 kurachi. All rights reserved.
//

import UIKit
import Photos
import CoreData

class ViewController: UIViewController ,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UITableViewDelegate, UITableViewDataSource{
    

    @IBOutlet weak var player1view: UIView!
    @IBOutlet weak var player2view: UIView!
    @IBOutlet weak var startBtn: UIButton!
    @IBOutlet weak var clearBtn: CustomBtn!
    @IBOutlet weak var settingBtn: UIButton!
    @IBOutlet weak var life1: UILabel!
    @IBOutlet weak var life2: UILabel!
    @IBOutlet weak var time1: UILabel!
    @IBOutlet weak var time2: UILabel!
    @IBOutlet weak var time_master: UILabel!
    @IBOutlet weak var timerSw: UISwitch!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lifeflow_width: NSLayoutConstraint!
    var lifeflow_lifes = [[Int]]()
    
    var _life1 :Int=20
    var _life2 : Int=20
    
//    var timer1:Timer?
//    var timer2:Timer?
    var timer_master:Timer?
    
//    var passMin:Int = 0
    var passMin_master:Int = 0
    let formatter = DateComponentsFormatter()
    var gameStatus:GameStatus = GameStatus.ready
    var currentPlayer : Player!
    var selected : Player!
    
    var appDelegate:AppDelegate!
    var viewContext:NSManagedObjectContext!
    var countDownCnt:Countdown = Countdown.three
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        //受信設定
        NotificationCenter.default.addObserver(self, selector: #selector(notificationFunc_pushhome(notification:)), name: .notificationName, object: nil)
        
        // Do any additional setup after loading the view.
        player2view.transform=CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        startBtn.imageView?.contentMode = .scaleAspectFit
        startBtn.contentHorizontalAlignment = .fill
        startBtn.contentVerticalAlignment = .fill
        clearBtn.imageView?.contentMode = .scaleAspectFit
        clearBtn.contentHorizontalAlignment = .fill
        clearBtn.contentVerticalAlignment = .fill
        settingBtn.imageView?.contentMode = .scaleAspectFit
        settingBtn.contentHorizontalAlignment = .fill
        settingBtn.contentVerticalAlignment = .fill
        
//        formatter.unitsStyle = .positional
//        formatter.allowedUnits = [.minute,.hour,.second]
        formatter.unitsStyle = .brief
        formatter.allowedUnits = [.minute, .second]
        
        setBackground_init()
        setMasterSetting_init()
        self.setNeedsStatusBarAppearanceUpdate()
        
        tableView?.dataSource = self
        tableView?.delegate = self
        timeHiddenRefresh()
    }
    @objc func notificationFunc_pushhome(notification: NSNotification?) {
        print("called! notificationFunc_pushhome")
        //画面初期化
        screenInitialize([])
    }
//    override func viewWillAppear(_ animated: Bool) {
//        print("viewwillappear!!!!!!")
//
//        settingBtn.setImage(UIImage(named: "setting" + (UITraitCollection.isDarkMode ? "n" : "d")), for: .normal)
//        startBtn.setImage(UIImage(named: "start" + (UITraitCollection.isDarkMode ? "n" : "d")), for: .normal)
//        clearBtn.setImage(UIImage(named: "restart" + (UITraitCollection.isDarkMode ? "n" : "d")), for: .normal)
//    }
    //背景設定初期メソッド（DBから読み込む）
    func setBackground_init()  {
        var player1Img:UIImage? = nil
        var player2Img:UIImage? = nil
        var scale1:CGFloat = CGFloat(1)
        var scale2:CGFloat = CGFloat(1)
        
        
//        let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
//        let viewContext = appDelegate.persistentContainer.viewContext
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        viewContext = appDelegate.persistentContainer.viewContext
        
        let query: NSFetchRequest<Background> = Background.fetchRequest()
        
        do {
            let fetchResults = try viewContext.fetch(query)
            if fetchResults.count != 0 {
                for result: AnyObject in fetchResults {
                    let player: Int16 = result.value(forKey: "player") as! Int16
                    
                    if player==1 {
                        player1Img=UIImage(data: result.value(forKey: "picture") as! Data)
                        scale1 = result.value(forKey: "scale") as! CGFloat
                    }
                    else if player==2 {
                        player2Img=UIImage(data: result.value(forKey: "picture") as! Data)
                        scale2 = result.value(forKey: "scale") as! CGFloat
                    }
                }
            }
            self.settingBackground(playerView: &player1view, setImage: player1Img ?? UIImage(),scale: scale1,initial: true)
            self.settingBackground(playerView: &player2view, setImage: player2Img ?? UIImage(),scale: scale2,initial: true)
        } catch {
        }
    }
    func setMasterSetting_init()  {
        let query: NSFetchRequest<Setting> = Setting.fetchRequest()
        do {
            let fetchResults = try viewContext.fetch(query)
            if fetchResults.count != 1 {
                setRecodeSw(isOn: false)
            }
            else{
                setRecodeSw(isOn: (fetchResults[0] as Setting).recode)
            }
//            for result: AnyObject in fetchResults {
//                let game = result as! Game
//                games.append(game)
//            }
        } catch {
        }
    }
    func setRecodeSw(isOn:Bool)  {
        timerSw.isOn=isOn
    }
    override var prefersStatusBarHidden: Bool{
        return true
    }
    @IBAction func timerSwValueChanged(_ sender: Any) {
        timeHiddenRefresh()
        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let viewContext = appDelegate.persistentContainer.viewContext
        
        //delete
        let request: NSFetchRequest<Setting> = Setting.fetchRequest()
        do {
            let fetchResults = try viewContext.fetch(request)
            for result: AnyObject in fetchResults {
                let record = result as! NSManagedObject
                viewContext.delete(record)
            }
            try viewContext.save()
        } catch {
        }
        
        //insert
        let entity = NSEntityDescription.entity(forEntityName: "Setting", in: viewContext)
        let recode = NSManagedObject(entity: entity!, insertInto: viewContext) as! Setting
        recode.recode=timerSw.isOn
        appDelegate.saveContext()
        
        //select
        let query: NSFetchRequest<Setting> = Setting.fetchRequest()
        do {
            let fetchResults = try viewContext.fetch(query)
            let setting = fetchResults[0] as Setting
            setRecodeSw(isOn: setting.recode)
        } catch {
        }
        
    }
    func timeHiddenRefresh()  {
//        time1.isHidden = !timerSw.isOn
//        time2.isHidden = !timerSw.isOn
        time1.isHidden = true
        time2.isHidden = true
        startBtn.isHidden = !timerSw.isOn
        clearBtn.isHidden = !timerSw.isOn
        lifeflow_width.constant=timerSw.isOn ? 80 : 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lifeflow_lifes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let lifes:[Int] = lifeflow_lifes[indexPath.row]
        let cell: TableViewCell_lifeflow = tableView.dequeueReusableCell(withIdentifier: "TableViewCell_lifeflow") as! TableViewCell_lifeflow
        cell.setCell(data: Data_lifeflow(p1life: lifes[0], p2life: lifes[1]))
        return cell
    }
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//    }
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let swipeCell = UITableViewRowAction(style: .default, title: NSLocalizedString("deleteBtn_title", comment: "")) { action, index in
            self.lifeflow_lifes.remove(at: indexPath.row)
            tableView.reloadData()
        }
        swipeCell.backgroundColor = .red
        return [swipeCell]
    }
    @IBAction func touchDown_startBtn(_ sender: Any) {
        switch gameStatus {
        case .ready:
            
            //ちょいバック回転(回転と言うよりはそれになるといった感じ。pi / 2   は画像の初期位置を0としてそれから45°き回転させた位置)
            let random = Int.random(in: 1 ... 10)
            startBtn.setImage(UIImage(named:"pause"), for: .normal)
            if random % 2 == 0 {
//                timer2 = Timer.scheduledTimer(timeInterval: 1.0,target: self, selector:  #selector(self.timerFunc2),userInfo: nil, repeats: true)
                currentPlayer = .player2
            }
            else{
//                timer1 = Timer.scheduledTimer(timeInterval: 1.0,target: self, selector:  #selector(self.timerFunc),userInfo: nil, repeats: true)
                currentPlayer = .player1
            }
            timer_master = Timer.scheduledTimer(timeInterval: 1.0,target: self, selector:  #selector(self.timerFunc_master),userInfo: nil, repeats: true)
            gameStatus = .playing
            
        case .playing:
            startBtn.setImage(UIImage(named:"start"), for: .normal)
//            if Player.player1 == currentPlayer{
//                if timer1 != nil{
//                    timer1!.invalidate()
//                }
//            }
//            else{
//                if timer2 != nil{
//                    timer2!.invalidate()
//                }
//            }
            if timer_master != nil{
                timer_master!.invalidate()
            }
            gameStatus = .stop
        case .stop:
            startBtn.setImage(UIImage(named:"pause"), for: .normal)
//            if Player.player1 == currentPlayer{
//                timer1 = Timer.scheduledTimer(timeInterval: 1.0,target: self, selector:  #selector(self.timerFunc),userInfo: nil, repeats: true)
//            }
//            else{
//                timer2 = Timer.scheduledTimer(timeInterval: 1.0,target: self, selector:  #selector(self.timerFunc2),userInfo: nil, repeats: true)
//            }
            timer_master = Timer.scheduledTimer(timeInterval: 1.0,target: self, selector:  #selector(self.timerFunc_master),userInfo: nil, repeats: true)
            gameStatus = .playing
        }
    }
    @IBAction func touchDown_clearBtn(_ sender: Any) {
        
        let t:CGFloat = 1.0
        self.clearBtn.spinAnim(self.clearBtn,t)
        
        //ちょいバック回転(回転と言うよりはそれになるといった感じ。pi / 2 は画像の初期位置を0としてそれから45°き回転させた位置)
//        UIView.animate(withDuration: 0.5 / 2) { () -> Void in
//            self.startBtn.transform = CGAffineTransform(rotationAngle:  0)
//        }
        lifeReset()
        if timerSw.isOn {
            saveGame()
        }
        
//        passMin = 0//経過時間
        //画面初期化
        screenInitialize(sender)
        timerSwValueChanged(sender)
    }
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        //画面初期化
//        screenInitialize([])
//    }
    func screenInitialize(_ sender: Any)  {
        passMin_master = 0//経過時間
        updateDisp(passMin: &passMin_master ,time:time_master)
        
    //        time1.text = formatter.string(from: TimeInterval(0))!
    //        time2.text = formatter.string(from: TimeInterval(0))!
    //        if timer1 != nil{
    //            timer1!.invalidate()
    //        }
    //        if timer2 != nil{
    //            timer2!.invalidate()
    //        }
        if timer_master != nil{
            timer_master!.invalidate()
        }
        lifeflow_lifes.removeAll()
        tableView.reloadData()
        startBtn.setImage(UIImage(named:"start"), for: .normal)
    //        startBtn.setImage(UIImage(named:"start" + (UITraitCollection.isDarkMode ? "n" : "d")), for: .normal)
        gameStatus = .ready
    //        timerSw.isOn=false
    }
    
    func saveGame()  {
        let gameEntity = NSEntityDescription.entity(forEntityName: "Game", in: viewContext)
        let gameRecode = NSManagedObject(entity: gameEntity!, insertInto: viewContext) as! Game
        gameRecode.gameDate=Date()
        gameRecode.time=time_master.text

        for (index,lifes) in lifeflow_lifes.enumerated() {
            for (index_life,life) in lifes.enumerated() {
                let lifeEntity = NSEntityDescription.entity(forEntityName: "Life", in: viewContext)
                let lifeRecode = NSManagedObject(entity: lifeEntity!, insertInto: viewContext) as! Life
                lifeRecode.player=Int16(index_life)
                lifeRecode.stage=Int16(index)
                lifeRecode.life=Int16(life)
                lifeRecode.game = gameRecode
            }
        }
        appDelegate.saveContext()
    }
    @IBAction func touchDown_settingBtn(_ sender: Any) {
        
        // ①UIAlertControllerクラスのインスタンスを生成する
        // titleにタイトル, messegeにメッセージ, prefereedStyleにスタイルを指定する
        // preferredStyleにUIAlertControllerStyle.actionSheetを指定してアクションシートを表示する
        let actionSheet: UIAlertController = UIAlertController(
            title: NSLocalizedString("bgAlert_title", comment: ""),
            message: NSLocalizedString("bgAlert_messsage", comment: ""),
            preferredStyle: UIAlertController.Style.actionSheet)
        
        // ②選択肢の作成と追加
        // titleに選択肢のテキストを、styleに.defaultを
        // handlerにボタンが押された時の処理をクロージャで実装する
        actionSheet.addAction(
            UIAlertAction(title: NSLocalizedString("bgAlert_button_set_1", comment: ""),style: .default, handler: {
                            (action: UIAlertAction!) -> Void in
                            self.selected = .player1
                            self.callPhotoLibrary()
            })
        )
        
        // ②選択肢の作成と追加
        actionSheet.addAction(
            UIAlertAction(title: NSLocalizedString("bgAlert_button_set_2", comment: ""), style: .default, handler: {
                (action: UIAlertAction!) -> Void in
                self.selected = .player2
                self.callPhotoLibrary()
            })
        )
        actionSheet.addAction(
            UIAlertAction(title: NSLocalizedString("bgAlert_button_del_1", comment: ""), style: .default, handler: {
                (action: UIAlertAction!) -> Void in
                self.deleteImg(player: Player.player1)
                self.setBackground_init()
            })
        )
        actionSheet.addAction(
            UIAlertAction(title: NSLocalizedString("bgAlert_button_del_2", comment: ""), style: .default, handler: {
                (action: UIAlertAction!) -> Void in
                self.deleteImg(player: Player.player2)
                self.setBackground_init()
            })
        )
        
        // ②選択肢の作成と追加
        actionSheet.addAction(
            UIAlertAction(title: NSLocalizedString("bgAlert_button_cancel", comment: ""), style: .cancel, handler: nil)
        )
        
        // ③表示するViewと表示位置を指定する
        actionSheet.popoverPresentationController?.sourceView = view
        actionSheet.popoverPresentationController?.sourceRect = (sender as AnyObject).frame
        
        // ④アクションシートを表示
        present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func touchDown_dice6(_ sender: Any) {
        ViewController_popup.dispDiceImage = getDiceImage(type: DiceType.six)
        performSegue(withIdentifier: "toPopUp", sender: nil)
    }
    func deleteImg(player:Player)  {
        let request: NSFetchRequest<Background> = Background.fetchRequest()
        let predicate = NSPredicate(format: "player = \(Player.player1==player ? "1" : "2")")

        request.predicate = predicate
        do {
            let fetchResults = try viewContext.fetch(request)
            for result: AnyObject in fetchResults {
                let record = result as! NSManagedObject
                viewContext.delete(record)
            }
            try viewContext.save()
        } catch {
        }
    }
    func lifeReset(){
        let life:Int = 20
        //player1
        if _life1<life{
            for _ in 0..<abs(life-_life1) {
                lifeIncrement(.player1)
            }
        }
        else{
            for _ in 0..<abs(life-_life1) {
                lifeDecrement(.player1)
            }
        }
        //player2
        if _life2<life{
            for _ in 0..<abs(life-_life2) {
                lifeIncrement(.player2)
            }
        }
        else{
            for _ in 0..<abs(life-_life2) {
                lifeDecrement(.player2)
            }
        }
    }
    
//    @IBAction func end(_ sender: Any){
//        if GameStatus.playing == gameStatus{
//            passMin = 0
//            if Player.player1 == currentPlayer {
//                if timer1 != nil{
//                    timer1!.invalidate()
//                }
//                timer2 = Timer.scheduledTimer(timeInterval: 1.0,target: self, selector:     #selector(self.timerFunc2),userInfo: nil, repeats: true)
//                time2.text = formatter.string(from: TimeInterval(0))!
//            }
//            else{
//                if timer2 != nil{
//                    timer2!.invalidate()
//                }
//                timer1 = Timer.scheduledTimer(timeInterval: 1.0,target: self, selector:     #selector(self.timerFunc),userInfo: nil, repeats: true)
//                time1.text = formatter.string(from: TimeInterval(0))!
//            }
//            currentPlayer = Player.player1 == currentPlayer ? .player2 : .player1
////            recodeLife()
//        }
//    }
    
//    @objc func timerFunc()  {
//        updateDisp(passMin: &passMin ,time:time1)
//    }
//    @objc func timerFunc2()  {
//        updateDisp(passMin: &passMin ,time:time2)
//    }
    @objc func timerFunc_master()  {
        updateDisp(passMin: &passMin_master ,time:time_master)
        countDown()
        if countDownCnt == .zero {
            recodeLife()
        }
    }
    
    func updateDisp(passMin:inout Int,time : UILabel)  {
        time.text = formatter.string(from: TimeInterval(Double(passMin)))!
        passMin = passMin + 1
    }
    func recodeLife()  {
//        print("life recode")
        //前のライフと同じ場合記録しない
        if lifeflow_lifes.count != 0
            && lifeflow_lifes[lifeflow_lifes.count-1][0] == _life1
            && lifeflow_lifes[lifeflow_lifes.count-1][1] == _life2
        {
            print("life recode return")
            return
        }
//        var test :[[Int]]
//        test.append([1,2])
        
        lifeflow_lifes.append([_life1,_life2])
        for lifes in lifeflow_lifes {
            print("add! p1 : \(lifes[0]) , p2 : \(lifes[1])")
        }
        tableView.reloadData()
    }
    @IBAction func touchDown_plusBtn1(_ sender: Any) {
        lifeIncrement(.player1)
    }
    @IBAction func touchDown_centerPlusBtn1(_ sender: Any) {
//        if GameStatus.ready == gameStatus ||
//            GameStatus.stop == gameStatus ||
//            !timerSw.isOn{
            lifeIncrement(.player1)
//        }
//        else{
//            end(sender)
//        }
    }
    @IBAction func touchDown_plusBtn2(_ sender: Any) {
        lifeIncrement(.player2)
    }
    @IBAction func touchDown_centerPlusBtn2(_ sender: Any) {
//        if GameStatus.ready == gameStatus ||
//            GameStatus.stop == gameStatus ||
//            !timerSw.isOn {
            lifeIncrement(.player2)
//        }
//        else{
//            end(sender)
//        }
    }
    @IBAction func touchDown_minusBtn1(_ sender: Any) {
        lifeDecrement(.player1)
    }
    @IBAction func touchDown_centerMinusBtn1(_ sender: Any) {
//        if GameStatus.ready == gameStatus ||
//            GameStatus.stop == gameStatus ||
//            !timerSw.isOn {
            lifeDecrement(.player1)
//        }
//        else{
//            end(sender)
//        }
    }
    @IBAction func touchDown_minusBtn2(_ sender: Any) {
        lifeDecrement(.player2)
    }
    @IBAction func touchDown_centerMinusBtn2(_ sender: Any) {
//        if GameStatus.ready == gameStatus ||
//            GameStatus.stop == gameStatus ||
//            !timerSw.isOn {
            lifeDecrement(.player2)
//        }
//        else{
//            end(sender)
//        }
    }
    enum Player {
        case player1
        case player2
    }
    enum GameStatus{
        case ready
        case playing
        case stop
    }
    enum DiceType {
        case six
        case twenty
    }
    enum Countdown {
        case three
        case two
        case one
        case zero
    }
    func lifeIncrement(_ p:Player){
        switch p {
        case .player1:
            _life1 += 1
            life1.text = String(_life1)
        case .player2:
            _life2 += 1
            life2.text = String(_life2)
        }
    }
    func lifeDecrement(_ p:Player)   {
        switch p {
        case .player1:
            _life1 -= 1
            life1.text = String(_life1)
        case .player2:
            _life2 -= 1
            life2.text = String(_life2)
        }
    }
    // 写真へのアクセスがOFFのときに使うメソッド
    func requestAuthorizationOn(){
        // authorization
        let status = PHPhotoLibrary.authorizationStatus()
        if (status == PHAuthorizationStatus.denied) {
            //アクセス不能の場合。アクセス許可をしてもらう。snowなどはこれを利用して、写真へのアクセスを禁止している場合は先に進めないようにしている。
            //アラートビューで設定変更するかしないかを聞く
            let alert = UIAlertController(title: "写真へのアクセスを許可",
                                          message: "写真へのアクセスを許可する必要があります。設定を変更してください。",
                                          preferredStyle: .alert)
            let settingsAction = UIAlertAction(title: "設定変更", style: .default) { (_) -> Void in
                guard let _ = URL(string: UIApplication.openSettingsURLString ) else {
                    return
                }
            }
            alert.addAction(settingsAction)
            alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel) { _ in
                // ダイアログがキャンセルされた。つまりアクセス許可は得られない。
            })
            self.present(alert, animated: true, completion: nil)
        }
    }
    //フォトライブラリを呼び出すメソッド
    func callPhotoLibrary(){
        //権限の確認
        requestAuthorizationOn()
        
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
    func countDown() {
        switch countDownCnt {
        case .three:
            countDownCnt = .two
        case .two:
            countDownCnt = .one
        case .one:
            countDownCnt = .zero
        case .zero:
            countDownCnt = .three
        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
//        let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
//        let viewContext = appDelegate.persistentContainer.viewContext
        if let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            let request: NSFetchRequest<Background> = Background.fetchRequest()
            var predicate:NSPredicate
            let p1selected = (Player.player1 == self.selected)
//            // スクリーンの縦横サイズを取得
//            let playerViewWidth:CGFloat = playerView.frame.size.width
//            let playerViewHeight:CGFloat = playerView.frame.size.height
//
//            // 画像の縦横サイズを取得
//            let imgWidth:CGFloat = setImage.size.width
//            let imgHeight:CGFloat = setImage.size.height
            // スクリーンの縦横サイズを取得
            let playerViewWidth:CGFloat = player1view.frame.size.width
//            let playerViewHeight:CGFloat = player1view.frame.size.height
            
            // 画像の縦横サイズを取得
            let imgWidth:CGFloat = pickedImage.size.width
//            let imgHeight:CGFloat = pickedImage.size.height
            
            let scale:CGFloat = playerViewWidth / imgWidth
            
            predicate = NSPredicate(format: "player = " + (p1selected ? "1" : "2"))
            request.predicate = predicate
            
            var change = false
            
            //change
            do {
                let fetchResults = try viewContext.fetch(request)
                if(fetchResults.count != 0){
                    change=true
                    for result: AnyObject in fetchResults {
                        let record = result as! NSManagedObject
                        record.setValue((p1selected ? 1 : 2), forKey: "player")
                        record.setValue(pickedImage.pngData(), forKey: "picture")
                        record.setValue(scale, forKey: "scale")
                    }
                    try viewContext.save()
                }
            } catch {
            }
            //add
            if !change {
                let background = NSEntityDescription.entity(forEntityName: "Background", in: viewContext)
                let newRecord = NSManagedObject(entity: background!, insertInto: viewContext)
                newRecord.setValue((p1selected ? 1 : 2), forKey: "player")
                newRecord.setValue(pickedImage.pngData(), forKey: "picture")
                newRecord.setValue(scale, forKey: "scale")
                appDelegate.saveContext()
            }
            
            //背景設定
            if Player.player1 == self.selected{
                self.settingBackground(playerView: &player1view, setImage: pickedImage,scale: scale)
            }
            else{
                self.settingBackground(playerView: &player2view, setImage: pickedImage,scale: scale)
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    //背景画像を設定
    //  playerView:プレイヤービュー
    //  setImage:背景画像
    func settingBackground(playerView : inout UIView, setImage : UIImage,scale:CGFloat,initial:Bool = false)  {
        
        let imageView = UIImageView(image:setImage)
        imageView.alpha = 0.6
        // スクリーンの縦横サイズを取得
//        let playerViewWidth:CGFloat = playerView.frame.size.width
//        let playerViewHeight:CGFloat = playerView.frame.size.height
        
        // 画像の縦横サイズを取得
        let imgWidth:CGFloat = setImage.size.width
        let imgHeight:CGFloat = setImage.size.height
        
//        print("imgWidth:\(imgWidth)")
//        print("imgHeight:\(imgHeight)")
        
        // 画像サイズをスクリーン幅に合わせる
//        let scale:CGFloat = playerViewWidth / imgWidth
//        let scale:CGFloat = 0.4
        print("scale:\(scale)")
        let rect:CGRect =
            CGRect(x:0, y:0, width:imgWidth*scale, height:imgHeight*scale)
//        let scale_w:CGFloat = playerViewWidth / imgWidth
//        let scale_h:CGFloat = playerViewWidth / imgHeight
//        let rect:CGRect =
//            CGRect(x:0, y:0, width:imgWidth*scale_w, height:imgHeight*scale_h)
        
        // ImageView frame をCGRectで作った矩形に合わせる
        imageView.frame = rect;
        
        // 画像の中心を画面の中心に設定
//        imageView.center = CGPoint(x:playerViewWidth/2, y:playerViewHeight/2)
        
        // UIImageViewのインスタンスをビューに追加
        imageView.tag = 100
        
        //画像のviewを削除
        if let viewWithTag = playerView.viewWithTag(100){
            viewWithTag.removeFromSuperview()
        }
        
        var b:Bool = true
        for subView in playerView.subviews{
            if b{
                playerView.addSubview(imageView)
                b=false
            }
            playerView.addSubview(subView)
        }
    }
    
    func getDiceImage(type:DiceType) -> UIImage {
        var num:Int
        var image = UIImage()
        switch type {
        case .six:
            num = Int.random(in: 1 ... 6)
            image = UIImage(named: UITraitCollection.isDarkMode ? "dice\(num)n" : "dice\(num)d")!
        case .twenty:
            num = Int.random(in: 1 ... 20)
        }
        return image
    }
}



class CustomBtn:UIButton{
    
    //CABasicAnimationのtransform.zを使用する
    let rotationAnimation = CABasicAnimation(keyPath:"transform.rotation.z")
    
    
    func spinAnim(_ sender: UIView,_ t:CGFloat)
    {
        rotationAnimation.toValue = CGFloat(Double.pi) * t
        rotationAnimation.duration = 0.4//アニメーションにかかる時間
        rotationAnimation.repeatCount = 1.0//何回繰り返すか(MAXFLOATを修正)
        
        
        //アニメーションさせたいものにaddする
        sender.layer.add(rotationAnimation, forKey: "rotationAnimation")
    }
    
    func spinStop(_ sender: UIView)
    {
        sender.layer.removeAnimation(forKey:"rotationAnimation")
    }
}
