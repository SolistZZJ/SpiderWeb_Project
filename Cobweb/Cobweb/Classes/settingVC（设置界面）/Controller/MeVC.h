//
//  MeVC.h
//  Cobweb
//
//  Created by solist on 2019/2/26.
//  Copyright © 2019 solist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UserModel;
NS_ASSUME_NONNULL_BEGIN

@interface MeVC : UITableViewController

@property(strong,nonatomic) UserModel *user;
@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property (weak, nonatomic) IBOutlet UILabel *userName;

@end

NS_ASSUME_NONNULL_END
