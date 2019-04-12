//
//  CommentSend.m
//  Cobweb
//
//  Created by solist on 2019/3/7.
//  Copyright © 2019 solist. All rights reserved.
//
#import "setting.h"
#import "CommentSend.h"
#import "AFNetworking.h"
#import "UserModel.h"
#import "MBProgressHUD.h"
@interface CommentSend ()<UITextViewDelegate>

//@property (weak, nonatomic) IBOutlet UITextView *commentTextView;
@property (strong, nonatomic) MBProgressHUD *hud;
@end



@implementation CommentSend

//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChanged) name:UITextFieldTextDidChangeNotification object:self.contentTextView];

-(void)awakeFromNib{
    [super awakeFromNib];
    _competitionID=[[NSString alloc]init];
}

- (IBAction)cancelBtnClick {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideCommentView" object:nil];
}

- (IBAction)sendCommentBtnClick {
    //获取准备发送到服务器的信息
    NSString *commentContent=self.contentTextView.text;
    UserModel *user=[UserModel sharedInstance];
    //发送通知获取比赛ID
    [[NSNotificationCenter defaultCenter] postNotificationName:@"getCompetitionID" object:self];
    
    AFHTTPSessionManager *manager=[AFHTTPSessionManager manager];
    
    //向服务器发送消息
    self.hud=[MBProgressHUD showHUDAddedTo:self animated:YES];
    self.hud.mode=MBProgressHUDModeIndeterminate;
//    self.hud.label.text=@"正在发表评论，请稍后";
    self.hud.labelText=@"正在发表评论，请稍后";
    manager.requestSerializer.timeoutInterval=15.f;
    NSDictionary *dict=@{
                         @"content":commentContent,
                         @"user":user.userID,
                         @"competition":self.competitionID
                         };
    [manager POST:[ipAddress stringByAppendingString:@"get_comment/"]
       parameters:dict headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if([responseObject[@"status"] integerValue]==0){
            //操作失败
            NSLog(@"%@",responseObject[@"error_message"]);
            
            //加载失败提示Hub
            [MBProgressHUD hideHUDForView:self animated:YES];
            
            self.hud=[MBProgressHUD showHUDAddedTo:self animated:YES];
            self.hud.mode=MBProgressHUDModeText;
//            self.hud.label.text=responseObject[@"error_message"];
            self.hud.labelText=responseObject[@"error_message"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self animated:YES];
                [MBProgressHUD hideHUDForView:self animated:YES];
            });
        }
        else{
            NSLog(@"评论成功");
            //加载成功提示Hub
            [MBProgressHUD hideHUDForView:self animated:YES];
            
            self.hud=[MBProgressHUD showHUDAddedTo:self animated:YES];
            self.hud.mode=MBProgressHUDModeCustomView;
            UIImage *image = [[UIImage imageNamed:@"Checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            self.hud.customView = [[UIImageView alloc] initWithImage:image];
            self.hud.labelText = NSLocalizedString(@"发布评论成功", @"HUD done title");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self animated:YES];

                //隐藏commentView
//                [self.contentTextView resignFirstResponder];
//                self.hidden=YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"hideCommentView" object:nil];
                
                //发送消息更新评论
                [[NSNotificationCenter defaultCenter] postNotificationName:@"sendComment" object:nil];
            });
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [MBProgressHUD hideHUDForView:self animated:YES];
        NSLog(@"发送数据失败！%@",error);
        
        self.hud=[MBProgressHUD showHUDAddedTo:self animated:YES];
        self.hud.mode=MBProgressHUDModeText;
        self.hud.labelText=@"请检查联网情况!";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self animated:YES];
        });
    }];
    
}





/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
