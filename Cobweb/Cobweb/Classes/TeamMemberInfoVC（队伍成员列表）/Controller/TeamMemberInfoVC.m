//
//  TeamMemberInfoVC.m
//  Cobweb
//
//  Created by solist on 2019/3/24.
//  Copyright © 2019 solist. All rights reserved.
//

#import "TeamMemberInfoVC.h"
#import "ApplyListCell.h"
#import "MBProgressHUD.h"
#import "UserModel.h"

#import <AVUser.h>
#import <LCChatKit.h>
#import "AFNetworking.h"
#import "setting.h"

@interface TeamMemberInfoVC ()

@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) AFHTTPSessionManager *manager;

@end

@implementation TeamMemberInfoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"%ld",self.memberList.count+1);
    return self.memberList.count+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ApplyListCell *cell=[tableView dequeueReusableCellWithIdentifier:@"ApplyListCellID"];
    if(!cell){
        cell=[[NSBundle mainBundle]loadNibNamed:@"ApplyListCell" owner:nil options:nil].lastObject;
        cell.hideBtn=YES;
        if(indexPath.row==0){
            //第一列显示队长信息
            cell.applicantInfo=self.captain;
        }
        else{
            //其余列显示队友信息
            UserModel *tmp=self.memberList[indexPath.row-1];
            cell.applicantInfo=tmp;
        }
        cell.teamID=self.teamID;
        cell.conversationID=self.conversationID;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 155;
}

-(UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath{
    UIContextualAction *kickAction=[UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"请离队伍" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [self kickMemPre:indexPath.row];
    }];
    kickAction.image=[UIImage imageNamed:@"kickMem"];
    kickAction.backgroundColor=[UIColor colorWithRed:1.0 green:0 blue:0 alpha:0.5];
    
   
    UISwipeActionsConfiguration *config=[UISwipeActionsConfiguration configurationWithActions:@[kickAction]];
    return config;
}

-(void)kickMemPre:(NSUInteger)memNum{
    if(![[UserModel sharedInstance].userID isEqualToString:self.captain.userID]){
        //非队长无权限踢人
        self.hud=[MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
        self.hud.mode=MBProgressHUDModeText;
        self.hud.labelText=@"只有队长可进行该操作";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.tableView animated:YES];
        });
    }
    else{
        if(memNum==0){
            //无法踢自己
            self.hud=[MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
            self.hud.mode=MBProgressHUDModeText;
            self.hud.detailsLabelFont=[UIFont systemFontOfSize:16];
            self.hud.detailsLabelText=@"您无法将自己请离队伍，若要解散队伍请在我的队伍界面右滑选择解散队伍";
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.tableView animated:YES];
            });
        }
        else{
            //弹出确定框
            UserModel *kickedMem=self.memberList[memNum-1];
            // 初始化对话框
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:[NSString stringWithFormat:@"确定要将[%@]踢出该团队吗？",kickedMem.userName] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction=[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self kickMethod:memNum];
            }];
            UIAlertAction *cancelAction=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            }];
            [alert addAction:okAction];
            [alert addAction:cancelAction];
            
            // 弹出对话框
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

