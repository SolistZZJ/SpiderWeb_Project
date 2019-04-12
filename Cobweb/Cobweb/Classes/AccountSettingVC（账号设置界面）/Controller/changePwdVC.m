//
//  changePwdVC.m
//  Cobweb
//
//  Created by solist on 2019/3/7.
//  Copyright © 2019 solist. All rights reserved.
//
#import "setting.h"
#import "changePwdVC.h"
#import "MBProgressHUD.h"
#import "AFNetworking.h"
#import "UserModel.h"
#import <LCChatKit.h>

@interface changePwdVC ()

@property(strong,nonatomic) UserModel *user;

@property(strong,nonatomic) UIBarButtonItem *finishBtn;
@property (weak, nonatomic) IBOutlet UITextField *pwd0;
@property (weak, nonatomic) IBOutlet UITextField *pwd1;
@property (weak,nonatomic) MBProgressHUD *hud;

@end

@implementation changePwdVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.user=[UserModel sharedInstance];
    
    //设置通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChanged) name:UITextFieldTextDidChangeNotification object:self.pwd0];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChanged) name:UITextFieldTextDidChangeNotification object:self.pwd1];
    
    //初始化完成按钮
    self.finishBtn=[[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(clickEvent)];
    [self.finishBtn setTintColor:[UIColor colorWithRed:50.0/255 green:205.0/255 blue:50.0/255 alpha:1]];
    self.finishBtn.enabled=NO;
    
    
    self.navigationItem.rightBarButtonItem=self.finishBtn;
}

-(void)clickEvent{
    //服务器响应
    AFHTTPSessionManager *manager=[AFHTTPSessionManager manager];
    
    //准备发送请求
    self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.mode=MBProgressHUDModeIndeterminate;
    self.hud.labelText=@"正在修改密码，请稍后";
    
    
    //先在leanCloud云上修改密码

    [AVUser logInWithUsernameInBackground:[UserModel sharedInstance].userID password:[UserModel sharedInstance].password block:^(AVUser * _Nullable user, NSError * _Nullable error) {
        [user updatePassword:[UserModel sharedInstance].password newPassword:self.pwd1.text block:^(id  _Nullable object, NSError * _Nullable error) {
            if(!error){
                
                //云上修改成功后在自己的服务器上再修改
                manager.requestSerializer.timeoutInterval=30.f;
                NSDictionary *dict=@{@"userID":self.user.userID,
                                     @"oldPwd":self.pwd0.text,
                                     @"newPwd":self.pwd1.text
                                     };
                [manager POST:[ipAddress stringByAppendingString:@"changePwd/"]
                   parameters:dict headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                       if([responseObject[@"status"] boolValue]){
                           //检验成功
                           [MBProgressHUD hideHUDForView:self.view animated:YES];
                           self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
                           self.hud.mode=MBProgressHUDModeText;
                           //self.hud.label.text=@"修改密码成功！";
                           self.hud.labelText=@"修改密码成功！";
                           
                           dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                               [MBProgressHUD hideHUDForView:self.view animated:YES];
                               [self.navigationController popViewControllerAnimated:YES];
                           });
                           
                       }
                       else{
                           //出错提示
                           [MBProgressHUD hideHUDForView:self.view animated:YES];
                           self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
                           self.hud.mode=MBProgressHUDModeText;
                           //            self.hud.labelText=responseObject[@"error_message"];
                           self.hud.labelText=responseObject[@"error_message"];
                           dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                               [MBProgressHUD hideHUDForView:self.view animated:YES];
                           });
                       }
                   } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                       //发送数据失败
                       [MBProgressHUD hideHUDForView:self.view animated:YES];
                       self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
                       self.hud.mode=MBProgressHUDModeText;
                       //        self.hud.labelText=@"请检查联网情况!";
                       self.hud.labelText=@"请检查联网情况!";
                       dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                           [MBProgressHUD hideHUDForView:self.view animated:YES];
                       });
                   }];
            }
            else{
                //发送数据失败
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
                self.hud.mode=MBProgressHUDModeText;
                self.hud.labelText=@"服务器故障，请稍后再试!";
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
            }
        }];
    }];
    
    
}

- (void)textDidChanged
{
    self.finishBtn.enabled = (self.pwd0.text.length > 0 &&self.pwd1.text.length > 0);
}

//移除通知监听者
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.pwd0 resignFirstResponder];
    [self.pwd1 resignFirstResponder];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
