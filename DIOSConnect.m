//
//  DIOSConnect.m
//
// ***** BEGIN LICENSE BLOCK *****
// Version: MPL 1.1/GPL 2.0
//
// The contents of this file are subject to the Mozilla Public License Version
// 1.1 (the "License"); you may not use this file except in compliance with
// the License. You may obtain a copy of the License at
// http://www.mozilla.org/MPL/
//
// Software distributed under the License is distributed on an "AS IS" basis,
// WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
// for the specific language governing rights and limitations under the
// License.
//
// The Original Code is Kyle Browning, released June 27, 2010.
//
// The Initial Developer of the Original Code is
// Kyle Browning
// Portions created by the Initial Developer are Copyright (C) 2010
// the Initial Developer. All Rights Reserved.
//
// Contributor(s):
//
// Alternatively, the contents of this file may be used under the terms of
// the GNU General Public License Version 2 or later (the "GPL"), in which
// case the provisions of the GPL are applicable instead of those above. If
// you wish to allow use of your version of this file only under the terms of
// the GPL and not to allow others to use your version of this file under the
// MPL, indicate your decision by deleting the provisions above and replacing
// them with the notice and other provisions required by the GPL. If you do
// not delete the provisions above, a recipient may use your version of this
// file under either the MPL or the GPL.
//
// ***** END LICENSE BLOCK *****

#import "DIOSConnect.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "NSData+Base64.h"
#import "DIOSConfig.h"

@implementation DIOSConnect

@synthesize connResult, sessid, params, userInfo, methodUrl, responseStatusMessage, requestMethod, error, progressDelegate;
@synthesize serverUrl = _serverUrl;

/*
 * This init function will automatically connect and setup the session for communicaiton with drupal
 */
- (id)init {
    self = [super init];
    error = nil;
    if(params == nil) {
        params = [[NSMutableDictionary alloc] init];
    }
    [self setRequestMethod:@"POST"];
    [self connect];
    return self;
}

- (id)initWithServerURL:(NSString *)url {
    self = [super init];
    error = nil;
    if (url != nil) {
        self.serverUrl = [NSString stringWithFormat:@"%@%@", url, DRUPAL_SERVICE];
    } else {
        self.serverUrl = [NSString stringWithString:DRUPAL_SERVICES_URL];
    }
    NSLog(@"Service URL: %@", self.serverUrl);
    if(params == nil) {
        NSMutableDictionary *newParams = [[NSMutableDictionary alloc] init];
        params = newParams;
    }
    [self setRequestMethod:@"POST"];
    [self connect];
    return self;
}

//Use this, if you have already connected to Drupal, for example, if the user is logged in, you should
//Store that session id somewhere and use it anytime you need to make a new drupal call.
//DIOSConnect should handle there rest.
- (id)initWithSession:(DIOSConnect*)aSession {
    self = [super init];
    if ([aSession respondsToSelector:@selector(userInfo)] && [aSession respondsToSelector:@selector(sessid)]) {
        [self setUserInfo:[aSession userInfo]];
        [self setSessid:[aSession sessid]];
    }
    error = nil;
    if(params == nil) {
        NSMutableDictionary *newParams = [[NSMutableDictionary alloc] init];
        params = newParams;
    }
    self.serverUrl = aSession.serverUrl;
    [self setRequestMethod:@"POST"];
    return self;
}

- (void)connect {
    [self setMethodUrl:@"system/connect"];
    [self runMethod];
}

- (void)setError:(NSError *)e {
    if (e != error) {
        [error release];
        error = [e retain];
    }
}

