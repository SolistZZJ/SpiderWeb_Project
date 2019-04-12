//
//  CreateTeamView.m
//  Cobweb
//
//  Created by solist on 2019/3/14.
//  Copyright © 2019 solist. All rights reserved.
//
#import "setting.h"
#import "CreateTeamView.h"
#import "MBProgressHUD.h"
#import "AFNetworking.h"
#import "UserModel.h"
#import "competitionModel.h"
#import "CompetitionDetail.h"
#import <sqlite3.h>
#import <LCChatKit.h>
#import <AVUser.h>


@interface CreateTeamView ()<UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate>
@property (strong, nonatomic) MBProgressHUD *hud;

@property(assign,nonatomic) sqlite3 *db;
@property(strong,nonatomic) NSArray *typeArray;
@property(strong,nonatomic) NSMutableArray *competitionArray;
@property(retain, nonatomic) UIPickerView *pickerCompetition;
//当前选择的大类竞赛角标
@property(assign, nonatomic) NSInteger index;

@property(strong, nonatomic) NSString *conversationID;

@end

@implementation CreateTeamView



-(void)layoutSubviews{
    //[self dataBaseOperateForCompetition];
    self.pickerCompetition=[[UIPickerView alloc]init];
    //设置pickerCompetition的代理和数据源
    self.pickerCompetition.delegate=self;
    self.pickerCompetition.dataSource=self;
    
    //设置competitionNameTextField的代理
    self.competitionChooseTextField.inputView=self.pickerCompetition;
    self.competitionChooseTextField.delegate=self;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField{
    if(textField==self.competitionChooseTextField){
        [self dataBaseOperateForCompetition];
    }
}

-(void)dataBaseOperateForCompetition{
    NSString *fileName=[[NSBundle mainBundle]pathForResource:@"competition.db" ofType:nil];
    //初始化数组
    self.typeArray=[NSArray array];
    self.competitionArray=[NSMutableArray array];
    
    const char *cFileName=fileName.UTF8String;
    int result=sqlite3_open(cFileName, &_db);
    if(result==SQLITE_OK){
        NSLog(@"成功打开数据库");
        NSString *sql=@"select distinct type from competition";
        sqlite3_stmt *stmt=nil;
        result=sqlite3_prepare_v2(self.db, [sql UTF8String], -1,&stmt, nil);
        if(result==SQLITE_OK){
            NSLog(@"查询成功");
            NSMutableArray *tmpArray=[NSMutableArray array];
            while (sqlite3_step(stmt)==SQLITE_ROW){
                const unsigned char *ID=sqlite3_column_text(stmt, 0);
                NSString *type=[NSString stringWithUTF8String:(const char*)ID];
                [tmpArray addObject:type];
            }
            self.typeArray=tmpArray;
            
            //查询不同种类的比赛有哪些
            for(int i=0;i<self.typeArray.count;++i){
                competitionModel *tmpModel=[[competitionModel alloc]init];
                tmpModel.type=self.typeArray[i];
                tmpModel.competitionArr=[NSMutableArray array];
                //查询具体比赛
                sql=[NSString stringWithFormat:@"select id,name from competition where type = '%@'",self.typeArray[i]];
                stmt=nil;
                
                result=sqlite3_prepare_v2(self.db, [sql UTF8String], -1,&stmt, nil);
                if(result==SQLITE_OK){
                    while (sqlite3_step(stmt)==SQLITE_ROW){
                        competitionDetailModel *tmpDetailModel=[[competitionDetailModel alloc]init];
                        
                        const unsigned char *ID=sqlite3_column_text(stmt, 0);
                        tmpDetailModel.competitionID=[NSString stringWithUTF8String:(const char*)ID];
                        const unsigned char *name=sqlite3_column_text(stmt, 1);
                        tmpDetailModel.competitionName=[NSString stringWithUTF8String:(const char*)name];
                        [tmpModel.competitionArr addObject:tmpDetailModel];
                    }
                    [self.competitionArray addObject:tmpModel];
                }
                else{
                    NSLog(@"查询失败");
                }
            }
            
        }
        else{
            NSLog(@"查询失败");
        }
        sqlite3_close(self.db);
    }
    else{
        NSLog(@"打开数据库失败");
    }
    
}

- (IBAction)returnBtnClicked:(id)sender {
    [UIView animateWithDuration:0.5 animations:^{
        //取消textField第一响应
        [self.teamTextField resignFirstResponder];
        [self.competitionChooseTextField resignFirstResponder];
        [self.maxNumTextField resignFirstResponder];
        [self.introductionTextView resignFirstResponder];
        //通知bottomV恢复响应
        [[NSNotificationCenter defaultCenter]postNotificationName:@"bottomEnable" object:nil];
        
        self.frame=CGRectMake(-([UIScreen mainScreen].bounds.size.width), 100, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-300);
    } completion:^(BOOL finished) {
        self.hidden=YES;
    }];
}

- (IBAction)createTeamBtnClicked:(id)sender {
    //错误检测
    if(self.teamTextField.text.length!=0&&self.introductionTextView.text.length!=0&&self.competitionChooseTextField.text.length!=0&&self.maxNumTextField.text.length!=0){
        if([self.maxNumTextField.text integerValue]<=1){
            self.hud=[MBProgressHUD showHUDAddedTo:self animated:YES];
            self.hud.mode=MBProgressHUDModeText;
//            self.hud.label.text=@"队伍人数不得少于2人";
            self.hud.labelText=@"队伍人数不得少于2人";
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self animated:YES];
                [MBProgressHUD hideHUDForView:self animated:YES];
            });
            return;
        }
        else if([self.maxNumTextField.text integerValue]>10){
            self.hud=[MBProgressHUD showHUDAddedTo:self animated:YES];
            self.hud.mode=MBProgressHUDModeText;
            self.hud.labelText=@"队伍人数不得超过10人";
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self animated:YES];
                [MBProgressHUD hideHUDForView:self animated:YES];
            });
            return;
        }
        else{
            //通过验证
        }
    }
    else{
        self.hud=[MBProgressHUD showHUDAddedTo:self animated:YES];
        self.hud.mode=MBProgressHUDModeText;
        self.hud.labelText=@"请补全队伍信息";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self animated:YES];
            [MBProgressHUD hideHUDForView:self animated:YES];
        });
        return ;
    }
    NSString *teamName=self.teamTextField.text;
    NSString *introduction=self.introductionTextView.text;
    NSString *maxNum=self.maxNumTextField.text;
    //查看该用户的目前的队伍
    AFHTTPSessionManager *manager=[AFHTTPSessionManager manager];
    //向服务器发送消息
    self.hud=[MBProgressHUD showHUDAddedTo:self animated:YES];
    self.hud.mode=MBProgressHUDModeIndeterminate;
    
    UserModel *me=[UserModel sharedInstance];
    NSLog(@"%@,%@",me.userName,me.password);
    NSString *clientId = [LCChatKit sharedInstance].client.clientId;
    NSLog(@"%@",clientId);
    //创建一个全局队列
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    //创建一个信号量（值为0）
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(queue, ^{

//        [AVUser logInWithUsernameInBackground:me.userID password:me.password block:^(AVUser * _Nullable user, NSError * _Nullable error) {
//            if(user!=nil){
                [[LCChatKit sharedInstance] openWithClientId:me.objectId callback:^(BOOL succeeded, NSError *error) {
                    
                    NSString *clientId = [LCChatKit sharedInstance].client.clientId;
                    
                    [[LCChatKit sharedInstance].client createConversationWithName:self.teamTextField.text clientIds:@[clientId] callback:^(AVIMConversation * _Nullable conversation, NSError * _Nullable error) {
                        self.conversationID=conversation.conversationId;
                        NSLog(@"%@",self.conversationID);
                        [conversation sendMessage:[AVIMTextMessage messageWithText:[NSString stringWithFormat:@"欢迎来到我的[%@]队伍",self.teamTextField.text] attributes:nil] callback:^(BOOL succeeded, NSError * _Nullable error) {
                            ;
                        }];
                        
                        //信号量加1
                        dispatch_semaphore_signal(semaphore);
                    }];
                }];

                //信号量加1
                dispatch_semaphore_signal(semaphore);
//            }
//            else{
//                NSLog(@"ppp");
//            }
//        }];

        
        
        //信号量减1，如果>0，则向下执行，否则等待
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"=====%@",self.conversationID);
        //设置等待时间为10s
        manager.requestSerializer.timeoutInterval=10.f;
        NSDictionary *dict=@{@"userID":[UserModel sharedInstance].userID,
                             @"competitionID":self.competitionID,
                             @"teamName":teamName,
                             @"introduction":introduction,
                             @"maxNum":maxNum,
                             @"isTeaming":@1,
                             @"conversationID":self.conversationID
                             };
        [manager POST:[ipAddress stringByAppendingString:@"create_team/"] parameters:dict headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [MBProgressHUD hideHUDForView:self animated:YES];
            if([responseObject[@"status"] integerValue]==0){
                //操作失败
                NSLog(@"%@",responseObject[@"error_message"]);
                
                //加载失败提示Hub
                self.hud=[MBProgressHUD showHUDAddedTo:self animated:YES];
                self.hud.mode=MBProgressHUDModeText;
                self.hud.labelText=responseObject[@"error_message"];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self animated:YES];
                    [MBProgressHUD hideHUDForView:self animated:YES];
                });
            }
            else{
                //操作成功
                
                [MBProgressHUD hideHUDForView:self animated:YES];
                self.hud=[MBProgressHUD showHUDAddedTo:self animated:YES];
                self.hud.mode=MBProgressHUDModeCustomView;
                UIImage *image = [[UIImage imageNamed:@"Checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                self.hud.customView = [[UIImageView alloc] initWithImage:image];
                self.hud.labelText = NSLocalizedString(@"队伍创建成功！", @"HUD done title");
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self animated:YES];
                    //隐藏创建队伍界面
                    [UIView animateWithDuration:0.5 animations:^{
                        //取消textField第一响应
                        [self.teamTextField resignFirstResponder];
                        [self.competitionChooseTextField resignFirstResponder];
                        [self.maxNumTextField resignFirstResponder];
                        [self.introductionTextView resignFirstResponder];
                        //通知bottomV恢复响应
                        [[NSNotificationCenter defaultCenter]postNotificationName:@"bottomEnable" object:nil];
                        //通知我的队伍界面更新myTeam数据
                        [[NSNotificationCenter defaultCenter]postNotificationName:@"updateMyTeamData" object:nil];
                        
                        
                        
                        self.frame=CGRectMake(-([UIScreen mainScreen].bounds.size.width), 100, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-300);
                    } completion:^(BOOL finished) {
                        self.hidden=YES;
                    }];
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
    });
   
