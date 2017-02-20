
import Foundation
import CogsSDK

class WSSMessagingVC: ViewController {
    
    @IBOutlet weak var statusLabel: UILabel!

    @IBAction func connectWS(_ sender: UIBarButtonItem) {
        let keys: [String] = [
            "R-*-*",
            "W-*-*",
            "A-*-*"
        ]

        CogsPubSubService.sharedService.connect(keys: keys)
    }

    @IBAction func disconnectWS(_ sender: UIBarButtonItem) {
        CogsPubSubService.sharedService.disconnect()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        CogsPubSubService.sharedService.delegate = self
    }
}

extension WSSMessagingVC: CogsPubSubServiceDelegate {
    func socketDidConnect() {
        statusLabel.text = "Socket connected"
    }

    func socketDidDisconnect() {
        statusLabel.text = "Socket disconnected"
    }
}
