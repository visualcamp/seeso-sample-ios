//
//  ViewController.swift
//  SeeSoSample
//
//  Created by VisualCamp on 2020/06/12.
//  Copyright © 2020 VisaulCamp. All rights reserved.
//

import UIKit
import AVKit
import SeeSo

class ViewController: UIViewController {
    
    let licenseKey : String = "Input your key." // Please enter the key value for development issued by the SeeSo.io
    
    var frame : Int = 0
    var lastTime : Double = 0
    enum AppState : String {
        case Disable = "Disable" // User denied access to the camera.
        case Idle = "Idle" // User has allowed access to the camera.
        case Initailzed = "Initalized" // GazeTracker has been successfully created.
        case Tracking = "Tracking" // Gaze Tracking state.
        case Calibrating = "Calibrating" // It is being calibrated.
    }
    
    var tracker : GazeTracker? = nil
    let statusLabel : UILabel = UILabel() // This label tells you the current status.
    
    //A switch with the ability to create or destroy Gaze Tracker objects.
    let initTrackerLabel : UILabel = UILabel()
    let initTrackerSwitch : UISwitch = UISwitch()
    
    //This switch is responsible for starting or stopping gaze tracking.
    let startTrackingLabel : UILabel = UILabel()
    let startTrackingSwitch : UISwitch = UISwitch()
    
    //This switch determines whether or not to put a filter in gaze coordinates.
    let gazeFilterLabel : UILabel = UILabel()
    let gazeFilterSwitch : UISwitch = UISwitch()
    
    // User Status
    let attentionView : UILabel =  UILabel()
    let blinkView : UILabel = UILabel()
    let blinkLeftView : UILabel = UILabel()
    let blinkRightView : UILabel = UILabel()
    let drowsinessView : UILabel = UILabel()

    let statusAttentionLabel : UILabel = UILabel()
    let attentionSwitch : UISwitch = UISwitch()

    let statusBlinkLabel : UILabel = UILabel()
    let blinkSwitch : UISwitch = UISwitch()

    let statusDrowsinessLabel : UILabel = UILabel()
    let drowsinessSwitch : UISwitch = UISwitch()

    // Gaze & Calibration
    var gazePointView : GazePointView? = nil
    var caliPointView : CalibrationPointView? = nil
    
    var caliMode : CalibrationMode = .FIVE_POINT
    
    var calibrationData : [Double] = []
    
    let startCalibrationLabel : UILabel = UILabel()
    let calibrationBtn : UIButton = UIButton()
    let bottomView : UIView = UIView()
    let loadBtn : UIButton = UIButton()
    let saveBtn : UIButton = UIButton()
    let fiveRadioBtn : RadioButton = RadioButton()
    let oneRadioBtn : RadioButton = RadioButton()
    
    var isFiltered : Bool = false
    
    var isUseAttention: Bool = false
    var isUseBlink: Bool = false
    var isUseDrowsiness: Bool = false

    let preview : UIView = UIView()
    
    var curState : AppState? = nil {
        didSet {
            changeState()
        }
    }
    
