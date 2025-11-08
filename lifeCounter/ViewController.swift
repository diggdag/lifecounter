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
import GoogleMobileAds
import AppTrackingTransparency

class ViewController: UIViewController ,UIImagePickerControllerDelegate,UINavigationControllerDelegate, ChildViewControllerDelegate,GADFullScreenContentDelegate{
    func didPerformAction(from viewController: UIViewController) {
        print("didPerformAction called!!")
        setBackground_init()
        if viewController is SettingsTableViewController {
            if SettingsTableViewController.defaultLifeChanged {
                refreshLife()
                SettingsTableViewController.defaultLifeChanged=false;
            }
        } else if viewController is ViewController_image {
            rotate_exec(rotate: screenRotate)
        }
    }
    @IBOutlet weak var player1view: UIView!
    @IBOutlet weak var player2view: UIView!
    @IBOutlet weak var clearBtn: CustomBtn!
    @IBOutlet weak var settingBtn: UIButton!
    @IBOutlet weak var life1: UILabel!
    @IBOutlet weak var life2: UILabel!
    @IBOutlet weak var dice: UIButton!
    @IBOutlet weak var p1bg: UIView!
    @IBOutlet weak var p2bg: UIView!
    @IBOutlet var bgwidthp1: NSLayoutConstraint!
    @IBOutlet var bgwidthp2: NSLayoutConstraint!
    @IBOutlet var bgHeightp1: NSLayoutConstraint!
    @IBOutlet var bgHeightp2: NSLayoutConstraint!
    @IBOutlet weak var p1bgtopmargin: NSLayoutConstraint!
    @IBOutlet weak var middleView: UIView!
    @IBOutlet weak var verticalDummy: UIView!
    @IBOutlet weak var rotateButton: UIButton!
    var lifeflow_lifes = [[Int]]()
    
    var _life1 :Int=20
    var _life2 : Int=20
    
    var timer_master:Timer?
    
    var passMin_master:Int = 0
    let formatter = DateComponentsFormatter()
    var gameStatus:GameStatus = GameStatus.ready
    var currentPlayer : Player!
    static var selected : Player!
    
    var appDelegate:AppDelegate!
    var viewContext:NSManagedObjectContext!
    var countDownCnt:Countdown = Countdown.three
    
    var interstitial: GADInterstitialAd?
    
    let RADIUS:CGFloat = 20
    var screenRotate:Rotate = .normal
    var bgopacity:CGFloat = 0.8
    var rewardedAd: GADRewardedAd?
    var canOpenBackgroundSetting = false
    private var earnedRewardPendingOpen = false   // ← 視聴完了後、閉じたら遷移するための一時フラグ
    // --- install-day skip (reward off on install day) ---
    private let kInstallDateKey = "installDate"
    // ====== Burst (連打) 表示用 ======
    private let burstWindow: TimeInterval = 0.6 // 最後のタップから何秒でリセットするか
    private var minusStreakP1 = 0
    private var minusStreakP2 = 0
    private var plusStreakP1  = 0
    private var plusStreakP2  = 0
    private var timerMinusP1: Timer?
    private var timerMinusP2: Timer?
    private var timerPlusP1:  Timer?
    private var timerPlusP2:  Timer?
    
    // ==== Life History (MVP: in-memory) ====

    private struct LifeEvent {
        let ts: Date
        let life1: Int
        let life2: Int
        let d1: Int      // 前回からの差分
        let d2: Int
        let reason: Reason
        enum Reason { case auto, manual, clear, dice }
    }

    private var history: [LifeEvent] = []
    private var lastSnapshot: (l1: Int, l2: Int) = (20, 20)
    
    // 入力停止で自動スナップショット
    private var idleTimer: Timer?
    private let idleSec: TimeInterval = 2.0   // お好みで 1.5〜3.0 秒くらい
    private var pendingReason: LifeEvent.Reason = .manual   // ← 追加

    // ドロワーUI
    private var historyBlur: UIVisualEffectView!
    private var historyTable: UITableView!
    
    
    private var historyContainer: UIView?
    private var drawerTrailing: NSLayoutConstraint?
    private var drawerWidth: CGFloat { max(180, view.bounds.width * 0.42) } // 以前: 0.28
    private var drawerIsOpen = false
    
    
    private func ensureInstallDateSaved() {
        // まだ保存されていなければ現在時刻を保存（初回起動時のみ）
        let ud = UserDefaults.standard
        if ud.object(forKey: kInstallDateKey) == nil {
            ud.set(Date(), forKey: kInstallDateKey)
            ud.synchronize()
            print("🗓️ Saved installDate = \(Date())")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appBecameActive),
            name: .appDidBecomeActive,
            object: nil
        )
        // ← 追加：インストール日時を確定させる
        ensureInstallDateSaved()
        //        styleIconButton(clearBtn,   symbolName: "arrow.triangle.2.circlepath")
        loadRewardedAd()
        let minDimension = min(p1bg.frame.width, p1bg.frame.height)
        bgwidthp1.constant = minDimension
        bgHeightp1.constant = minDimension
        
        let minDimension2 = min(p2bg.frame.width, p2bg.frame.height)
        bgwidthp2.constant = minDimension2
        bgHeightp2.constant = minDimension2
        
        AppManager.shared.viewController=self
        //受信設定
        NotificationCenter.default.addObserver(self, selector: #selector(notificationFunc_pushhome(notification:)), name: .notificationName, object: nil)
        
        //        interstitial = createAndLoadInterstitial()
        
        if #available(iOS 13.0, *) {
            Task{
                do{
                    interstitial = try await GADInterstitialAd.load(withAdUnitID: Consts.ADMOB_UNIT_ID_INTERSTITIAL_CLEAR, request: GADRequest())
                    interstitial?.fullScreenContentDelegate = self
                }
                catch{
                    print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                }
            }
        } else {
            // Fallback on earlier versions
            print("ロードしない")//バグの素
        }
        
