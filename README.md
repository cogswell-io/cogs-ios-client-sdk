# Cogs iOS SDK

For the time being, see documentation on https://www.cogswell.io

## [Code Samples](#code-samples)
You will see the name Gambit throughout our code samples. This was the code name used for Cogs prior to release.

### Preparation for using the Client SDK
There is no service to setup as the Swift Cogs client SDK maintains a singleton 
instance of the service internally. You simply need to make sure your client auth
components (access-key, client-salt, and client-secret) are available for each of your requests.

```swift
import GambitSDK

// Hex encoded access-key from one of your api keys in the Web UI.
let accessKey: String = "0000"

// Hex encoded client salt/secret pair acquired from /client_secret endpoint and 
// associated with above access-key.
let clientSalt: String = "0000"
let clientSecret: String = "0000"

// Acquire the Cogs SDK service singleton
cogsService = GambitService.sharedGambitService
```

### POST /event
This API route is used send an event to Cogs.

```swift
// This will be sent along with messages so that you can identify the event which
// "triggered" the message delivery.
let eventName: String = "my-event"

// The name of the namespace for which the event is destined.
let namespace: String = "my-namespace"

// The event attributes whose names and types should match the namespace schema.
let attributes: [String: AnyObject] = [
  "uuid": "deadbeef-dead-beef-dead-beefdeadbeef"
]

// Assemble the event
let eventRequeset = GambitRequestEvent(
  nil,
  nil,
  accessKey,
  clientSalt,
  clientSecret,
  nil,
  eventName,
  namespace,
  attributes
)

// Send the event, and handle the response
cogsService.registerPush(eventRequeset) { dat, rsp, err in
  if let error = err {
    // Handle error
  }
  else if let response = rsp as? NSHTTPURLResponse {
    if response.statusCode == 200 {
      // Handle successful request
    } else {
      // Handle non-200 status code
    }
  }
}
```

### POST /register_push
This API route is used to register a device to receive push notifications for a particular topic within a namespace.

```swift
// The iOS app identifier.
let platformAppId: String = "com.example.app"

// The app environment.
let environment: String = "production"

// The unique identifier for the device used to deliver APNS notifications.
let udid: String = "0000"

// The name of the namespace to which the device is registering for notifications
// on the specified topic.
let namespace: String = "my-namespace"

// The primary key attributes which identify the topic, whose names and types 
// must match the namespace schema.
let pkAttributes: [String: AnyObject] = [
  "uuid": "deadbeef-dead-beef-dead-beefdeadbeef"
]

let pushRequest = GambitRequestPush(
  clientSalt,
  clientSecret,
  udid,
  accessKey,
  pkAttributes,
  environment,
  platformAppId,
  namespace
)

// Send the push registration, and handle the response.
cogsService.registerPush(pushRequest) { dat, rsp, err in
  if let error = err {
    // Handle error
  }
  else if let response = rsp as? NSHTTPURLResponse {
    if response.statusCode == 200 {
      // Handle successful request
    } else {
      // Handle non-200 status code
    }
  }
}
```

### DELETE /unregister_push
This API route is used to unregister a device from a particular namespace/topic pair to which it was previously registered for push notifications.

```swift
// The iOS app identifier.
let platformAppId: String = "com.example.app"

// The app environment.
let environment: String = "production"

// The unique identifier for the device used to deliver APNS notifications.
let udid: String = "0000"

// The name of the namespace from which the device is unregistering for
// notifications on the specified topic.
let namespace: String = "my-namespace"

// The primary key attributes which identify the topic, whose names and types 
// must match the namespace schema.
let pkAttributes: [String: AnyObject] = [
  "uuid": "deadbeef-dead-beef-dead-beefdeadbeef"
]

// Assemble the push de-registration request
let pushRequest = GambitRequestPush(
  clientSalt,
  clientSecret,
  udid,
  accessKey,
  pkAttributes,
  environment,
  platformAppId,
  namespace
)

// Send the push de-registration, and handle the response.
cogsService.unregisterPush(pushRequest) { dat, rsp, err in
  if let error = err {
    // Handle error
  }
  else if let response = rsp as? NSHTTPURLResponse {
    if response.statusCode == 200 {
      // Handle successful request
    } else {
      // Handle non-200 status code
    }
  }
}
```

### GET /message
This API route is used to fetch the full content of a message by its ID. This is necessary since push notifications don't deliver the entire message content, only the message's ID.

```swift
// The ID of the message to be fetched.
let messageId: String = "00000000-0000-0000-0000-000000000000"

// The namespace of the message to be fetched.
let namespace: String = "my-namespace"

// The attributes identifying the topic of the message.
let pkAttributes: [String: AnyObject] = [
  "uuid": "deadbeef-dead-beef-dead-beefdeadbeef"
]

// Assemble the message request.
let messageRequest = GambitRequestPush(
  accessKey,
  clientSalt,
  clientSecret,
  messageId,
  namespace,
  pkAttributes
)

// Send request the message, and handle the response.
cogsService.message(messageRequest) { dat, rsp, err in
  if let error = err {
    // Handle error
  }
  else if let response = rsp as? NSHTTPURLResponse {
    if response.statusCode == 200 {
      if let data = dat {
        // Handle message body
      }
      else {
        // Handle no message body
      }
    } else {
      // Handle non-200 status code
    }
  }
}
```

