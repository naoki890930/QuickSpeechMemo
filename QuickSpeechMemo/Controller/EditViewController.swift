//
//  EditViewController.swift
//  QuickSpeechMemo
//
//  Created by Naoki Nishiya on 10/22/16.
//  Copyright © 2016 Naoki Nishiyama. All rights reserved.
//

import UIKit
import Speech
import RxSwift
import RxCocoa

class EditViewController: UIViewController {
    
    @IBOutlet weak var editTextView: UITextView!
    @IBOutlet weak var titleTextField: UITextField! {
        didSet { titleTextField.delegate = self }
    }
    @IBOutlet weak var saveButton: UIBarButtonItem! {
        didSet { saveButton.isEnabled = false }
    }
    
    private var disposeBag = DisposeBag()
    
    // Speech Framework
    private var speechRecgnizer: SFSpeechRecognizer!
    private var speechRequest: SFSpeechAudioBufferRecognitionRequest!
    private var audioEngin: AVAudioEngine!
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        log?.warning("didReceiveMemoryWarning")
    }
    
    // MARK: Setup
    
    private func setup() {
        setupKeyborad()
        setupSaveButton()
    }
    
    private func setupSaveButton() {
        saveButton.rx.tap
            .map { self.editTextView.text }
            .filter { $0 != nil && $0!.count > 0 }
            .flatMapLatest {
                EntryInterface.rx.save(title: self.titleTextField.text, text: $0)
            }
            .subscribe(
                onNext: {
                    _ = self.navigationController?.popViewController(animated: true)
                },
                onError: { error in
                    log?.error(error)
                }
            )
            .addDisposableTo(disposeBag)
        
        editTextView.rx.text
            .map { $0 == nil ? 0 : $0!.count }
            .subscribe(onNext: { textCount in
                self.saveButton.isEnabled = textCount > 0
            })
            .addDisposableTo(disposeBag)
    }
    
    private func setupKeyborad() {
        let size = CGSize(width: Device.Screen.size.width, height: 50)
        let kbToolBar = UIToolbar(frame: CGRect(origin: CGPoint.zero, size: size))
        kbToolBar.barStyle = .default
        kbToolBar.sizeToFit()
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(EditViewController.tapDoneButton(sender:)))
        kbToolBar.items = [spacer, doneButton]
        
        editTextView.inputAccessoryView = kbToolBar
    }
    
    func tapDoneButton(sender: UIBarButtonItem) {
        view.endEditing(true)
    }
    
    // MARK: Speech Framework
    
    private func startSpeechRecognition() {
        requestSRAuthorization()
            .do(onError: { _ in
                log?.error("Not authorized")
            })
            .flatMapLatest { () -> Observable<String> in
                return self.recognizeSpeech()
            }
            .do(
                onError: { error in log?.error(error) },
                onCompleted: { self.stopSpeechRecognition() }
            )
            .bindTo(editTextView.rx.text)
            .addDisposableTo(disposeBag)
    }
    
    private func prepareSpeechRecognition() {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP")) else {
            fatalError("Fial to init SFSpeechRecognizer")
        }
        speechRecgnizer = recognizer
        
        speechRequest = SFSpeechAudioBufferRecognitionRequest()
        speechRequest.shouldReportPartialResults = true
        
        audioEngin = AVAudioEngine()
        guard let inputNode = audioEngin.inputNode else { fatalError("Fail to get inputNode") }
        let recodingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recodingFormat) { [weak self] buffer, _ in
            self?.speechRequest.append(buffer)
        }
        audioEngin.prepare()
    }
    
    private func requestSRAuthorization() -> Observable<Void> {
        return Observable<Void>.create { observer in
            SFSpeechRecognizer.requestAuthorization { status in
                if status == .authorized {
                    observer.onNext()
                    observer.onCompleted()
                } else {
                    observer.onError(NSError())
                }
            }
            
            return Disposables.create()
        }
    }
    
    private func recognizeSpeech() -> Observable<String> {
        prepareSpeechRecognition()
        
        return Observable<String>.create { observer in
            do {
                try self.audioEngin.start()
            } catch let error {
                observer.onError(error)
            }
            
            let task = self.speechRecgnizer.recognitionTask(with: self.speechRequest) { result, error in
                var isFinal = false
                if let result = result {
                    isFinal = result.isFinal
                    observer.onNext(result.bestTranscription.formattedString)
                }
                
                if let error = error {
                    observer.onError(error)
                }
                
                if isFinal {
                    observer.onCompleted()
                }
            }
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    private func stopSpeechRecognition() {
        audioEngin.stop()
        speechRequest.endAudio()
    }

    // MARK: IBAction
    
    @IBAction func tapRecordButton(sender: KYShutterButton) {
        switch sender.buttonState {
        case .normal:
            startSpeechRecognition()
            sender.buttonState = .recording
        case .recording:
            stopSpeechRecognition()
            sender.buttonState = .normal
        }
    }
}

extension EditViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
