//
//  Node.h
//  MyTP
//
//  Created by Quadrani Paolo on 29/12/11.
//  Copyright (c) 2011 Paolo Quadrani. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DIOSConnect;

@interface Node : NSObject

@property (nonatomic, strong) NSMutableDictionary *nodeData;
@property (nonatomic, strong) NSMutableArray *comments;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *body;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *language;

- (id)initWithUserInfo:(NSDictionary *)userInfo;
- (id)initWithNodeData:(NSMutableDictionary *)data;

- (NSString *)bodyHTML;

- (NSArray *)valuesFromCustomField:(NSString *)field_name;
- (NSDictionary *)valueFromCustomField:(NSString *)field_name atIndex:(NSInteger)index;
- (void)setValue:(NSDictionary *)valueDict forCustomField:(NSString *)field_name atIndex:(NSInteger)index;

- (NSMutableDictionary *)customFieldWithData:(NSArray *)values andKey:(NSString *)key;

@end
