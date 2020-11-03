//
//  ARLiveRoomViewController.swift
//  OpenLive
//
//  Created by 余生丶 on 2020/10/16.
//

import UIKit
import ARtcKit

protocol ARLiveRoomVCDelegate: NSObjectProtocol {
    func liveVCNeedClose(_ liveVC: ARLiveRoomViewController)
}

class ARLiveRoomViewController: UIViewController {
    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var remoteContainerView: UIView!
    @IBOutlet weak var broadcastButton: UIButton!
    @IBOutlet weak var audioMuteButton: UIButton!
    @IBOutlet var sessionButtons: [UIButton]!
    
    var currentUid: String?
    var currentChannel: String!
    
    var videoConfig: ARVideoConfig?
    
    var sourceUid: String?
    var sourceToken: String?
    var sourceChannel: String?
    
    var destinationList: [ARDestination]?
   
    weak var delegate: ARLiveRoomVCDelegate?
    weak var collectionView: UICollectionView?
    
    fileprivate var chatMessageVC: ARChatMessageViewController?
    
    var clientRole = ARClientRole.audience {
        didSet {
            updateButtonsVisiablity()
        }
    }
    var rtcEngine: ARtcEngineKit!
    
    fileprivate var isBroadcaster: Bool {
        return clientRole == .broadcaster
    }
    fileprivate var isMuted = false {
        didSet {
            rtcEngine?.muteLocalAudioStream(isMuted)
            audioMuteButton?.setImage(UIImage(named: isMuted ? "btn_mute_cancel" : "btn_mute"), for: .normal)
        }
    }

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        roomNameLabel.text = currentChannel
        updateButtonsVisiablity()
        loadRtcKit()
    }
    
    //MARK: - user action
    @IBAction func doSwitchCameraPressed(_ sender: UIButton) {
        rtcEngine?.switchCamera()
    }
    
    @IBAction func doMutePressed(_ sender: UIButton) {
        isMuted = !isMuted
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
    
    @IBAction func doDoubleTapped(_ sender: UITapGestureRecognizer) {
        if fullSession == nil {
            if let tappedSession = viewLayouter.responseSession(of: sender, inSessions: videoSessions, inContainerView: remoteContainerView) {
                fullSession = tappedSession
            }
        } else {
            fullSession = nil
        }
    }
    
    @IBAction func doLeavePressed(_ sender: UIButton) {
        leaveChannel()
    }
    
    @IBAction func doStartPressed(_ sender: UIButton) {
        if let config = getMediaRelayConfiguration() {
            let value = rtcEngine.startChannelMediaRelay(config)
            info(string: "start channel media relay return value: \(value)")
        }
    }
    
    @IBAction func doUpdatePressed(_ sender: UIButton) {
        if let config = getMediaRelayConfiguration() {
            let value = rtcEngine.updateChannelMediaRelay(config)
            info(string: "update channel media relay return value: \(value)")
        }
    }
    
    @IBAction func doStopPressed(_ sender: UIButton) {
        let value = rtcEngine.stopChannelMediaRelay()
        info(string: "stop channel media relay return value: \(value)")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueId = segue.identifier else {
            return
        }

        switch segueId {
        case "VideoVCEmbedChatMessageVC":
            chatMessageVC = segue.destination as? ARChatMessageViewController
        case "liveToDestination":
            let destVC = segue.destination as! ARDestinationViewController
            destVC.collectionView?.dataSource = self
            destVC.updateLayout(updateCollectionView())
            self.collectionView = destVC.collectionView
        default:
            break
        }
    }
}

private extension ARLiveRoomViewController {
    func updateCollectionView() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        let width = 240 * 0.25
        layout.itemSize = CGSize(width: width, height: 180)
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        return layout
    }
    
    func updateButtonsVisiablity() {
        guard let sessionButtons = sessionButtons else {
            return
        }

        broadcastButton?.setImage(UIImage(named: isBroadcaster ? "btn_join_cancel" : "btn_join"), for: UIControl.State())

        for button in sessionButtons {
            button.isHidden = !isBroadcaster
        }
    }
    
    func setIdleTimerActive(_ active: Bool) {
        UIApplication.shared.isIdleTimerDisabled = !active
    }
    
    func alert(string: String) {
        guard !string.isEmpty else {
            return
        }
        chatMessageVC?.append(alert: string)
    }
    
    func info(string: String) {
        guard !string.isEmpty else {
            return
        }
        chatMessageVC?.append(chat: string)
    }
}

