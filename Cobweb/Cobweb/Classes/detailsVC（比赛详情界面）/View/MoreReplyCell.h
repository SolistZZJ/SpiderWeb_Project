//
//  MoreReplyCell.h
//  Cobweb
//
//  Created by solist on 2019/3/11.
//  Copyright © 2019 solist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommentCellModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface MoreReplyCell : UITableViewCell
@property (strong, nonatomic) CommentCellModel *commentModel;
@property (weak, nonatomic) IBOutlet UILabel *userContent;

@property (assign,nonatomic) BOOL isMainComment;

@end

NS_ASSUME_NONNULL_END