//    //创建队伍群聊conversation，并将创建的conversation的id存入model中
//    UserModel *me=[UserModel sharedInstance];
//    NSLog(@"%@",me.userName);
//    [AVUser logInWithUsernameInBackground:me.userName password:me.password block:^(AVUser * _Nullable user, NSError * _Nullable error) {
//        if(user!=nil){
//            [[LCChatKit sharedInstance] openWithClientId:user.objectId callback:^(BOOL succeeded, NSError *error) {
//                NSString *clientId = [LCChatKit sharedInstance].client.clientId;
//                [[LCChatKit sharedInstance].client createConversationWithName:self.teamTextField.text clientIds:@[clientId] callback:^(AVIMConversation * _Nullable conversation, NSError * _Nullable error) {
//                    self.conversationID=conversation.conversationId;
//                    NSLog(@"%@",self.conversationID);
//                }];
//            }];
//        }
//    }];
    
    
//    NSLog(@"%@",self.teamTextField.text);
//    NSLog(@"==%@",[LCChatKit sharedInstance].client);
//    [[LCChatKit sharedInstance].client createConversationWithName:self.teamTextField.text clientIds:@[clientId] callback:^(AVIMConversation * _Nullable conversation, NSError * _Nullable error) {
//        self.conversationID=conversation.conversationId;
//        NSLog(@"%@",self.conversationID);
//    }];
    
    
//    [AVUser logInWithUsernameInBackground:me.userName password:me.password block:^(AVUser *user, NSError *error) {
//        if (user!=nil) {
//            //登录聊天服务
//            [[LCChatKit sharedInstance] openWithClientId:user.objectId callback:^(BOOL succeeded, NSError *error) {
//                if (succeeded) {
//                    [[LCChatKit sharedInstance].client createConversationWithName:self.teamTextField.text clientIds:@[clientId] callback:^(AVIMConversation * _Nullable conversation, NSError * _Nullable error) {
//                        self.conversationID=conversation.conversationId;
//                        NSLog(@"%@",self.conversationID);
//                    }];
//                }
//            }];
//        }
//
//    }];
    
    
    
    
    
    
    
    
//    [AVUser logInWithUsernameInBackground:me.userName password:me.password block:^(AVUser *user, NSError *error) {
//        if (user!=nil) {
//            //登录聊天服务
//            [[LCChatKit sharedInstance] openWithClientId:user.objectId callback:^(BOOL succeeded, NSError *error) {
//                if (succeeded) {
//                        [[LCChatKit sharedInstance].client createConversationWithName:self.teamTextField.text clientIds:@[clientId] callback:^(AVIMConversation * _Nullable conversation, NSError * _Nullable error) {
//                            self.conversationID=conversation.conversationId;
//                            NSLog(@"%@",self.conversationID);
//                        }];
//                }
//            }];
//        }
//        else{
//            NSLog(@"failed");
//        }
//    }];
    
