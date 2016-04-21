# Cogs iOS Example App for Cogs SDK

## Description
The Example app for the Cogs SDK real-time message brokering system

## Requirements

* iOS 9.0+
* Xcode 7.3+
* Requires APNs enabled application. You can read more about APNs [here](https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/IPhoneOSClientImp.html#//apple_ref/doc/uid/TP40008194-CH103-SW2)

## Installation
### Manual
* Check out or download Cogs SDK
* Open GambitSDK.xcodeproj in Xcode
* Build the framework
* Navigate to the derived data folder and copy GambitSDK.framework and add it to you project

You can view a demo example using the SDK here: https://github.com/cogswell-io/cogs-ios-client-sdk

### Submodule

* Open up Terminal, and cd into your top-level project directory. If your project is not initialized as a git repository then run the following command:
```javascript
$ git init
```
* Add Cogs SDK as a git submodule by running the following command:
```javascript
$ git submodule add https://github.com/cogswell-io/cogs-ios-client-sdk
```
* Open the new GambitSDK folder, and drag the GambitSDK.xcodeproj into the Project Navigator of your application's Xcode project.
* Select the GambitSDK.xcodeproj in the Project Navigator and verify the deployment target matches that of your application target.
* Select your application project in the Project Navigator (blue project icon) to navigate to the target configuration window and select the application target under the "Targets" heading in the sidebar.
* In the tab bar at the top of that window, open the "General" panel.
* Click on the + button under the "Embedded Binaries" section.
* Select the GambitSDK.framework for iOS

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
  accessKey: accessKey,
  clientSalt: clientSalt,
  clientSecret: clientSecret,
  eventName: eventName,
  namespace: namespace,
  attributes: attributes
)

// Send the event, and handle the response
cogsService.requestEvent(eventRequeset) { dat, rsp, err in
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
  clientSalt: clientSalt,
  clientSecret: clientSecret,
  UDID: udid,
  accessKey: accessKey,
  attributes: pkAttributes,
  environment: environment,
  platformAppID: platformAppId,
  namespace: namespace
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
  clientSalt: clientSalt,
  clientSecret: clientSecret,
  UDID: udid,
  accessKey: accessKey,
  attributes: pkAttributes,
  environment: environment,
  platformAppID: platformAppId,
  namespace: namespace
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
  accessKey: accessKey,
  clientSalt: clientSalt,
  clientSecret: clientSecret,
  token: messageId,
  namespace: namespace,
  attributes: pkAttributes
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

## License

Copyright 2016 Aviata Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
