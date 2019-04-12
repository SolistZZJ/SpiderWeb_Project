//
//  TeamMemberInfoVC.h
//  Cobweb
//
//  Created by solist on 2019/3/24.
//  Copyright © 2019 solist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "userModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface TeamMemberInfoVC : UITableViewController

@property(nonatomic ,strong) UserModel *captain;
@property(nonatomic ,strong) NSMutableArray *memberList;
@property(nonatomic ,strong) NSString *conversationID;
@property(nonatomic ,strong) NSString *teamID;
@end

NS_ASSUME_NONNULL_END