//    //设置等待时间为10s
//    manager.requestSerializer.timeoutInterval=10.f;
//    NSDictionary *dict=@{@"userID":[UserModel sharedInstance].userID,
//                         @"competitionID":self.competitionID,
//                         @"teamName":self.teamTextField.text,
//                         @"introduction":self.introductionTextView.text,
//                         @"maxNum":self.maxNumTextField.text,
//                         @"isTeaming":@1,
//                         @"conversationID":self.conversationID
//                         };
//    [manager POST:[ipAddress stringByAppendingString:@"create_team/"] parameters:dict headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        [MBProgressHUD hideHUDForView:self animated:YES];
//        if([responseObject[@"status"] integerValue]==0){
//            //操作失败
//            NSLog(@"%@",responseObject[@"error_message"]);
//
//            //加载失败提示Hub
//            self.hud=[MBProgressHUD showHUDAddedTo:self animated:YES];
//            self.hud.mode=MBProgressHUDModeText;
//            self.hud.labelText=responseObject[@"error_message"];
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                [MBProgressHUD hideHUDForView:self animated:YES];
//                [MBProgressHUD hideHUDForView:self animated:YES];
//            });
//        }
//        else{
//            //操作成功
//
//
//            [MBProgressHUD hideHUDForView:self animated:YES];
//            self.hud=[MBProgressHUD showHUDAddedTo:self animated:YES];
//            self.hud.mode=MBProgressHUDModeCustomView;
//            UIImage *image = [[UIImage imageNamed:@"Checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
//            self.hud.customView = [[UIImageView alloc] initWithImage:image];
//            self.hud.labelText = NSLocalizedString(@"队伍创建成功！", @"HUD done title");
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                [MBProgressHUD hideHUDForView:self animated:YES];
//                //隐藏创建队伍界面
//                [UIView animateWithDuration:0.5 animations:^{
//                    //取消textField第一响应
//                    [self.teamTextField resignFirstResponder];
//                    [self.competitionChooseTextField resignFirstResponder];
//                    [self.maxNumTextField resignFirstResponder];
//                    [self.introductionTextView resignFirstResponder];
//                    //通知bottomV恢复响应
//                    [[NSNotificationCenter defaultCenter]postNotificationName:@"bottomEnable" object:nil];
//                    //通知我的队伍界面更新myTeam数据
//                    [[NSNotificationCenter defaultCenter]postNotificationName:@"updateMyTeamData" object:nil];
//
//                    self.frame=CGRectMake(-([UIScreen mainScreen].bounds.size.width), 100, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-300);
//                } completion:^(BOOL finished) {
//                    self.hidden=YES;
//                }];
//            });
//        }
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//        [MBProgressHUD hideHUDForView:self animated:YES];
//        NSLog(@"发送数据失败！%@",error);
//
//        self.hud=[MBProgressHUD showHUDAddedTo:self animated:YES];
//        self.hud.mode=MBProgressHUDModeText;
//        self.hud.labelText=@"请检查联网情况!";
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [MBProgressHUD hideHUDForView:self animated:YES];
//        });
//    }];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.teamTextField resignFirstResponder];
    [self.competitionChooseTextField resignFirstResponder];
    [self.maxNumTextField resignFirstResponder];
    [self.introductionTextView resignFirstResponder];
}


