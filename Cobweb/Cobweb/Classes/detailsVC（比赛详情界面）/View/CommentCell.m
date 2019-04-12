//
//  CommentCell.m
//  Cobweb
//
//  Created by solist on 2019/3/8.
//  Copyright © 2019 solist. All rights reserved.
//

#import "setting.h"
#import "CommentCell.h"
#import "MoreReplyView.h"
#import "MJExtension.h"
#import "MBProgressHUD.h"

@interface CommentCell()

@property (weak, nonatomic) IBOutlet UIImageView *rootUserImage;
@property (weak, nonatomic) IBOutlet UIImageView *childUserImage;

@property (weak, nonatomic) IBOutlet UILabel *rootUserName;
@property (weak, nonatomic) IBOutlet UILabel *rootTime;
@property (weak, nonatomic) IBOutlet UIView *seperateLine;


@property (weak, nonatomic) IBOutlet UILabel *childName;
@property (weak, nonatomic) IBOutlet UILabel *rootUserName2;
@property (weak, nonatomic) IBOutlet UILabel *childTime;
@property (weak, nonatomic) IBOutlet UIButton *lookupReplyBtn;
@property (weak, nonatomic) IBOutlet UILabel *arrow;

@property(strong, nonatomic) NSArray *childArray;


@property (strong, nonatomic) MoreReplyView *moreReplyView;

@property (strong, nonatomic) MBProgressHUD *hud;

@end

@implementation CommentCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setCommentModel:(CommentCellModel *)commentModel{
    _commentModel=commentModel;
    
    self.rootUserImage.image=[UIImage imageWithData:commentModel.profile];
    self.childUserImage.image=[UIImage imageWithData:commentModel.childProfile];
    self.rootUserName.text=commentModel.userName;
    self.rootCommentTextField.text=commentModel.content;
    self.rootTime.text=commentModel.creationTime;
//    self.rootUserImage.image=[UIImage imageWithData:commentModel.profile];
    
    
    self.rootUserImage.layer.cornerRadius=22.5;
    self.rootUserImage.layer.masksToBounds=YES;
    self.childUserImage.layer.cornerRadius=12.5;
    self.childUserImage.layer.masksToBounds=YES;
    
    //计算rootCommentTextField的frame
    CGFloat offset=10.0;
    CGFloat contentX=CGRectGetMaxX(self.rootUserImage.frame)+offset;
    CGFloat contentY=CGRectGetMaxY(self.rootUserName.frame)+offset;
    NSDictionary *textAttribute=@{NSFontAttributeName:[UIFont systemFontOfSize:14]};
    CGSize textSize=CGSizeMake([UIScreen mainScreen].bounds.size.width-contentX-offset, MAXFLOAT);
    CGFloat contentH=[self.rootCommentTextField.text boundingRectWithSize:textSize options:NSStringDrawingUsesLineFragmentOrigin attributes:textAttribute context:nil].size.height;
    CGFloat contentW=[UIScreen mainScreen].bounds.size.width-contentX-offset;
    self.rootCommentTextField.frame=CGRectMake(contentX, contentY, contentW, contentH);

    //计算rootTime的frame
    offset=5.0;
    CGFloat rootTimeX=contentX;
    CGFloat rootTimeY=CGRectGetMaxY(self.rootCommentTextField.frame)+offset;
    CGFloat rootTimeH=15;
    CGFloat rootTimeW=127;
    self.rootTime.frame=CGRectMake(rootTimeX, rootTimeY, rootTimeW, rootTimeH);
    
    if(commentModel.children.count==0){
        self.seperateLine.hidden=YES;
        self.childUserImage.hidden=YES;
        self.childName.hidden=YES;
        self.rootUserName2.hidden=YES;
        self.childCommentTextField.hidden=YES;
        self.childTime.hidden=YES;
        self.lookupReplyBtn.hidden=YES;
        self.arrow.hidden=YES;
        
        self.commentModel.cellHeight=CGRectGetMaxY(self.rootTime.frame)+offset;
    }
    else{
        //计算seperateLine的frame
        CGFloat seperateLineX=contentX;
        CGFloat seperateLineY=CGRectGetMaxY(self.rootTime.frame)+offset;
        CGFloat seperateLineH=1;
        CGFloat seperateLineW=contentW;
        self.seperateLine.frame=CGRectMake(seperateLineX, seperateLineY, seperateLineW, seperateLineH);

        //计算childImage的frame
        CGFloat childImageX=contentX;
        CGFloat childImageY=seperateLineY+offset;
        CGFloat childImageH=25.0;
        CGFloat childImageW=25.0;
        self.childUserImage.frame=CGRectMake(childImageX, childImageY, childImageW, childImageH);

        //计算childName的内容和frame
        self.childName.text=(commentModel.children[0])[@"userName"];
        UIFont *fnt = [UIFont boldSystemFontOfSize:14];
        self.childName.font = fnt;
        CGSize size = [self.childName.text sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:fnt,NSFontAttributeName,nil]];
        CGFloat childNameH=size.height;
        CGFloat childNameW=size.width;
        CGFloat childNameX=CGRectGetMaxX(self.childUserImage.frame)+offset;
        CGFloat childNameY=CGRectGetMidY(self.childUserImage.frame)-childNameH/2.0;
        self.childName.frame=CGRectMake(childNameX, childNameY, childNameW, childNameH);
        
        //计算arrow的frame
        CGFloat arrowX=CGRectGetMaxX(self.childName.frame)+offset;
        CGFloat arrowY=CGRectGetMinY(self.childUserImage.frame);
        self.arrow.frame=CGRectMake(arrowX, arrowY, 15, 25);
        
        //计算rootUserName2的frame
        fnt = [UIFont boldSystemFontOfSize:14];
        self.rootUserName2.font = fnt;
        self.rootUserName2.text=(commentModel.children[0])[@"receiveName"];
        CGFloat rootUserName2X=CGRectGetMaxX(self.arrow.frame)+offset;
        CGFloat rootUserName2Y=self.childName.frame.origin.y;
        size = [self.rootUserName2.text sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:fnt,NSFontAttributeName,nil]];
        CGFloat rootUserName2H=size.height;
        CGFloat rootUserName2W=size.width;
        self.rootUserName2.frame=CGRectMake(rootUserName2X, rootUserName2Y, rootUserName2W, rootUserName2H);
        
        //计算childCommentTextField的内容和frame
        self.childCommentTextField.text=(commentModel.children[0])[@"content"];

        
        CGFloat childCommentTextFieldX=self.rootCommentTextField.frame.origin.x;
        CGFloat childCommentTextFieldY=CGRectGetMaxY(self.childUserImage.frame)+offset;
        CGFloat childCommentTextFieldW=contentW;
        NSDictionary *textAttribute=@{NSFontAttributeName:[UIFont systemFontOfSize:14]};
        CGSize textSize=CGSizeMake([UIScreen mainScreen].bounds.size.width-contentX-offset, MAXFLOAT);
        CGFloat childCommentTextFieldH=[self.childCommentTextField.text boundingRectWithSize:textSize options:NSStringDrawingUsesLineFragmentOrigin attributes:textAttribute context:nil].size.height;
        self.childCommentTextField.frame=CGRectMake(childCommentTextFieldX, childCommentTextFieldY, childCommentTextFieldW, childCommentTextFieldH);
        
        //计算childTime的内容和frame
        self.childTime.text=(commentModel.children[0])[@"creationTime"];
        CGFloat childTimeX=childCommentTextFieldX;
        CGFloat childTimeY=CGRectGetMaxY(self.childCommentTextField.frame)+offset;
        CGFloat childTimeH=15;
        CGFloat childTimeW=127;
        self.childTime.frame=CGRectMake(childTimeX, childTimeY, childTimeW, childTimeH);
        
        if(commentModel.children.count>=2){
            //计算lookupReplyBtn的frame
            [self.lookupReplyBtn setTitle:[NSString stringWithFormat:@"查看全部%lu条回复",(unsigned long)commentModel.children.count] forState:UIControlStateNormal];
            
            CGFloat lookupReplyBtnX=childTimeX;
            CGFloat lookupReplyBtnY=CGRectGetMaxY(self.childTime.frame);
            self.lookupReplyBtn.frame=CGRectMake(lookupReplyBtnX, lookupReplyBtnY, 116, 30);
            self.commentModel.cellHeight=CGRectGetMaxY(self.lookupReplyBtn.frame)+offset;
        }
        else{
            self.lookupReplyBtn.hidden=YES;
            self.commentModel.cellHeight=CGRectGetMaxY(self.childTime.frame)+offset;
        }
        
    }
}

