//
//  LoginView.m
//  Cobweb
//
//  Created by solist on 2019/2/27.
//  Copyright © 2019 solist. All rights reserved.
//

#import "setting.h"
#import "LoginView.h"
#import "ErrorView.h"
#import "AFNetworking.h"
#import "MBProgressHUD.h"
#import "UserModel.h"
#import "MeVC.h"
#import "MJExtension.h"
#import <AVUser.h>
#import <LCChatKit.h>
#import "LCCKUser.h"

@interface LoginView ()
@property (weak, nonatomic) IBOutlet UITextField *userIDTextfield;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextfield;
@property (weak,nonatomic) MBProgressHUD *hud;
@property (strong,nonatomic) UIImage *imagePic;
@property (strong,nonatomic) NSString *fullPathImage;


@end

@implementation LoginView

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.updatedUserInfo=[UserModel sharedInstance];
    
    [self.userIDTextfield setValue:[UIColor whiteColor] forKeyPath:@"_placeholderLabel.textColor"];
    [self.passwordTextfield setValue:[UIColor whiteColor] forKeyPath:@"_placeholderLabel.textColor"];
    // Do any additional setup after loading the view.
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.userIDTextfield resignFirstResponder];
    [self.passwordTextfield resignFirstResponder];
}

- (IBAction)loginBtnClick {
    if(self.userIDTextfield.text.length==0){
        [self errorShow:@"用户名不能为空"];
    }
    else if(self.passwordTextfield.text.length==0){
        [self errorShow:@"密码不能为空"];
    }
    else{
        //向服务器发送登陆请求
        AFHTTPSessionManager *manager=[AFHTTPSessionManager manager];
        //            manager.requestSerializer=[AFHTTPRequest Serializerserializer];
        NSDictionary *dict=@{
                             @"userID":self.userIDTextfield.text,
                             @"password":self.passwordTextfield.text,
                             };

        //准备发送请求
        self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.mode=MBProgressHUDModeIndeterminate;
        self.hud.labelText=@"正在登录...";
        
        manager.requestSerializer.timeoutInterval=20.f;
        [manager POST:[ipAddress stringByAppendingString:@"login/"]
         parameters:dict headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if([responseObject[@"status"] boolValue]){
                NSLog(@"登录成功");
                NSLog(@"%@",responseObject[@"success_message"]);
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
                self.hud.mode=MBProgressHUDModeCustomView;
                UIImage *image = [[UIImage imageNamed:@"Checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                self.hud.customView = [[UIImageView alloc] initWithImage:image];
                self.hud.labelText = NSLocalizedString(@"登录成功！", @"HUD done title");
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    //更新账号数据，存入缓存
                    NSDictionary *dict=responseObject[@"success_message"];
                    
                    [self updateUserMethod:dict];
                    NSLog(@"%@",[UserModel sharedInstance].userName);
                    
                    //从服务器下载头像图片
//                    NSString *path=[@"http://119.23.190.159:8000/static/profiles/" stringByAppendingString:self.updatedUserInfo.profileImage];
                    NSString *path=[[ipAddress stringByAppendingString:@"static/profiles/"] stringByAppendingString:self.updatedUserInfo.profileImage];
                    NSString *urlStr=[path stringByAppendingString:@".png/"];
                    
                    
                    [self downloadImage:urlStr];
                });
                
                //登录leanCloud云
                [AVUser logInWithUsernameInBackground:self.userIDTextfield.text password:self.passwordTextfield.text block:^(AVUser * _Nullable user, NSError * _Nullable error) {
                    self.updatedUserInfo.objectId=user.objectId;
                    NSLog(@"%@",[LCChatKit sharedInstance].clientId);
                    NSLog(@"登录leanCloud成功！");
                    
                    
                }];
                
                //不知道为什么要加上这个，不加上这个切换用户进入聊天会报错，应该是leanCloud的问题
                [[LCChatKit sharedInstance] setFetchProfilesBlock:^(NSArray<NSString *> *userIds, LCCKFetchProfilesCompletionHandler completionHandler) {
                    if (userIds.count == 0) {
                        return;
                    }
                    NSMutableArray *users = [NSMutableArray arrayWithCapacity:userIds.count];
                    for (NSString *clientId in userIds) {
                        //查询 _User 表需开启 find 权限
                        AVQuery *userQuery = [AVQuery queryWithClassName:@"_User"];
                        AVObject *user = [userQuery getObjectWithId:clientId];
                        if (user) {
                            //"avatar" 是 _User 表的头像字段
                            AVFile *file = [user objectForKey:@"avatar"];
                            LCCKUser *user_ = [LCCKUser userWithUserId:user.objectId name:[user objectForKey:@"nickname"] avatarURL:[NSURL URLWithString:file.url] clientId:clientId];
                            
                            [users addObject:user_];
                        }else{
                            //注意：如果网络请求失败，请至少提供 ClientId！
                            LCCKUser *user_ = [LCCKUser userWithClientId:clientId];
                            [users addObject:user_];
                        }
                    }
                    !completionHandler ?: completionHandler([users copy], nil);
                }];
                
            }
            else{
                 NSLog(@"%@",responseObject[@"error_message"]);
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
                self.hud.mode=MBProgressHUDModeText;
                self.hud.labelText=responseObject[@"error_message"];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"登录失败,失败原因:%@",error);
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
            self.hud.mode=MBProgressHUDModeText;
            self.hud.labelText=@"请检查联网情况!";
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
        }];
        
    }
}

