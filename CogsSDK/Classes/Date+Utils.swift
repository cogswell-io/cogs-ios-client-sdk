
import Foundation

extension Date {

    var toISO8601: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"
        dateFormatter.timeZone   = TimeZone(secondsFromGMT: 0)
        dateFormatter.calendar   = Calendar(identifier: .iso8601)
        dateFormatter.locale     = Locale(identifier: "en_US_POSIX")

        return dateFormatter.string(from: self)
    }
}
