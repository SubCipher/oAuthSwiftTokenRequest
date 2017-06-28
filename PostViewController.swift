//
//  PostViewController.swift
//
//
//  Created by knax on 6/22/17.
//  Copyright © 2017 StepwiseDesigns. All rights reserved.
//

import UIKit
import SafariServices
import AVFoundation

class PostViewController: UIViewController, SFSafariViewControllerDelegate {
    
    
    
    let deviceSetting = VideoMemeDeviceSettings()
    weak var delegate: SFSafariViewControllerDelegate?
    
    let session = URLSession.shared
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    
    let googleAuthURL = "https://accounts.google.com/o/oauth2/v2/auth?"
    let baseURL = "https://www.googleapis.com/"
    
    
    let tokenExchangeMethod = "oauth2/v4/token"
    let tokenExchangeGrantType = "grant_type=authorization_code"
    
    //returns a list of videos that match the API request parameters. no auth required
    let listVideoMethod = "youtube/v3/videos?"
    
    //insert video URL
    let insertVideoMethod = "upload/youtube/v3/videos?"
    
    let scope = "scope=https://www.googleapis.com/auth/youtube.upload"
    let part = "part=snippet%2CcontentDetails%2Cstatistics"
    
    
    //sample video for listing
    let videoID = "id=xhsx1oO5j9Y"
    