//更新单例sharedUserModel
-(void)updateUserMethod:(NSDictionary *) dict{
    self.updatedUserInfo.userID=dict[@"userID"];
    self.updatedUserInfo.password=dict[@"password"];
    self.updatedUserInfo.userName=dict[@"userName"];
    self.updatedUserInfo.university=dict[@"university"];
    self.updatedUserInfo.major=dict[@"major"];
    self.updatedUserInfo.email=dict[@"email"];
    self.updatedUserInfo.creationTime=dict[@"creationTime"];
    self.updatedUserInfo.profileImage=dict[@"profileImage"];
    self.updatedUserInfo.sex=dict[@"sex"];
    self.updatedUserInfo.hobbies=dict[@"hobbies"];
    self.updatedUserInfo.phone=dict[@"phone"];
    self.updatedUserInfo.isAnonymous=[dict[@"isAnonymous"] boolValue];
}

-(void)downloadImage:(NSString *)urlString{
    
    NSData *imageData=[NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
    //保存图片到沙盒缓存
    NSString *imagePath=[[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]stringByAppendingPathComponent:self.updatedUserInfo.profileImage] stringByAppendingString:@".png"];
    [imageData writeToFile:imagePath atomically:YES];
    NSLog(@"%@",urlString);
    
    AFHTTPSessionManager *manager=[AFHTTPSessionManager manager];
    
    
    NSURL *url=[NSURL URLWithString:urlString];
    NSURLRequest *request=[NSURLRequest requestWithURL:url];
    
    NSURLSessionDownloadTask *download=[manager downloadTaskWithRequest:request progress:nil destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        NSString *fullPath=[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:response.suggestedFilename];
        
        NSLog(@"targetPath:%@",targetPath);
        NSLog(@"fullPath:%@",fullPath);
        self.fullPathImage=fullPath;
        return [NSURL fileURLWithPath:fullPath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        NSLog(@"%@",error);
        self.imagePic = [UIImage imageWithContentsOfFile:self.fullPathImage];
        //更新设置界面信息
        NSInteger index=[[self.navigationController viewControllers]indexOfObject:self];
        MeVC *me=(MeVC *)([self.navigationController.viewControllers objectAtIndex:index-1]);
        me.profileImage.image=self.imagePic;
        me.userName.text=self.updatedUserInfo.userName;
        [me.profileImage.layer setCornerRadius:CGRectGetHeight([me.profileImage bounds])/2];
        me.profileImage.layer.masksToBounds=YES;
        
        //模型转字典
        NSDictionary *infoDict=self.updatedUserInfo.mj_keyValues;
        NSLog(@"ooooo%@",infoDict);
        //将个人信息保存到document文件里的UserAccount.plist文件作为缓存
//        [infoDict writeToFile:[[NSBundle mainBundle] pathForResource:@"UserAccount.plist" ofType:nil] atomically:YES];
        NSString *docPath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *userAccountPath=[docPath stringByAppendingPathComponent:@"UserAccount.plist"];
        NSLog(@"%@",userAccountPath);
        [infoDict writeToFile:userAccountPath atomically:YES];
        //为mainVC更新数据
        [[NSNotificationCenter defaultCenter]postNotificationName:@"updateAccountInfo" object:self];
        
        //跳转到设置界面
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:index-1] animated:YES];
    }];
    
    [download resume];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)errorShow:(NSString *)info{
    //初始化提示框
    ErrorView *errorInfo=[[NSBundle mainBundle]loadNibNamed:@"ErrorView" owner:nil options:nil][0];
    [errorInfo setText:(info)];
    errorInfo.layer.cornerRadius=10;
    errorInfo.alpha=0;
    [self.view addSubview:errorInfo];
    //    errorInfo.center=CGPointMake(errorInfo.superview.center.x,errorInfo.superview.center.y);
    CGFloat w = [UIScreen mainScreen].bounds.size.width;
    CGFloat h = [UIScreen mainScreen].bounds.size.height;
    errorInfo.center=CGPointMake(w/2.0, h/2.0);    //设置动画，动画结束后提示框消失
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        errorInfo.alpha=1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:1 delay:1.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            errorInfo.alpha=0;
        } completion:^(BOOL finished){
            [errorInfo removeFromSuperview];
        }];
    }];
}
- (IBAction)keepAnonymousBtnClick:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)dealloc{
   //移除通知
   [[NSNotificationCenter defaultCenter]removeObserver:self];
}
@end
