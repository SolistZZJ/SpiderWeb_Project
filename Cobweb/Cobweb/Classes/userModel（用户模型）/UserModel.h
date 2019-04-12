//
//  UserModel.h
//  Cobweb
//
//  Created by solist on 2019/2/26.
//  Copyright © 2019 solist. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UserModel : NSObject

//@property(strong, nonatomic) AVIMClient *chatID;

@property(assign,nonatomic) BOOL isAnonymous;
@property(copy,nonatomic) NSString* userID;
@property(copy,nonatomic) NSString* password;
@property(copy,nonatomic) NSString* userName;
@property(copy,nonatomic) NSString* university;
@property(copy,nonatomic) NSString* major;
@property(copy,nonatomic) NSString* email;
@property(copy,nonatomic) NSString* creationTime;
@property(copy,nonatomic) NSString* profileImage;
@property(copy,nonatomic) NSString* sex;
@property(copy,nonatomic) NSMutableArray* hobbies;
@property(copy,nonatomic) NSString* phone;

@property(copy,nonatomic) NSString *objectId;

+(UserModel*) sharedInstance;

//-(instancetype)initInAnonymous;

-(instancetype)initWithUserID:(NSString *)userID password:(NSString *)password userName:(NSString *)userName university:(NSString *)university  major:(NSString *)major email:(NSString *)email creationTime:(NSString *)creationTime profileImage:(NSString *)profileImage sex:(NSString *)sex hobbies:(NSArray *)hobbies phone:(NSString *)phone;

@end

NS_ASSUME_NONNULL_END
