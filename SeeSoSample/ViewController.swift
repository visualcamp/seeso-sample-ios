//
//  ViewController.swift
//  SeeSoSample
//
//  Created by VisualCamp on 2020/06/12.
//  Copyright © 2020 VisualCamp. All rights reserved.
//

import UIKit
import AVKit
import SeeSo

class ViewController: UIViewController {
    
    let licenseKey : String = "Input your key." // Please enter the key value for development issued by the SeeSo.io

    //
    var frame : Int = 0
    var lastTime : Double = 0
    enum AppState : String {
        case Disable = "Disable" // User denied access to the camera.
        case Idle = "Idle" // User has allowed access to the camera.
        case Initialized = "Initialized" // GazeTracker has been successfully created.
        case Tracking = "Tracking" // Gaze Tracking state.
        case Calibrating = "Calibrating" // It is being calibrated.
    }
    
    var tracker : GazeTracker? = nil
    let statusLabel : UILabel = UILabel() // This label tells you the current status.
    
    var userStatusOn = false
    
    //This switch indicates whether to Initialize GazeTracker in using UserStatus.
    let userStatusSwitchLabel : UILabel = UILabel()
    let userStatusSwitch : UISwitch = UISwitch()
    //A switch with the ability to create or destroy Gaze Tracker objects.
    let initTrackerLabel : UILabel = UILabel()
    let initTrackerSwitch : UISwitch = UISwitch()
    
    var userStatusResultLabel : UserStatusLabel?
    
    //This switch is responsible for starting or stopping gaze tracking.
    let startTrackingLabel : UILabel = UILabel()
    let startTrackingSwitch : UISwitch = UISwitch()
    
    //This switch determines whether or not to put a filter in gaze coordinates.
    let gazeFilterLabel : UILabel = UILabel()
    let gazeFilterSwitch : UISwitch = UISwitch()
    
    var gazePointView : GazePointView? = nil
    let faceBoundView : UIView = UIView()
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
    
    let preview : UIImageView = UIImageView()

    var camera: CameraManager?


    
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
                    self.enableSwitch(select: self.userStatusSwitch)
                        self.camera = CameraManager()
                        self.camera?.delegate = self
                case .Initialized:
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
                self.setStatusLabelText(contents: state.rawValue)
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
                disableSwitch(select: userStatusSwitch)
                initGazeTracker()
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
        } else if sender == userStatusSwitch {
            self.userStatusOn = sender.isOn
            sender.isEnabled = true
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
                setStatusLabelText(contents: "Calibration Started failed.")
            }
        }
    }
    
    private func stopCalibration(){
        tracker?.stopCalibration()
        curState = .Tracking
    }
    
    private func startTracking(){
//        tracker?.startTracking()
        camera?.start()
    }
    
    private func stopTracking(){
//        tracker?.stopTracking()
        camera?.stop()
    }
    
    private func initGazeTracker() {
        let options = UserStatusOption()
        if let cameraManager = camera, let input = cameraManager.getInput() {
            let isExternalMode = options.useExternalMode(input: input)

            if isExternalMode {
                if userStatusOn {
                    options.useAll()
                }
                GazeTracker.initGazeTracker(license: licenseKey, delegate: self, option: options)
            } else {
                print("failed External mode")
            }
        }
    }
    
    private func deinitGazeTracker(){
        GazeTracker.deinitGazeTracker(tracker: tracker)
        tracker = nil
        curState = .Idle
        hideUserStatusLabel()
    }
    
    
    
}

extension ViewController: CameraManagerDelegate {
    func videoOutput(sampleBuffer: CMSampleBuffer) {
        let result = self.tracker?.addCMSampleBuffer(sampleBuffer: sampleBuffer)
        if result == false {
            print("image abnormal")
        }
    }


}

extension ViewController : InitializationDelegate {
    func onInitialized(tracker: GazeTracker?, error: InitializationError) {
        enableSwitch(select: initTrackerSwitch)
        if tracker != nil {
            self.tracker = tracker
            let userStatusDelegate : UserStatusDelegate? = userStatusOn ? userStatusResultLabel : nil
            if userStatusOn {
                // interval's default is 30s, setting 10s for demo
                self.tracker?.setAttentionInterval(interval: 10)
            }
            self.tracker?.statusDelegate = self
            self.tracker?.gazeDelegate = self
            self.tracker?.calibrationDelegate = self
            self.tracker?.userStatusDelegate = userStatusDelegate
            curState = .Initialized
        } else {
            setStatusLabelText(contents: error.description)
            resetSwitch(select: initTrackerSwitch)
            self.enableSwitch(select: initTrackerSwitch)
        }
    }
}

