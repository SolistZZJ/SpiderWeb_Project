//
//  ApplyListCell.m
//  Cobweb
//
//  Created by solist on 2019/3/22.
//  Copyright © 2019 solist. All rights reserved.
//

#import "ApplyListCell.h"
#import "setting.h"
#import "AFNetworking.h"
#import "MBProgressHUD.h"
#import <AVUser.h>
#import <LCChatKit.h>

@interface ApplyListCell ()

@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *universityLabel;
@property (weak, nonatomic) IBOutlet UILabel *majorLabel;
@property (weak, nonatomic) IBOutlet UILabel *telLabel;
@property (weak, nonatomic) IBOutlet UILabel *sexLabel;
@property (weak, nonatomic) IBOutlet UIButton *inviteBtn;
@property (weak, nonatomic) IBOutlet UIButton *rejectBtn;

@property (strong, nonatomic) NSString *applicantID;
@property (strong, nonatomic) AVIMConversation *conv;

@property (strong, nonatomic) MBProgressHUD *hud;

@property (weak, nonatomic) IBOutlet UIButton *phoneBtn;

@end

@implementation ApplyListCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

-(void)setApplicantInfo:(UserModel *)applicantInfo{
    _applicantInfo=applicantInfo;
    
    self.userNameLabel.text=applicantInfo.userName;
    self.universityLabel.text=[NSString stringWithFormat:@"大学:%@",applicantInfo.university];
    self.majorLabel.text=[NSString stringWithFormat:@"专业:%@",applicantInfo.major];
    self.telLabel.text=[NSString stringWithFormat:@"电话:%@",applicantInfo.phone];
    if([applicantInfo.sex isEqualToString:@"男"]){
        self.sexLabel.textColor=[UIColor blueColor];
        self.sexLabel.alpha=0.8;
    }
    else{
        self.sexLabel.textColor=[UIColor redColor];
        self.sexLabel.alpha=0.8;
    }
    self.sexLabel.text=[NSString stringWithFormat:@"性别:%@",applicantInfo.sex];
    
    //加载头像
    NSString *path=[[ipAddress stringByAppendingString:@"static/profiles/"] stringByAppendingString:self.applicantInfo.profileImage];
    NSURL *urlStr=[NSURL URLWithString:[path stringByAppendingString:@".png/"]];
    NSData *imageData=[NSData dataWithContentsOfURL:urlStr];
    UIImage *image=[UIImage imageWithData:imageData];
    self.avatar.image=image;
    self.avatar.layer.cornerRadius=30;
    self.avatar.layer.masksToBounds=YES;
    
    //自己的框不显示手机按钮
    if([UserModel sharedInstance].userID==applicantInfo.userID){
        self.phoneBtn.hidden=YES;
    }
  
    
    if(self.hideBtn){
        //当前一个界面要求显示当前队伍信息时，而非申请列表
        self.inviteBtn.hidden=YES;
        self.rejectBtn.hidden=YES;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)agreeBtnClicked {
    
    // 初始化对话框
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:[NSString stringWithFormat:@"确定要允许[%@]进入团队吗？",self.applicantInfo.userName] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction=[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self agreeMethod];
    }];
    UIAlertAction *cancelAction=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self cancelMethod];
    }];
    [alert addAction:okAction];
    [alert addAction:cancelAction];
    
    // 弹出对话框
    [[self viewController] presentViewController:alert animated:YES completion:nil];
    

    
}

#pragma mark 获得当前view的控制器
- (UIViewController*)viewController {
    for (UIView* next = [self superview]; next; next = next.superview) {
        UIResponder* nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController
                                          class]]) {
            return (UIViewController*)nextResponder;
        }
    }
    return nil;
}


