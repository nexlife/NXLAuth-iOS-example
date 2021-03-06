//
//  ViewController.m
//  ExampleApp for NXLAuth
//
//  Created by Jason Lee on 10/10/2018.
//  Copyright © 2018 Jaosn Lee. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import <NXLAuth/NXLAuth.h>

static NSString *const kAppAuthExampleAuthStateKey = @"currentAuthState";

@interface ViewController () <OIDAuthStateChangeDelegate, OIDAuthStateErrorDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _logTextView.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1.0].CGColor;
    _logTextView.layer.borderWidth = 1.0f;
    _logTextView.alwaysBounceVertical = true;
    _logTextView.textContainer.lineBreakMode = NSLineBreakByCharWrapping;
    _logTextView.text = @"";
    _accessToken.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1.0].CGColor;
    _accessToken.layer.borderWidth = 1.0f;
    _idToken.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1.0].CGColor;
    _idToken.layer.borderWidth = 1.0f;
    // Do any additional setup after loading the view, typically from a nib.
    _loginButton.layer.borderWidth = 1.0f;
    _loginButton.layer.borderColor = [UIColor colorWithRed:0.24 green:0.80 blue:0.50 alpha:1.0].CGColor;
    _loginButton.layer.cornerRadius = 5;
    [_loginButton setTitleColor:[UIColor colorWithRed:0.24 green:0.80 blue:0.50 alpha:1.0] forState:UIControlStateNormal];
    
    _apiButton.layer.borderWidth = 1.0f;
    _apiButton.layer.borderColor = [UIColor colorWithRed:0.40 green:0.40 blue:0.40 alpha:1.0].CGColor;
    _apiButton.layer.cornerRadius = 5;
    [_apiButton setTitleColor:[UIColor colorWithRed:0.40 green:0.40 blue:0.40 alpha:1.0] forState:UIControlStateNormal];
    
    _userinfoButton.layer.borderWidth = 1.0f;
    _userinfoButton.layer.borderColor = [UIColor colorWithRed:0.40 green:0.40 blue:0.40 alpha:1.0].CGColor;
    _userinfoButton.layer.cornerRadius = 5;
    [_userinfoButton setTitleColor:[UIColor colorWithRed:0.40 green:0.40 blue:0.40 alpha:1.0] forState:UIControlStateNormal];
    
    _loginButton.layer.borderWidth = 1.0f;
    _loginButton.layer.borderColor = [UIColor colorWithRed:0.40 green:0.40 blue:0.40 alpha:1.0].CGColor;
    _loginButton.layer.cornerRadius = 5;
    [_loginButton setTitleColor:[UIColor colorWithRed:0.40 green:0.40 blue:0.40 alpha:1.0] forState:UIControlStateNormal];
    
    _logoutButton.layer.borderWidth = 1.0f;
    _logoutButton.layer.borderColor = [UIColor colorWithRed:1.00 green:0.00 blue:0.00 alpha:1.0].CGColor;
    _logoutButton.layer.cornerRadius = 5;
    [_logoutButton setTitleColor:[UIColor colorWithRed:1.00 green:0.00 blue:0.00 alpha:1.0] forState:UIControlStateNormal];
    [self loadState];
    [self updateUI];
    
}

- (IBAction)button:(id)sender {
    AppDelegate *appDelegate = (AppDelegate *) [UIApplication sharedApplication].delegate;
    NXLAppAuthManager *nexMng = [[NXLAppAuthManager alloc] init];
    NSArray *scopes = @[ ScopeOpenID, ScopeOffline];
    [nexMng authRequest:scopes :^(OIDAuthorizationRequest *request){
        [self logMessage:@"[Client] Initiating authorization request with scope: %@", request.scope];
        [self logMessage:@"[Client] Request URL: %@", request.authorizationRequestURL];
        
        appDelegate.currentAuthorizationFlow = [nexMng authStateByPresentingAuthorizationRequest:request presentingViewController:self callback:^(OIDAuthState * _Nullable authState, NSError * _Nullable error) {
            NSLog(@"[Client] authState: %@", authState);
            NSLog(@"[Client] authorizationCode: %@", authState.lastAuthorizationResponse.authorizationCode);
            NSLog(@"[Client] accessToken: %@", authState.lastTokenResponse.accessToken);
            NSLog(@"[Client] idToken: %@", authState.lastTokenResponse.idToken);
            NSLog(@"[Client] refreshToken: %@", authState.lastTokenResponse.refreshToken);
            self->_accessToken.text = authState.lastTokenResponse.accessToken;
            self->_idToken.text = authState.lastTokenResponse.idToken;
            
            if (authState) {
                [self setAuthState:authState];
                [self logMessage:@"[Client] Got authorization tokens. Access token: %@",authState.lastTokenResponse.accessToken];
                
            } else {
                [self logMessage:@"[Client] Authorization error: %@", [error localizedDescription]];
                [self setAuthState:nil];
            }
        }];
    }];
}
- (IBAction)getUserInfo:(id)sender {
    NXLAppAuthManager *nexMng = [[NXLAppAuthManager alloc] init];
    [nexMng getUserInfo:^(NSDictionary * _Nonnull response) {
        [self logMessage:@"[Client] User Info: %@", response];
    }];
}

