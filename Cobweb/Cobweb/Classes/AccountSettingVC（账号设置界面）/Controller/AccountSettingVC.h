//
//  AccountSettingVC.h
//  Cobweb
//
//  Created by solist on 2019/3/5.
//  Copyright © 2019 solist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UserModel;
NS_ASSUME_NONNULL_BEGIN

@interface AccountSettingVC : UITableViewController
@property(strong,nonatomic) UserModel *user;


@end

NS_ASSUME_NONNULL_END
