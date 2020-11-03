//
//  RawMediaDataMain.swift
//  AR-Plugin-RawMediaData-iOS
//
//  Created by 余生丶 on 2020/10/22.
//

import UIKit
import ARtcKit

class RawMediaDataMain: ARBaseViewController {

    var localVideo = Bundle.loadView(fromNib: "VideoView", withType: VideoView.self)
    var remoteVideo = Bundle.loadView(fromNib: "VideoView", withType: VideoView.self)
    
    @IBOutlet weak var container: UIStackView!
    var rtcKit: ARtcEngineKit!
    var rtcMediaDataPlugin: ARMediaDataPlugin?
    
    // indicate if current instance has joined channel
    var isJoined: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // layout render view
        localVideo.setPlaceholder(text: "本地预览")
        remoteVideo.setPlaceholder(text: "远端视频")
        container.addArrangedSubview(localVideo)
        container.addArrangedSubview(remoteVideo)
        
        // set up instance when view loadedlet config = ARtcEngineConfig()
        rtcKit = ARtcEngineKit.sharedEngine(withAppId: AppID, delegate: self)
        
        // get channel name from configs
        guard let channelName = configs["channelName"] as? String else {return}
        
        // make myself a broadcaster
        rtcKit.setChannelProfile(.profileiveBroadcasting)
        rtcKit.setClientRole(.broadcaster)
        
        
        // enable video module and set up video encoding configs
        rtcKit.enableVideo()
        rtcKit.setVideoEncoderConfiguration(ARVideoEncoderConfiguration(size: CGSize.init(width: 640, height: 360), frameRate: .fps15, bitrate: 400, orientationMode: .adaptative))
        
        // setup raw media data observers
       rtcMediaDataPlugin = ARMediaDataPlugin(rtcKit: rtcKit);
        
        // Register audio observer
        let audioType:ObserverAudioType = ObserverAudioType(rawValue: ObserverAudioType.recordAudio.rawValue | ObserverAudioType.playbackAudioFrameBeforeMixing.rawValue | ObserverAudioType.mixedAudio.rawValue | ObserverAudioType.playbackAudio.rawValue) ;
        rtcMediaDataPlugin?.registerAudioRawDataObserver(audioType)
        rtcMediaDataPlugin?.audioDelegate = self

        // Register video observer
        let videoType:ObserverVideoType = ObserverVideoType(rawValue: ObserverVideoType.captureVideo.rawValue | ObserverVideoType.renderVideo.rawValue | ObserverVideoType.preEncodeVideo.rawValue)
        rtcMediaDataPlugin?.registerVideoRawDataObserver(videoType)
        rtcMediaDataPlugin?.videoDelegate = self;

        // Register packet observer
        let packetType:ObserverPacketType = ObserverPacketType(rawValue: ObserverPacketType.sendAudio.rawValue | ObserverPacketType.sendVideo.rawValue | ObserverPacketType.receiveAudio.rawValue | ObserverPacketType.receiveVideo.rawValue)
        rtcMediaDataPlugin?.registerPacketRawDataObserver(packetType)
        rtcMediaDataPlugin?.packetDelegate = self;
        
        // set up local video to render your local camera preview
        let videoCanvas = ARtcVideoCanvas()
        videoCanvas.uid = "0"
        // the view to be binded
        videoCanvas.view = localVideo.videoView
        videoCanvas.renderMode = .hidden
        rtcKit.setupLocalVideo(videoCanvas)
        
        // Set audio route to speaker
        rtcKit.setDefaultAudioRouteToSpeakerphone(true)
        
