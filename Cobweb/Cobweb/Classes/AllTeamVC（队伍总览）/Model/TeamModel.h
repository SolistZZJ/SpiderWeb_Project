//
//  TeamModel.h
//  Cobweb
//
//  Created by solist on 2019/3/14.
//  Copyright © 2019 solist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface TeamModel : NSObject

@property(nonatomic,strong) NSString* teamID;
@property(nonatomic,strong) NSString* userID;
@property(nonatomic,strong) NSString* competition;
@property(nonatomic,strong) NSString* introduction;
@property(nonatomic,strong) NSString* teamName;
@property(nonatomic,assign) NSInteger maxNum;
@property(nonatomic,assign) NSInteger nowNum;
@property(nonatomic,assign) NSInteger isTeaming;
@property(nonatomic,strong) UserModel *captain;
@property(nonatomic,strong) NSArray *member_list;
@property(nonatomic,strong) NSArray *join_list;

@property(nonatomic,assign) double cellHeight;
@property(nonatomic,assign) BOOL isAllTeam;

@property(nonatomic,strong) NSString *conversationID;
@end

NS_ASSUME_NONNULL_END
