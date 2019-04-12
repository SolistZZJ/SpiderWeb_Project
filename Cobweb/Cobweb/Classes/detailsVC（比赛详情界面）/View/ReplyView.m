//
//  ReplyView.m
//  Cobweb
//
//  Created by solist on 2019/3/10.
//  Copyright © 2019 solist. All rights reserved.
//
#import "setting.h"
#import "ReplyView.h"
#import "MBProgressHUD.h"
#import "AFNetworking.h"

@interface ReplyView ()

@property (strong, nonatomic) MBProgressHUD *hud;

@end

@implementation ReplyView
- (IBAction)cancelBtnClick:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideCommentView" object:nil];
}

- (IBAction)sendReplyBtnClick:(id)sender {
    if(self.replyContent.text.length==0){
        self.hud=[MBProgressHUD showHUDAddedTo:self animated:YES];
        self.hud.mode=MBProgressHUDModeText;
//        self.hud.label.text=@"回复内容不可为空!";
        self.hud.labelText=@"回复内容不可为空!";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self animated:YES];
        });
    }
    else{
        AFHTTPSessionManager *manager=[AFHTTPSessionManager manager];
        //向服务器发送消息
        self.hud=[MBProgressHUD showHUDAddedTo:self animated:YES];
        self.hud.mode=MBProgressHUDModeIndeterminate;
        //self.hud.label.text=@"正在发表评论，请稍后";
        self.hud.labelText=@"正在发表评论，请稍后";
        manager.requestSerializer.timeoutInterval=15.f;
        NSLog(@"%@",self.replyContent.text);
        NSLog(@"%@",self.user);
        NSLog(@"%@",self.parent);
        NSLog(@"%@",self.competition);
        NSLog(@"%@",self.root);
        
        
        NSDictionary *dict=@{
                             @"content":self.replyContent.text,
                             @"user":self.user,
                             @"parent":self.parent,
                             @"competition":self.competition,
                             @"root":self.root
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
//                self.hud.label.text=responseObject[@"error_message"];
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
//                self.hud.labeltext = NSLocalizedString(@"回复成功", @"HUD done title");
                self.hud.labelText=NSLocalizedString(@"回复成功", @"HUD done title");
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self animated:YES];
                    
                    //隐藏commentView
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideCommentView" object:nil];
                    
                    //发送消息更新评论
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"sendComment" object:nil];
                    
                    //发送消息更新子评论
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"closeReplyView" object:nil];
                });
            }
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [MBProgressHUD hideHUDForView:self animated:YES];
            NSLog(@"发送数据失败！%@",error);
            
            self.hud=[MBProgressHUD showHUDAddedTo:self animated:YES];
            self.hud.mode=MBProgressHUDModeText;
//            self.hud.label.text=@"请检查联网情况!";
            self.hud.labelText=@"请检查联网情况!";
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self animated:YES];
            });
        }];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
