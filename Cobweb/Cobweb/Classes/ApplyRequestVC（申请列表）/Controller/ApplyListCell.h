//
//  ApplyListCell.h
//  Cobweb
//
//  Created by solist on 2019/3/22.
//  Copyright © 2019 solist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface ApplyListCell : UITableViewCell
@property(nonatomic, strong) UserModel *applicantInfo;
@property(nonatomic, strong) NSString *teamID;
@property(strong, nonatomic) NSString *conversationID;

@property(assign, nonatomic) BOOL hideBtn;
@end

NS_ASSUME_NONNULL_END
