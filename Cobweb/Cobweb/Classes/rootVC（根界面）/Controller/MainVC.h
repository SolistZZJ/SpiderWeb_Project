//
//  MainVC.h
//  Cobweb
//
//  Created by solist on 2019/2/26.
//  Copyright © 2019 solist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UserModel;
NS_ASSUME_NONNULL_BEGIN

@interface MainVC : UITabBarController

@property(strong,nonatomic) UserModel *user;

@end

NS_ASSUME_NONNULL_END
