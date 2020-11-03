//
//  ARLiveRoomViewController.swift
//  ARInjectStreaming
//
//  Created by 余生丶 on 2020/10/15.
//

import UIKit
import ARtcKit

let ScreenWidth = UIScreen.main.bounds.size.width
let ScreenHeight = UIScreen.main.bounds.size.height

class ARLiveRoomViewController: UIViewController {

    @IBOutlet weak var broadcastButton: UIButton!
    @IBOutlet weak var audioMuteButton: UIButton!
    @IBOutlet weak var switchButton: UIButton!
    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var rtmpButton: UIButton!
    @IBOutlet weak var injectConfigButton: UIButton!
    @IBOutlet weak var remoteContainerView: UIView!
    
    var roomName: String!
    var myUid: String?
    var clientRole = ARClientRole.audience {
        didSet {
            updateButtonsVisiablity()
        }
    }
    
    fileprivate var isBroadcaster: Bool {
        return clientRole == .broadcaster
    }
    
    var rtcEngine: ARtcEngineKit!
    
    fileprivate var videoSessions = [ARVideoSession]() {
        didSet {
            guard remoteContainerView != nil else {
                return
            }
            updateInterface(withAnimation: true)
        }
    }
    
    fileprivate var fullSession: ARVideoSession? {
        didSet {
            if fullSession != oldValue && remoteContainerView != nil {
                updateInterface(withAnimation: true)
            }
        }
    }
    
    fileprivate let viewLayouter = ARVideoViewLayouter()
    
    fileprivate var injectStreamConfig = ARLiveInjectStreamConfig()
    
    fileprivate var injectRtmpUrl: String?
    
    @IBAction func doDoubleTapped(_ sender: UITapGestureRecognizer) {
        if fullSession == nil {
            if let tappedSession = viewLayouter.responseSession(of: sender, inSessions: videoSessions, inContainerView: remoteContainerView) {
                fullSession = tappedSession
            }
        } else {
            fullSession = nil
        }
    }
    
    @IBAction func doBroadcastPressed(_ sender: UIButton) {
        if isBroadcaster {
            clientRole = .audience
            if fullSession?.uid == "0" {
                fullSession = nil
            }
        } else {
            clientRole = .broadcaster
        }
        
        rtcEngine.setClientRole(clientRole)
        updateInterface(withAnimation :true)
    }
    
    @IBAction func doSwitchCameraPressed(_ sender: UIButton) {
        rtcEngine.switchCamera()
    }
    
    @IBAction func doMutePressed(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        rtcEngine.muteLocalAudioStream(sender.isSelected)
    }
    
    @IBAction func doRtmpPressed(_ sender: UIButton) {
        if sender.isSelected {
            rtcEngine.removeInjectStreamUrl(injectRtmpUrl!)
            self.injectRtmpUrl = nil
        } else {
            let popView = ARPopView.newPopViewWith(buttonTitle: "Add Stream", placeholder: "Input Rtmp URL ...")
            popView?.frame = CGRect(x: 0, y: ScreenHeight, width: ScreenWidth, height: ScreenHeight)
            popView?.delegate = self
            self.view.addSubview(popView!)
            UIView.animate(withDuration: 0.2) {
                popView?.frame = self.view.frame
            }
        }
    }
    
    @IBAction func doLeavePressed(_ sender: UIButton) {
        leaveChannel()
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        roomNameLabel.text = roomName
        updateButtonsVisiablity()
        
        loadAgoraKit()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueId = segue.identifier, !segueId.isEmpty else {
            return
        }
        switch segueId {
        case "channelPopInjectConfig":
            let injectConfigVC = segue.destination as! ARInjectStreamConfigTableViewController
            injectConfigVC.injectStreamConfig = injectStreamConfig
            injectConfigVC.delegate = self
            injectConfigVC.popoverPresentationController?.delegate = self
            
        default:
            break
        }
    }
}

private extension ARLiveRoomViewController {
    func updateButtonsVisiablity() {
        guard let broadcastButton = self.broadcastButton, let switchButton = self.switchButton,  let audioMuteButton = self.audioMuteButton else {
            return
        }
        broadcastButton.isSelected = self.isBroadcaster
        switchButton.isHidden = !self.isBroadcaster
        audioMuteButton.isHidden = !self.isBroadcaster
    }
    
    func updateInterface(withAnimation animation: Bool) {
        if animation {
            UIView.animate(withDuration: 0.3) {
                self.updateInterface()
                self.view.layoutIfNeeded()
            }
        } else {
            updateInterface()
        }
    }
    
    func updateInterface() {
        var displaySessions = videoSessions
        if !isBroadcaster && !displaySessions.isEmpty {
            displaySessions.removeFirst()
        }
        viewLayouter.layout(sessions: displaySessions, fullSession: fullSession, inContainer: remoteContainerView)
        setStreamType(forSessions: displaySessions, fullSession: fullSession)
    }
    
    func setStreamType(forSessions sessions: [ARVideoSession], fullSession: ARVideoSession?) {
        if let fullSession = fullSession {
            for session in sessions {
                rtcEngine.setRemoteVideoStream(session.uid, type: (session == fullSession ? .high : .low))
            }
        } else {
            for session in sessions {
                rtcEngine.setRemoteVideoStream(session.uid, type: .high)
            }
        }
    }
    
