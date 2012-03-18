//
//  DIOSComment.m
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


#import "DIOSComment.h"
#import "DIOSConfig.h"

@implementation DIOSComment

- (id)init {
    self = [super init];
    return self;
}

- (NSDictionary *)getComments:(NSString*)nid andStart:(NSString *)start andCount:(NSString *)count {
    [self setRequestMethod:@"GET"];
    NSString *url = [NSString stringWithFormat:@"node/%@/comments", nid];
    [self setMethodUrl:url];
    [self addParam:nid forKey:@"nid"];
    [self addParam:start forKey:@"start"];
    [self addParam:count forKey:@"count"];
    [self runMethod];
    return [self connResult];
}

- (NSArray *)allCommentsForNodeID:(NSString*)nid {
    [self setRequestMethod:@"GET"];
    [self setMethodUrl:[NSString stringWithFormat:@"comment?fields=*&parameters[nid]=%@", nid]];
    [self runMethod];
    return (NSArray *)[self connResult];
}

- (NSDictionary *)getComment:(NSString*)cid {
    [self setRequestMethod:@"GET"];
    [self setMethodUrl:[NSString stringWithFormat:@"comment/%@", cid]];
    [self addParam:cid forKey:@"cid"];
    [self runMethod];
    return [self connResult];
}

- (NSInteger)getCommentCountForNid:(NSString*)nid {
    [self setRequestMethod:@"POST"];
    [self setMethodUrl:@"comment/countAll"];
    [self addParam:nid forKey:@"nid"];
    [self runMethod];
    return [[self connResult] intValue];
}

- (NSInteger)getCommentCountNewForNid:(NSString*)nid {
    [self setRequestMethod:@"POST"];
    [self setMethodUrl:@"comment/countNew"];
    [self addParam:nid forKey:@"nid"];
    [self runMethod];
    return [[self connResult] intValue];
}

- (NSDictionary *)addComment:(NSString*)nid subject:(NSString*)aSubject body:(NSString*)aBody {
    [self setMethodUrl:@"comment"];
    if(![nid isEqualToString:@""]) 
        [self addParam:nid forKey:@"nid"];
    if(aSubject != nil)
        [self addParam:aSubject forKey:@"subject"];
    if(aBody != nil) {
        NSDictionary *bodyValues = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:aBody, nil] forKeys:[NSArray arrayWithObjects:@"value", nil]];
        NSDictionary *languageDict = [NSDictionary dictionaryWithObject:[NSArray arrayWithObject:bodyValues] forKey:DRUPAL_LANGUAGE];
        [self addParam:languageDict forKey:@"comment_body"];
        [self addParam:DRUPAL_LANGUAGE forKey:@"language"];
    }
    if([[self userInfo] objectForKey:@"uid"] != nil) {
        id temp = [[self userInfo] objectForKey:@"uid"];
        [self addParam:[temp stringValue] forKey:@"uid"];
    }    
    if([[self userInfo] objectForKey:@"name"] != nil) {
        id temp = [[self userInfo] objectForKey:@"name"];
        [self addParam:temp forKey:@"name"];
    }
    [self runMethod];
    return [self connResult];
}

- (NSDictionary *)addComment:(NSDictionary *)comment {
    [self setMethodUrl:@"comment"];
    [self addParam:comment forKey:@"comment"];
    [self runMethod];    
    return (NSDictionary *)[self connResult];
}

- (void)updateComment:(NSString*)cid subject:(NSString*)aSubject body:(NSString*)aBody {
    [self setMethodUrl:[NSString stringWithFormat:@"comment/%@", cid]];
    [self setRequestMethod:@"PUT"];
    NSMutableDictionary *comment = [[NSMutableDictionary alloc] init];
    if(![cid isEqualToString:@""]) 
        [comment setObject:cid forKey:@"cid"];
    if(aSubject != nil)
        [comment setObject:aSubject forKey:@"subject"];
    if(aBody != nil) {
        NSDictionary *bodyValues = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:aBody, nil] forKeys:[NSArray arrayWithObjects:@"value", nil]];
        NSDictionary *languageDict = [NSDictionary dictionaryWithObject:[NSArray arrayWithObject:bodyValues] forKey:DRUPAL_LANGUAGE];
        [comment setObject:languageDict forKey:@"comment_body"];
        [comment setObject:DRUPAL_LANGUAGE forKey:@"language"];
    }
    if([[self userInfo] objectForKey:@"uid"] != nil) {
        id temp = [[self userInfo] objectForKey:@"uid"];
        [comment setObject:[temp stringValue] forKey:@"uid"];
    }    
    if([[self userInfo] objectForKey:@"name"] != nil) {
        id temp = [[self userInfo] objectForKey:@"name"];
        [comment setObject:temp forKey:@"name"];
    }
    [self runMethod];
    [comment release];
    return;
}

- (id)updateComment:(NSString*)cid withData:(NSDictionary *)data {
    [self setMethodUrl:[NSString stringWithFormat:@"comment/%@", cid]];
    [self setRequestMethod:@"PUT"];
    [self addParam:cid forKey:@"cid"];
    [self addParam:data forKey:@"comment"];
    [self runMethod];    
    return [self connResult];
}

- (BOOL)deleteComment:(NSString*)cid {
    [self setRequestMethod:@"DELETE"];
    [self setMethodUrl:[NSString stringWithFormat:@"comment/%@", cid]];
    [self runMethod];
    return [[self connResult] boolValue];
}

@end