//踢人操作
-(void)kickMethod:(NSInteger)memNum{
    //向服务器发送请求
    self.hud=[MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
    self.hud.mode=MBProgressHUDModeIndeterminate;
    
    UserModel *me=[UserModel sharedInstance];

//    [AVUser logInWithUsernameInBackground:me.userID password:me.password block:^(AVUser * _Nullable user, NSError * _Nullable error) {
 //       if(user!=nil){
            [[LCChatKit sharedInstance] openWithClientId:me.objectId callback:^(BOOL succeeded, NSError *error) {
                if(succeeded){
                    UserModel *kickedMem=self.memberList[memNum-1];
                    
                    AVQuery *userQuery = [AVQuery queryWithClassName:@"_User"];
                    [userQuery whereKey:@"username" equalTo:kickedMem.userID];
                    AVObject *obj=[userQuery getFirstObject];
                    NSMutableDictionary *theDict=obj.dictionaryForObject;
                    NSString *kickedMemClientID=theDict[@"objectId"];
                    NSLog(@"===kickedMemClientID:%@",kickedMemClientID);
                    
                    AVIMClient *client=[LCChatKit sharedInstance].client;
                    AVIMConversationQuery *query = [client conversationQuery];
                    [query getConversationById:self.conversationID callback:^(AVIMConversation * _Nullable conversation, NSError * _Nullable error) {
                        
                        [conversation removeMembersWithClientIds:@[kickedMemClientID] callback:^(BOOL succeeded, NSError * _Nullable error) {
                            if(succeeded){
                                //向自己的后台提交踢人申请
                                self.manager=[AFHTTPSessionManager manager];
                                //设置等待时间为20s
                                self.manager.requestSerializer.timeoutInterval=20.f;
                                NSDictionary *dict=@{
                                                     @"kickedMemID":kickedMem.userID,
                                                     @"teamID":self.teamID
                                                     };
                                [self.manager POST:[ipAddress stringByAppendingString:@"out_team/"] parameters:dict headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                    [MBProgressHUD hideHUDForView:self.tableView animated:YES];
                                    if([responseObject[@"status"] integerValue]==0){
                                        //动作失败提示Hub
                                        self.hud=[MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
                                        self.hud.mode=MBProgressHUDModeText;
                                        self.hud.labelText=responseObject[@"error_message"];
                                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                            [MBProgressHUD hideHUDForView:self.tableView animated:YES];
                                        });
                                        
                                        //因后续操作失败，重新将该人加回队伍
                                        [conversation addMembersWithClientIds:@[kickedMemClientID] callback:^(BOOL succeeded, NSError * _Nullable error) {
                                            
                                        }];
                                    }
                                    else{
                                        //动作成功提示Hub
                                        self.hud=[MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
                                        self.hud.mode=MBProgressHUDModeText;
                                        self.hud.labelText=responseObject[@"success_message"];
                                        
                                        //更新当前tableview
                                        NSMutableArray *tmpMemberList=[NSMutableArray array];
                                        for (UserModel *mem in self.memberList) {
                                            if(![kickedMem.userID isEqualToString:mem.userID]){
                                                [tmpMemberList addObject:mem];
                                            }
                                        }
                                        self.memberList=tmpMemberList;
                                        [self.tableView reloadData];
                                        
                                        //给上一界面发送消息，删除该成员相关信息等
                                        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateAfterKickData" object:@{
                                                                                                                                   @"kickedMem":kickedMem
                                                                                                                                   }];
                                        
                                        
                                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                            [MBProgressHUD hideHUDForView:self.tableView animated:YES];
                                        });
                                        
                                    }
                                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                    [MBProgressHUD hideHUDForView:self.tableView animated:YES];
                                    self.hud=[MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
                                    self.hud.mode=MBProgressHUDModeText;
                                    self.hud.labelText=@"服务器连接失败，请稍后再试";
                                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                        [MBProgressHUD hideHUDForView:self.tableView animated:YES];
                                    });
                                    //因后续操作失败，重新将该人加回队伍
                                    [conversation addMembersWithClientIds:@[kickedMemClientID] callback:^(BOOL succeeded, NSError * _Nullable error) {
                                        
                                    }];
                                }];
                                
                            }
                            else{
                                [MBProgressHUD hideHUDForView:self.tableView animated:YES];
                                self.hud=[MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
                                self.hud.mode=MBProgressHUDModeText;
                                self.hud.labelText=@"踢除队伍成员失败，请稍后再试";
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                    [MBProgressHUD hideHUDForView:self.tableView animated:YES];
                                });
                            }
                        }];
                    }];
                    
                }
                else{
                    [MBProgressHUD hideHUDForView:self.tableView animated:YES];
                    self.hud=[MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
                    self.hud.mode=MBProgressHUDModeText;
                    self.hud.labelText=@"用户状态异常，请重新登录后再试";
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideHUDForView:self.tableView animated:YES];
                    });
                }
            }];
 //       }
//        else{
//            [MBProgressHUD hideHUDForView:self.tableView animated:YES];
//            self.hud=[MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
//            self.hud.mode=MBProgressHUDModeText;
//            self.hud.labelText=@"用户状态异常，请重新登录后再试";
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                [MBProgressHUD hideHUDForView:self.tableView animated:YES];
//            });
//        }
//    }];
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
