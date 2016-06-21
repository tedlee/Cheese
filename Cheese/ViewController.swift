//
//  ViewController.swift
//  Cheese
//
//  Created by Ted Lee on 2016-06-20.
//  Copyright © 2016 Moonshot Labs. All rights reserved.
//

import UIKit
import Speech

public class ViewController: UIViewController, SFSpeechRecognizerDelegate {

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(localeIdentifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private let audioEngine = AVAudioEngine()
    private var recognitionTask: SFSpeechRecognitionTask?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            /*
             The callback may not be called on the main thread. Add an
             operation to the main queue to update the record button's state.
             */
            OperationQueue.main().addOperation {
                switch authStatus {
                    case .authorized:
                        print("Microphone access authorized")
                        try! self.startRecording()
                    case .denied:
                        print("Microphone access denied")
                    case .restricted:
                        print("Microphone access restricted")
                    case .notDetermined:
                        print("Microphone access restricted")
                }
            }
        }
    }
    
    private func startRecording() throws {
        
        // Start the audio session
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else { fatalError("Audio engine has no input node") }
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        // Configure request so that results are returned before audio recording is finished
        recognitionRequest.shouldReportPartialResults = true
        
        // A recognition task represents a speech recognition session.
        // We keep a reference to the task so that it can be cancelled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                print(result.bestTranscription.formattedString)
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                // The recognitionTask will always time out after ~60 seconds
                // This is a built-in limitation of SFSpeechRecognizer
                print("Recognition task timed out")
                
                try! self.startRecording()
                print ("Restarting recognition task")
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        print("Now listening...")
        try audioEngine.start()
    }
    

}

