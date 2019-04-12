//
//  ApplyRequestVC.h
//  Cobweb
//
//  Created by solist on 2019/3/22.
//  Copyright © 2019 solist. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ApplyRequestVC : UITableViewController
@property(strong, nonatomic) NSArray *applyList;
@property(strong, nonatomic) NSString *teamID;
@property(strong, nonatomic) NSString *conversationID;
@end

NS_ASSUME_NONNULL_END
