
import Foundation

final class DialectValidator {

    static func parseAndAutoValidate(record: String, completionHandler: @escaping (JSON?, Error?, PubSubErrorResponse?) -> Void) {
        do {
            let json = try JSONSerialization.jsonObject(with: record.data(using: String.Encoding.utf8)!, options: .allowFragments) as JSON
            self.autoValidate(json, completionHandler: { (object, error, errorResponse) in
                completionHandler(object, error, errorResponse)
            })
        } catch {
            let error = NSError(domain: "CogsSDKError - PubSub Response", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
            completionHandler(nil, error, nil)
        }
    }

    private static func autoValidate(_ json: JSON, completionHandler: @escaping (JSON?, Error?, PubSubErrorResponse?) -> Void) {
        do {
            let generalError = try PubSubGeneralErrorResponse(json: json)

            completionHandler(nil, nil, generalError)
        } catch {
            do {
                let invalidRequestError = try PubSubBadRequestResponse(json: json)
                completionHandler(nil, nil, invalidRequestError)
            } catch {
                completionHandler(json, nil, nil)
            }
        }
    }
}