        // start joining channel
        // 1. Users can only see each other after they join the
        // same channel successfully using the same app id.
        // 2. If app certificate is turned on at dashboard, token is needed
        // when joining channel. The channel name and uid used to calculate
        // the token has to match the ones used for channel join
        let result = rtcKit.joinChannel(byToken: nil, channelId: channelName, uid: nil) {[unowned self] (channel, uid, elapsed) -> Void in
            self.isJoined = true
            ARLogUtils.log(message: "Join \(channel) with uid \(uid) elapsed \(elapsed)ms", level: .info)
        }
        if result != 0 {
            // Usually happens with invalid parameters
            // Error code description can be found at:
            self.showAlert(title: "Error", message: "joinChannel call failed: \(result), please check your params")
        }
    }
    
    override func willMove(toParent parent: UIViewController?) {
        if parent == nil {
            // leave channel when exiting the view
            if isJoined {
                rtcKit.leaveChannel { (stats) -> Void in
                    ARLogUtils.log(message: "left channel, duration: \(stats.duration)", level: .info)
                }
            }
        }
    }
}

/// anyrtc engine delegate events
extension RawMediaDataMain: ARtcEngineDelegate {
    /// callback when warning occured for sdk, warning can usually be ignored, still it's nice to check out
    /// what is happening
    /// Warning code description can be found at:
    /// @param warningCode warning code of the problem
    func rtcEngine(_ engine: ARtcEngineKit, didOccurWarning warningCode: ARWarningCode) {
        ARLogUtils.log(message: "warning: \(warningCode)", level: .warning)
    }
    
    /// callback when error occured for sdk, you are recommended to display the error descriptions on demand
    /// to let user know something wrong is happening
    /// Error code description can be found at:
    /// @param errorCode error code of the problem
    func rtcEngine(_ engine: ARtcEngineKit, didOccurError errorCode: ARErrorCode) {
        ARLogUtils.log(message: "error: \(errorCode)", level: .error)
        self.showAlert(title: "Error", message: "Error \(errorCode) occur")
    }
    
    /// callback when a remote user is joinning the channel, note audience in live broadcast mode will NOT trigger this event
    /// @param uid uid of remote joined user
    /// @param elapsed time elapse since current sdk instance join the channel in ms
    func rtcEngine(_ engine: ARtcEngineKit, didJoinedOfUid uid: String, elapsed: Int) {
        ARLogUtils.log(message: "remote user join: \(uid) \(elapsed)ms", level: .info)
        
        // Only one remote video view is available for this
        // tutorial. Here we check if there exists a surface
        // view tagged as this uid.
        let videoCanvas = ARtcVideoCanvas()
        videoCanvas.uid = uid
        // the view to be binded
        videoCanvas.view = remoteVideo.videoView
        videoCanvas.renderMode = .hidden
        rtcKit.setupRemoteVideo(videoCanvas)
    }
    
    /// callback when a remote user is leaving the channel, note audience in live broadcast mode will NOT trigger this event
    /// @param uid uid of remote joined user
    /// @param reason reason why this user left, note this event may be triggered when the remote user
    /// become an audience in live broadcasting profile
    func rtcEngine(_ engine: ARtcEngineKit, didOfflineOfUid uid: String, reason: ARUserOfflineReason) {
        ARLogUtils.log(message: "remote user left: \(uid) reason \(reason)", level: .info)
        
        // to unlink your view from sdk, so that your view reference will be released
        // note the video will stay at its last frame, to completely remove it
        // you will need to remove the EAGL sublayer from your binded view
        let videoCanvas = ARtcVideoCanvas()
        videoCanvas.uid = uid
        // the view to be binded
        videoCanvas.view = nil
        videoCanvas.renderMode = .hidden
        rtcKit.setupRemoteVideo(videoCanvas)
    }
}

// audio data plugin, here you can process raw audio data
// note this all happens in CPU so it comes with a performance cost
extension RawMediaDataMain : ARAudioDataPluginDelegate
{
    /// Retrieves the recorded audio frame.
    func mediaDataPlugin(_ mediaDataPlugin: ARMediaDataPlugin, didRecord audioRawData: ARAudioRawData) -> ARAudioRawData {
        return audioRawData
    }
    
    /// Retrieves the audio playback frame for getting the audio.
    func mediaDataPlugin(_ mediaDataPlugin: ARMediaDataPlugin, willPlaybackAudioRawData audioRawData: ARAudioRawData) -> ARAudioRawData {
        return audioRawData
    }
    
