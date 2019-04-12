//
//  ReplyView.h
//  Cobweb
//
//  Created by solist on 2019/3/10.
//  Copyright © 2019 solist. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReplyView : UIView
@property (weak, nonatomic) IBOutlet UITextView *replyContent;
@property (weak, nonatomic) IBOutlet UILabel *fatherName;

@property (strong, nonatomic) NSString *root;
@property (strong, nonatomic) NSString *user;
@property (strong, nonatomic) NSString *parent;
@property (strong, nonatomic) NSString *competition;

@end

NS_ASSUME_NONNULL_END