    //It is an object that filters the gaze coordinate value.
    var filterManager : OneEuroFilterManager? = OneEuroFilterManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        //Check if the camera is accessible.
        if !checkAccessCamera() {
            //If access is not possible, the user is requested to access.
            requestAccess()
        }else{
            curState = .Idle
        }
        initViewComponents()
    }
    
    private func requestAccess(){
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                self.curState = .Idle
            } else {
                //If you are denied access, you cannot use any function.
                self.curState = .Disable
            }
        }
    }
    
    // Whenever the AppState, ui processing and appropriate functions are called.
    private func changeState() {
        if let state : AppState = curState {
            
            print("state : \(state.rawValue)")
            DispatchQueue.main.async {
                switch state {
                case .Disable:
                    self.disableLoadBtn()
                    self.disableSaveBtn()
                    self.disableUIComponents()
                case .Idle:
                    self.setIdleStateUIComponents()
                    self.disableLoadBtn()
                    self.disableSaveBtn()
                case .Initailzed:
                    self.setInitializedStateUIComponents()
                     self.tracker?.removeCameraPreview()
                    self.disableLoadBtn()
                    self.disableSaveBtn()
                case .Tracking:
                    if self.checkLoadData() {
                        self.enableLoadBtn()
                    }
                    self.setTrackingStateUIComponents()
                    self.calibrationBtn.setTitle("START", for: .normal)
                case .Calibrating:
                    self.disableLoadBtn()
                    self.setCalibratingUIComponents()
                }
                self.setStatusLableText(contents: state.rawValue)
            }
        }
    }
    
    private func checkAccessCamera() -> Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
    
    //This function is called when the switch is clicked.
    @objc func onClickSwitch(sender : UISwitch){
        sender.isEnabled = false
        if sender == initTrackerSwitch {
            if sender.isOn {
                let userStatusOption = UserStatusOption()

                if isUseAttention {
                    userStatusOption.useAttention()
                }

                if isUseBlink {
                    userStatusOption.useBlink()
                }

                if isUseDrowsiness {
                    userStatusOption.useDrowsiness()
                }

                initGazeTracker(option: userStatusOption)
            }else{
                deinitGazeTracker()
                sender.isEnabled = true
            }
        } else if sender == startTrackingSwitch {
            if sender.isOn {
                startTracking()
            }else{
                stopTracking()
            }
        } else if sender == gazeFilterSwitch {
            self.isFiltered = sender.isOn
            if self.isFiltered {
                filterManager = OneEuroFilterManager()
            }else{
                filterManager = nil
            }
            enableSwitch(select: sender)
        } else if sender == attentionSwitch {
            self.isUseAttention = sender.isOn
            enableSwitch(select: sender)
        } else if sender == blinkSwitch {
            self.isUseBlink = sender.isOn
            enableSwitch(select: sender)
        } else if sender == drowsinessSwitch {
            self.isUseDrowsiness = sender.isOn
            enableSwitch(select: sender)
        }
    }
    
    //This function is called when the button is clicked.
    @objc func onClickBtn(sender : UIButton){
        if sender == fiveRadioBtn {
            if caliMode == .ONE_POINT{
                caliMode = .FIVE_POINT
                print("Five-point calibration mode is selected.")
            }
        }else if sender == oneRadioBtn {
            if caliMode == .FIVE_POINT{
                caliMode = .ONE_POINT
                print("One-point calibration mode is selected.")
            }
        }else if sender == calibrationBtn {
            if curState == AppState.Calibrating {
                stopCalibration()
                DispatchQueue.main.async {
                    self.curState = .Tracking
                    self.calibrationBtn.setTitle("START", for: .normal)
                }
            }else if curState == AppState.Tracking {
                startCalibration()
                DispatchQueue.main.async {
                    self.calibrationBtn.setTitle("STOP", for: .normal)
                }
            }
        }else if sender == loadBtn {
            DispatchQueue.main.async {
                if self.checkLoadData() {
                    if self.loadCalibrationData()
                    {
                        self.statusLabel.text = "Loaded calibration datas"
                    }else {
                        self.statusLabel.text = "Load failed."
                    }
                }
            }
        }else if sender == saveBtn {
            DispatchQueue.main.async {
                self.saveCalibrationData()
                self.disableSaveBtn()
                self.statusLabel.text = "Saved calibration datas."
            }
        }
    }
    
    private func startCalibration(){
        print("StartCalimode : \(caliMode.description)")
        let result = tracker?.startCalibration(mode: caliMode, criteria: .DEFAULT)
        if let isStart = result {
            if !isStart{
                setStatusLableText(contents: "Calibration Started failed.")
            }
        }
    }
    
    private func stopCalibration(){
        tracker?.stopCalibration()
        curState = .Tracking
    }
    
    private func startTracking(){
        tracker?.startTracking()
    }
    
    private func stopTracking(){
        tracker?.stopTracking()
    }
    
    private func initGazeTracker() {
        GazeTracker.initGazeTracker(license: licenseKey, delegate: self)
    }
    
    private func initGazeTracker(option: UserStatusOption) {
        GazeTracker.initGazeTracker(license: licenseKey, delegate: self, option: option)
    }

    private func deinitGazeTracker(){
        GazeTracker.deinitGazeTracker(tracker: tracker)
        tracker = nil
        curState = .Idle
    }
}

