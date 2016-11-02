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
import CoreLocation
import SwiftLocation

class EditViewController: UIViewController, StoryboardInitializable {
    
    @IBOutlet weak var editTextView: UITextView!
    @IBOutlet weak var titleTextField: UITextField! {
        didSet { titleTextField.delegate = self }
    }
    @IBOutlet weak var saveButton: UIBarButtonItem! {
        didSet { saveButton.isEnabled = false }
    }
    
    var entry: Entry? = nil
    private var inputText = ""
    
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
        setupInputFields()
    }
    
    /// 保存ボタン設定
    private func setupSaveButton() {
        var saveButtonTapResult: Observable<Void>
        if let updateEntry = entry {
            // 更新時
            saveButtonTapResult = saveButton.rx.tap
                .flatMapLatest { _ -> Observable<Void> in
                    return EntryInterface.rx.update(
                        object: updateEntry,
                        title: self.titleTextField.text,
                        text: self.editTextView.text)
                }
        } else {
            // 新規保存時
            saveButtonTapResult = saveButton.rx.tap
                .flatMapLatest { _ -> Observable<CLLocation> in
                    return Location.rxGetLocation(withAccuracy: .block)
                }
                .flatMapLatest { location -> Observable<Void> in
                    return EntryInterface.rx.save(
                        title: self.titleTextField.text,
                        text: self.editTextView.text,
                        latitude: Double(location.coordinate.latitude),
                        longitude: Double(location.coordinate.longitude))
                }
        }
        // 保存成功時は前の画面に戻る
        saveButtonTapResult.subscribe(
                onNext: { _ = self.navigationController?.popViewController(animated: true) },
                onError: { error in log?.error(error) }
            )
            .addDisposableTo(disposeBag)
        
        // メモ内容が入力されたら保存ボタンを有効化
        editTextView.rx.text
            .map { $0 == nil ? 0 : $0!.count }
            .subscribe(onNext: { textCount in
                self.saveButton.isEnabled = textCount > 0
            })
            .addDisposableTo(disposeBag)
    }
    
    /// 入力時キーボード設定
    private func setupKeyborad() {
        let size = CGSize(width: Device.Screen.size.width, height: 50)
        let kbToolBar = UIToolbar(frame: CGRect(origin: CGPoint.zero, size: size))
        kbToolBar.barStyle = .default
        kbToolBar.sizeToFit()
        
        // キーボードに完了ボタン追加
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(EditViewController.tapDoneButton(sender:)))
        kbToolBar.items = [spacer, doneButton]
        
        editTextView.inputAccessoryView = kbToolBar
    }
    
    func tapDoneButton(sender: UIBarButtonItem) {
        view.endEditing(true)
    }
    
    /// 入力フィールドの初期値設定
    private func setupInputFields() {
        titleTextField.text = entry?.title
        editTextView.text = entry?.text ?? ""
    }
    
    // MARK: Speech Framework
    /// 音声認識開始
    private func startSpeechRecognition() {
        // 前回入力値を保管
        inputText = editTextView.text
        
        requestSRAuthorization() // 音声認識許可
            .do(onError: { _ in
                log?.error("Not authorized")
            })
            .flatMapLatest { () -> Observable<String> in
                return self.recognizeSpeech() // 音声認識開始
            }
            .subscribe(
                onNext: { text in
                    self.editTextView.text = self.inputText + text // 音声認識結果を入力フィールドに反映
                },
               onError: { error in log?.error(error) }
            )
            .addDisposableTo(disposeBag)
    }
    
    /// 音声認識準備
    private func prepareSpeechRecognition() {
        // 音声認識の言語を日本語に設定
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP")) else {
            fatalError("Fial to init SFSpeechRecognizer")
        }
        speechRecgnizer = recognizer
        
        speechRequest = SFSpeechAudioBufferRecognitionRequest()
        // 確定前の結果を随時取得
        speechRequest.shouldReportPartialResults = true
        
        // マイク入力設定
        audioEngin = AVAudioEngine()
        guard let inputNode = audioEngin.inputNode else { fatalError("Fail to get inputNode") }
        let recodingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recodingFormat) { [weak self] buffer, _ in
            self?.speechRequest.append(buffer)
        }
        audioEngin.prepare()
    }
    
    /// 音声認識の許可を求める
    ///
    /// - Returns: Observable
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
    
    /// 音声認識
    ///
    /// - Returns: Observable
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
    
    // 音声認識終了
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
