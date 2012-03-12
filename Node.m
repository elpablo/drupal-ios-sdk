//
//  Node.m
//  iOS_Drupal
//
//  Created by Quadrani Paolo on 29/12/11.
//  Copyright (c) 2011 Paolo Quadrani. All rights reserved.
//

#import "Node.h"
#import "Categories/NSDictionaryHelper.h"

@interface Node ()


@end


@implementation Node

@synthesize nodeData = _nodeData;
@synthesize title = _title;
@synthesize body = _body;
@synthesize type = _type;
@synthesize language = _language;
@synthesize comments = _comments;

- (id)initWithUserInfo:(NSDictionary *)userInfo {
    self = [super init];
    if (self) {
        _nodeData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                     @"", @"body", 
                     @"und", @"language",
                     @"", @"type", 
                     @"", @"title",
                     @"now", @"date",
                     @"1", @"status",
                     @"", @"name",
                     @"", @"nid",
                     @"0", @"tnid",
                     @"1", @"promote",
                     @"0", @"sticky",
                     @"2", @"comment",
                     nil];
        if ([[userInfo objectForKey:@"uid"] isEqualToNumber:[NSNumber numberWithInt:0]]) {
            [_nodeData setObject:@"" forKey:@"name"];
        } else if(userInfo == nil) {
            [_nodeData setObject:@"" forKey:@"name"];
        } else {
            [_nodeData setObject:[userInfo objectForKey:@"name"] forKey:@"name"];
            [_nodeData setObject:[userInfo objectForKey:@"uid"] forKey:@"uid"];
        }
        _comments = [[NSMutableArray alloc] init];
        _title = [[NSString alloc] initWithString:@""];
        _body = [[NSString alloc] initWithString:@""];
        _type = [[NSString alloc] initWithString:@""];
        _language = [[NSString alloc] initWithString:@"und"];
    }
    return self;
}

- (id)initWithNodeData:(NSMutableDictionary *)data {
    self = [super init];
    if (self) {
        _comments = [[NSMutableArray alloc] init];
        [self setNodeData:data];
    }
    return self;
}

- (void)setNodeData:(NSMutableDictionary *)data {
    if (_nodeData == data) {
        return;
    }
    [_nodeData release];
    _nodeData = [data retain];
    [_language release];
    _language = [[_nodeData objectForKey:@"language"] retain];
    [_title release];
    _title = [[_nodeData objectForKey:@"title"] retain];
    [_type release];
    _type = [[_nodeData objectForKey:@"type"] retain];
}

- (void)dealloc {
    [_nodeData release];
    [_title release];
    [_body release];
    [_type release];
    [_comments release];
    [_language release];
    [super dealloc];
}

- (NSArray *)valuesFromCustomField:(NSString *)field_name {
    NSDictionary *field_dic = (NSDictionary *)[self.nodeData objectForKey:field_name];
    NSArray *und = nil;
    if ([field_dic count] > 0 && [field_dic containsKey:_language]) {
        und = (NSArray *)[field_dic objectForKey:_language];
    }
    return und;
}

- (NSDictionary *)valueFromCustomField:(NSString *)field_name atIndex:(NSInteger)index {
    NSArray *array = [self valuesFromCustomField:field_name];
    BOOL valuePresent = [array count] > index;
    if (valuePresent) {
        NSDictionary *dic = [array objectAtIndex:index];
        return dic;
    }
    return nil;
}

- (NSMutableDictionary *)customFieldWithData:(NSArray *)values andKey:(NSString *)key {
    NSMutableDictionary *valuesDict = [NSMutableDictionary dictionaryWithObjects:values forKeys:[NSArray arrayWithObjects:key, nil]];
    NSMutableDictionary *fieldDict = [NSMutableDictionary dictionaryWithObject:[NSArray arrayWithObject:valuesDict] forKey:_language];
    return fieldDict;
}

- (void)setValue:(NSDictionary *)valueDict forCustomField:(NSString *)field_name atIndex:(NSInteger)index {
    NSMutableDictionary *fieldDict = [NSMutableDictionary dictionaryWithObject:[NSArray arrayWithObject:valueDict] forKey:_language];
    [_nodeData setObject:fieldDict forKey:field_name];
}

- (void)setTitle:(NSString *)t {
    if (_title == t) {
        return;
    }
    [_title release];
    _title = [t retain];
    [_nodeData setObject:_title forKey:@"title"];
}

- (void)setType:(NSString *)t {
    if (_type == t) {
        return;
    }
    [_type release];
    _type = [t retain];
    [_nodeData setObject:_type forKey:@"type"];
}

- (void)setLanguage:(NSString *)l {
    if (_language == l) {
        return;
    }
    [_language release];
    _language = [l retain];
    [_nodeData setObject:_language forKey:@"language"];
}

- (void)setBody:(NSString *)b {
    if (_body == b) {
        return;
    }
    [_body release];
    _body = [b retain];
    NSMutableDictionary *valuesDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       _body, @"value", 
                                       @"", @"summary", 
                                       @"filtered_html", @"format", 
                                       [NSString stringWithFormat:@"<p>%@</p>", _body], @"safe_value",
                                       @"", @"safe_summary",
                                       nil];
    NSMutableDictionary *bodyDict = [NSMutableDictionary dictionaryWithObject:[NSArray arrayWithObject:valuesDict] forKey:_language];
    [_nodeData setObject:bodyDict forKey:@"body"];
}

- (NSString *)body {
    NSDictionary *dic = [self valueFromCustomField:@"body" atIndex:0];
    return [dic objectForKey:@"value"];
}

- (NSString *)bodyHTML {
    NSDictionary *dic = [self valueFromCustomField:@"body" atIndex:0];
    return [dic objectForKey:@"safe_value"];
}

- (void)setComments:(NSMutableArray *)c {
    if (_comments == c) {
        return;
    }
    [_comments removeAllObjects];
    [_comments release];
    _comments = [c retain];
}

@end