    /// Retrieves the audio frame of a specified user before mixing.
    /// The SDK triggers this callback if isMultipleChannelFrameWanted returns false.
    func mediaDataPlugin(_ mediaDataPlugin: ARMediaDataPlugin, willPlaybackBeforeMixing audioRawData: ARAudioRawData, ofUid uid: String) -> ARAudioRawData {
        return audioRawData
    }
    
    /// Retrieves the mixed recorded and playback audio frame.
    func mediaDataPlugin(_ mediaDataPlugin: ARMediaDataPlugin, didMixedAudioRawData audioRawData: ARAudioRawData) -> ARAudioRawData {
        return audioRawData
    }
}

// video data plugin, here you can process raw video data
// note this all happens in CPU so it comes with a performance cost
extension RawMediaDataMain : ARVideoDataPluginDelegate
{
    /// Occurs each time the SDK receives a video frame captured by the local camera.
    /// After you successfully register the video frame observer, the SDK triggers this callback each time a video frame is received. In this callback, you can get the video data captured by the local camera. You can then pre-process the data according to your scenarios.
    /// After pre-processing, you can send the processed video data back to the SDK by setting the videoFrame parameter in this callback.
    func mediaDataPlugin(_ mediaDataPlugin: ARMediaDataPlugin, didCapturedVideoRawData videoRawData: ARVideoRawData) -> ARVideoRawData {
        return videoRawData
    }
    
    /// Occurs each time the SDK receives a video frame before sending to encoder
    /// After you successfully register the video frame observer, the SDK triggers this callback each time a video frame is going to be sent to encoder. In this callback, you can get the video data before it is sent to enoder. You can then pre-process the data according to your scenarios.
    /// After pre-processing, you can send the processed video data back to the SDK by setting the videoFrame parameter in this callback.
    func mediaDataPlugin(_ mediaDataPlugin: ARMediaDataPlugin, willPreEncode videoRawData: ARVideoRawData) -> ARVideoRawData {
        return videoRawData
    }
    
    /// Occurs each time the SDK receives a video frame sent by the remote user.
    ///After you successfully register the video frame observer and isMultipleChannelFrameWanted return false, the SDK triggers this callback each time a video frame is received. In this callback, you can get the video data sent by the remote user. You can then post-process the data according to your scenarios.
    ///After post-processing, you can send the processed data back to the SDK by setting the videoFrame parameter in this callback.
    func mediaDataPlugin(_ mediaDataPlugin: ARMediaDataPlugin, willRenderVideoRawData videoRawData: ARVideoRawData, ofUid uid: String) -> ARVideoRawData {
        return videoRawData
    }
}

// packet data plugin, here you can process raw network packet(before decoding/encoding)
// note this all happens in CPU so it comes with a performance cost
extension RawMediaDataMain : ARPacketDataPluginDelegate
{
    /// Occurs when the local user sends a video packet.
    func mediaDataPlugin(_ mediaDataPlugin: ARMediaDataPlugin, willSendVideoPacket videoPacket: ARPacketRawData) -> ARPacketRawData {
        return videoPacket
    }
    
    /// Occurs when the local user sends an audio packet.
    func mediaDataPlugin(_ mediaDataPlugin: ARMediaDataPlugin, willSendAudioPacket audioPacket: ARPacketRawData) -> ARPacketRawData {
        return audioPacket
    }
    
    /// Occurs when the local user receives a video packet.
    func mediaDataPlugin(_ mediaDataPlugin: ARMediaDataPlugin, didReceivedVideoPacket videoPacket: ARPacketRawData) -> ARPacketRawData {
        return videoPacket
    }
    
    /// Occurs when the local user receives an audio packet.
    func mediaDataPlugin(_ mediaDataPlugin: ARMediaDataPlugin, didReceivedAudioPacket audioPacket: ARPacketRawData) -> ARPacketRawData {
        return audioPacket
    }
}

