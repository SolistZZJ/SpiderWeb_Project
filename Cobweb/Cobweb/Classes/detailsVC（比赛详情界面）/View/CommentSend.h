//
//  CommentSend.h
//  Cobweb
//
//  Created by solist on 2019/3/7.
//  Copyright © 2019 solist. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CommentSend : UIView
@property (weak, nonatomic) IBOutlet UIButton *cencelBtn;
@property (weak, nonatomic) IBOutlet UIButton *sendCommentBtn;
@property (weak, nonatomic) IBOutlet UITextView *contentTextView;

@property (strong, nonatomic) NSString *competitionID;
@end

NS_ASSUME_NONNULL_END
