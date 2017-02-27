
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

        if let path = Bundle.main.path(forResource: "Keys", ofType: "plist") {

            if let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
                self.urlTextField.text = dict["url"] as? String
                self.readKeyTextField.text = dict["readKey"] as? String
                self.writeKeyTextField.text = dict["writeKey"] as? String
                self.adminKeyTextField.text = dict["adminKey"] as? String
            }
        }
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
                self.sessionUUIDLabel.text = sessionUUID
            }
        }

        connectionHandler.onReconnect = {
            DispatchQueue.main.async {
                self.statusLabel.text = "Session is restored"
            }
        }

        connectionHandler.onClose = { (error) in
            if let err = error {
                DispatchQueue.main.async {
                    self.openAlertWithMessage(message: err.localizedDescription, title: "PubSub Error")
                }
            } else {
                DispatchQueue.main.async {
                    self.statusLabel.text = "Session is closed"
                }
            }
        }

        connectionHandler.onRawRecord = { (record) in
            print (record)
            do {
                 let json = try JSONSerialization.jsonObject(with: record.data(using: String.Encoding.utf8)!, options: .allowFragments) as JSON
                do {
                    let response = try PubSubResponse(json: json)

                    if let sessionUUID = response.uuid {
                        DispatchQueue.main.async {
                            self.sessionUUIDLabel.text = sessionUUID
                        }
                    }

                    if let channels = response.channels {
                        DispatchQueue.main.async {
                            self.channelListLabel.text = channels.joined(separator: ", ")
                        }
                    }

                    if let id = response.messageUUID {
                        DispatchQueue.main.async {
                            self.acknowledgeLabel.text = "MessageID: \(id)"
                        }
                    }
                } catch {

                }
            } catch {
                let error = NSError(domain: "CogsSDKError - PubSub Response", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])

                DispatchQueue.main.async {
                    self.openAlertWithMessage(message: error.localizedDescription, title: "PubSub Error")
                }
            }
        }

        connectionHandler.onMessage = { (receivedMessage) in
            DispatchQueue.main.async {
                self.receivedMessageLabel.text = receivedMessage.message
            }
        }

        connectionHandler.onError = { (error) in
            DispatchQueue.main.async {
                self.openAlertWithMessage(message: error.localizedDescription, title: "PubSub Error")
            }
        }

        connectionHandler.onErrorResponse = { (responseError) in
            DispatchQueue.main.async {
                self.openAlertWithMessage(message: "\(responseError.message) \n \(responseError.code)", title: "PubSub Response Error")
            }
        }
        
        connectionHandler.connect(sessionUUID: nil)
    }

    @IBAction func disconnectWS(_ sender: UIBarButtonItem) {
        guard (connectionHandler) != nil else { return }

        connectionHandler.close()
    }

    @IBAction func getSessionUUID(_ sender: UIButton) {
        guard (connectionHandler) != nil else { return }

        connectionHandler.getSessionUuid {json, error in
            print(json as Any)
        }
    }

    @IBAction func subscribeToChannel(_ sender: UIButton) {
        guard let channelName = channelNameTextField.text, !channelName.isEmpty else { return }
        guard (connectionHandler) != nil else { return }

        connectionHandler.subscribe(channelName: channelName){ json, error in
            print(json as Any)
        }
    }

    @IBAction func unsubscribeFromCahnnel(_ sender: UIButton) {
        guard let channelName = channelNameTextField.text, !channelName.isEmpty else { return }
        guard (connectionHandler) != nil else { return }

        connectionHandler.unsubsribe(channelName: channelName){ json, error in
            print(json as Any)
        }
    }

    @IBAction func getAllSubscriptions(_ sender: UIButton) {
        guard (connectionHandler) != nil else { return }

        connectionHandler.listSubscriptions(){ json, error in
            print(json as Any)
        }
    }

    @IBAction func unsubscribeFromAll(_ sender: UIButton) {
        guard (connectionHandler) != nil else { return }

        connectionHandler.unsubscribeAll(){ json, error in
            print(json as Any)
        }
    }

    @IBAction func publishMessage(_ sender: UIButton) {
        guard let channel = messageChannelTextField.text, !channel.isEmpty else { return }
        let messageText = messageTextView.text!
        let ack = ackSwitch.isOn

        guard (connectionHandler) != nil else { return }

        if ack {
            connectionHandler.publishWithAck(channelName: channel, message: messageText){ json, error in
                print(json as Any)
            }
        } else {
            connectionHandler.publish(channelName: channel, message: messageText){ json, error in
                print(json as Any)
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

//MARK: UITextFieldDelegate

extension WSSMessagingVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
