//
//  MoreReplyView.h
//  Cobweb
//
//  Created by solist on 2019/3/11.
//  Copyright © 2019 solist. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class CommentCellModel;
@interface MoreReplyView : UIView

@property (assign,nonatomic) NSInteger childrenNum;
@property (strong,nonatomic) NSArray *childInfoArray;
@property (strong,nonatomic) CommentCellModel *mainComment;

@end

NS_ASSUME_NONNULL_END
