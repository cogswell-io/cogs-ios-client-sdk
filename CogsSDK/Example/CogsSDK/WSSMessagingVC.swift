
import Foundation
import CogsSDK

class WSSMessagingVC: ViewController {

    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var readKeyTextField: UITextField!
    @IBOutlet weak var writeKeyTextField: UITextField!
    @IBOutlet weak var adminKeyTextField: UITextField!

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var sessionUUIDLabel: UILabel!
    @IBOutlet weak var channelNameTextField: UITextField!
    @IBOutlet weak var channelListLabel: UILabel!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var messageChannelTextField: UITextField!
    @IBOutlet weak var ackSwitch: UISwitch!
    @IBOutlet weak var receivedMessageLabel: UILabel!
    @IBOutlet weak var acknowledgeLabel: UILabel!

    fileprivate var fpubSubService: CogsPubSubService!
    fileprivate var connectionHandler: ConnectionHandle!

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func connectWS(_ sender: UIBarButtonItem) {
        guard let url = urlTextField.text else { return }
        
        guard let readKey = readKeyTextField.text else { return }
        guard let writeKey = writeKeyTextField.text else { return }
        guard let adminKey = adminKeyTextField.text else { return }
        
        let keys: [String] = [readKey, writeKey, adminKey]
        
        let pubSubService = CogsPubSubService()
        let connectionHandler = pubSubService.connnect(keys: keys,
                                                        options: PubSubOptions(url: url,
                                                                               timeout: 30,
                                                                               autoReconnect: true))
        self.connectionHandler = connectionHandler
        
        connectionHandler.onNewSession = { sessionUUID in
            DispatchQueue.main.async {
                self.statusLabel.text = "New session is opened"
            }
        }

        connectionHandler.onReconnect = {
            DispatchQueue.main.async {
                self.statusLabel.text = "Session is restored"
            }
        }

        connectionHandler.onClose = { (error) in
            print(error)
            DispatchQueue.main.async {
                self.statusLabel.text = "Service is disconnected"
            }
        }

        connectionHandler.onRawRecord = { (record) in
            print(record)
        }

        connectionHandler.onMessage = { (message) in
            print(message)
        }
        
        connectionHandler.connect(sessionUUID: nil)
    }

    @IBAction func disconnectWS(_ sender: UIBarButtonItem) {
        guard (connectionHandler) != nil else { return }

        connectionHandler.close()
    }

    @IBAction func getSessionUUID(_ sender: UIButton) {
        guard (connectionHandler) != nil else { return }

        connectionHandler.getSessionUuid() //{ json in
//            do {
//                let id = try PubSubResponseUUID(json: json)
//                DispatchQueue.main.async {
//                    self.sessionUUIDLabel.text = id.uuid
//                }
//            } catch {
//                do {
//                    let responseError = try PubSubErrorResponse(json: json)
//                    DispatchQueue.main.async {
//                        self.openAlertWithMessage(message: responseError.message, title: responseError.message)
//                    }
//                } catch {
//                    DispatchQueue.main.async {
//                        self.openAlertWithMessage(message: "\(error)", title: "Error")
//                    }
//                }
//            }
//        }
    }

    @IBAction func subscribeToChannel(_ sender: UIButton) {
        guard let channelName = channelNameTextField.text, !channelName.isEmpty else { return }
        guard (connectionHandler) != nil else { return }

        connectionHandler.subscribe(channelName: channelName) //{ json in

//            do {
//                let subscription = try PubSubResponseSubscription(json: json)
//                DispatchQueue.main.async {
//                    self.channelListLabel.text = subscription.channels.joined(separator: ", ")
//                }
//            } catch {
//                do {
//                    let responseError = try PubSubErrorResponse(json: json)
//                    DispatchQueue.main.async {
//                        self.openAlertWithMessage(message: responseError.message, title: responseError.message)
//                    }
//                } catch {
//                    DispatchQueue.main.async {
//                        self.openAlertWithMessage(message: "\(error)", title: "Error")
//                    }
//                }
//            }
//        }
    }

