
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

    fileprivate var pubSubService: CogsPubSubService!

    override func viewDidLoad() {
        super.viewDidLoad()


    }

    @IBAction func connectWS(_ sender: UIBarButtonItem) {
        guard let url = urlTextField.text else { return }

        let pubSubService = CogsPubSubService(options: PubSubOptions(url: url, timeout: 30, autoReconnect: true))
        self.pubSubService = pubSubService

        pubSubService.onNewSession = {
            DispatchQueue.main.async {
                self.statusLabel.text = "New session is opened"
            }
        }

        pubSubService.onReconnect = {
            DispatchQueue.main.async {
                self.statusLabel.text = "Session is restored"
            }
        }

        pubSubService.onDisconnect = {
            DispatchQueue.main.async {
                self.statusLabel.text = "Service is disconnected"
            }
        }
//        let keys: [String] = [
//            "R-*-*",
//            "W-*-*",
//            "A-*-*"
//        ]

        guard let readKey = readKeyTextField.text else { return }
        guard let writeKey = writeKeyTextField.text else { return }
        guard let adminKey = adminKeyTextField.text else { return }

        let keys: [String] = [readKey, writeKey, adminKey]

        pubSubService.connect(keys: keys, sessionUUID: nil)
    }

    @IBAction func disconnectWS(_ sender: UIBarButtonItem) {
        guard let service = pubSubService else { return }

        service.close()
    }

    @IBAction func getSessionUUID(_ sender: UIButton) {
        guard let service = pubSubService else { return }

        service.getSessionUuid() { json in
            do {
                let id = try PubSubResponseUUID(json: json)
                DispatchQueue.main.async {
                    self.sessionUUIDLabel.text = id.uuid
                }
            } catch {
                do {
                    let responseError = try PubSubErrorResponse(json: json)
                    DispatchQueue.main.async {
                        self.openAlertWithMessage(message: responseError.message, title: responseError.message)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.openAlertWithMessage(message: "\(error)", title: "Error")
                    }
                }
            }
        }
    }

    @IBAction func subscribeToChannel(_ sender: UIButton) {
        guard let channelName = channelNameTextField.text, !channelName.isEmpty else { return }
        guard let service = pubSubService else { return }

        service.subscribe(channelName: channelName) { json in

            do {
                let subscription = try PubSubResponseSubscription(json: json)
                DispatchQueue.main.async {
                    self.channelListLabel.text = subscription.channels.joined(separator: ", ")
                }
            } catch {
                do {
                    let responseError = try PubSubErrorResponse(json: json)
                    DispatchQueue.main.async {
                        self.openAlertWithMessage(message: responseError.message, title: responseError.message)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.openAlertWithMessage(message: "\(error)", title: "Error")
                    }
                }
            }
        }
    }

    @IBAction func unsubscribeFromCahnnel(_ sender: UIButton) {
        guard let channelName = channelNameTextField.text, !channelName.isEmpty else { return }
        guard let service = pubSubService else { return }

        service.unsubsribe(channelName: channelName) { json in
            do {
                let subscription = try PubSubResponseSubscription(json: json)
                DispatchQueue.main.async {
                    self.channelListLabel.text = subscription.channels.joined(separator: ", ")
                }
            } catch {
                do {
                    let responseError = try PubSubErrorResponse(json: json)
                    DispatchQueue.main.async {
                        self.openAlertWithMessage(message: responseError.message, title: responseError.message)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.openAlertWithMessage(message: "\(error)", title: "Error")
                    }
                }
            }
        }
    }

    @IBAction func getAllSubscriptions(_ sender: UIButton) {
        guard let service = pubSubService else { return }

        service.listSubscriptions { json in
            do {
                let subscription = try PubSubResponseSubscription(json: json)
                DispatchQueue.main.async {
                    self.channelListLabel.text = subscription.channels.joined(separator: ", ")
                }
            } catch {
                do {
                    let responseError = try PubSubErrorResponse(json: json)
                    DispatchQueue.main.async {
                        self.openAlertWithMessage(message: responseError.message, title: responseError.message)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.openAlertWithMessage(message: "\(error)", title: "Error")
                    }
                }
            }
        }
    }

    @IBAction func unsubscribeFromAll(_ sender: UIButton) {
        guard let service = pubSubService else { return }

        service.unsubscribeAll{ json in
            do {
                let subscription = try PubSubResponseSubscription(json: json)
                DispatchQueue.main.async {
                    self.channelListLabel.text = subscription.channels.joined(separator: ", ")
                }

            } catch {
                do {
                    let responseError = try PubSubErrorResponse(json: json)
                    DispatchQueue.main.async {
                        self.openAlertWithMessage(message: responseError.message, title: responseError.message)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.openAlertWithMessage(message: "\(error)", title: "Error")
                    }
                }
            }
        }
    }

    @IBAction func publishMessage(_ sender: UIButton) {
        guard let channel = channelNameTextField.text, !channel.isEmpty else { return }
        let messageText = messageTextView.text!
        let ack = ackSwitch.isOn

        guard let service = pubSubService else { return }

        if ack {
            service.publishWithAck(channelName: channel, message: messageText) { json in
                do {
                    let receivedMessage = try PubSubMessage(json: json)
                    DispatchQueue.main.async {
                        self.receivedMessageLabel.text = receivedMessage.message
                    }
                } catch {
                    do {
                        let acknowledge = try PubSubResponse(json: json)
                        DispatchQueue.main.async {
                            self.acknowledgeLabel.text = "\(acknowledge.description)"
                        }
                    } catch {
                        do {
                            let responseError = try PubSubErrorResponse(json: json)
                            DispatchQueue.main.async {
                                self.openAlertWithMessage(message: responseError.message, title: responseError.message)
                            }
                        } catch {
                            DispatchQueue.main.async {
                                self.openAlertWithMessage(message: "\(error)", title: "Error")
                            }
                        }
                    }
                }
            }
        } else {
            service.publish(channelName: channel, message: messageText) { json in
                do {
                    let receivedMessage = try PubSubMessage(json: json)
                    DispatchQueue.main.async {
                        self.receivedMessageLabel.text = receivedMessage.message
                    }
                } catch {
                    do {
                        let responseError = try PubSubErrorResponse(json: json)
                        DispatchQueue.main.async {
                            self.openAlertWithMessage(message: responseError.message, title: responseError.message)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.openAlertWithMessage(message: "\(error)", title: "Error")
                        }
                    }
                }
            }
        }
    }

    fileprivate func openAlertWithMessage(message msg: String, title: String) {
        let actionCtrl = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        actionCtrl.addAction(action)

        self.present(actionCtrl, animated: true, completion: nil)
    }
}