    func addLocalSession() {
        let localSession = ARVideoSession.localSession()
        videoSessions.append(localSession)
        rtcEngine.setupLocalVideo(localSession.canvas)
    }
    
    func fetchSession(ofUid uid: String) -> ARVideoSession? {
        for session in videoSessions {
            if session.uid == uid {
                return session
            }
        }
        return nil
    }
    
    func videoSession(ofUid uid: String) -> ARVideoSession {
        if let fetchedSession = fetchSession(ofUid: uid) {
            return fetchedSession
        } else {
            let newSession = ARVideoSession(uid: uid)
            videoSessions.append(newSession)
            return newSession
        }
    }
    
    func setIdleTimerActive(_ active: Bool) {
        UIApplication.shared.isIdleTimerDisabled = !active
    }
    
    func alert(string: String) {
        guard !string.isEmpty else {
            return
        }
        
        let alert = UIAlertController(title: nil, message: string, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

//MARK: - ARtcKit SDK

private extension ARLiveRoomViewController {
    func loadAgoraKit() {
        rtcEngine = ARtcEngineKit.sharedEngine(withAppId: AppID, delegate: self)
        rtcEngine.setChannelProfile(.profileiveBroadcasting)
        rtcEngine.enableDualStreamMode(true)
        rtcEngine.enableVideo()
        rtcEngine.setClientRole(clientRole)
        
        addLocalSession()
        let code = rtcEngine.joinChannel(byToken: nil, channelId: roomName, uid: "0", joinSuccess: nil)
        if code == 0 {
            setIdleTimerActive(false)
            rtcEngine.setEnableSpeakerphone(true)
        } else {
            DispatchQueue.main.async(execute: {
                self.alert(string: "Join channel failed: \(code)")
            })
        }
    }
    
    func leaveChannel() {
        setIdleTimerActive(true)
        
        rtcEngine.setupLocalVideo(nil)
        rtcEngine.leaveChannel(nil)
        if isBroadcaster {
            rtcEngine.stopPreview()
        }
        
        for session in videoSessions {
            session.hostingView.removeFromSuperview()
        }
        videoSessions.removeAll()
    }
}

extension ARLiveRoomViewController: ARtcEngineDelegate {
    
    func rtcEngine(_ engine: ARtcEngineKit, didJoinChannel channel: String, withUid uid: String, elapsed: Int) {
        myUid = uid
    }
    
    func rtcEngine(_ engine: ARtcEngineKit, didJoinedOfUid uid: String, elapsed: Int) {
        let userSession = videoSession(ofUid: uid)
        rtcEngine.setupRemoteVideo(userSession.canvas)
        
        // check if is the RTMP stream
        if uid == "share666" {
            if injectRtmpUrl == nil {
                rtmpButton.isHidden = true
                injectConfigButton.isHidden = true
            }
        }
    }
    
    func rtcEngine(_ engine: ARtcEngineKit, firstLocalVideoFrameWith size: CGSize, elapsed: Int) {
        if let _ = videoSessions.first {
            updateInterface(withAnimation: false)
        }
    }
    
    func rtcEngine(_ engine: ARtcEngineKit, didOfflineOfUid uid: String, reason: ARUserOfflineReason) {
        var indexToDelete: Int?
        for (index, session) in videoSessions.enumerated() {
            if session.uid == uid {
                indexToDelete = index
            }
        }
        
        if let indexToDelete = indexToDelete {
            let deletedSession = videoSessions.remove(at: indexToDelete)
            deletedSession.hostingView.removeFromSuperview()
            
            if deletedSession == fullSession {
                fullSession = nil
            }
        }
        
        // check if is the RTMP stream
        if uid == "share666" {
            if injectRtmpUrl == nil {
                rtmpButton.isHidden = false
                injectConfigButton.isHidden = false
            }
        }
    }
    
    func rtcEngine(_ engine: ARtcEngineKit, streamInjectedStatusOfUrl url: String, uid: String, status: ARInjectStreamStatus) {
        switch status {
        case .startSuccess:
            self.rtmpButton.isSelected = true
        case .stopSuccess:
            self.rtmpButton.isSelected = false
        default:
            self.alert(string: "streamInjectedStatusOfUrl: \(status.rawValue)")
        }
    }
}

extension ARLiveRoomViewController: ARInjectStreamConfigTableVCDelegate {
    func injectStreamConfigTableVCDidUpdate(_ injectStreamConfigTableVC: ARInjectStreamConfigTableViewController) {
        injectStreamConfig = injectStreamConfigTableVC.injectStreamConfig
    }
}

//MARK: - UIPopoverPresentationControllerDelegate

extension ARLiveRoomViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

extension ARLiveRoomViewController: ARPopViewDelegate {
    func popViewButtonDidPressed(_ popView: ARPopView) {
        guard let url = popView.inputTextField.text else {
            return
        }
        self.injectRtmpUrl = url
        rtcEngine.addInjectStreamUrl(url, config: self.injectStreamConfig)
        
        popView.removeFromSuperview()
    }
}