extension ViewController : StatusDelegate {
    func onStarted() {
        curState = .Tracking
        //self.tracker?.setCameraPreview(preview: self.preview)
        if userStatusOn {
            showUserStatusLabel()
        }
    }
    
    func onStopped(error: StatusError) {
        setStatusLabelText(contents: "onStopped : \(error.description)")
        resetSwitch(select: startTrackingSwitch)
        self.enableSwitch(select: startTrackingSwitch)
        //self.tracker?.removeCameraPreview()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.curState = .Initialized
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


// UI componenents setting functions
extension ViewController {
    
    private func initViewComponents(){
        initStatusLabel()
        initModeUI()
        initInitTrackerUI()
        initStartTrackingUI()
        initGazePointView()
        initGazeFilterUI()
        initStartCalibrationUI()
        initCalibrationPointView()
        initCalibrationModeUI()
        initPreview()
        initFaceBoundView()
        initUserStatusLabel()
    }
    
    private func initStatusLabel(){
        statusLabel.frame.size = CGSize(width: 120, height: 40)
        statusLabel.center = CGPoint(x: self.view.frame.width/2, y: 70)
        statusLabel.textAlignment = .center
        statusLabel.adjustsFontSizeToFitWidth = true
        statusLabel.textColor = UIColor.blue
        statusLabel.font = .systemFont(ofSize: 20)
        self.view.addSubview(statusLabel)
    }
    
    private func initModeUI(){
        userStatusSwitch.frame.size = CGSize(width: 50, height: 50)
        userStatusSwitch.frame.origin = CGPoint(x: self.view.frame.width - 60, y: self.view.frame.height/2 - 140)
        userStatusSwitch.addTarget(self, action: #selector(onClickSwitch(sender:)), for: .valueChanged)
        self.view.addSubview(userStatusSwitch)
        
        userStatusSwitchLabel.frame.size = CGSize(width: 150, height: userStatusSwitch.frame.height)
        userStatusSwitchLabel.frame.origin = CGPoint(x: userStatusSwitch.frame.minX - (userStatusSwitchLabel.frame.width + 5), y: userStatusSwitch.frame.minY)
        userStatusSwitchLabel.text = "UserStatus"
        userStatusSwitchLabel.textColor = UIColor.blue
        userStatusSwitchLabel.textAlignment = .center
        self.view.addSubview(userStatusSwitchLabel)
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
        preview.frame.size = CGSize(width: 120, height: 160)
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

    private func initFaceBoundView() {
        self.faceBoundView.layer.borderWidth = 2
        self.faceBoundView.layer.borderColor = UIColor.red.cgColor
        self.faceBoundView.backgroundColor = .clear
        self.preview.addSubview(faceBoundView)
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
    
    private func initUserStatusLabel(){
        userStatusResultLabel = UserStatusLabel(frame: CGRect(x: 15, y: self.preview.frame.minY, width: self.preview.frame.minX - 30, height: self.preview.frame.height))
        self.view.addSubview(userStatusResultLabel!)
        self.userStatusResultLabel!.isHidden = true
        DispatchQueue.main.async {
            self.userStatusResultLabel?.layoutIfNeeded()
        }
        self.view.bringSubviewToFront(gazePointView!)
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
        disableBtn(select: calibrationBtn)
        disableBtn(select: fiveRadioBtn)
        disableBtn(select: oneRadioBtn)

    }
    
    private func setIdleStateUIComponents(){
        disableSwitch(select: startTrackingSwitch)
        disableSwitch(select: gazeFilterSwitch)
        disableBtn(select: calibrationBtn)
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
    
    private func showUserStatusLabel(){
        DispatchQueue.main.async {
            self.userStatusResultLabel?.isHidden = false
        }
    }
    
    private func hideUserStatusLabel(){
        DispatchQueue.main.async {
            self.userStatusResultLabel?.isHidden = true
        }
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
    private func setStatusLabelText(contents : String){
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

