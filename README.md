# CogsSDK

<!-- toc -->
- [Description](#description)
- [Requirements](#requirements)
- [Installation](#installation)
    -[Manual](#manual)
    -[CocoaPods](#cocoapods)
- [Usage](#usage)
    - [Cogs Pub/Sub Options](#cogs-pubsub-options)
        - [Connection Events](#connection-events)
            - [Event: onNewSession](#event-onnewsession)
            - [Event: onReconnect](#event-onreconnect)
            - [Event: onRawRecord](#event-onrawrecord)
            - [Event: onMessage](#event-onmessage)
            - [Event: onError](#event-onerror)
            - [Event: onErrorResponse](#event-onerrorresponse)
            - [Event: onClose](#event-onclose)
    - [Cogs Pub/Sub Service](#cogs-pubsub-service)
    - [Cogs Pub/Sub ConnectionHandle API](#cogs-pubsub-connectionhandle-api)
        - [getSessionUuid(completion:)](#getsessionuuidcompletion)
        - [subscribe(channel:messageHandler:completion:)](#subscribechannelmessagehandlercompletion)
        - [unsubscribe(channel:completion:)](#subscribechannelcompletion)
        - [unsubscribeAll(completion:)](#unsubscribeallcompletion)
        - [listSubscriptions(completion:)](#listsubscriptionscompletion)
        - [publish(channel:message:errorHandler:)](#publishchannelmessageerrorHandler)
        - [publishWithAck(channel:message:completion:)](#publishwithackchannelmessagecompletion)
        - [dropConnection()](#dropconnection)
        - [close()](#connectionclose)
    - [Gambit Service](#gambit-service)
        - [requestEvent(_ gambitRequest:completionHandler:)](#requestevent_-gambitrequestcompletionhandler)
        - [registerPush(_ gambitRequest:completionHandler:)](#registerpush_-gambitrequestcompletionhandler)
        - [unregisterPush(_ gambitRequest:completionHandler:)](#unregisterpush_-gambitrequestcompletionhandler)
        - [message(_ gambitRequest:completionHandler:)](#message_-gambitrequestcompletionhandler)
- [PubSub Tests](#pubsub-tests)
- [Author](#author)
- [License](#license)

<!-- tocstop -->

## Description
The Swift client SDK containing the Cogs Pub Sub API.

## Requirements

* iOS 9.0+
* Xcode 8.0+
* Swift 3.0+

## Installation

### Manual
* Check out or download CogsSDK.
* Open CogsSDK.xcworkspace in Xcode.
* Build.
* Navigate to the derived data folder and copy CogsSDK.framework and add it to you project.

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate CogsSDK into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

target '<Your Target Name>' do
pod 'CogsSDK'
end
```

Then, run the following command:

```bash
$ pod install
```

## Usage

## Cogs Pub/Sub Options
Create a ```PubSubOptions``` and set connection's options and event handlers. If no options are provided the default ones would be set.

```swift
let options = PubSubOptions.defaultOptions 
or 
let options = PubSubOptions(url: url,
                            connectionTimeout: 30,
                            autoReconnect: true,
                            minReconnectDelay: 5,
                            maxReconnectDelay: 300,
                            maxReconnectAttempts: -1,
                            onNewSessionHandler: { (sessionUUID) in
                                print(sessionUUID)
                            },
                            onReconnectHandler: {
                                print("Session is restored")
                            },
                            onRawRecordHandler: { (record) in
                                print (record)
                            },
                            onMessageHandler: { (receivedMessage) in
                                print (receivedMessage)
                            },
                            onCloseHandler: { (error) in
                                if let err = error {
                                    print(err.localizedDescription)
                                } else {
                                    print("Session is closed")
                                }
                            },
                            onErrorHandler: { (error) in
                                print(error.localizedDescription)
                            },
                            onErrorResponseHandler: { (responseError) in
                                print("\(responseError.message) \n \(responseError.code)")
                            })
```

## Connection Events

### Event: onNewSession
The ```onNewSession``` event indicates that the session associated with this connection is not a resumed session, therefore there are no subscriptions associated with this session. If there had been a previous session and the connection was replaced by an auto-reconnect, the previous session was not restored resulting in all subscriptions being lost.

```swift
options.onNewSession = { sessionUUID in
    print("New session \(sessionUUID) is opened."
}
```
### Event: onReconnect
The ```onReconnect``` event is emitted on socket reconnection if it disconnected for any reason.

```swift
options.onReconnect = {
    print("Session is restored")
}
```

### Event: onRawRecord
The ```onRawRecord``` event is emitted for every raw record received from the server, whether a response to a request or a message. This is mostly useful for debugging issues with server communication.

```swift
options.onRawRecord = { (record) in
  print (record)
}
```

### Event: onMessage
The ```onMessage``` event is emitted whenever the socket receives messages from any channel.

```swift
options.onMessage = { (receivedMessage) in
    print (receivedMessage)
}
```

### Event: onError
The ```onError``` event is emitted on any connection errors, failed publishes, or when any exception is thrown.

```swift
options.onError = { (error) in
    print(error.localizedDescription)
}
```

### Event: onErrorResponse
The ```onErrorResponse``` event is emitted whenever a message is sent to the user with an error status code.

```swift
options.onErrorResponse = { (responseError) in
  print("\(responseError.message) \n \(responseError.code)")
}
```

### Event: onClose
The ```onClose``` event is emitted whenever the socket connection closes.

```swift
options.onClose = { (error) in
    if let err = error {
        print(err.localizedDescription)
    } else {
        print("Session is closed")
    }
}
```

## Cogs Pub/Sub Service

Create a ```PubSubService``` object to obtain a connection handle. The created ```PubSubConnectionHandle``` object initializes and establishes a web socket connection.

```swift
let keys: [String] = ["read key", "write key", "admin key"]
        
let options = PubSubOptions(url: url,
                            connectionTimeout: 30,
                            autoReconnect: true,
                            minReconnectDelay: 5,
                            maxReconnectDelay: 300,
                            maxReconnectAttempts: -1,
                            onNewSessionHandler: { (sessionUUID) in
                                print(sessionUUID)
                            },
                            onReconnectHandler: {
                                print("Session is restored")
                            },
                            onRawRecordHandler: { (record) in
                                print (record)
                            },
                            onMessageHandler: { (receivedMessage) in
                                print (receivedMessage)
                            },
                            onCloseHandler: { (error) in
                                if let err = error {
                                    print(err.localizedDescription)
                                } else {
                                    print("Session is closed")
                                }
                            },
                            onErrorHandler: { (error) in
                                print(error.localizedDescription)
                            },
                            onErrorResponseHandler: { (responseError) in
                                print("\(responseError.message) \n \(responseError.code)")
                            })
        
let connection = PubSubService.connnect(keys: keys,
                                     options: options)
```

## Cogs Pub/Sub ConnectionHandle API
This is a summary of all functions exposed by the ```PubSubConnectionHandle``` object, and examples of their usage.

### getSessionUuid(completion:)
Fetch the session UUID from the server. The successful result contains the UUID associated with this connection's session.

```swift
connection.getSessionUuid { outcome in
    switch outcome {
        case .pubSubSuccess(let uuid):
            print("Session uuid \(uuid)")

        case .pubSubResponseError(let error):
            print(error)
    }
}
```

### subscribe(channel:messageHandler:completion:)
Subscribes the connection to a channel, supplying a handler which will be called with each message received from this channel. The successful result contains a list of the subscribed channels.The connection needs read permissions in order to subscribe to a channel.

```swift
connection.subscribe(channel: channel,
                  messageHandler: { (message) in
                    print("\(message.id) | \(message.message)")
        }) { outcome in
            switch outcome {
            case .pubSubSuccess(let subscribedChannels):
                print(subscribedChannels)
                
            case .pubSubResponseError(let error):
                print(error)
            }
        }
```

### unsubscribe(channel:completion:)
Unsubscribes the connection from a particular channel. The successful result contains an array with currently subscribed channels without the channel just unsubscribed from. The connection needs read permission in order to unsubscribe from the channel.

```swift
connection.unsubscribe(channel: channel){ outcome in
    switch outcome {
    case .pubSubSuccess(let subscribedChannels):
        print(subscribedChannels) //The list won't include the channel to unsubscribe from

    case .pubSubResponseError(let error):
        print(error)
    }
}
```
### unsubscribeAll(completion:)
Unsubscribes connection from all channels. The successful result should be an empty array. The connection needs read permission in order to unsubscribe from all channels.

```swift
connection.unsubscribeAll(){ outcome in
    switch outcome {
    case .pubSubSuccess(let subscribedChannels):
        print(subscribedChannels)
        // This is the list of channels to which we were subscribed prior to running this operation.

    case .pubSubResponseError(let error):
        print(error)
    }
}
```

### listSubscriptions(completion:)
Gets all subscriptions. The successful result contains an array with currently subscribed channels.

```swift
connection.listSubscriptions(){ outcome in
    switch outcome {
    case .pubSubSuccess(let subscribedChannels):
        print(subscribedChannels)

    case .pubSubResponseError(let error):
        print(error)
    }
}
```

### publish(channel:message:errorHandler:)
Publishes a message to a channel. The connection must have write permissions to successfully publish a message. The message string is limited to 64KiB. Messages that exceed this limit will result in the termination of the websocket connection.

```swift
connection.publish(channel: channel, message: messageText){ error in
    print(error as Any)
}
```

### publishWithAck(channel:message:completion:)
Publishes a message to a channel. The successful result contains the UUID of the published message.

```swift
connection.publishWithAck(channel: channel, message: messageText){ outcome in
    switch outcome {
    case .pubSubSuccess(let messadeUuid):
        print(messadeUuid)

    case .pubSubResponseError(let error):
        print(error)
    }
}
```

### dropConnection()
Drops connection.

```swift
connection.dropConnection()
```

### close()
Closes the pub/sub connection handle by closing the WebSocket.

```swift
connection.close()
```

## Gambit Service

There is no service to setup as the CogsSDK maintains a singleton 
instance of the service internally. You need to make sure your client auth
components (access-key, client-salt, and client-secret) are available for each of your requests.

```swift

import CogsSDK

// Hex encoded access-key from one of your api keys in the Web UI.
let accessKey: String = "0000"

// Hex encoded client salt/secret pair acquired from /client_secret endpoint and 
// associated with above access-key.
let clientSalt: String = "0000"
let clientSecret: String = "0000"

// Acquire the CogsSDK service singleton
cogsService = GambitService.sharedGambitService

```

### requestEvent(_ gambitRequest:completionHandler:)
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
      if let data = dat {
        do {
            let json : JSON = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            let parsedResponse = try GambitResponseEvent(json: json)
            // Handle message content
        } catch {
            // Handle JSON parse error
        }
      } else {
        // Handle no response data
      }
    } else {
      // Handle non-200 status code
    }
  }
}

```

### registerPush(_ gambitRequest:completionHandler:)
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
      if let data = dat {
        do {
            let json : JSON = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            let parsedResponse = try GambitResponsePush(json: json)
            // Handle message content
        } catch {
            // Handle JSON parse error
        }
      } else {
        // Handle no response data
      }
    } else {
      // Handle non-200 status code
    }
  }
}

```

### unregisterPush(_ gambitRequest:completionHandler:)
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
      if let data = dat {
        do {
            let json : JSON = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            let parsedResponse = try GambitResponsePush(json: json)
            // Handle message content
        } catch {
            // Handle JSON parse error
        }
      } else {
        // Handle no response data
      }
    } else {
      // Handle non-200 status code
    }
  }
}

```

### message(_ gambitRequest:completionHandler:)
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
        do {
            let json : JSON = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            let parsedResponse = try GambitResponseMessage(json: json)
            // Handle message content
        } catch {
            // Handle JSON parse error
        }
      } else {
        // Handle no response data
      }
    } else {
      // Handle non-200 status code
    }
  }
}

```

## PubSub Tests
- Locate the ```Keys.plist``` file from the ```Tests``` folder in the project pane in Xcode and populate ```adminKey```, ```readKey``` and ```writeKey``` with your own keys
- Go to the Test navigator in Xcode (the rhombus icon among the buttons on the top)
- Expand ```CogsSDK_Tests``` and select test class or single test to run
- Click on the play button to the right


## Author

Aviata Inc.

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