private extension ARLiveRoomViewController {
    func updateInterface(withAnimation animation: Bool) {
        if animation {
            UIView.animate(withDuration: 0.3, animations: { [weak self] in
                self?.updateInterface()
                self?.view.layoutIfNeeded()
            })
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
}

//MARK: - ARtcKit SDK

private extension ARLiveRoomViewController {
    func loadRtcKit() {
        rtcEngine = ARtcEngineKit.sharedEngine(withAppId: AppID, delegate: self)
        rtcEngine.enableVideo()

        let file = NSHomeDirectory() + "/Documents/sdk.log"
        rtcEngine.setLogFile(file)
        rtcEngine.enableVideo()
        rtcEngine.setChannelProfile(.profileiveBroadcasting)
        
        if let config = videoConfig {

        } else {
            
        }
        
        rtcEngine.setClientRole(clientRole)
        if isBroadcaster {
            rtcEngine.startPreview()
        }
        
        addLocalSession()
        
        let code = rtcEngine.joinChannel(byToken: nil, channelId: currentChannel, uid: currentUid, joinSuccess: nil)
        
        info(string: "join channel uid: \(currentUid ?? "0")")
        
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
        
        delegate?.liveVCNeedClose(self)
    }
    
    func getMediaRelayConfiguration() -> ARChannelMediaRelayConfiguration? {
        guard let list = destinationList else {
            alert(string: "destination list nil")
            return nil
        }
        
        let config = ARChannelMediaRelayConfiguration()
        
        // Source
        if let uid = sourceUid {
            config.sourceInfo.uid = uid
        } else {
            config.sourceInfo.uid = currentUid!
        }
        
        if let channel = sourceChannel {
            config.sourceInfo.channelName = channel
        }
        
        if let token = sourceToken {
            config.sourceInfo.token = token
        }
        
        info(string: "Source: channel: \(config.sourceInfo.channelName ?? "nil"), uid: \(config.sourceInfo.uid), token: \(config.sourceInfo.token ?? "nil")")
        
        // Destination
        for item in list where item.isPrepareForMediaRelay() {
            let info = getRelayInfoFromDestination(item)
            config.setDestinationInfo(info, forChannelName: item.channel)
        }
        
        guard let destinationInfos = config.destinationInfos else {
            alert(string: "destinationInfos nil")
            return nil
        }
        
        for (key, value) in destinationInfos {
            info(string: "Destination: channel: \(key), uid: \(value.uid), token: \(value.token ?? "nil")")
        }
        
        return config
    }
    
    func getRelayInfoFromDestination(_ destination: ARDestination) -> ARChannelMediaRelayInfo {
        let info = ARChannelMediaRelayInfo(token: destination.token.count > 0 ? destination.token : nil)
        info.uid = destination.uid
        return info
    }
}

extension ARLiveRoomViewController: ARtcEngineDelegate {
    
    func rtcEngine(_ engine: ARtcEngineKit, didJoinChannel channel: String, withUid uid: String, elapsed: Int) {
        let userSession = videoSession(ofUid: uid)
        rtcEngine.setupRemoteVideo(userSession.canvas)
        info(string: "didJoinedOfUid: \(uid)")
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
    }
    
    func rtcEngine(_ engine: ARtcEngineKit, channelMediaRelayStateDidChange state: ARChannelMediaRelayState, error: ARChannelMediaRelayError) {
        if error == .none {
            info(string: "channelMediaRelayStateDidChange, state: \(state.rawValue), error: \(error.rawValue))")
        } else {
            alert(string: "channelMediaRelayStateDidChange, state: \(state.rawValue), error: \(error.rawValue))")
        }
    }
    
    func rtcEngine(_ engine: ARtcEngineKit, didReceive event: ARChannelMediaRelayEvent) {
        info(string: "didReceivedChannelMediaRelayEvent: \(event.rawValue)")
    }
    
    func rtcEngine(_ engine: ARtcEngineKit, didOccurError errorCode: ARErrorCode) {
        alert(string: "didOccurError: \(errorCode.rawValue)")
    }
    
    func rtcEngine(_ engine: ARtcEngineKit, didOccurWarning warningCode: ARWarningCode) {
        alert(string: "didOccurWarning: \(warningCode.rawValue)")
    }
}

extension ARLiveRoomViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return destinationList!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DestinationView", for: indexPath) as! ARDestinationView
        cell.delegate = self
        let info = destinationList![indexPath.row]
        cell.updateFrom(info)
        return cell
    }
}

extension ARLiveRoomViewController: ARDestinationViewDelegate {
    func destinationView(_ cell: ARDestinationView, willUpdate info: ARDestination) {
        if let index = collectionView?.indexPath(for: cell) {
            destinationList![index.item] = info
        }
    }
}