- (IBAction)callApi:(id)sender {
    NXLAppAuthManager *nexMng = [[NXLAppAuthManager alloc] init];
    NSURL *userinfoEndpoint =
    _authState.lastAuthorizationResponse.request.configuration.discoveryDocument.userinfoEndpoint;
    if (!userinfoEndpoint) {
        [self logMessage:@"[Client] Userinfo endpoint not declared in discovery document"];
        return;
    }
    NSString *currentAccessToken = _authState.lastTokenResponse.accessToken;
    [self logMessage:@"[Client] Performing userinfo request"];
    //    [self logMessage:@"[Client] AuthState: %@", _authState];
    [nexMng getFreshToken:^(NSString * _Nonnull accessToken, NSString * _Nonnull idToken, OIDAuthState * _Nonnull currentAuthState, NSError * _Nullable error) {
        [self setAuthState:currentAuthState];
        if (error) {
            [self logMessage:@"[Client1] Error fetching fresh tokens: %@", [error localizedDescription]];
            return;
        }
        
        // log whether a token refresh occurred
        if (![currentAccessToken isEqual:accessToken]) {
            [self logMessage:@"[Client] Token refreshed"];
            [self logMessage:@"Access token was refreshed automatically (%@ to %@)",
             currentAccessToken,
             accessToken];
            
        } else {
            [self logMessage:@"[Client] Token still valid"];
            [self logMessage:@"Access token was fresh and not updated [%@]", accessToken];
        }
        // creates request to the userinfo endpoint, with access token in the Authorization header
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:userinfoEndpoint];
        NSString *authorizationHeaderValue = [NSString stringWithFormat:@"Bearer %@", accessToken];
        [request addValue:authorizationHeaderValue forHTTPHeaderField:@"Authorization"];
        
        NSURLSessionConfiguration *configuration =
        [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration
                                                              delegate:nil
                                                         delegateQueue:nil];
        
        [self logMessage:@"[Client] API Request URL: %@", request.URL];
        [self logMessage:@"[Client] API Request Header: %@", request.allHTTPHeaderFields];
        
        // performs HTTP request
        NSURLSessionDataTask *postDataTask =
        [session dataTaskWithRequest:request
                   completionHandler:^(NSData *_Nullable data,
                                       NSURLResponse *_Nullable response,
                                       NSError *_Nullable error) {
                       dispatch_async(dispatch_get_main_queue(), ^() {
                           if (error) {
                               [self logMessage:@"HTTP request failed %@", error];
                               return;
                           }
                           if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
                               [self logMessage:@"Non-HTTP response"];
                               return;
                           }
                           
                           NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                           [self logMessage:@"[Client] API Response: %@", data];
                           id jsonDictionaryOrArray =
                           [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
                           
                           if (httpResponse.statusCode != 200) {
                               // server replied with an error
                               NSString *responseText = [[NSString alloc] initWithData:data
                                                                              encoding:NSUTF8StringEncoding];
                               if (httpResponse.statusCode == 401) {
                                   // "401 Unauthorized" generally indicates there is an issue with the authorization
                                   // grant. Puts OIDAuthState into an error state.
                                   NSError *oauthError =
                                   [OIDErrorUtilities resourceServerAuthorizationErrorWithCode:0
                                                                                 errorResponse:jsonDictionaryOrArray
                                                                               underlyingError:error];
                                   [self->_authState updateWithAuthorizationError:oauthError];
                                   // log error
                                   [self logMessage:@"Authorization Error (%@). Response: %@", oauthError, responseText];
                               } else {
                                   [self logMessage:@"HTTP: %d. Response: %@",
                                    (int)httpResponse.statusCode,
                                    responseText];
                               }
                               return;
                           }
                           
                           // success response
                           [self logMessage:@"Success: %@", jsonDictionaryOrArray];
                       });
                   }];
        
        [postDataTask resume];
    }];
}

- (void)logMessage:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2) {
    // gets message as string
    va_list argp;
    va_start(argp, format);
    NSString *log = [[NSString alloc] initWithFormat:format arguments:argp];
    va_end(argp);
    
    // outputs to stdout
    NSLog(@"%@", log);
    
    // appends to output log
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"hh:mm:ss";
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    _logTextView.text = [NSString stringWithFormat:@"%@%@%@: %@",
                         _logTextView.text,
                         ([_logTextView.text length] > 0) ? @"\n" : @"",
                         dateString,
                         log];
}

