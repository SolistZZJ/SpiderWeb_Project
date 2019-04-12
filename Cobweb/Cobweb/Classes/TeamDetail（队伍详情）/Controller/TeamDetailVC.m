//
//  TeamDetailVC.m
//  Cobweb
//
//  Created by solist on 2019/3/18.
//  Copyright © 2019 solist. All rights reserved.
//

#import "TeamDetailVC.h"
#import "TeamModel.h"
#import <sqlite3.h>
#import "MJExtension.h"
#import "UserModel.h"
#import "MBProgressHUD.h"
#import <AVUser.h>
#import <LCChatKit.h>
#import "ChatListViewController.h"
#import "AFNetworking.h"
#import "ApplyRequestVC.h"
#import "TeamMemberInfoVC.h"
#import <AVIMClient.h>
#import "setting.h"



@interface TeamDetailVC ()<UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) NSString *comName;
@property (weak, nonatomic) IBOutlet UIButton *joinChatBtn;
@property (weak, nonatomic) IBOutlet UIButton *applyListBtn;
@property (weak, nonatomic) IBOutlet UIButton *applyBtn;
@property (weak, nonatomic) IBOutlet UIButton *teamManageBtn;


@property (weak, nonatomic) IBOutlet UIImageView *captainImage;
@property (weak, nonatomic) IBOutlet UILabel *competitionName;
@property (weak, nonatomic) IBOutlet UILabel *captainName;
@property (weak, nonatomic) IBOutlet UILabel *numOfTeam;
@property (weak, nonatomic) IBOutlet UITextView *introduction;
@property (weak, nonatomic) IBOutlet UITableView *memberView;

@property (assign, nonatomic) NSInteger numOfMember;
@property (strong, nonatomic) NSMutableArray *memberList;
@property (weak, nonatomic) IBOutlet UILabel *nullLabel;

@property (strong, nonatomic) MBProgressHUD *hud;
@property (nonatomic, strong) NSArray *applyList;
@end

@implementation TeamDetailVC

-(void)sqliteOperate:(NSString *)competitionID{
    sqlite3 *db;
    NSString *fileName=[[NSBundle mainBundle]pathForResource:@"competition.db" ofType:nil];
    const char *cFileName=fileName.UTF8String;
    int result=sqlite3_open(cFileName, &db);
    if(result==SQLITE_OK){
        NSLog(@"查询比赛Name时成功打开数据库");
        NSString *sql=[NSString stringWithFormat:@"select name from competition where id=%@",competitionID];
        sqlite3_stmt *stmt=nil;
        result=sqlite3_prepare_v2(db, [sql UTF8String], -1,&stmt, nil);
        if(result==SQLITE_OK){
            NSLog(@"查询比赛Name时查询成功");
            NSLog(@"%@",sql);
            while (sqlite3_step(stmt)==SQLITE_ROW){
                const unsigned char *competitionName=sqlite3_column_text(stmt, 0);
                self.comName=[NSString stringWithUTF8String:(const char*)competitionName];
//                self.competitionName.text=[NSString stringWithFormat:@"%@(%@)",self.teamModel.teamName,comName];
            }
        }
        else{
            NSLog(@"查询比赛Name时查询失败");
        }
        
        sqlite3_close(db);
    }
    else{
        NSLog(@"查询比赛Name时打开数据库失败");
    }
    
}

-(void)setTeamModel:(TeamModel *)teamModel{
    _teamModel=teamModel;
    [self sqliteOperate:teamModel.competition];
//    self.captainName.text=[NSString stringWithFormat:@"队长:%@",teamModel.captain.userName];
//    self.numOfTeam.text=[NSString stringWithFormat:@"当前人数:%ld/%ld",(long)teamModel.nowNum,(long)teamModel.maxNum];
//    self.introduction.text=teamModel.introduction;
    
    self.numOfMember=teamModel.member_list.count;
    //！！！！！！
    //使用memberList和applyList不要使用teamModel！！！！！！！
    //！！！！！！
    self.memberList=[UserModel mj_objectArrayWithKeyValuesArray:teamModel.member_list];
    self.applyList=[UserModel mj_objectArrayWithKeyValuesArray:teamModel.join_list];
//    NSLog(@"1:%@",self.applyList);
//    NSLog(@"2:%@",teamModel.join_list);
}

//接受踢人操作VC发出的消息
-(void)updateAfterKickData:(NSNotification *)notification{
    NSDictionary * infoDic = [notification object];
    UserModel *kickedMem=infoDic[@"kickedMem"];
    
    //队伍当前人数减1
    self.teamModel.nowNum--;
    self.numOfMember--;
    //更新memberList
    NSMutableArray *tmpMemberList=[NSMutableArray array];
    for (UserModel *mem in _memberList) {
        if(![mem.userID isEqualToString:kickedMem.userID]){
            [tmpMemberList addObject:mem];
        }
    }
    self.memberList=tmpMemberList;
    
    //修改右上角人数
    self.numOfTeam.text=[NSString stringWithFormat:@"当前人数：%ld/%ld",(long)self.numOfMember+1,(long)self.teamModel.maxNum];
    
    if(self.numOfMember>0){
        self.nullLabel.hidden=YES;
    }
    else{
        self.nullLabel.hidden=NO;
    }
    
    [self.memberView reloadData];
}

