//
//  DIOSConnect.h
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

#import <Foundation/Foundation.h>

@interface DIOSConnect : NSObject 


@property (nonatomic, retain) id connResult;
@property (nonatomic, retain) id progressDelegate;
@property (nonatomic, retain) NSString *sessid;
@property (nonatomic, retain) NSMutableDictionary *params;
@property (nonatomic, retain) NSDictionary *userInfo;
@property (nonatomic, copy)   NSString *serverUrl;
@property (nonatomic, retain) NSString *methodUrl;
@property (nonatomic, retain) NSString *responseStatusMessage;
@property (nonatomic, retain) NSString *requestMethod;
@property (nonatomic, readonly) NSError *error;

- (id)init;
- (id)initWithSession:(DIOSConnect*)aSession;
// Use method below passing the URL in which is located your Drupal7 installation
// to avoid writing it in the DIOSConfig.h
- (id)initWithServerURL:(NSString *)url;

- (void)runMethod;

- (NSString *)buildParams;
- (void)addParam:(id)value forKey:(NSString *)key;
- (void)removeParam:(NSString *)key;

- (void)connect;

@end
