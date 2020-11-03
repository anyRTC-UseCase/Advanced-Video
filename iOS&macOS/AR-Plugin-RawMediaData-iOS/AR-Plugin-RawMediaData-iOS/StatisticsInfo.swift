//
//  StatisticsInfo.swift
//  AR-Plugin-RawMediaData-iOS
//
//  Created by 余生丶 on 2020/10/22.
//

import Foundation
import ARtcKit

struct StatisticsInfo {
    struct LocalInfo {
        var channelStats = ARChannelStats()
        var videoStats = ARtcLocalVideoStats()
        var audioStats = ARtcLocalAudioStats()
    }
    
    struct RemoteInfo {
        var videoStats = ARtcRemoteVideoStats()
        var audioStats = ARtcRemoteAudioStats()
    }
    
    enum StatisticsType {
        case local(LocalInfo), remote(RemoteInfo)
        
        var isLocal: Bool {
            switch self {
            case .local:  return true
            case .remote: return false
            }
        }
    }
    
    var dimension = CGSize.zero
    var fps:UInt = 0
    
    var type: StatisticsType
    
    init(type: StatisticsType) {
        self.type = type
    }
    
    mutating func updateChannelStats(_ stats: ARChannelStats) {
        guard self.type.isLocal else {
            return
        }
        switch type {
        case .local(let info):
            var new = info
            new.channelStats = stats
            self.type = .local(new)
        default:
            break
        }
    }
    
    mutating func updateLocalVideoStats(_ stats: ARtcLocalVideoStats) {
        guard self.type.isLocal else {
            return
        }
        switch type {
        case .local(let info):
            var new = info
            new.videoStats = stats
            self.type = .local(new)
        default:
            break
        }
        dimension = CGSize(width: Int(stats.encodedFrameWidth), height: Int(stats.encodedFrameHeight))
        fps = stats.sentFrameRate
    }
    
    mutating func updateLocalAudioStats(_ stats: ARtcLocalAudioStats) {
        guard self.type.isLocal else {
            return
        }
        switch type {
        case .local(let info):
            var new = info
            new.audioStats = stats
            self.type = .local(new)
        default:
            break
        }
    }
    
    mutating func updateVideoStats(_ stats: ARtcRemoteVideoStats) {
        switch type {
        case .remote(let info):
            var new = info
            new.videoStats = stats
            dimension = CGSize(width: Int(stats.width), height: Int(stats.height))
            fps = stats.rendererOutputFrameRate
            self.type = .remote(new)
        default:
            break
        }
    }
    
    mutating func updateAudioStats(_ stats: ARtcRemoteAudioStats) {
        switch type {
        case .remote(let info):
            var new = info
            new.audioStats = stats
            self.type = .remote(new)
        default:
            break
        }
    }
    
    func description(audioOnly:Bool) -> String {
        var full: String
        switch type {
        case .local(let info):  full = localDescription(info: info, audioOnly: audioOnly)
        case .remote(let info): full = remoteDescription(info: info, audioOnly: audioOnly)
        }
        return full
    }
    
    func localDescription(info: LocalInfo, audioOnly: Bool) -> String {
        
        let dimensionFps = "\(Int(dimension.width))×\(Int(dimension.height)),\(fps)fps"
        
        let lastmile = "LM Delay: \(info.channelStats.lastmileDelay)ms"
        let videoSend = "VSend: \(info.videoStats.sentBitrate)kbps"
        let audioSend = "ASend: \(info.audioStats.sentBitrate)kbps"
        let cpu = "CPU: \(info.channelStats.cpuAppUsage)%/\(info.channelStats.cpuTotalUsage)%"
        let vSendLoss = "VSend Loss:"
        let aSendLoss = "ASend Loss:"
//        let vSendLoss = "VSend Loss: \(info.videoStats.txPacketLossRate)%"
//        let aSendLoss = "ASend Loss: \(info.audioStats.txPacketLossRate)%"
        
        if(audioOnly) {
            return [lastmile,audioSend,cpu,aSendLoss].joined(separator: "\n")
        }
        return [dimensionFps,lastmile,videoSend,audioSend,cpu,vSendLoss,aSendLoss].joined(separator: "\n")
    }
    
    func remoteDescription(info: RemoteInfo, audioOnly: Bool) -> String {
        let dimensionFpsBit = "\(Int(dimension.width))×\(Int(dimension.height)), \(fps)fps"
        
        var audioQuality: ARNetworkQuality
        if let quality = ARNetworkQuality(rawValue: info.audioStats.quality.rawValue) {
            audioQuality = quality
        } else {
            audioQuality = ARNetworkQuality.unknown
        }
        
        let videoRecv = "VRecv: \(info.videoStats.receivedBitrate)kbps"
        let audioRecv = "ARecv: \(info.audioStats.receivedBitrate)kbps"
        
        let videoLoss = "VLoss: \(info.videoStats.packetLossRate)%"
        let audioLoss = "ALoss: \(info.audioStats.audioLossRate)%"
        let aquality = "AQuality:"
//        let aquality = "AQuality: \(audioQuality.description())"
        if(audioOnly) {
            return [audioRecv,audioLoss,aquality].joined(separator: "\n")
        }
        return [dimensionFpsBit,videoRecv,audioRecv,videoLoss,audioLoss,aquality].joined(separator: "\n")
    }
}
