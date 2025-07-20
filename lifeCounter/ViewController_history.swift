//
//  ViewController_history.swift
//  lifeCounter
//
//  Created by 倉知諒 on 2021/09/24.
//  Copyright © 2021 kurachi. All rights reserved.
//

import UIKit
import CoreData
import GoogleMobileAds

class ViewController_history: UIViewController,UITableViewDelegate, UITableViewDataSource {
    var games = [Game]()
//    let format = NSLocalizedString("restoreListCellText", comment: "")//%@のバックアップ
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lifeflow_p1: UITextView!
    @IBOutlet weak var lifeflow_p2: UITextView!
    @IBOutlet weak var bannerView: GADBannerView!
    override func viewDidLoad() {
        super.viewDidLoad()
        //アド
        //AD : unit id
        
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
//        print("banner view max height:"+(50*aspect).description)
        let _bannerView: GADBannerView = GADBannerView(adSize: GADInlineAdaptiveBannerAdSizeWithWidthAndMaxHeight(viewWidth,50*aspect))
        _bannerView.adUnitID = Consts.ADMOB_UNIT_ID_MAIN
        _bannerView.rootViewController = self
        //AD : test device
        let request: GADRequest = GADRequest()
//        request.testDevices = [Consts.ADMOB_TEST_DEVICE_ID_SE2]
        _bannerView.load(request)
        bannerView.addSubview(_bannerView)
        
        tableView?.dataSource = self
        tableView?.delegate = self
        refreshData()
    }
    func refreshData()  {
        games = [Game]()
        lifeflow_p1.text = ""
        lifeflow_p2.text = ""
        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let viewContext = appDelegate.persistentContainer.viewContext
        let query: NSFetchRequest<Game> = Game.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "gameDate", ascending: false)
        let sortDescriptors = [sortDescriptor]
        query.sortDescriptors = sortDescriptors
        do {
            let fetchResults = try viewContext.fetch(query)
            for result: AnyObject in fetchResults {
                let game = result as! Game
                games.append(game)
            }
        } catch {
        }
        tableView.reloadData()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return games.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let game:Game = games[indexPath.row]
        let cell: TableViewCell_game = tableView.dequeueReusableCell(withIdentifier: "TableViewCell_game") as! TableViewCell_game
        cell.setCell(data:Data_game(gameDate: (game.name != nil && game.name != "") ? game.name! : Utilities.dateFormatChangeYYYYMMDD(date: game.gameDate), time: game.time!))
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let game:Game = games[indexPath.row]
        lifeflow_p1.text = createText(game: game,player: Consts.PLAYER1)
        lifeflow_p2.text = createText(game: game,player: Consts.PLAYER2)
    }
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let swipeCell = UITableViewRowAction(style: .default, title: NSLocalizedString("deleteBtn_title", comment: "")) { action, index in
            
            let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
            let viewContext = appDelegate.persistentContainer.viewContext
            let request: NSFetchRequest<Game> = Game.fetchRequest()
            let game: Game = self.games[indexPath.row]

            let alert: UIAlertController = UIAlertController(title: NSLocalizedString("confirm_title", comment: ""),
                                                             message:String(format: NSLocalizedString("confirm_sentence_delete", comment: ""), arguments: [(game.name != nil && game.name != "") ? game.name! : Utilities.dateFormatChangeYYYYMMDD(date: game.gameDate)]) ,
                preferredStyle: UIAlertController.Style.alert)
            let cancelAction: UIAlertAction = UIAlertAction(
                title: NSLocalizedString("dialog_button_no", comment: ""),
                style: UIAlertAction.Style.cancel,
                handler: {
                    (action: UIAlertAction!) -> Void in
                }
            )
            let defaultAction: UIAlertAction = UIAlertAction(
                title: NSLocalizedString("dialog_button_yes", comment: ""),
                style: UIAlertAction.Style.default,
                handler: {
                    (action: UIAlertAction!) -> Void in
                    let predicate = NSPredicate(format: "gameDate = %@", game.gameDate! as CVarArg)

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
                    self.refreshData()
                }
            )
            alert.addAction(cancelAction)
            alert.addAction(defaultAction)
            self.present(alert, animated: true, completion: nil)
        }
        swipeCell.backgroundColor = .red
        let swipeCell_rename = UITableViewRowAction(style: .default, title: NSLocalizedString("renameBtn_title", comment: "")) { action, index in
            
            let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
            let viewContext = appDelegate.persistentContainer.viewContext
            let request: NSFetchRequest<Game> = Game.fetchRequest()
            let game: Game = self.games[indexPath.row]

            let alert: UIAlertController = UIAlertController(title: NSLocalizedString("rename_title", comment: ""),
                message: NSLocalizedString("rename_sentence", comment: ""),
                preferredStyle: UIAlertController.Style.alert)
            
            let cancelAction: UIAlertAction = UIAlertAction(
                title: NSLocalizedString("bgAlert_button_cancel", comment: ""),
                style: UIAlertAction.Style.cancel,
                handler: {
                    (action: UIAlertAction!) -> Void in
                }
            )
            let defaultAction: UIAlertAction = UIAlertAction(
                title: NSLocalizedString("dialog_button_change", comment: ""),
                style: UIAlertAction.Style.default,
                handler: {
                    [weak alert](action: UIAlertAction!) -> Void in
                    guard let textFields = alert?.textFields else {
                        return
                    }
                    guard !textFields.isEmpty else {
                        return
                    }
                    var newName = ""
                    for text in textFields {
                        if text.tag == 1 {
                            newName = text.text!
                        }
                    }
                    if newName == ""{
                        return
                    }
                    let predicate = NSPredicate(format: "gameDate = %@", game.gameDate! as CVarArg)

                    request.predicate = predicate
                    do {
                        let fetchResults = try viewContext.fetch(request)
                        for result: AnyObject in fetchResults {
                            let record = result as! NSManagedObject
                            record.setValue(newName, forKey: "name")
                        }
                        try viewContext.save()
                    } catch {
                    }
                    self.refreshData()
                }
            )
            alert.addTextField(configurationHandler: {(text:UITextField!) -> Void in
                text.tag = 1
            })
            alert.addAction(cancelAction)
            alert.addAction(defaultAction)
            self.present(alert, animated: true, completion: nil)
        }
        swipeCell_rename.backgroundColor = .brown
        return [swipeCell,swipeCell_rename]
    }
    func createText(game:Game,player:Int16) -> String {
        var text = ""
//        print("------------")
        for (_,life) in lifeArray(game.life).enumerated() {
//            print("stage:\(life.stage),player:\(life.player),life:\(life.life)")
            var lifeText = String(life.life)
            
            if lifeText.count == 1 {
                lifeText = lifeText + " "//スペース埋め
            }
            if life.player == player {
                text = text + lifeText + "\n"
            }
        }
        return text
    }
    private func lifeArray(_ lifes: NSSet?) -> [Life] {
        let set = lifes as? Set<Life> ?? []
       return set.sorted {
        $0.player < $1.player
       }.sorted {
        $0.stage < $1.stage
       }
   }
}
