import UIKit
import Flutter
import UserNotifications
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    var backgroundTaskID : UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    var userToken : String?
    let serverToken : String = "key=xxxx"
    
    func sentPushNotificationToAndroidFCM(title : String, body: String, chatID: String, allUsersTokens: Any, allAndroidUsers: Any, iosUsers: Any) {
        let messageID = Int.random(in: 1...10000)
        let url = "https://fcm.googleapis.com/fcm/send"
        let FCMUrl = URL(string: url)!
        var request = URLRequest(url: FCMUrl)
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(self.serverToken, forHTTPHeaderField: "authorization")
        request.httpMethod = "POST"
        let httpBody : [String: Any] = [
            "priority" : "high",
            "registration_ids" : allAndroidUsers,
            "data" : [
                "content" : [
                    "id" : messageID,
                    "channelKey" : "basic_channel",
                    "title" : title,
                    "body" : body,
                    "notificationLayout" : "BigPicture",
                    "largeIcon" : "https://avidablogfiles.worpress.com/2012/08/emmemc3b3riadeneilarmstrong3.jpg",
                    "bigPicture" : "https://www.dw.com/image/49519617_303.jpg",
                    "showWhen" : true,
                    "autoCancel": true,
                    "privacy": "Private",
                    "chatID" : chatID,
                    "allUsersInvoledTokens": allUsersTokens,
                    "androidUsersInvolvedTokens": allAndroidUsers,
                    "iosUsersInvolvedTokens": iosUsers
                ]
            ]
        ]
        let jsonDataAsString : String?
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: httpBody, options: [])
            request.httpBody = jsonData
        } catch  {
            print("Error parsing to json \(error)")
        }
            
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                let response = response as? HTTPURLResponse,
                error == nil else {                                              // check for fundamental networking error
                print("error", error ?? "Unknown error")
                return
            }

            guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                let responseBody = String(data: data, encoding: String.Encoding.utf8)
                print("Body of response is \(responseBody)")
                print("response = \(response)")
                return
            }

            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(responseString)")
        }

        task.resume()
        
    }
    
    func sendMessageToServer(message: String, recivedNotification : UNNotificationContent) {
        print("In sendMessageToServer")
        DispatchQueue.global(qos: .background).async {
            self.backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "SendReplyToServerTasks") {
                // End the task if time expires.
                UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
                self.backgroundTaskID = UIBackgroundTaskIdentifier.invalid
            }
            
            // Send the data synchronously.
            let db = Firestore.firestore()
            var userDataFromDB : [String : Any] = [:];
            let user = FirebaseAuth.Auth.auth().currentUser
            let userUID = user?.uid
            db.collection("users").document(userUID!).getDocument(completion: { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    print("\(querySnapshot!.documentID) => \(querySnapshot!.data())")
                    userDataFromDB = querySnapshot!.data()!
                    
                    print("userUID is \(userUID!)")
                    
                    let userInfo = recivedNotification.userInfo as [AnyHashable: Any]
                    var notificationContent : [String: Any] ;
                    do {
                        try notificationContent = JSONSerialization.jsonObject(with: (userInfo["content"] as! String)
                                                                                .data(using: .utf8)!, options: []) as! [String: Any]
                        print("Recived notification content is  \(String(describing: notificationContent["chatID"]!))")
                        
                        var allUsersInvolvedTokens : Any = notificationContent["allUsersInvoledTokens"]!
                        var iosUsersInvolvedTokens : Any = notificationContent["iosUsersInvolvedTokens"]!
                        var androidUsersInvolvedTokens : Any = notificationContent["androidUsersInvolvedTokens"]!
                        
                        print("Recived ntofication content is: --------")
                        print("allUsersInvolvedTokens is:")
                        print(allUsersInvolvedTokens)
                        print("iosUsersInvolvedTokens is:")
                        print(iosUsersInvolvedTokens)
                        print("androidUsersInvolvedTokens is:")
                        print(androidUsersInvolvedTokens)
                        print("--------------- end of notification")
                        
                        let chatID = notificationContent["chatID"] as! String
                        var ref: DocumentReference? = nil
                        ref = Firestore.firestore().collection("chats").document(chatID).collection("messages").addDocument(data: [
                            "text": message,
                            "createdAt": Timestamp.init(),
                            "userUID": userUID!,
                            "userName": userDataFromDB["username"]!
                        ]) { err in
                            if let err = err {
                                print("Error adding document: \(err)")
                            } else {
                                print("Document added with ID: \(ref!.documentID)")
                                let userName = userDataFromDB["username"]! as! String
                                self.sentPushNotificationToAndroidFCM(title: userName , body: message, chatID: chatID, allUsersTokens: allUsersInvolvedTokens, allAndroidUsers: androidUsersInvolvedTokens, iosUsers: iosUsersInvolvedTokens)
                            }
                        }
                        
                    }
                    catch {
                        print(error)
                    }
                }
            })
            
        }
        
        // End the task assertion.
        UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
        self.backgroundTaskID = UIBackgroundTaskIdentifier.invalid
    }
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        //    registerForPushNotifications()
        //FirebaseApp.configure()
        //Messaging.messaging()
        // Check if launched from notification
        let notificationOption = launchOptions?[.remoteNotification]
        
        //Refresh app code
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        // Period: 3600s = 1 hour
        UIApplication.shared.setMinimumBackgroundFetchInterval(30)
        
        //Firebase code
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in})
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        Messaging.messaging().token(completion: {token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                print("FCM registration token: \(token)")
                self.userToken = token
                //TODO code was here
            }
        })
        
        
        
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
        }
        
        //Initalization of actionable notification
        let readAction = UNNotificationAction(identifier: "READ_ACTION",
                                              title: "Przeczytana",
                                              options: UNNotificationActionOptions(rawValue: 0))
        let responseAction = UNTextInputNotificationAction(identifier: "RESPONSE_ACTION",
                                                           title: "Odpowiedź",
                                                           options: UNNotificationActionOptions(rawValue: 0))
        
        let messageActionCategory =
            UNNotificationCategory(identifier: "MESSAGE_ACTION",
                                   actions: [readAction, responseAction],
                                   intentIdentifiers: [],
                                   hiddenPreviewsBodyPlaceholder: "",
                                   options: .customDismissAction)
        
        UNUserNotificationCenter.current().setNotificationCategories([messageActionCategory])
        
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { (notification) in
            print("Recived notification in background \(notification)")
            
            // run your code here (or whatever)
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { (notification) in
            print("App becomeActive notification")
            
            // run your code here (or whatever)
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { (notification) in
            print("App willResignActive notification")
            
            // run your code here (or whatever)
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override
    func application(
      _ application: UIApplication,
      didReceiveRemoteNotification userInfo: [AnyHashable: Any],
      fetchCompletionHandler completionHandler:
      @escaping (UIBackgroundFetchResult) -> Void
    ) {
      guard let aps = userInfo["aps"] as? [String: AnyObject] else {
        print("Failed when getting aps key from userInfo")
        completionHandler(.failed)
        return
      }
        
        print("aps is \(aps)")
        print("userInfo is \(userInfo)")
      
    }
    
    //    func registerForPushNotifications() {
    //        UNUserNotificationCenter.current()
    //          .requestAuthorization(
    //            options: [.alert, .sound, .badge]) { [weak self] granted, _ in
    //            print("Permission granted: \(granted)")
    //            guard granted else { return }
    //            // 1
    //            let viewAction = UNNotificationAction(
    //              identifier: Identifiers.viewAction,
    //              title: "View",
    //              options: [.foreground])
    //
    //            // 2
    //            let newsCategory = UNNotificationCategory(
    //              identifier: Identifiers.newsCategory,
    //              actions: [viewAction],
    //              intentIdentifiers: [],
    //              options: [])
    //
    //            // 3
    //            UNUserNotificationCenter.current().setNotificationCategories([newsCategory])
    //
    //
    //            self?.getNotificationSettings()
    //          }
    //
    //    }
    //
    //    func getNotificationSettings() {
    //      UNUserNotificationCenter.current().getNotificationSettings { settings in
    //        print("Notification settings: \(settings)")
    //        guard settings.authorizationStatus == .authorized else { return }
    //        DispatchQueue.main.async {
    //          UIApplication.shared.registerForRemoteNotifications()
    //        }
    //
    //      }
    //    }
    
    //    override func application(
    //      _ application: UIApplication,
    //      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    //    ) {
    //        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    //          let token = tokenParts.joined()
    //          print("Device Token: \(token)")
    //    }
    
    //    override func application(
    //      _ application: UIApplication,
    //      didFailToRegisterForRemoteNotificationsWithError error: Error
    //    ) {
    //      print("Failed to register: \(error)")
    //    }
    override
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler:
                                    @escaping () -> Void) {
        
        // Get the meeting ID from the original notification.
        let notificationContent = response.notification.request.content
        
        // Perform the task associated with the action.
        switch response.actionIdentifier {
        case "READ_ACTION":
            print("1st action clicked")
            break
            
        case "RESPONSE_ACTION":
            print("2nd action clicked")
            let textResponse = response as! UNTextInputNotificationResponse
            self.processNotificationResponse(userResponse: textResponse.userText, recivedNotification: notificationContent)
            break
            
        // Handle other actions…
        
        default:
            print("Cant process action from notification")
            break
        }
        
        // Always call the completion handler when done.
        completionHandler()
    }
    
    
    func processNotificationResponse(userResponse : String, recivedNotification : UNNotificationContent) {
        print("response typed by user is \(userResponse)")
        sendMessageToServer(message: userResponse , recivedNotification: recivedNotification)
    }
    

    
    
    
    
    
    
    
    
    
    // print("Chat id in recived message is \(contentObject!["chatID"])")
    
    
    
    //        user?.getIDTokenResultWith(completion: { (userTokenId, error) in
    //        if (error != nil) {
    //            print("error getting userToken \(error)")
    //        }
    //
    //        print("userTokenId is \(userTokenId?.token)")
    //
    //
    //    })
    
}



func convertToDictionary(text: String) -> [String: Any]? {
    if let data = text.data(using: .utf8) {
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
    }
    return nil
}

extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}



