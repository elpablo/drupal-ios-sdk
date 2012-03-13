//
//  NodeManager.m
//  MyTP
//
//  Created by Paolo Quadrani on 31/10/11.
//  Copyright (c) 2011 Paolo Quadrani. All rights reserved.
//

#import "NodeManager.h"

#import "DIOSNode.h"
#import "DIOSTaxonomy.h"
#import "DIOSViews.h"
#import "DIOSComment.h"
#import "DIOSFile.h"
#import "NSData+Base64.h"

#import "Categories/NSDictionaryHelper.h"


@interface NodeManager ()

@property (nonatomic, retain) NSMutableDictionary *nodeFactory;

- (void)_initParameters;

@end


@implementation NodeManager

@synthesize userSession = _userSession;
@synthesize node = _node;
@synthesize allTags = _allTags;
@synthesize vocabularyCache = _vocabularyCache;
@synthesize nodeFactory = _nodeFactory;


static NodeManager *sharedInstance = nil;

+ (NodeManager *)sharedInstance {
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [[self alloc] init];
            [sharedInstance _initParameters];
        }
        return sharedInstance;
    }
}

- (void)_initParameters {
    _nodeFactory = [[NSMutableDictionary alloc] init];
}

- (BOOL)authenticateUser:(NSString *)username withPassword:(NSString *)pwd forServerURL:(NSString *)serverURL {
    BOOL result = NO;
    DIOSUser *session = [[DIOSUser alloc] initWithServerURL:serverURL];
    DIOSUser *user = [[DIOSUser alloc] initWithSession:session];
    [session release];
    NSDictionary *info = user.userInfo;
    NSString *name = [info objectForKey:@"name"];
    if (name != nil && [name isEqualToString:username]) {
        NSLog(@"Already logged-in as %@...", username);
        result = YES;
    } else {
        [user loginWithUsername:username andPassword:pwd];
        result = [user isAuthenticated];
    }
    if (result) {
        self.userSession = user;
    }
    [user release];
    return result;
}

#pragma mark - Memory Management

- (NSUInteger)retainCount {
    return (NSUIntegerMax);
}

- (oneway void)release {
}

- (id)autorelease {
    return (self);
}

- (id)retain {
    return (self);
}

- (void)dealloc {
    [self.nodeFactory removeAllObjects];
    self.nodeFactory = nil;
    [self setVocabularyCache:nil];
    [self setUserSession:nil];
    [self setNode:nil];
    [self setAllTags:nil ];
    [super dealloc];
}

- (DIOSNode *)node {
    if (_node == nil || ![_node.sessid isEqualToString:self.userSession.sessid]) {
        [_node release]; _node = nil;
        _node = [[[DIOSNode alloc] initWithSession:self.userSession] retain];
    }
    return _node;
}

#pragma mark - Views Management

