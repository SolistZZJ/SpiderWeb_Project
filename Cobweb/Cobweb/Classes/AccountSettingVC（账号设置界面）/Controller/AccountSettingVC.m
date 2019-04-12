//
//  AccountSettingVC.m
//  Cobweb
//
//  Created by solist on 2019/3/5.
//  Copyright © 2019 solist. All rights reserved.
//

#import "AccountSettingVC.h"
#import "UserModel.h"
#import <LCChatKit.h>
#import <AVIMClient.h>
@interface AccountSettingVC ()

@end

@implementation AccountSettingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.user=[UserModel sharedInstance];
}

-(void)creatAlertControllerSheet{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"管理账号" message:@"选择退出登录后，仍会保存原账号下图片信息等缓存" preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *action0 = [UIAlertAction actionWithTitle:@"重新登录" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //更新当前账户为游客（匿名）
//        //为mainVC更新数据
//        [[NSNotificationCenter defaultCenter]postNotificationName:@"LogoutAccount" object:self];
        [[NSNotificationCenter defaultCenter]postNotificationName:@"updateLogoutAccountInfo" object:self];
        [self LogoutAccount];
        
        //删除document里的plist文件
        NSString *docPath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *userAccountPath=[docPath stringByAppendingPathComponent:@"UserAccount.plist"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:userAccountPath error:nil];
        
        
        NSInteger index=[[self.navigationController viewControllers]indexOfObject:self];
        [self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:index-1] animated:YES];
        
        [self performSegueWithIdentifier:@"relogin" sender:nil];
    }];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"退出登录" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        
//        //登出聊天
//        [[LCChatKit sharedInstance] openWithClientId:self.user.objectId callback:^(BOOL succeeded, NSError *error) {
//            [[LCChatKit sharedInstance] removeAllCachedProfiles];
//            [[LCChatKit sharedInstance] removeAllCachedRecentConversations];
//            [[LCChatKit sharedInstance] closeWithCallback:^(BOOL succeeded, NSError *error) {
//                if(succeeded){
//                    [AVUser logOut];
//                    NSLog(@"%@",error);
//                }
//                else{
//                    NSLog(@"%@",error);
//                }
//            }];
//        }];
        

        
        //更新当前账户为游客（匿名）
        //为mainVC更新数据
        [[NSNotificationCenter defaultCenter]postNotificationName:@"updateLogoutAccountInfo" object:self];
        [self LogoutAccount];
        
        //删除document里的plist文件
        NSString *docPath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *userAccountPath=[docPath stringByAppendingPathComponent:@"UserAccount.plist"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:userAccountPath error:nil];
        
        
        
        NSInteger index=[[self.navigationController viewControllers]indexOfObject:self];
        [self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:index-1] animated:YES];
    }];
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"点击了取消");
    }];
    UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"修改密码" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //修改密码changePwd
        [self performSegueWithIdentifier:@"changePwd" sender:nil];
    }];
    
    [actionSheet addAction:action3];
    [actionSheet addAction:action0];
    [actionSheet addAction:action1];
    [actionSheet addAction:action2];
    
    
    //相当于之前的[actionSheet show];
    [self presentViewController:actionSheet animated:YES completion:nil];
    
}

-(void)LogoutAccount{
    
    //登出聊天
    [[LCChatKit sharedInstance] openWithClientId:self.user.objectId callback:^(BOOL succeeded, NSError *error) {
        [[LCChatKit sharedInstance] removeAllCachedProfiles];
        [[LCChatKit sharedInstance] removeAllCachedRecentConversations];
        [[LCChatKit sharedInstance] closeWithCallback:^(BOOL succeeded, NSError *error) {
            if(succeeded){
                [AVUser logOut];
                NSLog(@"%@",error);
            }
            else{
                NSLog(@"%@",error);
            }
        }];
    }];
    
    self.user.userID=@"";
    self.user.password=@"";
    self.user.userName=@"";
    self.user.university=@"";
    self.user.major=@"";
    self.user.email=@"";
    self.user.creationTime=@"";
    self.user.profileImage=@"";
    self.user.sex=@"";
//    self.user.hobbies;
    self.user.phone=@"";
    self.user.isAnonymous=YES;
}

#pragma mark - Table view cell event
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //0.1s后取消选中
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
    
    if(indexPath.section==0){
        if(indexPath.row==0){
            [self performSegueWithIdentifier:@"AccountInfoView" sender:nil];
        }
        else if(indexPath.row==1){
            [self creatAlertControllerSheet];
        }
    }
}

-(void)dealloc{
    //移除通知
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}
- (IBAction)newPwd:(id)sender {
}
@end