extension ViewController : InitializationDelegate {
    func onInitialized(tracker: GazeTracker?, error: InitializationError) {
        enableSwitch(select: initTrackerSwitch)
        if tracker != nil {
            self.tracker = tracker
            self.tracker?.setDelegates(statusDelegate: self, gazeDelegate: self, calibrationDelegate: self, imageDelegate: nil, userStatusDelegate: self)
            self.tracker?.setAttentionInterval(interval: 30)
            curState = .Initailzed
        }else {
            setStatusLableText(contents: error.description)
            resetSwitch(select: initTrackerSwitch)
            self.enableSwitch(select: initTrackerSwitch)
        }
    }
}

extension ViewController : StatusDelegate {
    func onStarted() {
        curState = .Tracking
        self.tracker?.setCameraPreview(preview: self.preview)
    }
    
    func onStopped(error: StatusError) {
        setStatusLableText(contents: "onStopped : \(error.description)")
        resetSwitch(select: startTrackingSwitch)
        self.enableSwitch(select: startTrackingSwitch)
        self.tracker?.removeCameraPreview()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.curState = .Initailzed
        })
    }
}

extension ViewController : GazeDelegate {
    func onGaze(gazeInfo: GazeInfo) {
        
        //During the calibration process, the gaze UI is not displayed.
        if tracker != nil && tracker!.isCalibrating() {
            self.hidePointView(view: self.gazePointView!)
        }else{
            //When no filter is used, the x,y coordinates are used directly to show the gaze coordinates.
            if !self.isFiltered {
              if gazeInfo.trackingState == .SUCCESS || gazeInfo.trackingState == .LOW_CONFIDENCE {
                    self.showPointView(view: self.gazePointView!)
                    self.gazePointView?.moveView(x: gazeInfo.x, y: gazeInfo.y)
                }else {
                    self.hidePointView(view: self.gazePointView!)
                }
            }else{
                //If the filter is in use, it is displayed on the screen using the filtered value through the filter manager.
                if gazeInfo.trackingState == .SUCCESS {
                    if filterManager != nil && filterManager!.filterValues(timestamp: gazeInfo.timestamp, val:[gazeInfo.x ,gazeInfo.y]) {
                        let _xy = filterManager!.getFilteredValues()
                        self.showPointView(view: self.gazePointView!)
                        self.gazePointView?.moveView(x: _xy[0], y: _xy[1])
                    }
                }else {
                    self.hidePointView(view: self.gazePointView!)
                }
            } 
        }
    }
}

extension ViewController : CalibrationDelegate {
    func onCalibrationProgress(progress: Double) {
        caliPointView?.setProgress(progress: progress)
    }
    
    func onCalibrationNextPoint(x: Double, y: Double) {
        if curState != AppState.Calibrating {
            curState = .Calibrating
        }
        DispatchQueue.main.async {
            self.caliPointView?.center = CGPoint(x: CGFloat(x), y: CGFloat(y))
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                if let result = self.tracker?.startCollectSamples() {
                    print("startCollectSamples : \(result)")
                }
            })
        }
    }
    
    func onCalibrationFinished(calibrationData : [Double]) {
        print("Finished calibration.")
        curState = .Tracking
        changeState()
        self.calibrationData = calibrationData
        enableSaveBtn()
    }
}

extension ViewController : UserStatusDelegate {
    func onAttension(timestampBegin: Int, timestampEnd: Int, score: Double) {
        attentionView.text = "Attention: " + String(round(score * 10000) / 10000)
    }

    func onBlink(timestamp: Int, isBlinkLeft: Bool, isBlinkRight: Bool, isBlink: Bool, eyeOpenness: Double) {
        blinkView.text = "Blink: " + String(isBlink)
        blinkLeftView.text = "Blink Left: " + String(isBlinkLeft)
        blinkRightView.text = "Blink Right: " + String(isBlinkRight)
    }

    func onDrowsiness(timestamp: Int, isDrowsiness: Bool) {
        drowsinessView.text = "Drowsiness: " + String(isDrowsiness)
    }
}

// UI componenents setting functions
extension ViewController {
    
