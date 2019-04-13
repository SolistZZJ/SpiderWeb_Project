//
//  MainVC.m
//  Cobweb
//
//  Created by solist on 2019/2/26.
//  Copyright © 2019 solist. All rights reserved.
//

#import "MainVC.h"
#import "UserModel.h"
#import "MJExtension.h"
#import "MeVC.h"
#import "LoginView.h"
#import "AFNetworking.h"
#import <LCChatKit.h>
#import "LCCKUser.h"

@interface MainVC ()

@end

@implementation MainVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    
    //NSLog(@"%@",NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES));
    
    //从plist中读取账号信息
//    NSString *path=[[NSBundle mainBundle]pathForResource:@"UserAccount.plist" ofType:nil];
//    NSDictionary *accountInfo=[NSDictionary dictionaryWithContentsOfFile:path];
//    
    
    NSString *docPath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *userAccountPath=[docPath stringByAppendingPathComponent:@"UserAccount.plist"];
    NSLog(@"%@",userAccountPath);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL result = [fileManager fileExistsAtPath:userAccountPath];
    NSDictionary *accountInfo;
    if(result){
        accountInfo=[NSDictionary dictionaryWithContentsOfFile:userAccountPath];
    }
    else{
        NSString *path=[[NSBundle mainBundle]pathForResource:@"UserAccount.plist" ofType:nil];
        accountInfo=[NSDictionary dictionaryWithContentsOfFile:path];
    }
    
    self.user=[UserModel sharedInstance];
    
    
    [self setupUserInfo:accountInfo];
    
    if(!self.user.isAnonymous){
        //登录leanCloud云
        [AVUser logInWithUsernameInBackground:self.user.userID password:self.user.password block:^(AVUser * _Nullable user, NSError * _Nullable error) {
            self.user.objectId=user.objectId;
            NSLog(@"登录leanCloud成功！");
        }];
    }
    
    [[LCChatKit sharedInstance] setConversationInvalidedHandler:^(NSString *conversationId, LCCKConversationViewController *conversationController, id<LCCKUserDelegate> administrator, NSError *error) {
        conversationController.title=@"抱歉，您已不在该队伍中";
    }];
    
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
    
    
    //查看数据库是否在Cache中，不在的话将mainbundle里的数据库复制进来
    NSString *dbRootPath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *dbPath=[dbRootPath stringByAppendingPathComponent:@"competition.db"];
    // 复制本地数据到沙盒中
    NSFileManager *file_Manager = [NSFileManager defaultManager];
    if (![file_Manager fileExistsAtPath:dbPath]) {
        // 获得数据库文件在工程中的路径——源路径。
        NSString *sourcesPath = [[NSBundle mainBundle] pathForResource:@"competition.db"ofType:nil];
        NSError *error ;
        if ([file_Manager copyItemAtPath:sourcesPath toPath:dbPath error:&error]) {
            NSLog(@"数据库移动成功");
        } else {
            NSLog(@"数据库移动失败");
        }
    }
    
}

//更新单例sharedUserModel
-(void)setupUserInfo:(NSDictionary *) dict{
    
    self.user.userID=dict[@"userID"];
    self.user.password=dict[@"password"];
    self.user.userName=dict[@"userName"];
    self.user.university=dict[@"university"];
    self.user.major=dict[@"major"];
    self.user.email=dict[@"email"];
    self.user.creationTime=dict[@"creationTime"];
    self.user.profileImage=dict[@"profileImage"];
    self.user.sex=dict[@"sex"];
    self.user.hobbies=dict[@"hobbies"];
    self.user.phone=dict[@"phone"];
    self.user.isAnonymous=[dict[@"isAnonymous"] boolValue];
//    self.user.chatID=[[AVIMClient alloc] initWithClientId:dict[@"userID"]];
    

    NSLog(@"%@",dict[@"userName"]);
    NSLog(@"%@:%@",[dict[@"isAnonymous"] class],(NSNumber*)dict[@"isAnonymous"]);

}

////通知返回当前userAccountd
//-(void)sendAccountInfo:(NSNotification *)note{
//    MeVC *tmp=note.object;
//    tmp.user=self.user;
//}
//
////更新当前用户信息
//-(void)updateAccountInfo:(NSNotification *)note{
//    LoginView *tmp=note.object;
//    self.user=tmp.updatedUserInfo;
//
//    //更新MeVC的user数据
//    [[NSNotificationCenter defaultCenter]postNotificationName:@"updateLoginAccountInfo" object:self];
//}
//
////更新当前用户信息为匿名用户
//-(void)logoutAccountInfo:(NSNotification *)note{
//    NSString *path=[[NSBundle mainBundle]pathForResource:@"UserAccount.plist" ofType:nil];
//    NSDictionary *accountInfo=[NSDictionary dictionaryWithContentsOfFile:path];
//    self.user=[UserModel mj_objectWithKeyValues:accountInfo];
//
//    [[NSNotificationCenter defaultCenter]postNotificationName:@"updateLogoutAccountInfo" object:self];
//}

#pragma mark - Navigation

//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
//    if([segue.identifier isEqualToString:@"me"]){
//        meVc *meVC=(CompetitionDetail *)segue.destinationViewController;
//        detailVC.cellModel=nowModel;
//    }
//}


@end