-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 2;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    if(component==0){
        return self.typeArray.count;
    }
    else{
        competitionModel *item= self.competitionArray[self.index];
        return item.competitionArr.count;
    }
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    if(component==0){
        self.index=row;
        //第一列选中第0行
        [pickerView selectRow:0 inComponent:1 animated:YES];
        
        //刷新数据
        [pickerView reloadAllComponents];
    }
    competitionModel *item=self.competitionArray[self.index];
    NSInteger competitionRow=[pickerView selectedRowInComponent:1];
    competitionDetailModel *item2=item.competitionArr[competitionRow];
    self.competitionChooseTextField.text=item2.competitionName;
    
    //获取选择的比赛id
    competitionModel *theType=self.competitionArray[[pickerView selectedRowInComponent:0]];
    competitionDetailModel *theDetail=theType.competitionArr[[pickerView selectedRowInComponent:1]];
    self.competitionID=theDetail.competitionID;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    if(component==0){
        competitionModel *item= self.competitionArray[row];
        return item.type;
    }
    else{
        competitionModel *item=self.competitionArray[self.index];
        competitionDetailModel *item2=item.competitionArr[row];
        NSString *competitionName=item2.competitionName;
        return competitionName;
    }
}

-(void)dealloc{
    
    //删除消息响应
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