        // Do any additional setup after loading the view.
        
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        viewContext = appDelegate.persistentContainer.viewContext
        ensureDefaultSettingExists()   // ★これを最初に呼ぶ
        ensureDefaultBackgroundExists() // ← これ追加
        let request: NSFetchRequest<Setting> = Setting.fetchRequest()
        do {
            let fetchResults = try viewContext.fetch(request)
            if let setting = fetchResults.first {
                screenRotate = Rotate(rawValue: setting.rotateDirection) ?? .normal
                
                // ✅ 0でも常にフェールセーフで20を入れる
                let p1 = (setting.defaultLifeP1 == 0) ? 20 : Int(setting.defaultLifeP1)
                let p2 = (setting.defaultLifep2 == 0) ? 20 : Int(setting.defaultLifep2)
                
                _life1 = p1
                _life2 = p2
                life1.text = String(p1)
                life2.text = String(p2)
                
                if setting.bgopacity != 0 {
                    bgopacity = CGFloat(setting.bgopacity)
                } else {
                    bgopacity = 0.8
                }
                
                // ✅ 不正値(0)の場合、CoreData側にも正しい値を保存しておくと安全
                if setting.defaultLifeP1 == 0 || setting.defaultLifep2 == 0 {
                    setting.defaultLifeP1 = 20
                    setting.defaultLifep2 = 20
                    try? viewContext.save()
                }
            } else {
                // ✅ レコード無しでも必ず20/20
                _life1 = 20; life1.text = "20"
                _life2 = 20; life2.text = "20"
                screenRotate = .normal
                bgopacity = 0.8
            }
        } catch {
            print("Error fetching data: \(error)")
            // ✅ エラー時も20/20で安全
            _life1 = 20; life1.text = "20"
            _life2 = 20; life2.text = "20"
            screenRotate = .normal
            bgopacity = 0.8
        }
        
        rotate_exec(rotate: screenRotate)
        updateRotateButtonPreview()
        clearBtn.imageView?.contentMode = .scaleAspectFit
        clearBtn.contentHorizontalAlignment = .fill
        clearBtn.contentVerticalAlignment = .fill
        settingBtn.imageView?.contentMode = .scaleAspectFit
        settingBtn.contentHorizontalAlignment = .fill
        settingBtn.contentVerticalAlignment = .fill
        
        formatter.unitsStyle = .brief
        formatter.allowedUnits = [.minute, .second]
        
        setBackground_init()
        setMasterSetting_init()
        self.setNeedsStatusBarAppearanceUpdate()
        