//This runs our method and actually gets a response from drupal
- (void)runMethod {
	UIApplication* app = [UIApplication sharedApplication];
	app.networkActivityIndicatorVisible = YES;
    
    [self setError:nil];

    // Removing 2 additional params but seems no needed anymore in drupal 7
    // Adding those 2 parameters the function
    // _services_arg_value($myVar, 'myVar');
    // inside the services callbacks doesn't work, because receive an array with more then 1 component returning the whole array.
    [self removeParam:@"sessid"];
//    [self removeParam:@"method"];
  
    NSString *url = [NSString stringWithFormat:@"%@/%@", self.serverUrl ? self.serverUrl : DRUPAL_SERVICES_URL, [self methodUrl]];
  
    ASIHTTPRequest *requestBinary = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];

    NSString *errorStr;
    NSData *dataRep = [NSPropertyListSerialization dataFromPropertyList: [self params]
                                                               format: NSPropertyListBinaryFormat_v1_0
                                                     errorDescription: &errorStr];

    if([[self requestMethod] isEqualToString:@"POST"] || [[self requestMethod] isEqualToString:@"PUT"]) {
        [requestBinary appendPostData:dataRep];
    }
    [requestBinary setRequestMethod:requestMethod];
    [requestBinary addRequestHeader:@"Content-Type" value:@"application/plist"];
    [requestBinary addRequestHeader:@"Accept" value:@"application/plist"];
    [requestBinary setTimeOutSeconds:300];
    [requestBinary setShouldRedirect:NO];
    [requestBinary setUploadProgressDelegate:progressDelegate];
    [requestBinary startSynchronous];
    responseStatusMessage = [requestBinary responseStatusMessage];

    [self setError:[requestBinary error]];
    if (!error) {
        NSData *response = [requestBinary responseData];

        NSPropertyListFormat format;
        id plist = nil;

        [self setResponseStatusMessage:[requestBinary responseStatusMessage]];

        if(response != nil) {
            plist = [NSPropertyListSerialization propertyListFromData:response
                                                   mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                                             format:&format
                                                   errorDescription:&errorStr];
            if (errorStr) {
                NSError *e = [NSError errorWithDomain:@"DIOS-Error" 
                                             code:1 
                                         userInfo:[NSDictionary dictionaryWithObject:errorStr forKey:NSLocalizedDescriptionKey]];
                [self setError:e];
                [errorStr release];
                NSLog(@"error-response: %@", [requestBinary responseString]);
            }
        } else {
            NSError *e = [NSError errorWithDomain:@"DIOS-Error" 
                                       code:1 
                                   userInfo:[NSDictionary dictionaryWithObject:@"I couldnt get a response, is the site down?" forKey:NSLocalizedDescriptionKey]];
			[self setError:e];
		}
		
        if([requestBinary responseStatusCode] != 200) {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:[requestBinary responseStatusMessage] forKey:NSLocalizedDescriptionKey];
            [self setError:[NSError errorWithDomain:@"DIOSConnect" code:[requestBinary responseStatusCode] userInfo:errorDetail]];
        }
        if (plist && !error) {
            [self setConnResult:plist];
            if([[self methodUrl] isEqualToString:@"system/connect"]) {
                if(plist != nil) {
                    [self setSessid:[plist objectForKey:@"sessid"]];
                    [self setUserInfo:[plist objectForKey:@"user"]];
                }
            }
            if([[self methodUrl] isEqualToString:@"user/login"]) {
                if(plist != nil) {					
                    [self setSessid:[plist objectForKey:@"sessid"]];
                    [self setUserInfo:[plist objectForKey:@"user"]];
                }
            }
            if([[self methodUrl] isEqualToString:@"user/logout"]) {
                if(plist != nil) {
                    [self setSessid:nil];
                    [self setUserInfo:nil];
                }
            }
        }
	}
	
	if(error) {
        NSLog(@"%@", [error localizedDescription]);
    }
	//Bug in ASIHTTPRequest, put here to stop activity indicator
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (NSString *)buildParams {
    NSString *finalParams;
    NSMutableArray *arrayofParams = nil;
    NSEnumerator *enumerator = [params keyEnumerator];
    NSString *aKey = nil;
    NSString *value = nil;
    while ( (aKey = [enumerator nextObject]) != nil) {
        value = [params objectForKey:aKey];
        [arrayofParams addObject:[NSString stringWithFormat:@"&%@=%@", aKey, value]];
    }

    finalParams = [arrayofParams componentsJoinedByString:@""];
    NSString *finalParamsString = @"";
    for (NSString *string in arrayofParams) {
        finalParamsString = [finalParamsString stringByAppendingString:string];
    }
    return finalParams;
}

- (void)addParam:(id)value forKey:(NSString *)key {
    if(value != nil) {
        [params setObject:value forKey:key];
    }
}

- (void)removeParam:(NSString *)key {
    [params removeObjectForKey:key];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"connresult = %@, userInfo = %@, methodUrl = %@, params = %@, sessionid = %@", connResult, userInfo, methodUrl, params, sessid];
}
- (void) dealloc {
    [error release];
    [connResult release];
    [sessid release];
    [self setMethodUrl:nil];
    [params release];
    [userInfo release];
    [_serverUrl release];
    [super dealloc];
}

@end
