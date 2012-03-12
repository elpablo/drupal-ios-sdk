//
//  NodeManager.h
//  MyTP
//
//  Created by Paolo Quadrani on 31/10/11.
//  Copyright (c) 2011 Paolo Quadrani. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DIOSUser.h"
#import "Node.h"

@class DIOSNode;

@interface NodeManager : NSObject {
    DIOSNode *_node;
    DIOSUser *_userSession;
    BOOL tagsNeedsUpdate;
}

@property (nonatomic, strong) DIOSUser *userSession;
@property (nonatomic, strong) DIOSNode *node;
@property (nonatomic, strong) NSMutableArray *allTags;
@property (nonatomic, strong) NSMutableArray *vocabularyCache;

+ (NodeManager *)sharedInstance;
- (void)registerNode:(NSString *)classType forItemType:(NSString *)name;
- (id)instanceForNodeData:(NSMutableDictionary *)data;
- (BOOL)authenticateUser:(NSString *)username withPassword:(NSString *)pwd forServerURL:(NSString *)serverURL;

//////////////////////////////////// New node data
- (NSMutableDictionary *)nodeData;

//////////////////////////////////// Node management
- (NSArray *)allNodes;
- (NSArray *)nodesFromTag:(NSDictionary *)tagDic;
- (NSArray *)nodesFromTitle:(NSString *)title;

- (id)getContentForNode:(NSDictionary *)nodeDic;

- (BOOL)saveNode:(NSMutableDictionary *)data;
- (void)deleteNode:(NSDictionary *)nodeDic;

//////////////////////////////////// Vocabulary management
- (NSArray *)allVocabulary;
- (NSDictionary *)vocabularyByName:(NSString *)name;

//////////////////////////////////// Tag management
- (NSArray *)tagsForVocabularyName:(NSString *)name;
- (id)addTagName:(NSString *)tagName andDescription:(NSString *) desc toVocabularyName:(NSString *)vocName;
- (id)addTag:(NSDictionary *)tagDic toVocabularyName:(NSString *)vocName;
- (void)deleteTag:(NSDictionary *)tagDic;
- (NSDictionary *)getTag:(NSString *)name;

//////////////////////////////////// Comments management
- (NSMutableDictionary *)addComment:(NSString *)cTitle withBody:(NSString *)cBody toNode:(Node *)n;
- (void)addComment:(NSMutableDictionary *)data toNode:(Node *)n;
- (NSArray *)commentsForNode:(Node *)node;
- (NSInteger)getCommentCountForNode:(Node *)n;
- (NSDictionary *)getComment:(NSString *)cid;
- (void)updateComment:(NSMutableDictionary *)data;
- (void)deleteComment:(NSDictionary *)c;

//////////////////////////////////// Files management
- (NSDictionary *)uploadFile:(NSString *)filePath;

@end
