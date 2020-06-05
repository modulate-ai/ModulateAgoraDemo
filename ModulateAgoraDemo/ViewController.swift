import UIKit
import AgoraAudioKit

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {

    @IBOutlet weak var radioSlider: UISlider!
    @IBOutlet weak var presenceSlider: UISlider!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var channelTextField: UITextField!
    
    var agoraKit: AgoraRtcEngineKit!
    var modulate_interface: ModulateAgoraInterface!
    var currently_calling: Bool = false
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeAgoraEngine()
        let sample_rate: UInt32 = 32000;
        let frame_size: UInt32 = 320; // 10ms
        agoraKit.setRecordingAudioFrameParametersWithSampleRate(Int(sample_rate), channel: 1, mode: AgoraAudioRawFrameOperationMode(rawValue: 2)!, samplesPerCall: Int(frame_size))
        
        // Setup Modulate interface and hook into Agora
        modulate_interface = ModulateAgoraInterface(maxFrameSize: frame_size, andExpectedSampleRate: sample_rate)
        modulate_interface.attachModulate(to: agoraKit)
        
        // Sync Modulate voice skin customization filter parameters with slider values
        modulate_interface.setRadioStrength(radioSlider.value);
        modulate_interface.setPresenceStrength(presenceSlider.value);

        joinChannel()
    }
    
    func askForMicrophonePermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case AVAudioSessionRecordPermission.granted:
            print("Permission granted")
        case AVAudioSessionRecordPermission.denied:
            print("Pemission denied")
        case AVAudioSessionRecordPermission.undetermined:
            print("Request permission here")
            AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
                // Handle granted
            })
        @unknown default:
            print("Switch case Error");
        }
    }
    
    func initializeAgoraEngine() {
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: AppID, delegate: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return true;
    }
    
    func joinChannel() {
        askForMicrophonePermission();
        let channelId: String = channelTextField.text!
        agoraKit.joinChannel(byToken: Token, channelId: channelId, info:nil, uid:0) {
            [unowned self] (sid, uid, elapsed) -> Void in
            NSLog("Joined channel %@", channelId);
            self.agoraKit.setEnableSpeakerphone(false)
            UIApplication.shared.isIdleTimerDisabled = true
            self.currently_calling = true
            let button_image: UIImage = UIImage(named: "btn_endcall")!
            self.callButton.setImage(button_image, for: .normal)
        }
    }
    
    @IBAction func didClickHangUpButton(_ sender: UIButton) {
        if(self.currently_calling) {
            leaveChannel()
        } else {
            joinChannel()
        }
    }
    
    func leaveChannel() {
        agoraKit.leaveChannel(nil)
        NSLog("Left channel");
        UIApplication.shared.isIdleTimerDisabled = false
        self.currently_calling = false
        let button_image: UIImage = UIImage(named: "btn_startcall")!
        callButton.setImage(button_image, for: .normal)
    }
    
    @IBAction func didClickMuteButton(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        agoraKit.muteLocalAudioStream(sender.isSelected)
    }
    
    @IBAction func radioEffectValueChanged(_ sender: UISlider) {
        let radio_strength: Float = sender.value
        modulate_interface.setRadioStrength(radio_strength);
        NSLog("Radio Effect Value Changed to %f", radio_strength);
    }
    
    @IBAction func presenceEffectValueChanged(_ sender: UISlider) {
        let presence_strength: Float = sender.value
        modulate_interface.setPresenceStrength(presence_strength);
        NSLog("Presence Effect Value Changed to %f", presence_strength);
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        let voice_skin_names: Array = modulate_interface.getVoiceSkinNames() as Array
        return voice_skin_names.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let voice_skin_names: Array = modulate_interface.getVoiceSkinNames() as Array
        let selected_name: String = voice_skin_names[row] as! String
        return selected_name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selected_name: String = self.pickerView(pickerView, titleForRow: row, forComponent: component)!
        NSLog("Selected voice skin %@", selected_name)
        modulate_interface.selectVoiceSkin(selected_name)
    }
}
