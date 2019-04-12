//
//  MyTeamVC.m
//  Cobweb
//
//  Created by solist on 2019/3/14.
//  Copyright © 2019 solist. All rights reserved.
//
#import "setting.h"
#import "MyTeamVC.h"
#import "MyTeamBottomView.h"
#import "TeamCell.h"
#import "MBProgressHUD.h"
#import "AFNetworking.h"
#import "UserModel.h"
#import "CreateTeamView.h"
#import "competitionModel.h"
#import "competitionDetailModel.h"
#import "MJExtension.h"
#import <sqlite3.h>
#import "TeamDetailVC.h"
#import "AllTeamVC.h"
#import "ChatListViewController.h"

@interface MyTeamVC ()<UITextFieldDelegate>
@property (strong, nonatomic) MyTeamBottomView *bottomV;
@property (strong, nonatomic) MBProgressHUD *hud;
@property (assign, nonatomic) NSInteger numOfMyTeam_captain;
@property (assign, nonatomic) NSInteger numOfMyTeam_member;
@property (strong, nonatomic) CreateTeamView *createTeamView;

@property(assign,nonatomic) sqlite3 *db;
@property(strong,nonatomic) NSArray *typeArray;
@property(strong,nonatomic) NSMutableArray *competitionArray;

@property(strong,nonatomic) NSArray *myCaptainTeams;
@property(strong,nonatomic) NSArray *myMemberTeams;

@property(strong,nonatomic) AFHTTPSessionManager *manager;
@end

@implementation MyTeamVC

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //返回该界面显示bottomV
    //self.bottomV.hidden=YES;
    
    //更新显示已经参加的队伍
    [self showMyTeam];
    
    //添加消息接收恢复响应信息
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(bottomEnable) name:@"bottomEnable" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updateMyTeamData) name:@"updateMyTeamData" object:nil];
    
    
    //添加buttomView
    self.bottomV =[[[NSBundle mainBundle]loadNibNamed:@"MyTeamBottomView" owner:nil options:nil] lastObject];
    [self.tabBarController.tabBar addSubview:self.bottomV];
    self.bottomV.frame=CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 47);
    
    //设置bottomV的view点击响应
    self.bottomV.buildTeam.userInteractionEnabled=YES;
    self.bottomV.myChatRoom.userInteractionEnabled=YES;
    
    UITapGestureRecognizer *buildTeamOnClick= [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buildTeamOnClickListener:)];
    [self.bottomV.buildTeam addGestureRecognizer:buildTeamOnClick];
    
    UITapGestureRecognizer *myChatRoomOnClick= [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(myChatRoomOnClickListener:)];
    [self.bottomV.myChatRoom addGestureRecognizer:myChatRoomOnClick];
}


-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    //到下一界面隐藏bottomV
    self.bottomV.hidden=YES;
    
    [self hideCreateTeamView];
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self cancelRequest];
}
- (void)cancelRequest
{
    if ([self.manager.tasks count] > 0) {
        NSLog(@"返回时取消网络请求");
        [self.manager.tasks.firstObject cancel];
    }
}
//隐藏创建队伍栏
-(void)hideCreateTeamView{
    [UIView animateWithDuration:0.5 animations:^{
        [self.createTeamView.teamTextField resignFirstResponder];
        [self.createTeamView.competitionChooseTextField resignFirstResponder];
        [self.createTeamView.maxNumTextField resignFirstResponder];
        [self.createTeamView.introductionTextView resignFirstResponder];
        //恢复响应
        self.bottomV.buildTeam.userInteractionEnabled=YES;
        self.bottomV.myChatRoom.userInteractionEnabled=YES;
        self.createTeamView.frame=CGRectMake(-([UIScreen mainScreen].bounds.size.width), 100, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-300);
    } completion:^(BOOL finished) {
        self.createTeamView.hidden=YES;
    }];
}

-(void)buildTeamOnClickListener:(UITapGestureRecognizer *)recognizer{
    NSLog(@"点击了创建队伍");
    self.createTeamView=[[NSBundle mainBundle] loadNibNamed:@"CreateTeamView" owner:nil options:nil].lastObject;
    self.createTeamView.hidden=NO;
    self.createTeamView.frame=CGRectMake(-([UIScreen mainScreen].bounds.size.width), 100, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-300);
    UIWindow * window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:self.createTeamView];
    [UIView animateWithDuration:0.5 animations:^{
        self.createTeamView.frame=CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-300);
    } completion:nil];
    
//    self.pickerCompetition=[[UIPickerView alloc]init];
//    //设置pickerCompetition的代理和数据源
//    self.pickerCompetition.delegate=self;
//    self.pickerCompetition.dataSource=self;
    