-(void)agreeMethod{
    self.hud=[MBProgressHUD showHUDAddedTo:self.superview animated:YES];
    self.hud.mode=MBProgressHUDModeIndeterminate;
    
    UserModel *me=[UserModel sharedInstance];
    //创建一个全局队列
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    //创建一个信号量（值为0）
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(queue, ^{

//        [AVUser logInWithUsernameInBackground:me.userID password:me.password block:^(AVUser * _Nullable user, NSError * _Nullable error) {
//            if(user!=nil){
//
                [[LCChatKit sharedInstance] openWithClientId:me.objectId callback:^(BOOL succeeded, NSError *error) {
                    if(succeeded){
                        
                        AVQuery *userQuery = [AVQuery queryWithClassName:@"_User"];
                        
                        [userQuery whereKey:@"username" equalTo:self.applicantInfo.userID];
                        //信号量加1
                        dispatch_semaphore_signal(semaphore);
                        AVObject *obj=[userQuery getFirstObject];
                        NSMutableDictionary *theDict=obj.dictionaryForObject;
                        self.applicantID=theDict[@"objectId"];
                        NSLog(@"applicantID:%@",self.applicantID);
                        AVIMClient *client=[LCChatKit sharedInstance].client;
                        
                        AVIMConversationQuery *query = [client conversationQuery];
                        
                        [query getConversationById:self.conversationID callback:^(AVIMConversation * _Nullable conversation, NSError * _Nullable error) {
                            self.conv=conversation;
                            NSLog(@"conversationID:%@",self.conv.conversationId);
                            //信号量加1
                            dispatch_semaphore_signal(semaphore);
                            
                            //信号量减1，如果>0，则向下执行，否则等待
                            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                            [self.conv addMembersWithClientIds:@[self.applicantID] callback:^(BOOL succeeded, NSError * _Nullable error) {
                                if(succeeded){
                                    //与leanCloud服务器交互成功，并成功将队友拉入队伍
                                    //开始与自己的服务器进行数据交互
                                    
                                    AFHTTPSessionManager *manager=[AFHTTPSessionManager manager];
                                    //设置等待时间为20s
                                    manager.requestSerializer.timeoutInterval=20.f;
                                    NSDictionary *dict=@{@"isPermitted":@1,
                                                         @"userID":self.applicantInfo.userID,
                                                         @"teamID":self.teamID
                                                         };
                                    [manager POST:[ipAddress stringByAppendingString:@"team_agree_or_not/"] parameters:dict headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                        [MBProgressHUD hideHUDForView:self.superview animated:YES];
                                        if([responseObject[@"status"] integerValue]==0){
                                            //动作失败提示Hub
                                            self.hud=[MBProgressHUD showHUDAddedTo:self.superview animated:YES];
                                            self.hud.mode=MBProgressHUDModeText;
                                            self.hud.labelText=responseObject[@"error_message"];
                                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                [MBProgressHUD hideHUDForView:self.superview animated:YES];
                                            });
                                            
                                            //操作失败，重新将该人踢出队伍
                                            [self.conv removeMembersWithClientIds:@[self.applicantID] callback:^(BOOL succeeded, NSError * _Nullable error) {
                                                
                                            }];
                                        }
                                        else{
                                            //动作成功提示Hub
                                            self.hud=[MBProgressHUD showHUDAddedTo:self.superview animated:YES];
                                            self.hud.mode=MBProgressHUDModeText;
                                            self.hud.labelText=responseObject[@"success_message"];
                                            
                                            //发送消息通知更新tableview的cell数据
                                            [[NSNotificationCenter defaultCenter]postNotificationName:@"updateApplyData" object:@{@"userID":self.applicantInfo.userID}];
                                            
                                            //发送给放个界面通知更改数据（删除该人的申请）
                                            [[NSNotificationCenter defaultCenter]postNotificationName:@"updateTeamDetailVCData" object:@{
                                                                                                                                         @"userID":self.applicantInfo.userID,
                                                                                            @"status":@"addMem",
                                                                                                                                         @"newMem":self.applicantInfo
                                                                                                                                         }
                                             ];
                                            
                                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                [MBProgressHUD hideHUDForView:self.superview animated:YES];
                                            });
                                        }
                                    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                        [MBProgressHUD hideHUDForView:self.superview animated:YES];
                                        self.hud=[MBProgressHUD showHUDAddedTo:self.superview animated:YES];
                                        self.hud.mode=MBProgressHUDModeText;
                                        self.hud.labelText=@"服务器连接失败，请稍后再试";
                                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                            [MBProgressHUD hideHUDForView:self.superview animated:YES];
                                        });
                                        
                                        //操作失败，重新将该人踢出队伍
                                        [self.conv removeMembersWithClientIds:@[self.applicantID] callback:^(BOOL succeeded, NSError * _Nullable error) {
                                            
                                        }];
                                    }];
                                }
                                else{
                                    [MBProgressHUD hideHUDForView:self.superview animated:YES];
                                    self.hud=[MBProgressHUD showHUDAddedTo:self.superview animated:YES];
                                    self.hud.mode=MBProgressHUDModeText;
                                    self.hud.labelText=@"添加队员失败，请稍后再试";
                                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                        [MBProgressHUD hideHUDForView:self.superview animated:YES];
                                    });
                                }
                            }];
                        }];
                    }
                    else{
                        [MBProgressHUD hideHUDForView:self.superview animated:YES];
                        self.hud=[MBProgressHUD showHUDAddedTo:self.superview animated:YES];
                        self.hud.mode=MBProgressHUDModeText;
                        self.hud.labelText=@"用户状态异常，请重新登录后再试";
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [MBProgressHUD hideHUDForView:self.superview animated:YES];
                        });
                    }
                }];
            //}
        //}];
    });
}

