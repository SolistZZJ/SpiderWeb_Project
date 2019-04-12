//
//  MoreReplyCell.m
//  Cobweb
//
//  Created by solist on 2019/3/11.
//  Copyright © 2019 solist. All rights reserved.
//

#import "MoreReplyCell.h"

@interface MoreReplyCell ()
@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property (weak, nonatomic) IBOutlet UILabel *userName;
@property (weak, nonatomic) IBOutlet UILabel *receiveName;
@property (weak, nonatomic) IBOutlet UILabel *arrow;
@property (weak, nonatomic) IBOutlet UILabel *Replytime;


@end

@implementation MoreReplyCell

-(void)setCommentModel:(CommentCellModel *)commentModel{
    _commentModel=commentModel;
    
    self.profileImage.image=[UIImage imageWithData:commentModel.profile];
    self.userName.text=commentModel.userName;
//    self.receiveName.text=commentModel.receiveName;
    self.Replytime.text=commentModel.creationTime;
    self.userContent.text=commentModel.content;
   
    [self.profileImage.layer setCornerRadius:22.5];
    self.profileImage.layer.masksToBounds=YES;
    
    int offset=10;
    
    //计算userName的尺寸和frame
    UIFont *fnt = [UIFont boldSystemFontOfSize:15];
    self.userName.font = fnt;
    CGSize size = [self.userName.text sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:fnt,NSFontAttributeName,nil]];
    CGFloat userNameH=size.height;
    CGFloat userNameW=size.width;
    CGFloat userNameX=CGRectGetMaxX(self.profileImage.frame)+offset;
    CGFloat userNameY=CGRectGetMinY(self.profileImage.frame);
    self.userName.frame=CGRectMake(userNameX, userNameY, userNameW, userNameH);
    
    if(self.isMainComment){
        self.arrow.hidden=YES;
        self.receiveName.hidden=YES;
    }
    else{
        //计算arrow的frame
        offset=5;
        CGFloat arrowX=CGRectGetMaxX(self.userName.frame)+offset;
        CGFloat arrowY=CGRectGetMinY(self.userName.frame);
        self.arrow.frame=CGRectMake(arrowX, arrowY, 15, 18);
        
        //计算receiveName的尺寸和frame
        self.receiveName.text=commentModel.receiveName;
        self.receiveName.font = fnt;
        size = [self.receiveName.text sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:fnt,NSFontAttributeName,nil]];
        CGFloat receiveNameH=size.height;
        CGFloat receiveNameW=size.width;
        CGFloat receiveNameX=CGRectGetMaxX(self.arrow.frame)+offset;
        CGFloat receiveNameY=CGRectGetMinY(self.arrow.frame);
        self.receiveName.frame=CGRectMake(receiveNameX, receiveNameY, receiveNameW, receiveNameH);
    }
    
    //计算userContent的尺寸和frame
    offset=10.0;
    CGFloat userContentX=CGRectGetMinX(self.userName.frame);
    CGFloat userContentY=CGRectGetMaxY(self.userName.frame)+offset;
    NSDictionary *textAttribute=@{NSFontAttributeName:[UIFont systemFontOfSize:14]};
    CGSize textSize=CGSizeMake([UIScreen mainScreen].bounds.size.width-userContentX-offset, MAXFLOAT);
    CGFloat userContentH=[self.userContent.text boundingRectWithSize:textSize options:NSStringDrawingUsesLineFragmentOrigin attributes:textAttribute context:nil].size.height;
    CGFloat userContentW=[UIScreen mainScreen].bounds.size.width-userContentX-offset;
    self.userContent.frame=CGRectMake(userContentX, userContentY, userContentW, userContentH);
    
    //计算Replytime的尺寸和frame
    offset=5.0;
    CGFloat ReplytimeX=userContentX;
    CGFloat ReplytimeY=CGRectGetMaxY(self.userContent.frame)+offset;
    CGFloat ReplytimeH=15;
    CGFloat ReplytimeW=127;
    self.Replytime.frame=CGRectMake(ReplytimeX, ReplytimeY, ReplytimeW, ReplytimeH);
    
    //计算出cell高度
    commentModel.cellHeight=CGRectGetMaxY(self.Replytime.frame)+offset;
}

@end