//接收申请人操作VC发出的消息
-(void)updateTeamDetailVCData:(NSNotification *)notification{
    //更新数据
    NSDictionary * infoDic = [notification object];
    NSString *userID=infoDic[@"userID"];
    NSString *status=infoDic[@"status"];
    int i=0;
    NSMutableArray *tmpArr=[NSMutableArray array];
    //寻找删除的cell数据
    for (UserModel *tmp in self.applyList) {
        if(tmp.userID==userID){
            i++;
            continue;
        }
        [tmpArr addObject:self.applyList[i]];
        i++;
    }
    self.applyList=tmpArr;
    
    if([status isEqualToString:@"addMem"]){
        //添加了申请人
        self.teamModel.nowNum++;
        UserModel *newMem=infoDic[@"newMem"];
        NSLog(@"%@",newMem);
        [self.memberList addObject:newMem];
        self.numOfMember++;
        self.numOfTeam.text=[NSString stringWithFormat:@"当前人数：%ld/%ld",(long)self.numOfMember+1,(long)self.teamModel.maxNum];
        NSLog(@"num:%ld",self.numOfMember);
        self.nullLabel.hidden=YES;
        [self.memberView reloadData];
    }
    else{
        //拒绝了申请人
        
    }
}

-(void)viewDidDisappear:(BOOL)animated{
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]){
//        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
//    }
    
    //接受ApplyListCell的消息
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updateTeamDetailVCData:) name:@"updateTeamDetailVCData" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updateAfterKickData:) name:@"updateAfterKickData" object:nil];
    
    self.memberView.dataSource=self;
    self.memberView.delegate=self;
    
    //更新数据
    self.captainName.text=[NSString stringWithFormat:@"队长:%@",self.teamModel.captain.userName];
    self.numOfTeam.text=[NSString stringWithFormat:@"当前人数:%ld/%ld",(long)self.teamModel.nowNum,(long)self.teamModel.maxNum];
    self.introduction.text=self.teamModel.introduction;
    self.competitionName.text=[NSString stringWithFormat:@"%@(%@)",self.teamModel.teamName,self.comName];
    
    //从本地找头像缓存
    NSString *imagePath=[[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]stringByAppendingPathComponent:self.teamModel.captain.profileImage] stringByAppendingString:@".png"];
    self.captainImage.image=[UIImage imageWithContentsOfFile:imagePath];
    self.captainImage.layer.cornerRadius=30;
    self.captainImage.layer.masksToBounds=YES;
    
    if(self.numOfMember>0){
        self.nullLabel.hidden=YES;
    }
    else{
        self.nullLabel.hidden=NO;
    }
    
    //查看是从allteam还是myteam得到的界面，两个界面样式不同
    if(self.teamModel.isAllTeam){
        self.applyListBtn.hidden=YES;
        self.joinChatBtn.hidden=YES;
        self.teamManageBtn.hidden=YES;
    }
    else{
        self.applyBtn.hidden=YES;
        if(self.teamModel.captain.userID!=[UserModel sharedInstance].userID){
            //队员不可对申请列表进行操作
            self.applyListBtn.hidden=YES;
        }
    }
}


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.numOfMember;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString * identifier= @"myNormalCell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    
    UserModel *tmpModel=self.memberList[indexPath.row];
    
    //加载头像
    NSString *path=[[ipAddress stringByAppendingString:@"static/profiles/"] stringByAppendingString:tmpModel.profileImage];
    NSURL *urlStr=[NSURL URLWithString:[path stringByAppendingString:@".png/"]];
    NSData *imageData=[NSData dataWithContentsOfURL:urlStr];
    UIImage *image=[UIImage imageWithData:imageData];
    
    cell.imageView.image=image;
    CGSize itemSize = CGSizeMake(35, 35);
    UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
    CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
    [cell.imageView.image drawInRect:imageRect];
    cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    cell.imageView.layer.cornerRadius=17.5;
    cell.imageView.layer.masksToBounds=YES;
    
    cell.textLabel.text = tmpModel.userName;
    
    cell.detailTextLabel.text = tmpModel.university;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSLog(@"%f",cell.imageView.bounds.size.width);
    return cell;
}