- (NSArray *)viewElementsWithName:(NSString *)name andParameters:(NSString *)params {
    DIOSViews *views = [[[DIOSViews alloc] initWithSession:self.userSession] autorelease];
    if (params) {
        return [views viewsGet:name andArguments:[params stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    } else {
        return [views viewsGet:name];
    }
}

#pragma mark - Node management

- (void)registerNode:(NSString *)classType forItemType:(NSString *)name {
    if (![self.nodeFactory containsKey:name]) {
        [self.nodeFactory setObject:classType forKey:name];
    }
}

- (id)instanceForNodeData:(NSMutableDictionary *)data {
    NSString *name = [data objectForKey:@"type"];
    if ([self.nodeFactory containsKey:name]) {
        NSString *typeName = [self.nodeFactory objectForKey:name];
        Class c = NSClassFromString(typeName);
        id node = NSAllocateObject(c, 0, NULL);
        if (node) {
            [node setNodeData:data];
        }
        return node;
    }
    return nil;
}

- (NSArray *)allNodes {
    return [self.node nodeGetIndex];
}

- (NSArray *)allVocabulary {
    if (_vocabularyCache == nil) {
        DIOSTaxonomy *taxonomy = [[DIOSTaxonomy alloc] initWithSession:self.userSession];
        NSArray *arr = [taxonomy allVocabulary];
        _vocabularyCache = [[NSMutableArray alloc] initWithArray:arr];
        [taxonomy release];
    }
    return _vocabularyCache;
}

- (NSDictionary *)vocabularyByName:(NSString *)name {
    NSArray *v = [self allVocabulary];
    NSString *queryKey = @"name";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", queryKey, name];
    NSArray *res = [v filteredArrayUsingPredicate:predicate];
    
    NSDictionary *dic = [res count] == 0 ? nil : [res objectAtIndex:0];
    return dic;
}

- (NSArray *)tagsForVocabularyName:(NSString *)name {
    NSDictionary *v = [self vocabularyByName:name];
    NSArray *tags = nil;
    if (v != nil) {
        NSNumber *vid = [v objectForKey:@"vid"];
        DIOSTaxonomy *taxonomy = [[DIOSTaxonomy alloc] initWithSession:self.userSession];
        tags = [taxonomy getTree:[vid stringValue]];
        [taxonomy release];
    }
    return tags;
}

- (NSMutableArray *)allTags {
    if (_allTags == nil || tagsNeedsUpdate) {
        [_allTags release];
        _allTags = [[self tagsForVocabularyName:@"Tags"] mutableCopy];
        tagsNeedsUpdate = NO;
    }
    return _allTags;
}

- (NSArray *)nodesFromTag:(NSDictionary *)tagDic {
    DIOSTaxonomy *taxonomy = [[DIOSTaxonomy alloc] initWithSession:self.userSession];
    NSString *tid = [tagDic objectForKey:@"tid"];
    NSArray *arr = (NSArray *)[taxonomy selectNodes:tid];
    [taxonomy release];
    return arr;
}

- (NSArray *)nodesFromTitle:(NSString *)title {
    return [self.node nodeSearchFromTitle:title];
}

- (id)getContentForNode:(NSDictionary *)nodeDic {
    return [self.node nodeGet:[nodeDic objectForKey:@"nid"]];
}

- (NSMutableDictionary *)nodeData {
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                 @"", @"body", 
                                 @"und", @"language",
                                 @"", @"type", 
                                 @"", @"title",
                                 @"now", @"date",
                                 @"1", @"status",
                                 @"", @"name",
                                 @"", @"nid",
                                 nil];

    if ([[_userSession.userInfo objectForKey:@"uid"] isEqualToNumber:[NSNumber numberWithInt:0]]) {
        [data setObject:@"" forKey:@"name"];
    } else if([[self userSession] userInfo] == nil) {
        [data setObject:@"" forKey:@"name"];
    } else {
        [data setObject:[_userSession.userInfo objectForKey:@"name"] forKey:@"name"];
        [data setObject:[_userSession.userInfo objectForKey:@"uid"] forKey:@"uid"];
    }
    return data;
}

- (BOOL)saveNode:(NSMutableDictionary *)data {
    // Save node...
    BOOL saveOK = NO;
    NSDictionary *dic = [self.node nodeSave:data];
    if (dic) {
        // and update the returned node ID...
        [data setObject:[dic objectForKey:@"nid"] forKey:@"nid"];
        saveOK = YES;
    }
    return saveOK;
}

- (void)deleteNode:(NSDictionary *)nodeDic {
    NSNumber *nid = [nodeDic objectForKey:@"nid"];
    [self.node nodeDelete:[nid stringValue]];
}

- (NSMutableDictionary *)addComment:(NSString *)cTitle withBody:(NSString *)cBody toNode:(Node *)n {
    NSString *nid = [[n.nodeData objectForKey:@"nid"] stringValue];

    NSMutableDictionary *comment = [[NSMutableDictionary alloc] init];
    if(![nid isEqualToString:@""]) {
        [comment setObject:nid forKey:@"nid"];
    }
    // Comment subject
    [comment setObject:cTitle forKey:@"subject"];
    // Comment body
    NSString *safeValue = [[[NSString alloc] initWithFormat:@"<p>%@</p>", cBody] autorelease];
    NSDictionary *bodyValues = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:cBody, safeValue, @"filtered_html", nil] forKeys:[NSArray arrayWithObjects:@"value", @"safe_value", @"format", nil]];
    NSDictionary *languageDict = [NSDictionary dictionaryWithObject:[NSArray arrayWithObject:bodyValues] forKey:n.language];
    [comment setObject:languageDict forKey:@"comment_body"];
    // Comment language
    [comment setObject:n.language forKey:@"language"];
    // Comment user ID
    if([[self.userSession userInfo] objectForKey:@"uid"] != nil) {
        id temp = [[self.userSession userInfo] objectForKey:@"uid"];
        [comment setObject:[temp stringValue] forKey:@"uid"];
    }
    // and name
    if([[self.userSession userInfo] objectForKey:@"name"] != nil) {
        id temp = [[self.userSession userInfo] objectForKey:@"name"];
        [comment setObject:temp forKey:@"name"];
    }
    
    DIOSComment *c = [[[DIOSComment alloc] initWithSession:self.userSession] autorelease];
    // Store result dictionary will contain comment ID and URL
    NSDictionary *dic = [c addComment:comment];
    if (dic) {
        [comment setObject:[dic objectForKey:@"cid"] forKey:@"cid"];
    }
    return comment;
}

- (void)addComment:(NSMutableDictionary *)data toNode:(Node *)n {
    DIOSComment *c = [[[DIOSComment alloc] initWithSession:self.userSession] autorelease];
    // Store result dictionary will contain comment ID and URL
    NSDictionary *dic = [c addComment:data];
    if (dic) {
        [data setObject:[dic objectForKey:@"cid"] forKey:@"cid"];
    }
}

