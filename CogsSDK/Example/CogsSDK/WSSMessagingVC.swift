
import Foundation
import CogsSDK

class WSSMessagingVC: ViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var sessionUUIDLabel: UILabel!
    @IBOutlet weak var channelNameTextField: UITextField!
    @IBOutlet weak var channelListLabel: UILabel!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var messageChannelTextField: UITextField!
    @IBOutlet weak var ackSwitch: UISwitch!
    @IBOutlet weak var receivedMessageLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func connectWS(_ sender: UIBarButtonItem) {
        let keys: [String] = [
            "R-*-*",
            "W-*-*",
            "A-*-*"
        ]

        CogsPubSubService.sharedService.connect(keys: keys) {
            DispatchQueue.main.async {
                self.statusLabel.text = "Service is connected"
            }
        }
    }

    @IBAction func disconnectWS(_ sender: UIBarButtonItem) {
        CogsPubSubService.sharedService.disconnect() {
            DispatchQueue.main.async {
                self.statusLabel.text = "Service is disconnected"
            }
        }
    }

    @IBAction func getSessionUUID(_ sender: UIButton) {
        CogsPubSubService.sharedService.getSessionUUID() { id in
            DispatchQueue.main.async {
                self.sessionUUIDLabel.text = id
            }
        }
    }

    @IBAction func subscribeToChannel(_ sender: UIButton) {
        guard let channelName = channelNameTextField.text, !channelName.isEmpty else { return }

        CogsPubSubService.sharedService.subsribeToChannel(channelName: channelName) { channels in
            DispatchQueue.main.async {
                self.channelListLabel.text = channels.joined(separator: "\n")
            }
        }
    }

    @IBAction func unsubscribeFromCahnnel(_ sender: UIButton) {
        guard let channelName = channelNameTextField.text, !channelName.isEmpty else { return }

        CogsPubSubService.sharedService.unsubsribeFromChannel(channelName: channelName) { channels in
            DispatchQueue.main.async {
                self.channelListLabel.text = channels.joined(separator: "\n")
            }
        }
    }

    @IBAction func getAllSubscriptions(_ sender: UIButton) {
        CogsPubSubService.sharedService.getAllSubscriptions { channels in
            DispatchQueue.main.async {
                self.channelListLabel.text = channels.joined(separator: "\n")
            }
        }
    }

    @IBAction func unsubscribeFromAll(_ sender: UIButton) {
        CogsPubSubService.sharedService.unsubsribeFromAllChannels { channels in
            DispatchQueue.main.async {
                self.channelListLabel.text = channels.joined(separator: "\n")
            }
        }
    }

    @IBAction func publishMessage(_ sender: UIButton) {
        guard let channel = channelNameTextField.text, !channel.isEmpty else { return }
        let messageText = messageTextView.text!
        let ack = ackSwitch.isOn
        
        CogsPubSubService.sharedService.publishMessage(channelName: channel, message: messageText, acknowledgement: ack) { receivedMessage in
            DispatchQueue.main.async {
                self.receivedMessageLabel.text = receivedMessage.message
            }
        }
    }
}
