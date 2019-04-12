//
//  UserModel.m
//  Cobweb
//
//  Created by solist on 2019/2/26.
//  Copyright © 2019 solist. All rights reserved.
//

#import "UserModel.h"

@implementation UserModel

static UserModel* sharedUserModel;

+(UserModel *)sharedInstance{
    if(!sharedUserModel){
        sharedUserModel=[[UserModel alloc]init];
    }
    return sharedUserModel;
}

//-(instancetype)initInAnonymous{
//    self=[super init];
//    if(self){
//        self.isAnonymous=YES;
//    }
//    return self;
//}

//-(void)setUserID:(NSString *)userID
//{
//    sharedUserModel.userID=userID;
//    NSLog(@"sb");
//}
//
//-(void)setPassword:(NSString *)password
//{
//    sharedUserModel.password=password;
//}
//
//-(void)setUserName:(NSString *)userName
//{
//    sharedUserModel.userName=userName;
//}
//
//- (void)setUniversity:(NSString *)university
//{
//    sharedUserModel.university=university;
//}
//
//-(void)setMajor:(NSString *)major{
//    sharedUserModel.major=major;
//}
//
//-(void)setEmail:(NSString *)email{
//    sharedUserModel.email=email;
//}
//
//-(void)setCreationTime:(NSString *)creationTime{
//    sharedUserModel.creationTime=creationTime;
//}
//
//-(void)setProfileImage:(NSString *)profileImage
//{
//    sharedUserModel.profileImage=profileImage;
//}
//
//-(void)setSex:(NSString *)sex{
//    sharedUserModel.sex=sex;
//}
//
//-(void)setHobbies:(NSMutableArray *)hobbies
//{
//    sharedUserModel.hobbies=hobbies;
//}
//
//-(void)setPhone:(NSString *)phone{
//    sharedUserModel.phone=phone;
//}
//
//-(void)setIsAnonymous:(BOOL)isAnonymous{
//    sharedUserModel.isAnonymous=isAnonymous;
//}
//
//-(void)setIsTeacher:(BOOL)isTeacher{
//    sharedUserModel.isTeacher=isTeacher;
//}

-(instancetype)initWithUserID:(NSString *)userID password:(NSString *)password userName:(NSString *)userName university:(NSString *)university  major:(NSString *)major email:(NSString *)email creationTime:(NSString *)creationTime profileImage:(NSString *)profileImage sex:(NSString *)sex hobbies:(NSMutableArray *)hobbies phone:(NSString *)phone{
    self=[super init];
    if(self){
        self.isAnonymous=NO;
        self.userID=userID;
        self.password=password;
        self.userName=userName;
        self.university=university;
        self.major=major;
        self.email=email;
        self.creationTime=creationTime;
        self.profileImage=profileImage;
        self.sex=sex;
        self.hobbies=hobbies;
        self.phone=phone;
        
        
    }
    return self;
}

@end
