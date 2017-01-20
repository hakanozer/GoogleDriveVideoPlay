//
//  ViewController.swift
//  AvKitGoogleDriveVideoPlay
//
//  Created by Hakan on 31/12/2016.
//  Copyright © 2016 Hakan. All rights reserved.
//


import UIKit
import AVKit
import AVFoundation
import Alamofire
import AlamofireNetworkActivityIndicator
import SwiftyJSON



class ViewController: UIViewController, AVPlayerItemOutputPullDelegate, UITableViewDelegate, UITableViewDataSource {
    
    
    let iconTitle = ["Atem Tutem Men Seni", "Dandini Dandini Danalı Bebek", "Eşekli Ninni", "Uyusun da Büyüsün Ninni"]
    let videoIDs = ["0B-lXPBlVFnehd3dDbkw5M3JTZzA","0B-lXPBlVFnehYlN3OEtabGFTVjg","0B-lXPBlVFnehRWNuNTNCM1ppMWc","0B-lXPBlVFneha3RZYUE1ekd4YUE"]
    
    let control = AVPlayerViewController()
    var player:AVPlayer!
    var timerZaman:Timer!
    var ileriGeriZaman:Double = 1
    var videoStatus = false
    var userSoundVal: Float = 0.5
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var txtDriveVideoID: UITextField!
    @IBOutlet weak var sesSeviyeLbl: UILabel!
    @IBOutlet weak var sesSeviyeNesne: UISlider!
    @IBOutlet weak var lblGecenSure: UILabel!
    @IBOutlet weak var lblToplamSure: UILabel!
    @IBOutlet weak var sureNesne: UISlider!
    @IBOutlet weak var yukleniyor: UIActivityIndicatorView!
    