- (void)updateUI {
    NSLog(@"UPDATE UI");
    // dynamically changes authorize button text depending on authorized state
    if (!_authState) {
        _status.text = nil;
        _accessToken.text = nil;
        _idToken.text = nil;
        [self logMessage:@"[Client] Auth Status: %@", nil];
        _loginButton.layer.borderColor = [UIColor colorWithRed:0.24 green:0.80 blue:0.50 alpha:1.0].CGColor;
        [_loginButton setTitleColor:[UIColor colorWithRed:0.24 green:0.80 blue:0.50 alpha:1.0] forState:UIControlStateNormal];
        _loginButton.layer.backgroundColor = [UIColor clearColor].CGColor;
        _apiButton.layer.borderColor = [UIColor colorWithRed:0.40 green:0.40 blue:0.40 alpha:1.0].CGColor;
        [_apiButton setTitleColor:[UIColor colorWithRed:0.40 green:0.40 blue:0.40 alpha:1.0] forState:UIControlStateNormal];
        _userinfoButton.layer.borderColor = [UIColor colorWithRed:0.40 green:0.40 blue:0.40 alpha:1.0].CGColor;
        [_userinfoButton setTitleColor:[UIColor colorWithRed:0.40 green:0.40 blue:0.40 alpha:1.0] forState:UIControlStateNormal];
        _logoutButton.layer.borderColor = [UIColor colorWithRed:1.00 green:0.00 blue:0.00 alpha:1.0].CGColor;
        [_logoutButton setTitleColor:[UIColor colorWithRed:1.00 green:0.00 blue:0.00 alpha:1.0] forState:UIControlStateNormal];
         _logoutButton.layer.backgroundColor = [UIColor clearColor].CGColor;
    } else {
        _status.text = @"Authenticated";
        [self logMessage:@"[Client] Auth Status: Authenticated"];
        _loginButton.layer.borderColor = [UIColor colorWithRed:0.24 green:0.80 blue:0.50 alpha:1.0].CGColor;
        [_loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _loginButton.layer.backgroundColor = [UIColor colorWithRed:0.24 green:0.80 blue:0.50 alpha:1.0].CGColor;
        _logoutButton.layer.borderColor = [UIColor colorWithRed:1.00 green:0.00 blue:0.00 alpha:1.0].CGColor;
        [_logoutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _logoutButton.layer.backgroundColor = [UIColor colorWithRed:1.00 green:0.00 blue:0.00 alpha:1.0].CGColor;
        _apiButton.layer.borderColor = [UIColor colorWithRed:0.17 green:0.75 blue:0.87 alpha:1.0].CGColor;
        [_apiButton setTitleColor:[UIColor colorWithRed:0.17 green:0.75 blue:0.87 alpha:1.0] forState:UIControlStateNormal];
        _userinfoButton.layer.borderColor = [UIColor colorWithRed:0.17 green:0.75 blue:0.87 alpha:1.0].CGColor;
        [_userinfoButton setTitleColor:[UIColor colorWithRed:0.17 green:0.75 blue:0.87 alpha:1.0] forState:UIControlStateNormal];
        
        _accessToken.text = _authState.lastTokenResponse.accessToken;
        
        _idToken.text = _authState.lastTokenResponse.idToken;
    }
}

- (void)setAuthState:(nullable OIDAuthState *)authState {
    NSLog(@"[Client] setAuthState");
    if (_authState == authState) {
        return;
    }
    _authState = authState;
//    if (authState != nil) {
//        [self performSegueWithIdentifier:@"login_success" sender:self];
//    }

    _authState.stateChangeDelegate = self;
    
    [self saveState];
    [self updateUI];
}

- (void)stateChanged {
    [self saveState];
    [self updateUI];
}

- (void)saveState {
    // for production usage consider using the OS Keychain instead
    //    NSLog(@"[Client] AuthState before archieve: %@", _authState);
    NSData *archivedAuthState = [ NSKeyedArchiver archivedDataWithRootObject:_authState];
    [[NSUserDefaults standardUserDefaults] setObject:archivedAuthState
                                              forKey:kAppAuthExampleAuthStateKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)loadState {
    // loads OIDAuthState from NSUSerDefaults
    NSData *archivedAuthState =
    [[NSUserDefaults standardUserDefaults] objectForKey:kAppAuthExampleAuthStateKey];
    OIDAuthState *authState = [NSKeyedUnarchiver unarchiveObjectWithData:archivedAuthState];
    if (!authState) {
        [self logMessage:@"[Client] Load Previous State: %@", nil];
    } else {
        [self logMessage:@"[Client] Load Previous State Success"];
    }
    [self setAuthState:authState];
}


- (IBAction)logout:(id)sender {
    NSLog(@"Logout1");
    [self setAuthState:nil];
    NXLAppAuthManager *ssoMng = [[NXLAppAuthManager alloc] init];
    [ssoMng logOut];
    _status.text = nil;
    _logTextView.text = @"";
//    [self updateUI];
}
- (IBAction)logOutHome:(id)sender {
    NSLog(@"Logout2");
    [self setAuthState:nil];
    NXLAppAuthManager *ssoMng = [[NXLAppAuthManager alloc] init];
    [ssoMng logOut];
    _status.text = nil;
    _logTextView.text = @"";
    [self performSegueWithIdentifier:@"logout_success" sender:self];
}


- (IBAction)clearLog:(id)sender {
    _logTextView.text = @"";
}

@end