-(void)cancelMethod{
    
}

- (IBAction)rejectBtnClicked {
    // 初始化对话框
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:[NSString stringWithFormat:@"确定要拒绝[%@]进入团队吗？",self.applicantInfo.userName] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *noAction=[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self disagreeMethod];
    }];
    UIAlertAction *cancelAction=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self cancelMethod];
    }];
    [alert addAction:noAction];
    [alert addAction:cancelAction];
    
    // 弹出对话框
    [[self viewController] presentViewController:alert animated:YES completion:nil];
}

-(void)disagreeMethod{
    self.hud=[MBProgressHUD showHUDAddedTo:self.superview animated:YES];
    self.hud.mode=MBProgressHUDModeIndeterminate;
    
    AFHTTPSessionManager *manager=[AFHTTPSessionManager manager];
    //设置等待时间为20s
    manager.requestSerializer.timeoutInterval=20.f;
    NSDictionary *dict=@{@"isPermitted":@0,
                         @"userID":self.applicantInfo.userID,
                         @"teamID":self.teamID
                         };
    [manager POST:[ipAddress stringByAppendingString:@"team_agree_or_not/"] parameters:dict headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [MBProgressHUD hideHUDForView:self.superview animated:YES];
        if([responseObject[@"status"] integerValue]==0){
            //动作失败提示Hub
            self.hud=[MBProgressHUD showHUDAddedTo:self.superview animated:YES];
            self.hud.mode=MBProgressHUDModeText;
            self.hud.labelText=responseObject[@"error_message"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.superview animated:YES];
            });
        }
        else{
            //动作成功提示Hub
            self.hud=[MBProgressHUD showHUDAddedTo:self.superview animated:YES];
            self.hud.mode=MBProgressHUDModeText;
            self.hud.labelText=responseObject[@"success_message"];
            
            //发送消息通知更新tableview的cell数据
            [[NSNotificationCenter defaultCenter]postNotificationName:@"updateApplyData" object:@{@"userID":self.applicantInfo.userID}];
            
            //发送给放个界面通知更改数据（删除该人的申请）
            [[NSNotificationCenter defaultCenter]postNotificationName:@"updateTeamDetailVCData" object:@{@"userID":self.applicantInfo.userID}];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.superview animated:YES];
            });
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [MBProgressHUD hideHUDForView:self.superview animated:YES];
        NSLog(@"发送数据失败！%@",error);
        
        self.hud=[MBProgressHUD showHUDAddedTo:self.superview animated:YES];
        self.hud.mode=MBProgressHUDModeText;
        self.hud.labelText=@"请检查联网情况!";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.superview animated:YES];
        });
    }];
}

- (IBAction)callCandidate {
    NSString *telephoneNumber=self.applicantInfo.phone;
    NSMutableString * str=[[NSMutableString alloc] initWithFormat:@"tel:%@",telephoneNumber];
    UIApplication *application = [UIApplication sharedApplication];
    NSURL *URL = [NSURL URLWithString:str];
    [application openURL:URL options:@{} completionHandler:^(BOOL success) {
        //OpenSuccess=选择 呼叫 为 1  选择 取消 为0
        NSLog(@"OpenSuccess=%d",success);
        
    }];
}


@end