- (void)updateComment:(NSMutableDictionary *)data {
    DIOSComment *c = [[[DIOSComment alloc] initWithSession:self.userSession] autorelease];
    id res = [c updateComment:[[data objectForKey:@"cid"] stringValue] withData:data];
    if (res == nil) {
        NSLog(@"Problems saving comment...");
    }
}

- (void)deleteComment:(NSDictionary *)c {
    DIOSComment *comment = [[[DIOSComment alloc] initWithSession:self.userSession] autorelease];
    BOOL ok = [comment deleteComment:[c objectForKey:@"cid"]];
    if (!ok) {
        NSLog(@"Problem deleting comment: %@", c);
    }
}

- (NSArray *)commentsForNode:(Node *)node {
    NSString *nid = [[node.nodeData objectForKey:@"nid"] stringValue];
    DIOSComment *comment = [[DIOSComment alloc] initWithSession:self.userSession];
    NSArray *arr = [comment allCommentsForNodeID:nid];
    [comment release];
    return arr;
}

- (NSInteger)getCommentCountForNode:(Node *)n {
    NSString *nid = [[n.nodeData objectForKey:@"nid"] stringValue];
    DIOSComment *comment = [[DIOSComment alloc] initWithSession:self.userSession];
    NSInteger num = [comment getCommentCountForNid:nid];
    [comment release];
    return num;
}

- (NSDictionary *)getComment:(NSString *)cid {
    DIOSComment *comment = [[[DIOSComment alloc] initWithSession:self.userSession] autorelease];
    return [comment getComment:cid];
}

- (id)addTag:(NSDictionary *)tagDic toVocabularyName:(NSString *)vocName {
    tagsNeedsUpdate = YES;
    NSDictionary *v = [self vocabularyByName:vocName];
    NSNumber *vid = [v objectForKey:@"vid"];

    DIOSTaxonomy *taxonomy = [[[DIOSTaxonomy alloc] initWithSession:self.userSession] autorelease];
    NSMutableDictionary * term = [[[NSMutableDictionary alloc] initWithDictionary:tagDic] autorelease];
    [term setObject:[vid stringValue] forKey:@"vid"];
    return [taxonomy createTermInVocabulary:term];
}

- (id)addTagName:(NSString *)tagName andDescription:(NSString *)desc toVocabularyName:(NSString *)vocName {
    tagsNeedsUpdate = YES;
    NSDictionary *v = [self vocabularyByName:vocName];
    NSNumber *vid = [v objectForKey:@"vid"];
    
    DIOSTaxonomy *taxonomy = [[DIOSTaxonomy alloc] initWithSession:self.userSession];
    NSMutableDictionary *term = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                 tagName, @"name", 
                                 [vid stringValue], @"vid", 
                                 desc, @"description", nil];
    id res = [taxonomy createTermInVocabulary:term];
    [term release];
    [taxonomy release];
    return res;
}

- (void)deleteTag:(NSDictionary *)tagDic {
    [self.allTags removeObject:tagDic];
    DIOSTaxonomy *taxonomy = [[DIOSTaxonomy alloc] initWithSession:self.userSession];
    NSString *tid = [tagDic objectForKey:@"tid"];
    [taxonomy deleteTerm:tid];
    [taxonomy release];
}

- (NSDictionary *)getTag:(NSString *)name {
    NSString *queryKey = @"name";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", queryKey, name];
    NSArray *res = [self.allTags filteredArrayUsingPredicate:predicate];
    
    NSDictionary *tagDic = [res count] == 0 ? nil : [res objectAtIndex:0];
    return tagDic;
}

- (NSDictionary *)uploadFile:(NSString *)filePath {
    NSData *fileData = [[NSData alloc] initWithContentsOfFile:filePath];
    
    DIOSFile *aFile = [[DIOSFile alloc] initWithSession:self.userSession];
    NSMutableDictionary *file = [[NSMutableDictionary alloc] init];

    NSString *base64Image = [fileData base64EncodedString];
    [file setObject:base64Image forKey:@"file"];
	NSString *timestamp = [NSString stringWithFormat:@"%d", (long)[[NSDate date] timeIntervalSince1970]];
    [file setObject:timestamp forKey:@"timestamp"];
    [file setObject:[filePath lastPathComponent] forKey:@"filename"];
    NSString *fileSize = [NSString stringWithFormat:@"%d", [fileData length]];
    [file setObject:fileSize forKey:@"filesize"];
    [file setObject:[self.userSession.userInfo objectForKey:@"uid"] forKey:@"uid"];
    id res = [aFile fileSave:file];
    
    NSDictionary *file_dic = nil;
    if ([res isKindOfClass:[NSDictionary class]]) {
        // if save was ok, res is a NSDictionary with 'uri' and 'fid' keys.
        NSString *fidStr = [[res objectForKey:@"fid"] stringValue];
        file_dic = [aFile fileGet:fidStr withFileContent:NO];
    }
    [file release];
    [aFile release];
    [fileData release];

    return file_dic;
}

@end
