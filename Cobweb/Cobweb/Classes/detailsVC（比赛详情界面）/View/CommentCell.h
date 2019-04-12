//
//  CommentCell.h
//  Cobweb
//
//  Created by solist on 2019/3/8.
//  Copyright © 2019 solist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommentCellModel.h"

NS_ASSUME_NONNULL_BEGIN
@class MoreReplyView;
@interface CommentCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *test;


@property (strong, nonatomic) CommentCellModel *commentModel;
@property (weak, nonatomic) IBOutlet UILabel *rootCommentTextField;
@property (weak, nonatomic) IBOutlet UILabel *childCommentTextField;



@end

NS_ASSUME_NONNULL_END