        //写真アクセス許可
        if #available(iOS 14, *) {
            let accessLebel:PHAccessLevel = .addOnly
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
            //            PHPhotoLibrary.authorizationStatus()
            dice.setTitle("D6", for: .normal)
        }
        p1bg.layer.cornerRadius = RADIUS
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            self,
            selector: #selector(self.myEvent),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        //        bannerView.backgroundColor=UIColor.green
        
        setupHistoryDrawerIfNeeded()
    }
    @objc func appBecameActive() {
        updateLifeLabelStyle(isDark: UITraitCollection.isDarkMode)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //ad
        loadBannerAd()
    }
    
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to:size, with:coordinator)
        //ad start
        coordinator.animate(alongsideTransition: { _ in
            self.loadBannerAd()
            guard let container = self.historyContainer,
                          let widthC = container.constraints.first(where: { $0.firstAttribute == .width }) else { return }
                    widthC.constant = self.drawerWidth
                    if self.drawerIsOpen == false { self.drawerTrailing?.constant = self.drawerWidth + 16 }
                    self.view.layoutIfNeeded()
        })
        //ad end
    }
    
    //トラッキング許可をユーザから取得するためのメソッド
    @objc func myEvent() {
        if #available(iOS 14, *) {
            if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
                    GADMobileAds.sharedInstance().start(completionHandler: nil)
                })
            }
        }
        else {
            GADMobileAds.sharedInstance().start(completionHandler: nil)
        }
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
    }
    private func setupHistoryDrawerIfNeeded() {
        guard historyContainer == nil else { return }

        // コンテナ（右ドロワー）
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        container.layer.cornerRadius = 12
        container.clipsToBounds = true
        container.layoutMargins = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6) // ← 左右を少なくして余白調整

        view.addSubview(container)

        // 幅と上下制約
        let widthC = container.widthAnchor.constraint(equalToConstant: drawerWidth)
        NSLayoutConstraint.activate([
            widthC,
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])

        // 右からのスライド用制約
        let trailingC = container.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                           constant: drawerWidth + 16)
        trailingC.isActive = true

        self.historyContainer = container
        self.drawerTrailing = trailingC

        // ===== テーブルビュー =====
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .clear
        table.separatorStyle = .singleLine
        table.separatorInset = .zero
        table.rowHeight = 40 // ← 行間を少し詰める
        table.showsVerticalScrollIndicator = false
        table.dataSource = self
        table.delegate = self

        container.addSubview(table)
        NSLayoutConstraint.activate([
            table.leadingAnchor.constraint(equalTo: container.layoutMarginsGuide.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: container.layoutMarginsGuide.trailingAnchor),
            table.topAnchor.constraint(equalTo: container.layoutMarginsGuide.topAnchor),
            table.bottomAnchor.constraint(equalTo: container.layoutMarginsGuide.bottomAnchor)
        ])
        self.historyTable = table

        // ===== スワイプジェスチャ =====
        let edge = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(onEdgePan(_:)))
        edge.edges = .right
        view.addGestureRecognizer(edge)
    }
    
    @objc private func onEdgePan(_ g: UIScreenEdgePanGestureRecognizer) {
        setupHistoryDrawerIfNeeded()
        guard let trailing = drawerTrailing else { return }
        let tx = -g.translation(in: view).x                 // 右端→左へドラッグを正方向に
        let t = max(0, min(1, tx / drawerWidth))            // 0..1 にクランプ
        trailing.constant = (1 - t) * (drawerWidth + 16)    // 1=開き切り

        if g.state == .ended || g.state == .cancelled {
            (t > 0.35) ? openDrawer(animated: true) : closeDrawer(animated: true)
        }
    }
    @objc private func onDrawerPan(_ g: UIPanGestureRecognizer) {
        // 念のためここでも生成
        setupHistoryDrawerIfNeeded()

        if g.state == .began { g.setTranslation(.zero, in: view) }

        let dx = g.translation(in: view).x
        let progress = max(0, min(1, 1 - dx / drawerWidth))

        guard let trailing = drawerTrailing else { return }   // ← 安全に取り出す
        trailing.constant = progress * (drawerWidth + 16)

        if g.state == .ended || g.state == .cancelled {
            (progress < 0.65) ? openDrawer(animated: true) : closeDrawer(animated: true)
        }
    }
    private func openDrawer(animated: Bool) {
        setupHistoryDrawerIfNeeded()
        historyContainer?.isHidden = false
        drawerIsOpen = true
        drawerTrailing?.constant = drawerWidth + 16
        historyTable?.reloadData() // ←追加
        animateLayout(animated)
    }

    private func closeDrawer(animated: Bool) {
        drawerTrailing?.constant = 0                  // ← ?. で安全に
        drawerIsOpen = false
        animateLayout(animated) { [weak self] in self?.historyContainer?.isHidden = true }
    }
    private func animateLayout(_ animated: Bool, completion: (() -> Void)? = nil) {
        if animated {
            UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut]) {
                self.view.layoutIfNeeded()
            } completion: { _ in completion?() }
        } else {
            view.layoutIfNeeded()
            completion?()
        }
    }
    // アイドルタイマーを蹴る（理由つき）
    private func bumpIdleTimer(reason: LifeEvent.Reason = .manual) {
        pendingReason = reason                     // 直近の操作理由を覚える
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: idleSec, repeats: false) { [weak self] _ in
            self?.snapshotIfChanged(reason: self?.pendingReason ?? .manual)
        }
    }

    // スナップショット
    private func snapshotIfChanged(reason: LifeEvent.Reason) {
        guard _life1 != lastSnapshot.l1 || _life2 != lastSnapshot.l2 else { return }

        let ev = LifeEvent(
            ts: Date(),
            life1: _life1, life2: _life2,
            d1: _life1 - lastSnapshot.l1,
            d2: _life2 - lastSnapshot.l2,
            reason: reason
        )

        history.append(ev)
        if history.count > 200 { history.removeFirst() }

        lastSnapshot = (_life1, _life2)

        // 👇 ドロワーのテーブルを更新
        historyTable?.reloadData()
    }
    private func scheduleReset(_ timerRef: inout Timer?, action: @escaping () -> Void) {
        timerRef?.invalidate()
        timerRef = Timer.scheduledTimer(withTimeInterval: burstWindow, repeats: false) { _ in
            action()
        }
    }
    
    /// 画面上に “±N” をフワッと出して消す
    private func showBurst(on host: UIView, text: String, side: OverlaySide) {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 42, weight: .semibold)
        label.textAlignment = .center
        // 背景が暗いときは白文字＋影、明るいときは黒文字＋白影
        if UITraitCollection.isDarkMode {
            label.textColor = .white
            label.layer.shadowColor = UIColor.black.cgColor
        } else {
            label.textColor = .black
            label.layer.shadowColor = UIColor.white.withAlphaComponent(0.7).cgColor
        }
        label.layer.shadowOpacity = 0.9
        label.layer.shadowRadius  = 4
        label.layer.shadowOffset  = .zero
        label.alpha = 0
        
        // 出す位置（左/右の半分エリアの中央）
        let half = host.bounds.width / 2
        let x: CGFloat = (side == .left) ? half * 0.5 : (half * 1.5)
        let y: CGFloat = host.bounds.height * 0.5
        label.frame = CGRect(x: 0, y: 0, width: half, height: 56)
        label.center = CGPoint(x: x, y: y)
        host.addSubview(label)
        
        // ふわっと出て、少し上に移動しながら消える
        UIView.animate(withDuration: 0.08, animations: {
            label.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseOut]) {
                label.alpha = 0
                label.center.y -= 18
            } completion: { _ in
                label.removeFromSuperview()
            }
        }
    }
    // --- install-day grace window (DEBUG: 60s / RELEASE: 24h) ---
    private var installGraceSeconds: TimeInterval {
        //        return 60                  // デバッグ時は 1分
        return 12 * 60 * 60        // リリース時は 12時間
    }
    
    private func isWithinInstallGrace() -> Bool {
        let ud = UserDefaults.standard
        guard let installed = ud.object(forKey: kInstallDateKey) as? Date else {
            // 何らかの理由で未保存なら猶予中扱い（安全側）
            return true
        }
        let elapsed = Date().timeIntervalSince(installed)
        return elapsed < installGraceSeconds
    }
    func loadRewardedAd() {
        Task {
            do {
                rewardedAd = try await GADRewardedAd.load(withAdUnitID: Consts.ADMOB_UNIT_ID_REWARD, request: GADRequest())
                rewardedAd?.fullScreenContentDelegate = self
                print("✅ Rewarded ad loaded successfully")
            } catch {
                print("❌ Failed to load rewarded ad: \(error.localizedDescription)")
            }
        }
    }
    func showRewardedAd() {
        guard let rewardedAd = rewardedAd else {
            print("❌ Rewarded ad not ready")
            loadRewardedAd()
            // UX向上：未準備メッセージ（任意）
            let a = UIAlertController(title: "広告の準備中", message: "しばらくしてからもう一度お試しください。", preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default))
            present(a, animated: true)
            return
        }
        rewardedAd.present(fromRootViewController: self) {
            let reward = rewardedAd.adReward
            print("✅ User earned reward: \(reward.amount) \(reward.type)")
            
            // ここでは遷移せず、閉じられてから実行する
            self.canOpenBackgroundSetting = true
            self.earnedRewardPendingOpen = true
        }
    }
    @objc func notificationFunc_pushhome(notification: NSNotification?) {
        print("called! notificationFunc_pushhome")
        //画面初期化
        //        screenInitialize([])
    }
    //背景設定初期メソッド（DBから読み込む）
    func setBackground_init()  {
        var player1Img:UIImage? = nil
        var player2Img:UIImage? = nil
        var scale1:CGFloat = CGFloat(1)
        var scale2:CGFloat = CGFloat(1)
        
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        viewContext = appDelegate.persistentContainer.viewContext
        
        let query: NSFetchRequest<Background> = Background.fetchRequest()
        
        do {
            let fetchResults = try viewContext.fetch(query)
            if fetchResults.count != 0 {
                for result: AnyObject in fetchResults {
                    let player: Int16 = result.value(forKey: "player") as! Int16
                    
                    if player==1 || player==3 {
                        player1Img=UIImage(data: result.value(forKey: "picture") as! Data)
                        scale1 = result.value(forKey: "scale") as! CGFloat
                    }
                    if player==2 || player==3 {
                        player2Img=UIImage(data: result.value(forKey: "picture") as! Data)
                        scale2 = result.value(forKey: "scale") as! CGFloat
                    }
                }
            }
            
            let request: NSFetchRequest<Setting> = Setting.fetchRequest()
            let fetchResults2 = try viewContext.fetch(request)
            if let setting = fetchResults2.first {
                print("bunki 1")
                if setting.bgopacity != 0 {
                    bgopacity=CGFloat(setting.bgopacity)
                }
            }
            else{
                
                print("bunki 2")
            }
            
            
            self.settingBackground(playerView: &p1bg, setImage: player1Img ?? UIImage(),scale: scale1,initial: true,bgopacity: self.bgopacity)
            self.settingBackground(playerView: &p2bg, setImage: player2Img ?? UIImage(),scale: scale2,initial: true,bgopacity: self.bgopacity)
        } catch {
            print("Error fetching data: \(error)")
        }
    }
    func refreshLife() {
        let request: NSFetchRequest<Setting> = Setting.fetchRequest()
        do {
            let fetchResults = try viewContext.fetch(request)
            if let setting = fetchResults.first {
                let p1 = (setting.defaultLifeP1 == 0) ? Int(Consts.DEFAULT_LIFE) : Int(setting.defaultLifeP1)
                let p2 = (setting.defaultLifep2 == 0) ? Int(Consts.DEFAULT_LIFE) : Int(setting.defaultLifep2)
                _life1 = p1; life1.text = String(p1)
                _life2 = p2; life2.text = String(p2)
                // ついでに不正(0)を検知したら保存し直しておくと後々安全
                if setting.defaultLifeP1 == 0 || setting.defaultLifep2 == 0 {
                    setting.defaultLifeP1 = Int16(p1)
                    setting.defaultLifep2 = Int16(p2)
                    try? viewContext.save()
                }
            } else {
                // 念のため：レコード無しでも20/20に
                _life1 = Int(Consts.DEFAULT_LIFE); life1.text = String(Consts.DEFAULT_LIFE)
                _life2 = Int(Consts.DEFAULT_LIFE); life2.text = String(Consts.DEFAULT_LIFE)
            }
        } catch {
            print("Error fetching data: \(error)")
            // 失敗時も20/20で表示
            _life1 = Int(Consts.DEFAULT_LIFE); life1.text = String(Consts.DEFAULT_LIFE)
            _life2 = Int(Consts.DEFAULT_LIFE); life2.text = String(Consts.DEFAULT_LIFE)
        }
    }
    func setMasterSetting_init()  {
        let query: NSFetchRequest<Setting> = Setting.fetchRequest()
        do {
            let fetchResults = try viewContext.fetch(query)
            if fetchResults.count != 1 {
                //                setRecodeSw(isOn: false)
            }
            else{
                //                setRecodeSw(isOn: (fetchResults[0] as Setting).recode)
            }
        } catch {
        }
    }
    override var prefersStatusBarHidden: Bool{
        return true
    }
    @IBAction func touchDown_clearBtn(_ sender: Any) {
        haptic(.heavy)
        self.clearBtn.spinAnim(self.clearBtn, 1.0)

        guard let interstitial = interstitial else {
            print("Ad wasn't ready.（広告が使える状態でない）")
            return
        }
        interstitial.present(fromRootViewController: self)

        // --- ライフをデフォルト値へ ---
        refreshLife()

        // --- 履歴を自動クリア ---
        history.removeAll()
        historyTable?.reloadData()

        // --- スナップショット基準を現状（初期値）に更新 ---
        lastSnapshot = (_life1, _life2)

        // --- アイドルタイマー停止（直後の自動記録を防止）---
        idleTimer?.invalidate()

        // （任意）ドロワーを閉じる
        closeDrawer(animated: true)
    }
    
    //広告作成
    //    @available(iOS 13.0.0, *)
    //    func createAndLoadInterstitial() -> GADInterstitialAd? {
    //        Task{
    //            do{
    //                var interstitial = try await GADInterstitialAd.load(withAdUnitID: Consts.ADMOB_UNIT_ID_INTERSTITIAL_CLEAR, request: GADRequest())
    //                //            interstitial.delegate = self
    //                //        interstitial.load(GADRequest())
    //                return interstitial
    //            }
    //            catch{
    //                print("Failed to load interstitial ad with error: \(error.localizedDescription)")
    //                return nil
    //            }
    //        }
    //    }
    //
    //    //広告非表示
    //    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
    //        print("interstitialDidDismissScreen!!")
    //        interstitial = createAndLoadInterstitial()
    //    }
    
    //    func screenInitialize(_ sender: Any)  {
    //        passMin_master = 0//経過時間
    //        lifeflow_lifes.removeAll()
    //        gameStatus = .ready
    //    }
    /// Tells the delegate that the ad failed to present full screen content.
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad did fail to present full screen content.")
    }
    
    /// Tells the delegate that the ad will present full screen content.
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad will present full screen content.")
    }
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad dismissed. Reloading ads...")
        if ad is GADRewardedAd {
            loadRewardedAd()
            
            // 視聴完了していれば、閉じたあとに解放ダイアログを出してから遷移
            if earnedRewardPendingOpen && canOpenBackgroundSetting {
                earnedRewardPendingOpen = false
                let done = UIAlertController(
                    title: "背景設定が解放されました",
                    message: "背景設定画面に進みます。",
                    preferredStyle: .alert
                )
                done.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    self.canOpenBackgroundSetting = false
                    self.openBackgroundSetting()
                }))
                present(done, animated: true)
            }
        } else if ad is GADInterstitialAd {
            Task {
                do {
                    self.interstitial = try await GADInterstitialAd.load(withAdUnitID: Consts.ADMOB_UNIT_ID_INTERSTITIAL_CLEAR, request: GADRequest())
                    self.interstitial?.fullScreenContentDelegate = self
                } catch {
                    print("Failed to reload interstitial: \(error.localizedDescription)")
                }
            }
        }
    }
    @IBAction func touchDown_image_settingBtn(_ sender: Any) {
        haptic(.light)
        openBackgroundSetting()   // ← 直接開く（リワード無し）
    }
    
    private func openBackgroundSetting() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let childVC = storyboard.instantiateViewController(withIdentifier: "ViewController_image") as? ViewController_image else {
            return
        }
        childVC.delegate = self
        present(childVC, animated: true, completion: nil)
        rotate_exec(rotate: .normal)
    }
    
    @IBAction func touchDown_setting(_ sender: Any) {
        haptic(.light)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let childVC = storyboard.instantiateViewController(withIdentifier: "SettingsTableViewController") as? SettingsTableViewController else {
            return
        }
        //        let childVC = SettingsTableViewController()
        childVC.delegate = self
        present(childVC, animated: true, completion: nil)
        //        self.performSegue(withIdentifier: "toSetting", sender: nil)
    }
    @IBAction func touchDown_dice6(_ sender: Any) {
        haptic(.light)
        let diceNum_p1 = getDiceNum(type: DiceType.six)
        var diceNum_p2 = getDiceNum(type: DiceType.six)
        while diceNum_p1 == diceNum_p2 {
            print("一致したので振り直し p1:\(diceNum_p1),p2\(diceNum_p2)")
            diceNum_p2 = getDiceNum(type: DiceType.six)
        }
        ViewController_popup.dispDiceImage = getDiceImage(type: .six, num: diceNum_p1)
        ViewController_popup.dispDiceImage2 = getDiceImage(type: .six, num: diceNum_p2)
        performSegue(withIdentifier: "toPopUp", sender: nil)
    }
    func deleteImg(player:Player)  {
        let request: NSFetchRequest<Background> = Background.fetchRequest()
        let predicate = NSPredicate(format: "player = \(Player.player1==player ? "1" : "2") OR player = '3'")
        
        request.predicate = predicate
        do {
            let fetchResults = try viewContext.fetch(request)
            if(fetchResults.count != 0){
                for result: AnyObject in fetchResults {
                    let record = result as! Background
                    var newPlayer = record.player
                    let pNum:Int16 = (Player.player1==player ? 1 : 2)
                    if record.player == 0{//nil
                    }
                    else if record.player == pNum{//me
                        newPlayer -= pNum
                    }
                    //                    else if record.player == pNumReverse{//you
                    //                    }
                    else if record.player == 3{//both
                        newPlayer -= pNum
                    }
                    print("id:\(record.id) newPlayer:\(newPlayer)")
                    record.setValue(newPlayer, forKey: "player")
                    
                    try viewContext.save()
                }
            }
        } catch {
        }
    }
    // PLUS BTN1 (Player 1)
    @IBAction func touchDown_plusBtn1(_ sender: Any) {
        haptic(.light)
        lifeIncrement(.player1)
        addOverlay(to: p1bg, side: .right)
        
        plusStreakP1 += 1
        showBurst(on: p1bg, text: "+\(plusStreakP1)", side: .right)
        scheduleReset(&timerPlusP1) { [weak self] in
            self?.plusStreakP1 = 0
        }
    }
    @IBAction func touchUpInside_plusBtn1(_ sender: Any) {
        removeOverlay(from: p1bg)
    }
    @IBAction func touchUpOutside_plusBtn1(_ sender: Any) {
        removeOverlay(from: p1bg)
    }
    @IBAction func touchCancel_plusBtn1(_ sender: Any) {
        removeOverlay(from: p1bg)
    }
    
    // PLUS BTN2 (Player 2)
    @IBAction func touchDown_plusBtn2(_ sender: Any) {
        haptic(.light)
        lifeIncrement(.player2)
        addOverlay(to: p2bg, side: .right)
        
        plusStreakP2 += 1
        showBurst(on: p2bg, text: "+\(plusStreakP2)", side: .right)
        scheduleReset(&timerPlusP2) { [weak self] in
            self?.plusStreakP2 = 0
        }
    }
    @IBAction func touchUpInside_plusBtn2(_ sender: Any) {
        removeOverlay(from: p2bg)
    }
    @IBAction func touchUpOutside_plusBtn2(_ sender: Any) {
        removeOverlay(from: p2bg)
    }
    @IBAction func touchCancel_plusBtn2(_ sender: Any) {
        removeOverlay(from: p2bg)
    }
    
    // MINUS BTN1 (Player 1)
    @IBAction func touchDown_minusBtn1(_ sender: Any) {
        haptic(.light)
        lifeDecrement(.player1)
        addOverlay(to: p1bg, side: .left)
        
        // 連打カウント＆表示
        minusStreakP1 += 1
        showBurst(on: p1bg, text: "-\(minusStreakP1)", side: .left)
        scheduleReset(&timerMinusP1) { [weak self] in
            self?.minusStreakP1 = 0
        }
    }
    @IBAction func touchUpInside_minusBtn1(_ sender: Any) {
        removeOverlay(from: p1bg)
    }
    @IBAction func touchUpOutside_minusBtn1(_ sender: Any) {
        removeOverlay(from: p1bg)
    }
    @IBAction func touchCancel_minusBtn1(_ sender: Any) {
        removeOverlay(from: p1bg)
    }
    
    // MINUS BTN2 (Player 2)
    @IBAction func touchDown_minusBtn2(_ sender: Any) {
        haptic(.light)
        lifeDecrement(.player2)
        addOverlay(to: p2bg, side: .left)
        
        minusStreakP2 += 1
        showBurst(on: p2bg, text: "-\(minusStreakP2)", side: .left)
        scheduleReset(&timerMinusP2) { [weak self] in
            self?.minusStreakP2 = 0
        }
    }
    @IBAction func touchUpInside_minusBtn2(_ sender: Any) {
        removeOverlay(from: p2bg)
    }
    @IBAction func touchUpOutside_minusBtn2(_ sender: Any) {
        removeOverlay(from: p2bg)
    }
    @IBAction func touchCancel_minusBtn2(_ sender: Any) {
        removeOverlay(from: p2bg)
    }
    
    
    enum OverlaySide {
        case left
        case right
    }
    
    func addOverlay(to view: UIView, side: OverlaySide) {
        // 既にオーバーレイがあれば追加しない
        if view.viewWithTag(999) == nil {
            let halfWidth = view.bounds.width / 2
            let xPosition: CGFloat = (side == .left) ? 0 : halfWidth
            
            let overlay = UIView(frame: CGRect(x: xPosition, y: 0, width: halfWidth, height: view.bounds.height))
            let color = UITraitCollection.isDarkMode ? UIColor.black : UIColor.white
            overlay.backgroundColor = color.withAlphaComponent(0.3)
            overlay.tag = 999
            view.addSubview(overlay)
        }
    }
    
    func removeOverlay(from view: UIView) {
        if let overlay = view.viewWithTag(999) {
            overlay.removeFromSuperview()
        }
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
    enum Rotate: Int16{
        case normal = 0
        case left = 1
        case right = 2
        case bothFacing  = 3
    }
    func nextMode(from current: Rotate) -> Rotate {
        switch current {
        case .normal:     return .left
        case .left:       return .right
        case .right:      return .bothFacing
        case .bothFacing: return .normal
        }
    }
    private func previewImage(for next: Rotate) -> UIImage? {
        let symbolName: String = {
            switch next {
            case .normal:
                // 上向き＋下向き（対面）
                return "person.fill"
            case .left:
                return "person.fill.turn.right"
            case .right:
                return "person.fill.turn.left"
            case .bothFacing:
                // 両方こちら向き（下向き×2 のアイコンはないので妥協案）
                return "person.2.fill"
            }
        }()
        
        return UIImage(systemName: symbolName)?.withRenderingMode(.alwaysTemplate)
    }
    
    // 置き換え：プレビュー更新
    func updateRotateButtonPreview() {
        let next = nextMode(from: screenRotate)
        rotateButton.setImage(previewImage(for: next), for: .normal)
        // テンプレ色にしているなら色も指定
        // rotateButton.tintColor = .tintColor
    }
    func lifeIncrement(_ p: Player) {
        switch p {
        case .player1: _life1 += 1; life1.text = String(_life1)
        case .player2: _life2 += 1; life2.text = String(_life2)
        }
        bumpIdleTimer(reason: .manual)    // ← これだけ。snapshotIfChanged は削除
    }

    func lifeDecrement(_ p: Player) {
        switch p {
        case .player1: _life1 -= 1; life1.text = String(_life1)
        case .player2: _life2 -= 1; life2.text = String(_life2)
        }
        bumpIdleTimer(reason: .manual)    // ← これだけ。snapshotIfChanged は削除
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
    
    //背景画像を設定
    //  playerView:プレイヤービュー
    //  setImage:背景画像
    //    func settingBackground(playerView : inout UIView, setImage : UIImage,scale:CGFloat,initial:Bool = false)  {
    //
    //        let imageView = UIImageView(image:setImage)
    //        imageView.alpha = 0.8
    //        // スクリーンの縦横サイズを取得
    //        let playerViewWidth:CGFloat = playerView.frame.size.width
    //        let playerViewHeight:CGFloat = playerView.frame.size.height
    //
    //        // 画像の縦横サイズを取得
    //        let imgWidth:CGFloat = setImage.size.width
    //        let imgHeight:CGFloat = setImage.size.height
    //        print("playerViewWidth:\(playerViewWidth),imgWidth:\(imgWidth)")
    //        // 画像のスケールを計算
    //        let widthScale: CGFloat = playerViewWidth / imgWidth
    //        let heightScale: CGFloat = playerViewHeight / imgHeight
    //        print("widthScale:\(widthScale)")
    ////        let finalScale: CGFloat = min(widthScale, heightScale)
    //        // 新しいフレームを計算
    //        let newWidth: CGFloat = imgWidth * widthScale
    //        let newHeight: CGFloat = imgHeight * widthScale
    //        let rect: CGRect = CGRect(x: 0, y: 0, width: newWidth, height: newHeight)
    ////        print("imgWidth:\(imgWidth)")
    ////        print("imgHeight:\(imgHeight)")
    //
    //        // 画像サイズをスクリーン幅に合わせる
    ////        let scale:CGFloat = playerViewWidth / imgWidth
    ////        let scale:CGFloat = 0.4
    ////        print("scale:\(scale)")
    ////        let rect:CGRect =
    ////            CGRect(x:0, y:0, width:imgWidth*scale, height:imgHeight*scale)
    ////        let scale_w:CGFloat = playerViewWidth / imgWidth
    ////        let scale_h:CGFloat = playerViewWidth / imgHeight
    ////        let rect:CGRect =
    ////            CGRect(x:0, y:0, width:imgWidth*scale_w, height:imgHeight*scale_h)
    //
    //        // ImageView frame をCGRectで作った矩形に合わせる
    //        imageView.frame = rect;
    //
    //        // 画像の中心を画面の中心に設定
    ////        imageView.center = CGPoint(x:playerViewWidth/2, y:playerViewHeight/2)
    //
    //        // UIImageViewのインスタンスをビューに追加
    //        imageView.tag = 100
    //
    //        //画像のviewを削除
    //        if let viewWithTag = playerView.viewWithTag(100){
    //            viewWithTag.removeFromSuperview()
    //        }
    //
    //        if playerView.subviews.count == 0 {
    //            playerView.addSubview(imageView)
    //        }
    //        else{
    //            var b:Bool = true
    //            for subView in playerView.subviews{
    //                if b{
    //                    playerView.addSubview(imageView)
    //                    b=false
    //                }
    //                playerView.addSubview(subView)
    //            }
    //        }
    //    }
    func settingBackground(playerView: inout UIView,
                           setImage: UIImage,
                           scale: CGFloat,
                           initial: Bool = false,
                           bgopacity: CGFloat) {
        // 既存の背景UIImageViewを再利用 or 新規作成
        let imageView: UIImageView
        if let iv = playerView.viewWithTag(100) as? UIImageView {
            imageView = iv
        } else {
            imageView = UIImageView()
            imageView.tag = 100
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFill // ← 余白をなくして全面表示
            playerView.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: playerView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: playerView.trailingAnchor),
                imageView.topAnchor.constraint(equalTo: playerView.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: playerView.bottomAnchor)
            ])
        }
        
        // 画像と透過度を設定
        imageView.alpha = bgopacity
        imageView.image = setImage
        if isSE2Size() {
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .clear
            // SE2サイズのときだけ余白を動的カラー、それ以外は透明（＝黒/白切替の影響を受けない）
            playerView.backgroundColor = .systemBackground
        }else {
            imageView.contentMode = .scaleAspectFill
            imageView.backgroundColor = .clear
            playerView.backgroundColor = .clear
        }
        // 背景ビュー全体に角丸を適用
        let RADIUS: CGFloat = 16 // ← 角丸半径（必要に応じて調整）
        playerView.layer.cornerRadius = RADIUS
        playerView.layer.masksToBounds = true
        imageView.layer.cornerRadius = RADIUS
        imageView.clipsToBounds = true
        
        // レイアウトを即時反映
        playerView.layoutIfNeeded()
    }
    
    func getDiceNum(type:DiceType) -> Int16 {
        var num:Int
        switch type {
        case .six:
            num = Int.random(in: 1 ... 6)
        case .twenty:
            num = Int.random(in: 1 ... 20)
        }
        return Int16(num)
    }
    func getDiceImage(type:DiceType,num:Int16) -> UIImage {
        var image = UIImage()
        switch type {
        case .six:
            image = UIImage(named: UITraitCollection.isDarkMode ? "dice\(num)n" : "dice\(num)d")!
        case .twenty:
            image = UIImage()
        }
        return image
    }
    @IBAction func touchDown_rotate(_ sender: Any) {
        haptic(.light)
        print("touchDown_rotate called!screenRotate(before):\(screenRotate)")
        
        switch screenRotate {
        case .normal:
            screenRotate = .left
        case .left:
            screenRotate = .right
        case .right:
            screenRotate = .bothFacing   // ★ 追加状態へ
        case .bothFacing:
            screenRotate = .normal
        }
        rotate_exec(rotate: screenRotate)
        updateRotateButtonPreview()
        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let viewContext = appDelegate.persistentContainer.viewContext
        let request: NSFetchRequest<Setting> = Setting.fetchRequest()
        do {
            let fetchResults = try viewContext.fetch(request)
            if fetchResults.isEmpty {
                //insert
                let entity = NSEntityDescription.entity(forEntityName: "Setting", in: viewContext)
                if let entity = entity {
                    let record = Setting(entity: entity, insertInto: viewContext)
                    record.rotateDirection = screenRotate.rawValue
                }
            }
            else{
                //edit
                for record in fetchResults {
                    record.rotateDirection = screenRotate.rawValue
                }
            }
            try viewContext.save()
            //            appDelegate.saveContext()
        } catch {
        }
        
        
        print("touchDown_rotate called!screenRotate(after):\(screenRotate)")
    }
    func rotate_exec(rotate: Rotate)  {
        print("rotate_exec called!\(rotate.rawValue)")
        
        var rotatep1: CGFloat = 0         // 自分
        var rotatep2: CGFloat = .pi       // 相手（normal は向かい合わせ）
        
        switch rotate {
        case .normal:
            rotatep1 = 0
            rotatep2 = .pi                // 既存
        case .left:
            rotatep1 = .pi/2
            rotatep2 = .pi/2
        case .right:
            rotatep1 = .pi*3/2
            rotatep2 = .pi*3/2
        case .bothFacing:
            rotatep1 = 0
            rotatep2 = 0                  // ★ どちらもこちら向き
        }
        
        player1view.transform=CGAffineTransform(rotationAngle: rotatep1)
        p1bg.transform=CGAffineTransform(rotationAngle: rotatep1)
        player2view.transform=CGAffineTransform(rotationAngle: rotatep2)
        p2bg.transform=CGAffineTransform(rotationAngle: rotatep2)
        
        // フレームの再計算
        updateFramesForRotation()
        // ドロワーは常時使えるので、回転の瞬間だけ閉じておくと崩れにくい
        closeDrawer(animated: false)
    }
    private func showRewardedAdWithDialog() {
        // すでに解放トークンがあればそのまま遷移
        if canOpenBackgroundSetting {
            canOpenBackgroundSetting = false
            openBackgroundSetting()
            return
        }
        
        // ★ 変更：猶予中（DEBUG=1分 / RELEASE=24h）は無制限で開放
        if isWithinInstallGrace() {
            print("🆓 Install grace active → skipping reward ad")
            openBackgroundSetting()
            return
        }
        
        // 以降は従来の事前告知→視聴フロー
        let alert = UIAlertController(
            title: "背景設定の解放",
            message: "広告を視聴すると、背景設定画面に1回だけ進めます。よろしいですか？",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        alert.addAction(UIAlertAction(title: "視聴する", style: .default, handler: { _ in
            self.showRewardedAd()
        }))
        present(alert, animated: true)
    }
    /// iPhone SE(2nd/3rd) / iPhone 8 相当の 750×1334px 端末か判定
    private func isSE2Size() -> Bool {
        // portrait/landscape どちらでもOKなように max/min で比較
        let b = UIScreen.main.bounds
        let scale = UIScreen.main.scale
        let nativeW = Int(max(b.width, b.height) * scale)
        let nativeH = Int(min(b.width, b.height) * scale)
        // 750x1334（または逆）に近ければtrue（誤差±2px許容）
        let a = (abs(nativeW - 1334) <= 2 && abs(nativeH - 750) <= 2)
        let b2 = (abs(nativeW - 750)  <= 2 && abs(nativeH - 1334) <= 2)
        return a || b2
    }
    func updateFramesForRotation() {
        let player1Frame = player1view.frame
        let player2Frame = player2view.frame
        
        // 回転後のフレームを計算
        let rotatedPlayer1Frame = CGRect(x: 0, y: view.bounds.height - player1Frame.width, width: player1Frame.height, height: player1Frame.width)
        let rotatedPlayer2Frame = CGRect(x: 0, y: 0, width: player2Frame.height, height: player2Frame.width)
        
        // Auto Layout制約を無効にしてから新しいフレームを適用
        //        player1view.translatesAutoresizingMaskIntoConstraints = true
        //        player2view.translatesAutoresizingMaskIntoConstraints = true
        p1bg.translatesAutoresizingMaskIntoConstraints = true
        p2bg.translatesAutoresizingMaskIntoConstraints = true
        
        //        player1view.frame = rotatedPlayer1Frame
        p1bg.frame = rotatedPlayer1Frame
        //        player2view.frame = rotatedPlayer2Frame
        p2bg.frame = rotatedPlayer2Frame
        
        // 必要に応じてAuto Layout制約を再設定
        //        player1view.translatesAutoresizingMaskIntoConstraints = false
        //        player2view.translatesAutoresizingMaskIntoConstraints = false
        p1bg.translatesAutoresizingMaskIntoConstraints = false
        p2bg.translatesAutoresizingMaskIntoConstraints = false
        
        // 必要な制約を再設定
        NSLayoutConstraint.activate([
            // player1 (下側のプレイヤー)
            //            player1view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            //            player1view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            p1bg.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            p1bg.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // player2 (上側のプレイヤー)
            //            player2view.topAnchor.constraint(equalTo: view.topAnchor),
            //            player2view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            p2bg.topAnchor.constraint(equalTo: view.topAnchor),
            p2bg.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    // 共通スタイル関数（ファイル先頭のどこでもOK）
    func styleIconButton(_ b: UIButton, symbolName: String) {
        // 1) アイコンを大きく・太く
        let cfg = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold, scale: .large)
        let img = UIImage(systemName: symbolName, withConfiguration: cfg)!.withRenderingMode(.alwaysTemplate)
        b.setImage(img, for: .normal)
        b.setTitle(nil, for: .normal)
        b.tintColor = .tintColor
        
        // 2) 触りやすいヒットエリア（見た目はそのままでもOK）
        b.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.widthAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        b.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        
        // 3) 画像のフィット
        b.imageView?.contentMode = .scaleAspectFit
    }
    
    private let DEFAULT_ROTATE: Rotate = .normal
    private func ensureDefaultSettingExists() {
        let request: NSFetchRequest<Setting> = Setting.fetchRequest()
        do {
            let results = try viewContext.fetch(request)
            if results.isEmpty {
                // 初回インストール時に1レコード作成
                if let entity = NSEntityDescription.entity(forEntityName: "Setting", in: viewContext) {
                    let s = Setting(entity: entity, insertInto: viewContext)
                    s.defaultLifeP1     = Consts.DEFAULT_LIFE
                    s.defaultLifep2     = Consts.DEFAULT_LIFE
                    s.bgopacity         = Consts.DEFAULT_BGOPACITY
                    s.rotateDirection   = DEFAULT_ROTATE.rawValue
                    try viewContext.save()
                    print("✅ Seeded default Setting(20/20, opacity \(Consts.DEFAULT_BGOPACITY))")
                }
            }
        } catch {
            print("ensureDefaultSettingExists error: \(error)")
        }
    }
    private func ensureDefaultBackgroundExists() {
        let req: NSFetchRequest<Background> = Background.fetchRequest()
        do {
            let count = try viewContext.count(for: req)
            if count == 0 {
                
                func insertDefaultImage(named: String, player: Int16) {
                    if let entity = NSEntityDescription.entity(forEntityName: "Background", in: viewContext),
                       let img = UIImage(named: named),
                       let data = img.pngData() {
                        
                        let record = Background(entity: entity, insertInto: viewContext)
                        let nextId = Utilities.getNextId(viewContext: viewContext)
                        record.id      = Int32(Int16(nextId))
                        record.picture = data
                        record.scale   = 1.0
                        record.player  = player
                        
                        print("🖼️ Seed default background \(named) → player \(player)")
                    }
                }
                
                // ✅ 自分用 & 相手用の２枚
                insertDefaultImage(named: Consts.ASSET_DEFAULT_BG_1, player: 1)
                insertDefaultImage(named: Consts.ASSET_DEFAULT_BG_2, player: 2)
                
                try viewContext.save()
                UserDefaults.standard.set(true, forKey: Consts.BG_SEEDED_KEY)
            }
        } catch {
            print("❌ ensureDefaultBackgroundExists error:", error)
        }
    }
    func updateLifeLabelStyle(isDark: Bool) {
        let labelList = [life1, life2]
        
        for label in labelList {
            guard let label = label else { continue }
            
            if isDark {
                label.textColor = .white
                label.layer.shadowColor = UIColor.black.cgColor
            } else {
                label.textColor = .black
                label.layer.shadowColor = UIColor.white.withAlphaComponent(0.6).cgColor
            }
            
            label.layer.shadowRadius = 4
            label.layer.shadowOpacity = 0.8
            label.layer.shadowOffset = .zero
            label.layer.masksToBounds = false
        }
    }
}
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return history.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = "lifeCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: id)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: id)

        let e = history[history.count - 1 - indexPath.row] // 新しい順で表示
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .white

        let time = DateFormatter.cached.string(from: e.ts)
        let delta = String(format: "P1 %+d  P2 %+d", e.d1, e.d2)
        cell.textLabel?.text = "\(time)  \(delta)"
        cell.detailTextLabel?.text = "→ \(e.life1) ｜ \(e.life2)"
        // tableView(_:cellForRowAt:)
        cell.textLabel?.font = .monospacedDigitSystemFont(ofSize: 16, weight: .semibold)
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.minimumScaleFactor = 0.75
        cell.textLabel?.lineBreakMode = .byTruncatingMiddle

        cell.detailTextLabel?.font = .systemFont(ofSize: 13, weight: .regular)
        cell.detailTextLabel?.adjustsFontSizeToFitWidth = true
        cell.detailTextLabel?.minimumScaleFactor = 0.8
        cell.detailTextLabel?.lineBreakMode = .byTruncatingTail
        return cell
    }
}

private extension DateFormatter {
    static let cached: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
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
protocol ChildViewControllerDelegate: AnyObject {
    func didPerformAction(from viewController: UIViewController)
}