    let scheme = "com.StepwiseDesigns.MyGreatAppAdventure"
    let apiKey = "key=myApiKey"
    let clientID = "client_id=xxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com"
    let redirect = "redirect_uri=com.StepwiseDesigns.MyGreatAppAdventure"
    let responseType = "response_type=code"
    let accessType = "access_type=offline"
    
    
    var authToken:String = ""
    var youTubeAuthURLmethod: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicatorView.isHidden = true
    }
    
    //MARK:- Authentication token Reqest
    //reference links
    //https://developer.apple.com/documentation/safariservices/sfsafariviewcontroller
    //https://stackoverflow.com/questions/38818786/safariviewcontroller-how-to-grab-oauth-token-from-url
    
    
    @IBAction func authentication(_ sender: Any) {
        
        self.youTubeAuthenticationMethod = URL(string: "\(googleAuthURL)&\(responseType)&\(clientID)&\(scope)&\(redirect+":\(scheme)")")
        print("")
        print("auth url = \(googleAuthURL)&\(responseType)&\(clientID)&\(scope)&\(redirect+":\(scheme)")")
        print("")
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(tokenRequest(_:)), name: Notification.Name("codeRequest"), object: nil)
        
        let safariVC = SFSafariViewController(url: youTubeAuthenticationMethod)
        safariVC.delegate = self
        self.present(safariVC, animated: true, completion: nil)
    }
    
    
    @objc func tokenRequest(_ notification : Notification) {
        
        guard let tokenDataAsURL = notification.object as? URL! else {
            print("got nothing")
            return
        }
        
        
        dismiss(animated: false, completion: nil)
        authToken =  filterTokenResponse(tokenDataAsURL.absoluteString) { (success, error) in
            if success {
                
            } else {
                print("error: no token returned from filter",error ?? "no code for token error")
            }
        }
        print("Test for auth...print it if you got it -->",authToken)
        
    }
    
    //MARK-: Filter For Server Response
    func filterTokenResponse(_ code: String, completionHandlerForToken: @escaping (_ success: Bool, _ error:NSError?)->Void) -> String {
        
        //use for loop and arrays to perform chacter matching for parsing the authToken response
        var codeResponse = code
        var indexCount = 0
        var matchArray = [Int]()
        let charToMatch = Character("=")
        
        for i in codeResponse.characters {
            
            if charToMatch == i {
                matchArray.append(indexCount)
            }
            indexCount += 1
        }
        
        let charToMatchIndex = matchArray.max()
        let start = codeResponse.characters.startIndex
        
        let filterRange = codeResponse.characters.index(start, offsetBy: charToMatchIndex!)
        
        let range = (codeResponse.startIndex...filterRange)
        codeResponse.characters.removeSubrange(range)
        if codeResponse.characters.contains("%"){
            codeResponse.characters.removeSubrange(codeResponse.characters.index(of: "%")!...codeResponse.characters.index(before: codeResponse.characters.endIndex))
            
        } else {
            completionHandlerForToken(false, NSError(domain: "no key for login access filterd", code: 0, userInfo: [NSLocalizedDescriptionKey: "filter could not parse data"]))
        }
        completionHandlerForToken(true, nil)
        return codeResponse
    }
    
    
    
    //MARK:- Authorization Request For Token
    @IBAction func postVideoActionButton(_ sender: Any) {
        
        activityIndicatorView.isHidden = false
        activityIndicatorView.startAnimating()
        
        
        let tokenExchangeCode = "code=\(authToken)"
        let urlContructForTokenExchange = "\(googleAuthURL)\(tokenExchangeMethod)&\(tokenExchangeCode)&\(clientID)&\(redirect)&\(scope)&\(tokenExchangeGrantType)"

        
        
        youTubePOSTRequest(urlContructForTokenExchange) {(success,error) in
            
            self.performUpdatesOnMainQueue {
                
                if success == false{
                    self.activityIndicatorView.stopAnimating()
                    self.activityIndicatorView.isHidden = true
                    print("did fail or not?1*********",success)
                    
                    let actionSheet = UIAlertController(title: "ERROR", message: "record update failed to post", preferredStyle: .alert)
                    
                    actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    self.present(actionSheet,animated: true, completion: nil)
                    
                } else {
                    
                    print("did fail or not?2*********",success)
                    self.activityIndicatorView.stopAnimating()
                    self.activityIndicatorView.isHidden = true
                    
                    
                    //if action is complete return to recordVC
                    let controller = self.storyboard!.instantiateViewController(withIdentifier: "NavigationController")
                    self.present(controller, animated: true, completion: nil)
                    
                    /* working URL samples from auth playground
                     code=4%2FhJIH8uIz_5Ha9Azmq_LrWHbKZzErDQ2mR84n8B77CIw&redirect_uri=https%3A%2F%2Fdevelopers.google.com%2Foauthplayground&client_id=407408718192.apps.googleusercontent.com&client_secret=************&scope=&grant_type=authorization_code
                     
                     
                     let postURLasString = "https://www.googleapis.com/youtube/v3/videos?part=snippet%2CcontentDetails%2Cstatistics&id=Ks-_Mh1QhMc&key=AIzaSyBtQXRLuqWCG8XX78VyMU31bRcUFkcMUrU"
                     
                     https://developers.google.com/identity/protocols/OAuth2WebServer#formingtheurl
                     
                     */
                }
            }
        }
    }
    
    
    func youTubePOSTRequest(_ urlAsString: String, completionHandlerForYouTubePOSTRequest: @escaping (_ success: Bool,_ error: NSError?) -> Void) {
        
        let jsonBody = ""
        let request = formatRequest(urlAsString, jsonBody)
        
        let _ = taskForYouTubePOSTrequest(request as URLRequest) { (response, error) in
            if error == nil {
                completionHandlerForYouTubePOSTRequest(true,nil)
            } else {
                
                completionHandlerForYouTubePOSTRequest(false,NSError(domain: "URLRequest", code: 1, userInfo: [NSLocalizedDescriptionKey: "error downloading data"]))
            }
        }
    }
    
    //MARK: - Helper Method For formatting POST URLRequest
    
    func formatRequest(_ mutableString:String, _ jsonBody: String) -> URLRequest{
        
        var request = URLRequest(url: URL(string:mutableString)!)
        request.httpMethod = "POST"
        request.addValue(authToken, forHTTPHeaderField: "code")
        request.addValue(clientID, forHTTPHeaderField: "client_id")
        request.addValue("com.StepwiseDesigns.VideoMeme", forHTTPHeaderField: "redirect_url")
        request.addValue("authorization_code", forHTTPHeaderField: "grant_type")
        
        //request.addValue(apiKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        
        //request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        //request.httpBody = jsonBody.data(using: String.Encoding.utf8)
        
        return request
    }
    
    func taskForYouTubePOSTrequest(_ processedURL: URLRequest,
                                   completionHandlerForParsePOST: @escaping ( _ results: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        
        let task = session.dataTask(with: processedURL as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandlerForParsePOST(response!, NSError(domain: "TaskForPost", code: 1, userInfo: userInfo))
                
            }
            guard (error == nil) else {
                sendError((error?.localizedDescription) ?? "unknown error")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                
                let responseValue = (response as? HTTPURLResponse)?.statusCode
                if let responseValue = responseValue { print("HTTPURLResponse response",responseValue.description) }
                print("")
                print("HTTPURLResponse header caught in guard w/status code",response)
                print("")
                return
            }
            self.convertDataWithCompletionHandler(data!, completionHandlerForConvertData: completionHandlerForParsePOST)
        }
        
        task.resume()
        return task
    }
    
    //MARK: - Convert from json
    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result:AnyObject?, _ error: NSError?) -> Void) {
        var parsedResult: AnyObject! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
            
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : error.localizedDescription]
            completionHandlerForConvertData(true as AnyObject?,NSError(domain: "convertDataWithCompletionHandler", code: 2, userInfo: userInfo))
        }
        completionHandlerForConvertData(parsedResult as AnyObject?,nil)
    }
    
    func performUpdatesOnMainQueue(_ updates: @escaping () -> Void) {
        DispatchQueue.main.async {
            updates()
        }
    }
    
}
