//
//  LCCKUser.m
//  Cobweb
//
//  Created by solist on 2019/3/20.
//  Copyright © 2019 solist. All rights reserved.
//

#import "LCCKUser.h"
@interface LCCKUser ()

@end


@implementation LCCKUser

@synthesize avatarURL=_avatarURL;

@synthesize clientId=_clientId;

@synthesize name=_name;

@synthesize userId=_userId;

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[LCCKUser alloc]initWithUserId:self.userId
                                      name:self.name
                                 avatarURL:self.avatarURL
                                  clientId:self.clientId];
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    [aCoder encodeObject:self.userId forKey:@"userId"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.avatarURL forKey:@"avatarURL"];
    [aCoder encodeObject:self.clientId forKey:@"clientId"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    if(self=[super init]){
        _userId=[aDecoder decodeObjectForKey:@"userId"];
        _name=[aDecoder decodeObjectForKey:@"name"];
        _avatarURL=[aDecoder decodeObjectForKey:@"avatarURL"];
        _clientId=[aDecoder decodeObjectForKey:@"clientId"];
    }
    return self;
}

- (instancetype)initWithUserId:(NSString *)userId name:(NSString *)name avatarURL:(NSURL *)avatarURL clientId:(NSString *)clientId {
    self=[super init];
    if(!self){
        return nil;
    }
    _userId=userId;
    _name=name;
    _avatarURL=avatarURL;
    _clientId=clientId;
    return self;
}

+ (instancetype)userWithUserId:(NSString *)userId name:(NSString *)name avatarURL:(NSURL *)avatarURL clientId:(NSString *)clientId {
    LCCKUser *user=[[LCCKUser alloc]initWithUserId:userId name:name avatarURL:avatarURL clientId:clientId];
    return user;
}

+ (instancetype)userWithUserId:(NSString *)userId name:(NSString *)name avatarURL:(NSURL *)avatarURL{
    return [self userWithUserId:userId name:name avatarURL:avatarURL clientId:userId];
}

- (instancetype)initWithUserId:(NSString *)userId name:(NSString *)name avatarURL:(NSURL *)avatarURL{
    return [self initWithUserId:userId name:name avatarURL:avatarURL clientId:userId];
}

+ (instancetype)userWithClientId:(NSString *)clientId{
    return [self userWithUserId:nil name:nil avatarURL:nil clientId:clientId];
}

- (instancetype)initWithClientId:(NSString *)ClientId{
    return [self initWithUserId:nil name:nil avatarURL:nil clientId:ClientId];
}


@end