    @IBAction func fncVideoPlay(_ sender: UIButton) {
        self.view.endEditing(true)
        self.videoOynat(driveVideoID: self.txtDriveVideoID.text!)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        self.tableView.reloadData()
        self.videoOynat(driveVideoID: self.txtDriveVideoID.text!)
        if UserDefaults.standard.object(forKey: "sesDegeri") != nil {
            self.userSoundVal = UserDefaults.standard.object(forKey: "sesDegeri") as! Float
        }
        self.sesSeviyeNesne.value = userSoundVal
        self.sesSeviyeLbl.text = "% \(Int(userSoundVal * 100))"
    }
    
    
    func videoOynat(driveVideoID:String) {
        
        self.yukleniyor.startAnimating()
        self.yukleniyor.alpha = 1
        self.lblToplamSure.text = "0"
        self.lblGecenSure.text = "0"
        self.sureNesne.maximumValue = 0
        self.sureNesne.minimumValue = 0
        self.sureNesne.value = 0
        /*
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async {
        }}
        print("https://drive.google.com/uc?export=download&id=\(driveVideoID)")
         */
        Alamofire.request("http://api.getlinkdrive.com/getlink?url=https://drive.google.com/file/d/\(driveVideoID)/view").responseJSON { response in
            if let jdata = response.result.value {
               let json = JSON(jdata)
               let sourURL = json[1]["src"].string
                DispatchQueue.global().async {
                self.control.player?.pause()
                let url = URL(string: sourURL!)
                let playerItem:AVPlayerItem = AVPlayerItem(url: url!)
                self.player = AVPlayer(playerItem: playerItem)
                self.control.player = self.player
                self.control.player?.play()
                self.control.player?.volume = self.userSoundVal
                self.videoStatus = true
                self.sesSeviyeNesne.value = self.userSoundVal
                self.sesSeviyeLbl.text = "% \(Int((self.userSoundVal) * 100))"
                self.sureNesne.maximumValue = Float((self.control.player?.currentItem?.asset.duration.seconds)!)
                }
            }
        }
    }
    
    
    func AVPlayerItemTimeJumped(note: NSNotification) {
        if self.timerZaman != nil {
            print("Timer Durum \(timerZaman.isValid)")
            self.timerZaman.invalidate()
        }
        self.timerZaman = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (Timer) in
            self.timerSureCalis()
        }
        self.yukleniyor.stopAnimating()
        self.yukleniyor.alpha = 0
        print("Video Oynuyor")
    }
    
    
    func AVPlayerItemDidPlayToEndTime(note: NSNotification) {
        videoStatus = false
        self.timerZaman.invalidate()
        self.yukleniyor.stopAnimating()
        self.yukleniyor.alpha = 0
        print("Video Bitti")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Simulator Yolu
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        print("Simulator Path : \(path)")
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        playerLayer.zPosition = -1
        
        let vw = self.view.frame.size.width - 20
        let vh = self.view.frame.size.height / 3
        self.control.view.frame = CGRect(x: 10, y: 20, width: vw, height: vh)
        self.view.addSubview(self.control.view)
        self.control.showsPlaybackControls = false
        self.control.player?.seek(to: kCMTimeZero)
        self.control.player?.actionAtItemEnd = .none
        
        // video oynama yakalama
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.AVPlayerItemTimeJumped(note:)),name: NSNotification.Name.AVPlayerItemTimeJumped, object: control.player?.currentItem)
        
        // video bitişi yakalama
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.AVPlayerItemDidPlayToEndTime(note:)),name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: control.player?.currentItem)
    }
    
    
    @IBAction func fncOynat(_ sender: UIButton) {
        if self.control.isReadyForDisplay {
            videoStatus = true
            DispatchQueue.global().async {
                self.control.player?.play()
            }
        }
    }
    
    
    @IBAction func fncdurdur(_ sender: UIButton) {
        if self.control.isReadyForDisplay {
            videoStatus = false
            self.timerZaman.invalidate()
            DispatchQueue.global().async {
                self.control.player?.pause()
            }
        }
    }
    
    
    @IBAction func sesSEviye(_ sender: UISlider) {
        self.userSoundVal = sender.value
        self.sesSeviyeLbl.text = "% \(Int(sender.value * 100))"
        self.control.player?.volume = sender.value
        UserDefaults.standard.set(sender.value, forKey: "sesDegeri")
    }
    
    
    @IBAction func playAcKapa(_ sender: UIButton) {
        if self.control.isReadyForDisplay {
            if(self.control.showsPlaybackControls)
            {
                self.control.showsPlaybackControls = false
                sender.setTitle("Close", for: UIControlState.normal)
            }
            else
            {
                self.control.showsPlaybackControls = true
                sender.setTitle("Open", for: UIControlState.normal)
            }
        }
    }
    
    
    @IBAction func fncBasaSar(_ sender: UIButton) {
        videoStatus = true
        if self.control.isReadyForDisplay {
            let seekTime : CMTime = CMTimeMake(Int64(0), Int32(1))
            self.control.player!.seek(to: seekTime)
            self.control.player!.seek(to: seekTime)
            self.control.player?.play()
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    @IBAction func fncSure(_ sender: UISlider) {
        if self.control.isReadyForDisplay {
            let seekTime : CMTime = CMTimeMake(Int64(sender.value), Int32(1))
            self.control.player!.seek(to: seekTime)
            lblGecenSure.text = self.control.player?.currentTime().durationText
        }
    }
    
    
    func timerSureCalis() {
        print("çalıştı")
        if videoStatus == false {
            self.timerZaman.invalidate()
        }
        self.sureNesne.value = Float((self.control.player?.currentTime().seconds)!)
        lblGecenSure.text = self.control.player?.currentTime().durationText
        lblToplamSure.text = self.control.player?.currentItem?.asset.duration.durationText
        if self.control.player?.currentItem?.error != nil {
            print("Video yüklenirken hata oluştu")
            self.timerZaman.invalidate()
        }
    }
    
    var ileriGeriTimer:Timer!
    @IBAction func ileriBasla(_ sender: UIButton) {
        if self.control.isReadyForDisplay {
            ileriGeriTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (Timer) in
                self.ileriGeriZaman += 1
                let seekTime : CMTime = CMTimeMake(Int64((self.control.player?.currentTime().seconds)! + self.ileriGeriZaman), Int32(1))
                self.control.player!.seek(to: seekTime)
            })
        }
    }
    
    
    @IBAction func ileriBitir(_ sender: UIButton) {
        if self.control.isReadyForDisplay {
            ileriGeriTimer.invalidate()
            ileriGeriZaman = 1
        }
    }
    
    
    @IBAction func geriBasla(_ sender: UIButton) {
        if self.control.isReadyForDisplay {
            ileriGeriTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (Timer) in
                self.ileriGeriZaman -= 1
                let seekTime : CMTime = CMTimeMake(Int64((self.control.player?.currentTime().seconds)! + self.ileriGeriZaman), Int32(1))
                self.control.player!.seek(to: seekTime)
            })
        }
    }
    
    @IBAction func geriBitir(_ sender: UIButton) {
        if self.control.isReadyForDisplay {
            ileriGeriTimer.invalidate()
            ileriGeriZaman = 1
        }
    }
    
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    // tableview senaryoları
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return iconTitle.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = iconTitle[indexPath.row]
        cell.detailTextLabel?.text = videoIDs[indexPath.row]
        cell.imageView?.image = UIImage(named: iconTitle[indexPath.row])
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.videoOynat(driveVideoID: videoIDs[indexPath.row])
    }
    
    
}


extension CMTime {
    var durationText:String {
        let totalSeconds = CMTimeGetSeconds(self)
        let hours:Int = Int(totalSeconds.truncatingRemainder(dividingBy: 86400) / 3600)
        let minutes:Int = Int(totalSeconds.truncatingRemainder(dividingBy: 3600) / 60)
        let seconds:Int = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        if hours > 0 {
            return String(format: "%i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format: "%02i:%02i", minutes, seconds)
        }
    }
}