    @IBAction func unsubscribeFromCahnnel(_ sender: UIButton) {
        guard let channelName = channelNameTextField.text, !channelName.isEmpty else { return }
        guard (connectionHandler) != nil else { return }

        connectionHandler.unsubsribe(channelName: channelName) //{ //json in
//            do {
//                let subscription = try PubSubResponseSubscription(json: json)
//                DispatchQueue.main.async {
//                    self.channelListLabel.text = subscription.channels.joined(separator: ", ")
//                }
//            } catch {
//                do {
//                    let responseError = try PubSubErrorResponse(json: json)
//                    DispatchQueue.main.async {
//                        self.openAlertWithMessage(message: responseError.message, title: responseError.message)
//                    }
//                } catch {
//                    DispatchQueue.main.async {
//                        self.openAlertWithMessage(message: "\(error)", title: "Error")
//                    }
//                }
//            }
//        }
    }

    @IBAction func getAllSubscriptions(_ sender: UIButton) {
        guard (connectionHandler) != nil else { return }

        connectionHandler.listSubscriptions() //{ json in
//            do {
//                let subscription = try PubSubResponseSubscription(json: json)
//                DispatchQueue.main.async {
//                    self.channelListLabel.text = subscription.channels.joined(separator: ", ")
//                }
//            } catch {
//                do {
//                    let responseError = try PubSubErrorResponse(json: json)
//                    DispatchQueue.main.async {
//                        self.openAlertWithMessage(message: responseError.message, title: responseError.message)
//                    }
//                } catch {
//                    DispatchQueue.main.async {
//                        self.openAlertWithMessage(message: "\(error)", title: "Error")
//                    }
//                }
//            }
//        }
    }

    @IBAction func unsubscribeFromAll(_ sender: UIButton) {
        guard (connectionHandler) != nil else { return }

        connectionHandler.unsubscribeAll() //{ json in
//            do {
//                let subscription = try PubSubResponseSubscription(json: json)
//                DispatchQueue.main.async {
//                    self.channelListLabel.text = subscription.channels.joined(separator: ", ")
//                }
//
//            } catch {
//                do {
//                    let responseError = try PubSubErrorResponse(json: json)
//                    DispatchQueue.main.async {
//                        self.openAlertWithMessage(message: responseError.message, title: responseError.message)
//                    }
//                } catch {
//                    DispatchQueue.main.async {
//                        self.openAlertWithMessage(message: "\(error)", title: "Error")
//                    }
//                }
//            }
//        }
    }

    @IBAction func publishMessage(_ sender: UIButton) {
        guard let channel = channelNameTextField.text, !channel.isEmpty else { return }
        let messageText = messageTextView.text!
        let ack = ackSwitch.isOn

        guard (connectionHandler) != nil else { return }

        if ack {
            connectionHandler.publishWithAck(channelName: channel, message: messageText)// { json in
//                do {
//                    let receivedMessage = try PubSubMessage(json: json)
//                    DispatchQueue.main.async {
//                        self.receivedMessageLabel.text = receivedMessage.message
//                    }
//                } catch {
//                    do {
//                        let acknowledge = try PubSubResponse(json: json)
//                        DispatchQueue.main.async {
//                            self.acknowledgeLabel.text = "\(acknowledge.description)"
//                        }
//                    } catch {
//                        do {
//                            let responseError = try PubSubErrorResponse(json: json)
//                            DispatchQueue.main.async {
//                                self.openAlertWithMessage(message: responseError.message, title: responseError.message)
//                            }
//                        } catch {
//                            DispatchQueue.main.async {
//                                self.openAlertWithMessage(message: "\(error)", title: "Error")
//                            }
//                        }
//                    }
//                }
//            }
        } else {
            connectionHandler.publish(channelName: channel, message: messageText) //{ json in
//                do {
//                    let receivedMessage = try PubSubMessage(json: json)
//                    DispatchQueue.main.async {
//                        self.receivedMessageLabel.text = receivedMessage.message
//                    }
//                } catch {
//                    do {
//                        let responseError = try PubSubErrorResponse(json: json)
//                        DispatchQueue.main.async {
//                            self.openAlertWithMessage(message: responseError.message, title: responseError.message)
//                        }
//                    } catch {
//                        DispatchQueue.main.async {
//                            self.openAlertWithMessage(message: "\(error)", title: "Error")
//                        }
//                    }
//                }
//            }
        }
    }

    fileprivate func openAlertWithMessage(message msg: String, title: String) {
        let actionCtrl = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        actionCtrl.addAction(action)

        self.present(actionCtrl, animated: true, completion: nil)
    }
}
