# Cogs iOS SDK

For the time being, see documentation on https://www.cogswell.io

## [Code Samples](#code-samples)
You will see the name Gambit throughout our code samples. This was the code name used for Cogs prior to release.

### Preparation for using the Client SDK
There is no service to setup as the Swift Cogs client SDK maintains a singleton 
instance of the service internally. You simply need to make sure your client auth
components (access-key, client-salt, and client-secret) are available for each of your requests.

```swift
let accessKey: String = "0000"
let clientSalt: String = "0000"
let clientSecret: String = "0000"
```

### POST /event
This API route is used send an event to Cogs.

```swift
let eventName: String = "my-event"
let namespace: String = "my-namespace"
let attributes: [String: AnyObject] = {
  "uuid": "deadbeef-dead-beef-dead-beefdeadbeef"
}

let request = GambitRequestEvent(
  accessKey = accessKey,
  clientSalt = clientSalt,
  clientSecret = clientSecret,
  eventName = eventName,
  namespace = namespace,
  attributes = attributes
)

GambitService.requestEvent(request, func (data, response, error) -> Void {
    // TODO: handle error, response, and data
})
```

### POST /register_push
This API route is used to register a device to receive push notifications for a particular topic within a namespace.

```swift
```

### DELETE /unregister_push
This API route is used to unregister a device from a particular namespace/topic pair to which it was previously registered for push notifications.

```swift
```

### GET /message
This API route is used to fetch the full content of a message by its ID. This is necessary since push notifications don't deliver the entire message content, only the message's ID.

```swift
```

