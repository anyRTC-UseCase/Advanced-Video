//
//  ARInjectStreamConfigTableViewController.swift
//  ARInjectStreaming
//
//  Created by 余生丶 on 2020/10/15.
//

import UIKit
import ARtcKit

protocol ARInjectStreamConfigTableVCDelegate: NSObjectProtocol {
    func injectStreamConfigTableVCDidUpdate(_ injectStreamConfigTableVC: ARInjectStreamConfigTableViewController)
}

class ARInjectStreamConfigTableViewController: UITableViewController {
    
    // video
    @IBOutlet weak var widthSlider: UISlider!
    @IBOutlet weak var widthLabel: UILabel!
    
    @IBOutlet weak var heightSlider: UISlider!
    @IBOutlet weak var heightLabel: UILabel!
    
    @IBOutlet weak var bitrateSlider: UISlider!
    @IBOutlet weak var bitrateLabel: UILabel!
    
    @IBOutlet weak var fpsSlider: UISlider!
    @IBOutlet weak var fpsLabel: UILabel!
    
    @IBOutlet weak var gopSlider: UISlider!
    @IBOutlet weak var gopLabel: UILabel!
    
    // audio
    @IBOutlet weak var sampleRateSwitch: UISegmentedControl!
    @IBOutlet weak var audioBitRateSwitch: UISegmentedControl!
    @IBOutlet weak var audioChannelsSwitch: UISegmentedControl!
    
    var injectStreamConfig: ARLiveInjectStreamConfig!
    weak var delegate: ARInjectStreamConfigTableVCDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        preferredContentSize = CGSize(width: 320, height: 400)
        print(injectStreamConfig.audioSampleRate)
        updateView(with: injectStreamConfig)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.injectStreamConfigTableVCDidUpdate(self)
    }
    
    @IBAction func doWidthSlided(_ sender: UISlider) {
        let width = sender.value
        widthLabel.formattedFloatValue = width
        injectStreamConfig.size.width = CGFloat(width)
    }
    
    @IBAction func doHeightSlided(_ sender: UISlider) {
        let height = sender.value
        heightLabel.formattedFloatValue = height
        injectStreamConfig.size.height = CGFloat(height)
    }
    
    @IBAction func doBitrateSlided(_ sender: UISlider) {
        let bitrate = sender.value
        bitrateLabel.formattedFloatValue = bitrate
        injectStreamConfig.videoBitrate = Int(bitrate)
    }
    
    @IBAction func doFPSSlided(_ sender: UISlider) {
        let fps = sender.value
        fpsLabel.formattedFloatValue = fps
        injectStreamConfig.videoFramerate = Int(fps)
    }
    
    @IBAction func doGOPSlided(_ sender: UISlider) {
        let gop = sender.value
        gopLabel.formattedFloatValue = gop
        injectStreamConfig.videoGop = Int(gop)
    }
    
    @IBAction func doAudioSampleRateSwitched(_ sender: UISegmentedControl) {
        if let audioSampleRate = ARAudioSampleRateType.sampleRate(at: sender.selectedSegmentIndex) {
            injectStreamConfig.audioSampleRate = audioSampleRate
        }
    }
    
    @IBAction func doAudioBitRateSwitched(_ sender: UISegmentedControl) {
        if let bitRateType = AGStreamAudioBitRate.bitRate(at: sender.selectedSegmentIndex) {
            injectStreamConfig.audioBitrate = bitRateType.rawValue
        }
    }
    
    @IBAction func doAudioChannelsSwitched(_ sender: UISegmentedControl) {
        injectStreamConfig.audioChannels = sender.selectedSegmentIndex + 1
    }
}

private extension ARInjectStreamConfigTableViewController {
    func updateView(with injectStreamConfig: ARLiveInjectStreamConfig) {
        let width = injectStreamConfig.size.width
        widthSlider.cgFloatValue = width
        widthLabel.formattedCGFloatValue = width
        
        let height = injectStreamConfig.size.height
        heightSlider.cgFloatValue = height
        heightLabel.formattedCGFloatValue = height
        
        let bitRate = injectStreamConfig.videoBitrate
        bitrateSlider.intValue = bitRate
        bitrateLabel.formattedIntValue = bitRate
        
        let fps = injectStreamConfig.videoFramerate
        fpsSlider.intValue = fps
        fpsLabel.formattedIntValue = fps
        
        let gop = injectStreamConfig.videoGop
        gopSlider.intValue = gop
        gopLabel.formattedIntValue = gop
        
        sampleRateSwitch.selectedSegmentIndex = injectStreamConfig.audioSampleRate.index()
        if let index = AGStreamAudioBitRate.index(of: injectStreamConfig.audioBitrate) {
            audioBitRateSwitch.selectedSegmentIndex = index
        }
        audioChannelsSwitch.selectedSegmentIndex = injectStreamConfig.audioChannels - 1
    }
}

extension ARAudioSampleRateType {
    func index() -> Int {
        switch self {
        case .type32000: return 0
        case .type44100: return 1
        case .type48000: return 2
        @unknown default:
            fatalError()
        }
    }
    
    static func sampleRate(at index: Int) -> ARAudioSampleRateType? {
        switch index {
        case 0: return .type32000
        case 1: return .type44100
        case 2: return .type48000
        default: return nil
        }
    }
}

enum AGStreamAudioBitRate: Int {
    case type48k = 48
    case type128k = 128
    
    static func index(of rate: Int) -> Int? {
        switch rate {
        case 48:    return 0
        case 128:   return 1
        default:        return nil
        }
    }
    
    static func bitRate(at index: Int) -> AGStreamAudioBitRate? {
        switch index {
        case 0: return .type48k
        case 1: return .type128k
        default: return nil
        }
    }
}