- (IBAction)joinChat:(id)sender {
    NSLog(@"点击了进入聊天群");
    //准备发送请求
    self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.mode=MBProgressHUDModeIndeterminate;
    self.hud.labelText=@"正在跳转队伍群聊界面，请稍后";
    
    UserModel *me=[UserModel sharedInstance];
    NSLog(@"%@",[AVUser currentUser].username);
//    [AVUser logInWithUsernameInBackground:me.userID password:me.password block:^(AVUser * _Nullable user, NSError * _Nullable error) {
//        if(user!=nil){
//

//    AVIMClient *client = [[AVIMClient alloc]initWithClientId:me.userID];
//    NSLog(@"%@",client);
//    [client openWithCallback:^(BOOL succeeded, NSError * _Nullable error) {
//        if(succeeded){
//            [MBProgressHUD hideHUDForView:self.view animated:YES];
//            NSLog(@"登录成功，跳转到群聊页面,conversationID:%@",self.teamModel.conversationID);
//
//            LCCKConversationViewController *conversationViewController = [[LCCKConversationViewController alloc] initWithConversationId:self.teamModel.conversationID];
//
//            //conversationViewController.enableAutoJoin=YES;
//            NSLog(@"%@",conversationViewController.peerId);
//            self.hidesBottomBarWhenPushed=YES;
//            [conversationViewController setFetchConversationHandler:^(AVIMConversation *conversation, LCCKConversationViewController *conversationController) {
//                self.hidesBottomBarWhenPushed=NO;
//            }];
//            [self.navigationController pushViewController:conversationViewController animated:YES];
//        }
//        else{
//            NSLog(@"%@",error);
//        }
//
//    }];
    
    
    
    
    [[LCChatKit sharedInstance] openWithClientId:me.objectId callback:^(BOOL succeeded, NSError *error) {
        if (succeeded) {

            [MBProgressHUD hideHUDForView:self.view animated:YES];
            NSLog(@"登录成功，跳转到群聊页面,conversationID:%@",self.teamModel.conversationID);

            LCCKConversationViewController *conversationViewController = [[LCCKConversationViewController alloc] initWithConversationId:self.teamModel.conversationID];

            //conversationViewController.enableAutoJoin=YES;
            NSLog(@"%@",conversationViewController.peerId);
            self.hidesBottomBarWhenPushed=YES;
            [conversationViewController setFetchConversationHandler:^(AVIMConversation *conversation, LCCKConversationViewController *conversationController) {
                self.hidesBottomBarWhenPushed=NO;
            }];
            [self.navigationController pushViewController:conversationViewController animated:YES];

        }
        else{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
            self.hud.mode=MBProgressHUDModeText;
            self.hud.labelText=@"网络连接失败！";
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
        }
    }];
    
    
//        }
//    }];
}
- (IBAction)applicationList:(id)sender {
     [self performSegueWithIdentifier:@"applyRequest" sender:self.applyList];
}

- (IBAction)teamMemberClicked {
    [self performSegueWithIdentifier:@"teamMemberInfo" sender:nil];
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"applyRequest"]){
        ApplyRequestVC *sonVC=(ApplyRequestVC *)segue.destinationViewController;
        sonVC.applyList=sender;
        sonVC.teamID=self.teamModel.teamID;
        sonVC.conversationID=self.teamModel.conversationID;
    }
    else if([segue.identifier isEqualToString:@"teamMemberInfo"]){
        TeamMemberInfoVC *sonVC=(TeamMemberInfoVC *)segue.destinationViewController;
        sonVC.memberList=self.memberList;
        sonVC.captain=self.teamModel.captain;
        sonVC.teamID=self.teamModel.teamID;
        sonVC.conversationID=self.teamModel.conversationID;
        
    }
}

- (IBAction)apply {
    BOOL isMember=NO;
    if([UserModel sharedInstance].isAnonymous){
        //匿名不允许加入队伍
        self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.mode=MBProgressHUDModeText;
        self.hud.labelText=@"请先登录！";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
        return;
    }
    //查看自己是否已经在成员表中
    for (UserModel *member in self.memberList) {
        if(member.userID==[UserModel sharedInstance].userID){
            isMember=YES;
            break;
        }
    }
    if(self.teamModel.captain.userID==[UserModel sharedInstance].userID){
        //自己申请自己的队伍
        self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.mode=MBProgressHUDModeText;
        self.hud.labelText=@"您已经是该队伍的队长了！";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
    }
    else if(isMember){
        //已经加入了队伍
        self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.mode=MBProgressHUDModeText;
        self.hud.labelText=@"您已经在队伍中了！";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
    }
    else
    {
        //申请加入队伍
        AFHTTPSessionManager *manager=[AFHTTPSessionManager manager];
        //向服务器发送消息
        self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.mode=MBProgressHUDModeIndeterminate;
        //设置等待时间为20s
        manager.requestSerializer.timeoutInterval=20.f;
        NSDictionary *dict=@{@"userID": [UserModel sharedInstance].userID,
                             @"teamID":self.teamModel.teamID
                             };
        //NSLog(@"%@,%@",[UserModel sharedInstance].userID,self.teamModel.teamID);
        [manager POST:[ipAddress stringByAppendingString:@"join_team/"] parameters:dict headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            if([responseObject[@"status"] integerValue]==0){
                //后台出错提示
                self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
                self.hud.mode=MBProgressHUDModeText;
                self.hud.labelText=responseObject[@"error_message"];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
            }
            else{
                //成功完成申请队伍操作
                self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
                self.hud.mode=MBProgressHUDModeText;
                self.hud.labelText=responseObject[@"success_message"];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
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
    
}


-(void)dealloc{
    //移除观察者
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