//    //设置competitionNameTextField的代理
//    self.createTeamView.competitionChooseTextField.inputView=self.pickerCompetition;
//    self.createTeamView.competitionChooseTextField.delegate=self;
    
    //取消响应
    self.bottomV.buildTeam.userInteractionEnabled=NO;
    self.bottomV.myChatRoom.userInteractionEnabled=NO;
}


-(void)myChatRoomOnClickListener:(UITapGestureRecognizer *)recognizer{
    NSLog(@"点击了我的讨论组");
    ChatListViewController *vc = [[ChatListViewController alloc]init];
    [self.navigationController pushViewController:vc animated:YES];
}

-(void) showMyTeam{
    //查看该用户的目前的队伍
    self.manager=[AFHTTPSessionManager manager];
    //向服务器发送消息
    self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.mode=MBProgressHUDModeIndeterminate;
    
    //设置等待时间为10s
    self.manager.requestSerializer.timeoutInterval=10.f;
    NSDictionary *dict=@{@"userID":[UserModel sharedInstance].userID};
    [self.manager POST:[ipAddress stringByAppendingString:@"return_myteam/"] parameters:dict headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if([responseObject[@"status"] integerValue]==0){
            //操作失败
            NSLog(@"%@",responseObject[@"error_message"]);
            
            //加载失败提示Hub
            self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
            self.hud.mode=MBProgressHUDModeText;
            self.hud.labelText=responseObject[@"error_message"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
        }
        else{
            //操作成功
            //NSLog(@"%@",responseObject[@"success_message"]);
            //NSLog(@"kkk%@",(responseObject[@"success_message"])[@"captain_team_list"][1]);
            NSDictionary *returnMessage=responseObject[@"success_message"];
            NSArray *myCaptainTeams_dictArr=returnMessage[@"captain_team_list"];
            NSArray *myMemberTeams_dictArr=returnMessage[@"member_team_list"];
            self.numOfMyTeam_captain=myCaptainTeams_dictArr.count;
            self.numOfMyTeam_member=myMemberTeams_dictArr.count;
            
            //字典数组转换为模型数组
            [TeamModel mj_setupObjectClassInArray:^NSDictionary *{
                return @{@"captain":[UserModel class]};
            }];
            
            self.myCaptainTeams=[TeamModel mj_objectArrayWithKeyValuesArray:myCaptainTeams_dictArr];
            self.myMemberTeams=[TeamModel mj_objectArrayWithKeyValuesArray:myMemberTeams_dictArr];
            
            
            //更新数据
            [self.tableView reloadData];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        NSLog(@"发送数据失败！%@",error);
        
        self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.mode=MBProgressHUDModeText;
        self.hud.labelText=@"请检查联网情况!";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]){
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
//    //更新显示已经参加的队伍
//    [self showMyTeam];
//
//    //添加消息接收恢复响应信息
//    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(bottomEnable) name:@"bottomEnable" object:nil];
//    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updateMyTeamData) name:@"updateMyTeamData" object:nil];
//
//
//    //添加buttomView
//    self.bottomV =[[[NSBundle mainBundle]loadNibNamed:@"MyTeamBottomView" owner:nil options:nil] lastObject];
//    [self.tabBarController.tabBar addSubview:self.bottomV];
//    self.bottomV.frame=CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 47);
//
//    //设置bottomV的view点击响应
//    self.bottomV.buildTeam.userInteractionEnabled=YES;
//    self.bottomV.myChatRoom.userInteractionEnabled=YES;
//
//    UITapGestureRecognizer *buildTeamOnClick= [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buildTeamOnClickListener:)];
//    [self.bottomV.buildTeam addGestureRecognizer:buildTeamOnClick];
//
//    UITapGestureRecognizer *myChatRoomOnClick= [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(myChatRoomOnClickListener:)];
//    [self.bottomV.myChatRoom addGestureRecognizer:myChatRoomOnClick];
//
    
    
    
    
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section==0){
        return self.numOfMyTeam_captain;
    }else{
        return self.numOfMyTeam_member;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section==0){
        TeamCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TeamCellID"];
        if(!cell){
            cell = [[NSBundle mainBundle] loadNibNamed:@"TeamCell" owner:nil options:nil].lastObject;
            cell.userInteractionEnabled=YES;
            TeamModel *tmp=self.myCaptainTeams[indexPath.row];
            tmp.isAllTeam=NO;
            cell.teamModel=tmp;
        }
        return cell;
    }
    else{
        TeamCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TeamCellID"];
        if(!cell){
            cell = [[NSBundle mainBundle] loadNibNamed:@"TeamCell" owner:nil options:nil].lastObject;
            cell.userInteractionEnabled=YES;
            
            cell.teamModel=self.myMemberTeams[indexPath.row];
        }
        return cell;
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if(section==0){
        return @"我的队伍";
    }
    else{
        return @"我加入的队伍";
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 50;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //0.1s后取消选中
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
    if(indexPath.section==0){
        [self performSegueWithIdentifier:@"teamDetail" sender:self.myCaptainTeams[indexPath.row]];
    }
    else{
        [self performSegueWithIdentifier:@"teamDetail" sender:self.myMemberTeams[indexPath.row]];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    TeamDetailVC *sonView=(TeamDetailVC *)segue.destinationViewController;
    sonView.teamModel=sender;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if(textField==self.createTeamView.competitionChooseTextField)
        return NO;
    else
        return YES;
}


-(UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if(indexPath.section==0){
        //我的队伍中显示解散队伍
        UIContextualAction *dissolveAction=[UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"解散队伍" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [self dissolveTeamPre:indexPath.row];
        }];
        dissolveAction.image=[UIImage imageNamed:@"dissolveTeam"];
        dissolveAction.backgroundColor=[UIColor colorWithRed:1.0 green:0 blue:0 alpha:0.5];
        
        
        UISwipeActionsConfiguration *config=[UISwipeActionsConfiguration configurationWithActions:@[dissolveAction]];
        return config;
    }
    else{
        //我加入的队伍中显示我离开队伍
        UIContextualAction *quitAction=[UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"离开队伍" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [self quitTeamPre:indexPath.row];
        }];
        quitAction.image=[UIImage imageNamed:@"quitTeam"];
        quitAction.backgroundColor=[UIColor colorWithRed:1.0 green:0 blue:0 alpha:0.5];
        
        
        UISwipeActionsConfiguration *config=[UISwipeActionsConfiguration configurationWithActions:@[quitAction]];
        return config;
    }
}

-(void)quitTeamPre:(NSInteger)teamNum{
    // 初始化对话框
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"确定要退出该队伍吗？" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction=[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self quitTeamMethod:teamNum];
    }];
    UIAlertAction *cancelAction=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alert addAction:okAction];
    [alert addAction:cancelAction];
    
    // 弹出对话框
    [self presentViewController:alert animated:YES completion:nil];
}
//离队操作
-(void)quitTeamMethod:(NSInteger)teamNum{
    //向服务器发送请求
    self.hud=[MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
    self.hud.mode=MBProgressHUDModeIndeterminate;
    
    UserModel *me=[UserModel sharedInstance];

//    [AVUser logInWithUsernameInBackground:me.userID password:me.password block:^(AVUser * _Nullable user, NSError * _Nullable error) {
//        if(user!=nil){
            [[LCChatKit sharedInstance] openWithClientId:me.objectId callback:^(BOOL succeeded, NSError *error) {
                if(succeeded){
                    TeamModel *quitedTeam=self.myMemberTeams[teamNum];
                    NSString *conversationID=quitedTeam.conversationID;
                    
                    AVIMClient *client=[LCChatKit sharedInstance].client;
                    AVIMConversationQuery *query = [client conversationQuery];
                    
                    [query getConversationById:conversationID callback:^(AVIMConversation * _Nullable conversation, NSError * _Nullable error) {
                        
                        [conversation quitWithCallback:^(BOOL succeeded, NSError * _Nullable error) {
                            if(succeeded){
                                //向自己的后台提交踢人申请
                                self.manager=[AFHTTPSessionManager manager];
                                //设置等待时间为20s
                                self.manager.requestSerializer.timeoutInterval=20.f;
                                NSDictionary *dict=@{
                                                     @"kickedMemID":[UserModel sharedInstance].userID,
                                                     @"teamID":quitedTeam.teamID
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
                                        [conversation addMembersWithClientIds:@[client.clientId] callback:^(BOOL succeeded, NSError * _Nullable error) {
                                            
                                        }];
                                    }
                                    else{
                                        //动作成功提示Hub
                                        self.hud=[MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
                                        self.hud.mode=MBProgressHUDModeText;
                                        self.hud.labelText=responseObject[@"success_message"];
                                        
                                        NSMutableArray *tmpMyMemberTeams=[NSMutableArray array];
                                        for (TeamModel *tmpTeam in self.myMemberTeams) {
                                            if(![tmpTeam.teamID isEqualToString:quitedTeam.teamID]){
                                                [tmpMyMemberTeams addObject:tmpTeam];
                                            }
                                        }
                                        self.myMemberTeams=tmpMyMemberTeams;
                                        self.numOfMyTeam_member--;
                                        [self.tableView reloadData];
                                        
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
                                    [conversation addMembersWithClientIds:@[client.clientId] callback:^(BOOL succeeded, NSError * _Nullable error) {
                                        
                                    }];
                                }];
                            }
                            else{
                                [MBProgressHUD hideHUDForView:self.tableView animated:YES];
                                self.hud=[MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
                                self.hud.mode=MBProgressHUDModeText;
                                self.hud.labelText=@"离开队伍失败，请稍后再试";
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
//        }
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


-(void)dissolveTeamPre:(NSInteger)teamNum{
    // 初始化对话框
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"确定要解散该队伍吗？" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction=[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self dissolveTeamMethod:teamNum];
    }];
    UIAlertAction *cancelAction=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alert addAction:okAction];
    [alert addAction:cancelAction];
    
    // 弹出对话框
    [self presentViewController:alert animated:YES completion:nil];
}
-(void)dissolveTeamMethod:(NSInteger)teamNum{
    //向服务器发送请求
    self.hud=[MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
    self.hud.mode=MBProgressHUDModeIndeterminate;
    
    UserModel *me=[UserModel sharedInstance];

//    [AVUser logInWithUsernameInBackground:me.userID password:me.password block:^(AVUser * _Nullable user, NSError * _Nullable error) {
//        if(user!=nil){
            [[LCChatKit sharedInstance] openWithClientId:me.objectId callback:^(BOOL succeeded, NSError *error) {
                if(succeeded){
                    TeamModel *dissolvedTeam=self.myCaptainTeams[teamNum];
                    NSString *conversationID=dissolvedTeam.conversationID;
                    
                    AVIMClient *client=[LCChatKit sharedInstance].client;
                    AVIMConversationQuery *query = [client conversationQuery];
                    
                    [query getConversationById:conversationID callback:^(AVIMConversation * _Nullable conversation, NSError * _Nullable error) {
                        NSArray *members=conversation.members;
                        //清除队伍时先把人移除
                        [conversation removeMembersWithClientIds:members callback:^(BOOL succeeded, NSError * _Nullable error) {
                            if(succeeded){
                                //在leanCloud服务器数据库中删除该conversation字段
                                AVQuery *conversationQuery = [AVQuery queryWithClassName:@"_Conversation"];
                                [conversationQuery whereKey:@"objectId" equalTo:conversationID];
                                [conversationQuery deleteAllInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                                    if(succeeded){
                                        //成功删除leanCloud上的数据
                                        //向自己的后台提交解散队伍申请
                                        self.manager=[AFHTTPSessionManager manager];
                                        //设置等待时间为20s
                                        self.manager.requestSerializer.timeoutInterval=20.f;
                                        NSDictionary *dict=@{
                                                             @"teamID":dissolvedTeam.teamID
                                                             };
                                        [self.manager POST:[ipAddress stringByAppendingString:@"dissolve_team/"] parameters:dict headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                            [MBProgressHUD hideHUDForView:self.tableView animated:YES];
                                            if([responseObject[@"status"] integerValue]==0){
                                                //动作失败提示Hub
                                                self.hud=[MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
                                                self.hud.mode=MBProgressHUDModeText;
                                                self.hud.labelText=responseObject[@"error_message"];
                                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                    [MBProgressHUD hideHUDForView:self.tableView animated:YES];
                                                });
                                            }
                                            else{
                                                //动作成功提示Hub
                                                self.hud=[MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
                                                self.hud.mode=MBProgressHUDModeText;
                                                self.hud.labelText=responseObject[@"success_message"];
                                                
                                                //更新当前tableview
                                                NSMutableArray *tmpMyCaptainTeams=[NSMutableArray array];
                                                for (TeamModel *tmpTeam in self.myCaptainTeams) {
                                                    if(![tmpTeam.teamID isEqualToString:dissolvedTeam.teamID]){
                                                        [tmpMyCaptainTeams addObject:tmpTeam];
                                                    }
                                                }
                                                self.myCaptainTeams=tmpMyCaptainTeams;
                                                self.numOfMyTeam_captain--;
                                                [self.tableView reloadData];
                                                
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
                                        }];
                                        
                                    }
                                    else{
                                        [MBProgressHUD hideHUDForView:self.tableView animated:YES];
                                        self.hud=[MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
                                        self.hud.mode=MBProgressHUDModeText;
                                        self.hud.labelText=@"解散队伍失败，请稍后再试";
                                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                            [MBProgressHUD hideHUDForView:self.tableView animated:YES];
                                        });
                                    }
                                }];

                            }
                            else{
                                [MBProgressHUD hideHUDForView:self.tableView animated:YES];
                                self.hud=[MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
                                self.hud.mode=MBProgressHUDModeText;
                                self.hud.labelText=@"解散队伍失败，请稍后再试";
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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
//        }
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

-(void)bottomEnable {
    //更新数据
    self.bottomV.myChatRoom.userInteractionEnabled=YES;
    self.bottomV.buildTeam.userInteractionEnabled=YES;
}

-(void)updateMyTeamData{
    [self showMyTeam];
}

- (void)dealloc {
    //移除观察者
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}



@end