    private func initViewComponents(){
        initStatusLabel()
        initInitTrackerUI()
        initStartTrackingUI()
        initGazePointView()
        initGazeFilterUI()
        initStartCalibrationUI()
        initCalibrationPointView()
        initCalibrationModeUI()
        initUserStatusUI()
        initPreview()
    }
    
    private func initStatusLabel(){
        statusLabel.frame.size = CGSize(width: 120, height: 40)
        statusLabel.center = CGPoint(x: self.view.frame.width/2, y: 50)
        statusLabel.textAlignment = .center
        statusLabel.adjustsFontSizeToFitWidth = true
        statusLabel.textColor = UIColor.blue
        statusLabel.font = .systemFont(ofSize: 20)
        self.view.addSubview(statusLabel)
    }
    
    private func initInitTrackerUI(){
        initTrackerSwitch.frame.size = CGSize(width: 50, height: 50)
        initTrackerSwitch.frame.origin = CGPoint(x: self.view.frame.width - 60, y: self.view.frame.height/2 - 80)
        initTrackerSwitch.addTarget(self, action: #selector(onClickSwitch(sender:)), for: .valueChanged)
        self.view.addSubview(initTrackerSwitch)
        
        initTrackerLabel.frame.size = CGSize(width: 150, height: initTrackerSwitch.frame.height)
        initTrackerLabel.frame.origin = CGPoint(x: initTrackerSwitch.frame.minX - (initTrackerLabel.frame.width + 5), y: initTrackerSwitch.frame.minY)
        initTrackerLabel.text = "InitGazeTracker"
        initTrackerLabel.textColor = UIColor.blue
        initTrackerLabel.textAlignment = .center
        self.view.addSubview(initTrackerLabel)
    }
    
    private func initPreview() {
        preview.frame.size = CGSize(width: 160, height: 120)
        preview.center = CGPoint(x: self.view.frame.width/2, y: 160)
        preview.alpha = 0.7
        self.view.addSubview(preview)
    }
    
    private func initStartTrackingUI(){
        startTrackingSwitch.frame.size = CGSize(width: 50, height: 50)
        startTrackingSwitch.frame.origin = CGPoint(x: self.view.frame.width - 60, y: self.view.frame.height/2 - 20)
        startTrackingSwitch.addTarget(self, action: #selector(onClickSwitch(sender:)), for: .valueChanged)
        self.view.addSubview(startTrackingSwitch)
        
        startTrackingLabel.frame.size = CGSize(width: 150, height: startTrackingSwitch.frame.height)
        startTrackingLabel.frame.origin = CGPoint(x: startTrackingSwitch.frame.minX - (startTrackingLabel.frame.width + 5), y: startTrackingSwitch.frame.minY)
        startTrackingLabel.text = "Tracking"
        startTrackingLabel.textColor = UIColor.blue
        startTrackingLabel.textAlignment = .center
        self.view.addSubview(startTrackingLabel)
    }
    
    private func initGazeFilterUI(){
        gazeFilterSwitch.frame.size = CGSize(width: 50, height: 50)
        gazeFilterSwitch.frame.origin = CGPoint(x: self.view.frame.width - 60, y: self.view.frame.height/2 + 40)
        gazeFilterSwitch.addTarget(self, action: #selector(onClickSwitch(sender:)), for: .valueChanged)
        self.view.addSubview(gazeFilterSwitch)
        
        gazeFilterLabel.frame.size = CGSize(width: 150, height: gazeFilterSwitch.frame.height)
        gazeFilterLabel.frame.origin = CGPoint(x: gazeFilterSwitch.frame.minX - (startTrackingLabel.frame.width + 5), y: gazeFilterSwitch.frame.minY)
        gazeFilterLabel.text = "Filtering"
        gazeFilterLabel.textColor = UIColor.blue
        gazeFilterLabel.textAlignment = .center
        self.view.addSubview(gazeFilterLabel)
    }
    
    private func initGazePointView(){
        self.gazePointView = GazePointView(frame: self.view.bounds)
        self.view.addSubview(gazePointView!)
        hidePointView(view: gazePointView!)
    }
    
    private func initCalibrationPointView(){
        self.caliPointView = CalibrationPointView(frame: CGRect(origin: .zero, size: CGSize(width: 40, height: 40)))
        self.view.addSubview(caliPointView!)
        hidePointView(view: caliPointView!)
    }
    
    private func initStartCalibrationUI(){
        calibrationBtn.frame.size = CGSize(width: 50, height: 50)
        calibrationBtn.setTitleColor(.gray, for: .disabled)
        calibrationBtn.frame.origin = CGPoint(x: self.view.frame.width - 60, y: self.view.frame.height/2 + 160)
        calibrationBtn.addTarget(self, action: #selector(onClickBtn(sender:)), for: .touchUpInside)
        calibrationBtn.setTitle("START", for: .normal)
        calibrationBtn.setTitleColor(.blue, for: .normal)
        calibrationBtn.titleLabel?.adjustsFontSizeToFitWidth = true
        self.view.addSubview(calibrationBtn)
    }
    
    private func initCalibrationModeUI(){
        oneRadioBtn.frame.size = CGSize(width: 50, height: 50)
        oneRadioBtn.isSelected = false
        oneRadioBtn.alternateButton = [fiveRadioBtn]
        oneRadioBtn.frame.origin = CGPoint(x: self.view.frame.width - 180, y: self.view.frame.height/2 + 160)
        oneRadioBtn.setTitle("ONE", for: .normal)
        oneRadioBtn.awakeFromNib()
        oneRadioBtn.addTarget(self, action: #selector(onClickBtn(sender:)), for: .touchUpInside)
        self.view.addSubview(oneRadioBtn)
        
        fiveRadioBtn.frame.size = CGSize(width: 50, height: 50)
        fiveRadioBtn.isSelected = true
        fiveRadioBtn.alternateButton = [oneRadioBtn]
        fiveRadioBtn.awakeFromNib()
        fiveRadioBtn.frame.origin = CGPoint(x: self.view.frame.width - 120, y: self.view.frame.height/2 + 160)
        fiveRadioBtn.setTitle("FIVE", for: .normal)
        fiveRadioBtn.addTarget(self, action: #selector(onClickBtn(sender:)), for: .touchUpInside)
        self.view.addSubview(fiveRadioBtn)
        
        startCalibrationLabel.frame.size = CGSize(width: 150, height: oneRadioBtn.frame.height)
        startCalibrationLabel.frame.origin = CGPoint(x: self.view.frame.width - 180, y: self.view.frame.height/2 + 100)
        startCalibrationLabel.text = "Calibration"
        startCalibrationLabel.textColor = UIColor.blue
        startCalibrationLabel.textAlignment = .center
        self.view.addSubview(startCalibrationLabel)
        
        
        bottomView.frame = CGRect(x: oneRadioBtn.frame.minX, y: oneRadioBtn.frame.maxY + 20, width: calibrationBtn.frame.maxX - oneRadioBtn.frame.minX, height: 80)
        self.view.addSubview(bottomView)
        
        loadBtn.frame = CGRect(x: 10, y: 5, width: bottomView.frame.width/2 - 20, height: bottomView.frame.height/2 - 20)
        saveBtn.frame = CGRect(x: bottomView.frame.width/2 + 10, y: 5, width: bottomView.frame.width/2 - 20, height: bottomView.frame.height/2 - 20)
        
        loadBtn.setTitle("Load", for: .normal)
        loadBtn.setTitleColor(.blue, for: .normal)
        loadBtn.addTarget(self, action: #selector(onClickBtn(sender:)), for: .touchDown)
        saveBtn.setTitle("Save", for: .normal)
        saveBtn.setTitleColor(.blue, for: .normal)
        saveBtn.addTarget(self, action: #selector(onClickBtn(sender:)), for: .touchDown)
        bottomView.addSubview(saveBtn)
        bottomView.addSubview(loadBtn)
    }
    
    private func initUserStatusUI() {
        // View UI
        attentionView.frame.size = CGSize(width: 200, height: 50)
        attentionView.frame.origin = CGPoint(x: 10, y: 10)

        blinkView.frame.size = CGSize(width: 200, height: 50)
        blinkView.frame.origin = CGPoint(x: 10, y: attentionView.frame.minY + 50)

        blinkLeftView.frame.size = CGSize(width: 200, height: 50)
        blinkLeftView.frame.origin = CGPoint(x: 10, y: blinkView.frame.minY + 50)

        blinkRightView.frame.size = CGSize(width: 200, height: 50)
        blinkRightView.frame.origin = CGPoint(x: 10, y: blinkLeftView.frame.minY + 50)

        drowsinessView.frame.size = CGSize(width: 200, height: 50)
        drowsinessView.frame.origin = CGPoint(x: 10, y: blinkRightView.frame.minY + 50)

        attentionView.text = "Attention: NONE"
        blinkView.text = "Blink: NONE"
        blinkLeftView.text = "Blink Left: NONE"
        blinkRightView.text = "Blink Right: NONE"
        drowsinessView.text = "Drowsiness: NONE"

        self.view.addSubview(attentionView)
        self.view.addSubview(blinkView)
        self.view.addSubview(blinkLeftView)
        self.view.addSubview(blinkRightView)
        self.view.addSubview(drowsinessView)

        // User Status Switch
        statusAttentionLabel.frame.size = CGSize(width: 100, height: initTrackerSwitch.frame.height)
        statusAttentionLabel.frame.origin = CGPoint(x: 10, y: initTrackerSwitch.frame.minY)
        statusAttentionLabel.text = "Attention"
        statusAttentionLabel.textColor = UIColor.blue
        statusAttentionLabel.textAlignment = .left
        self.view.addSubview(statusAttentionLabel)

        statusBlinkLabel.frame.size = CGSize(width: 100, height: initTrackerSwitch.frame.height)
        statusBlinkLabel.frame.origin = CGPoint(x: 10, y: statusAttentionLabel.frame.maxY + 30)
        statusBlinkLabel.text = "Blink"
        statusBlinkLabel.textColor = UIColor.blue
        statusBlinkLabel.textAlignment = .left
        self.view.addSubview(statusBlinkLabel)

        statusDrowsinessLabel.frame.size = CGSize(width: 100, height: initTrackerSwitch.frame.height)
        statusDrowsinessLabel.frame.origin = CGPoint(x: 10, y: statusBlinkLabel.frame.maxY + 30)
        statusDrowsinessLabel.text = "Drowsiness"
        statusDrowsinessLabel.textColor = UIColor.blue
        statusDrowsinessLabel.textAlignment = .left
        self.view.addSubview(statusDrowsinessLabel)

        attentionSwitch.frame.size = CGSize(width: 50, height: 50)
        attentionSwitch.frame.origin = CGPoint(x: statusAttentionLabel.frame.maxX, y: initTrackerSwitch.frame.minY)
        attentionSwitch.addTarget(self, action: #selector(onClickSwitch(sender:)), for: .valueChanged)
        self.view.addSubview(attentionSwitch)

        blinkSwitch.frame.size = CGSize(width: 50, height: 50)
        blinkSwitch.frame.origin = CGPoint(x: statusBlinkLabel.frame.maxX, y: attentionSwitch.frame.maxY + 30)
        blinkSwitch.addTarget(self, action: #selector(onClickSwitch(sender:)), for: .valueChanged)
        self.view.addSubview(blinkSwitch)

        drowsinessSwitch.frame.size = CGSize(width: 50, height: 50)
        drowsinessSwitch.frame.origin = CGPoint(x: statusDrowsinessLabel.frame.maxX, y: blinkSwitch.frame.maxY + 30)
        drowsinessSwitch.addTarget(self, action: #selector(onClickSwitch(sender:)), for: .valueChanged)
        self.view.addSubview(drowsinessSwitch)
    }
        
    private func disableSaveBtn(){
        DispatchQueue.main.async {
            self.saveBtn.isHidden = true
            self.calibrationData.removeAll()
        }
    }
    
    private func disableLoadBtn(){
        DispatchQueue.main.async {
            self.loadBtn.isHidden = true
        }
    }
    
    
    private func enableSaveBtn(){
        DispatchQueue.main.async {
            self.saveBtn.isHidden = false
        }
    }
    
    private func enableLoadBtn(){
        DispatchQueue.main.async {
            self.loadBtn.isHidden = false
        }
    }
    
    
    private func checkLoadData()-> Bool {
        if let _ = UserDefaults.standard.array(forKey: "calibrationData") as? [Double]{
            return true
        }
        return false
    }
    
    private func loadCalibrationData() -> Bool{
        if let calibrationData = UserDefaults.standard.array(forKey: "calibrationData") as? [Double]{
            self.calibrationData = calibrationData
            return self.tracker!.setCalibrationData(calibrationData: self.calibrationData)
        }
        return false
    }
    
    
    private func saveCalibrationData(){
        if calibrationData.count > 0 {
            UserDefaults.standard.removeObject(forKey: "calibrationData")
            UserDefaults.standard.set(calibrationData, forKey: "calibrationData")
        }
    }
    
    private func disableUIComponents(){
        disableSwitch(select: initTrackerSwitch)
        disableSwitch(select: startTrackingSwitch)
        disableSwitch(select: gazeFilterSwitch)
        disableSwitch(select: attentionSwitch)
        disableSwitch(select: blinkSwitch)
        disableSwitch(select: drowsinessSwitch)
        disableBtn(select: calibrationBtn)
        disableBtn(select: fiveRadioBtn)
        disableBtn(select: oneRadioBtn)
    }
    
    private func setIdleStateUIComponents(){
        disableSwitch(select: startTrackingSwitch)
        disableSwitch(select: gazeFilterSwitch)
        disableBtn(select: calibrationBtn)
        enableSwitch(select: attentionSwitch)
        enableSwitch(select: blinkSwitch)
        enableSwitch(select: drowsinessSwitch)
        resetSwitch(select: startTrackingSwitch)
        resetSwitch(select: gazeFilterSwitch)
        disableBtn(select: fiveRadioBtn)
        disableBtn(select: oneRadioBtn)
        hidePointView(view: gazePointView!)
        hidePointView(view: caliPointView!)
    }
    
    private func setInitializedStateUIComponents(){
        enableSwitch(select: startTrackingSwitch)
        enableSwitch(select: gazeFilterSwitch)
        disableSwitch(select: attentionSwitch)
        disableSwitch(select: blinkSwitch)
        disableSwitch(select: drowsinessSwitch)
        disableBtn(select: calibrationBtn)
        disableBtn(select: fiveRadioBtn)
        disableBtn(select: oneRadioBtn)
        hidePointView(view: gazePointView!)
        hidePointView(view: caliPointView!)
    }
    
    private func setTrackingStateUIComponents(){
        enableSwitch(select: startTrackingSwitch)
        showPointView(view: gazePointView!)
        enableBtn(select: calibrationBtn)
        enableBtn(select: fiveRadioBtn)
        enableBtn(select: oneRadioBtn)
        hidePointView(view: caliPointView!)
    }
    
    private func setCalibratingUIComponents(){
        hidePointView(view: gazePointView!)
        showPointView(view: caliPointView!)
        enableBtn(select: calibrationBtn)
        disableBtn(select: fiveRadioBtn)
        disableBtn(select: oneRadioBtn)
    }
    
    private func hidePointView(view : UIView){
        DispatchQueue.main.async {
            if !view.isHidden {
                view.isHidden = true
            }
        }
    }
    
    private func showPointView(view : UIView){
        DispatchQueue.main.async {
            if view.isHidden{
                view.isHidden = false
                if view == self.caliPointView {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        if let result = self.tracker?.startCollectSamples() {
                            print("startCollectSamples : \(result)")
                        }
                    })              
                }
            }
        }
    }

    private func setStatusLableText(contents : String){
        DispatchQueue.main.async {
            self.statusLabel.text = contents
        }
    }

    private func resetSwitch(select :UISwitch){
        DispatchQueue.main.async {
            select.setOn(false, animated: true)
        }
    }
    
    private func disableSwitch(select : UISwitch){
        DispatchQueue.main.async {
            select.isEnabled = false
        }
    }
    
    private func enableSwitch(select : UISwitch) {
        DispatchQueue.main.async {
            select.isEnabled = true
        }
    }
    
    private func disableBtn(select : UIButton){
        DispatchQueue.main.async {
            select.isEnabled = false
        }
    }
    
    private func enableBtn(select : UIButton){
        DispatchQueue.main.async {
            select.isEnabled = true
        }
    }
}