- (IBAction)lookUpAllReplyBtnClicked {
    //向服务器发送消息
    self.hud=[MBProgressHUD showHUDAddedTo:self.superview animated:YES];
    self.hud.mode=MBProgressHUDModeIndeterminate;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.moreReplyView=[[NSBundle mainBundle] loadNibNamed:@"MoreReplyView" owner:nil options:nil].lastObject;
        self.moreReplyView.childrenNum=self.commentModel.children.count;
        
        NSMutableArray *tmpArr=[NSMutableArray array];
        for(int i=0;i<self.commentModel.children.count;++i){
            CommentCellModel *model=[CommentCellModel mj_objectWithKeyValues:self.commentModel.children[i]];
            
            //更新子评论头像
//            NSURL *url=[NSURL URLWithString:[[@"http://119.23.190.159:8000/static/compress_images/" stringByAppendingString:model.user] stringByAppendingString:@"Image.png"]];
            
            NSURL *url=[NSURL URLWithString:[[[ipAddress stringByAppendingString:@"static/compress_images/"] stringByAppendingString:model.user]stringByAppendingString:@"Image.png"]];
            NSData *imageData=[NSData dataWithContentsOfURL:url];
            model.profile=imageData;
            [tmpArr addObject:model];
        }
        [MBProgressHUD hideHUDForView:self.superview animated:YES];
        self.childArray=tmpArr;
        self.moreReplyView.childInfoArray=self.childArray;
        self.moreReplyView.mainComment=self.commentModel;

        self.moreReplyView.frame=CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        UIWindow * window = [UIApplication sharedApplication].keyWindow;
        [window addSubview:self.moreReplyView];
        [UIView animateWithDuration:0.5 animations:^{
            self.moreReplyView.frame=CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        } completion:nil];
    });
}


@end
