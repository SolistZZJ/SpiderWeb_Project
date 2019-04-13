//
//  MatchingBestTeamView.m
//  Cobweb
//
//  Created by zyp on 2019/4/11.
//  Copyright © 2019 solist. All rights reserved.
//

#import "MatchingBestTeamView.h"
#import "TeamCell.h"
#import "AFNetworking.h"
#import "MBProgressHUD.h"
#import <sqlite3.h>
#import "MJExtension.h"
#import "TeamModel.h"
#import "UserModel.h"
#import "setting.h"

@interface MatchingBestTeamView ()<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *myTableView;
@property(nonatomic,strong) NSArray *allTeams;
@property(nonatomic,assign) NSString *prev;
@property(nonatomic,strong) AFHTTPSessionManager *manager;
@property(nonatomic,strong) NSMutableArray *typeArray;

@property(assign,nonatomic) sqlite3 *db;

@property (strong, nonatomic) MBProgressHUD *hud;

@end

@implementation MatchingBestTeamView


-(void)awakeFromNib
{
    [super awakeFromNib];
    self.myTableView.delegate=self;
    self.myTableView.dataSource=self;
    //初始化数组
    self.allTeams=[NSMutableArray array];
    self.prev=@"";
    
    [self getTypeArrByCache];
    [self showAllFittingTeam];
}

-(void)getTypeArrByCache{
    //查看用户最近浏览的比赛类型
    //打开数据库
    NSString *fileName=[[NSBundle mainBundle]pathForResource:@"competition.db" ofType:nil];
    const char *cFileName=fileName.UTF8String;
    int result=sqlite3_open(cFileName, &_db);
    NSString *documentsPath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *plistPath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_PreferencesList.plist",[UserModel sharedInstance].userID]];
    NSMutableArray *competition_favor=[NSMutableArray arrayWithContentsOfFile:plistPath];
    //用来存用户经常访问的type的可变数组
    self.typeArray=[NSMutableArray array];
    NSString *sql=@"select distinct type from competition where ";
    for(int i=0;i<competition_favor.count;++i){
        if(i==0){
            //第一个字符不加or
            sql=[[sql stringByAppendingString:@"id="]stringByAppendingString:
                 [competition_favor[i] description]];
        }
        else{
            sql=[[sql stringByAppendingString:@" or id="]stringByAppendingString:[competition_favor[i] description]];
        }
    }
    if([UserModel sharedInstance].hobbies.count>0){
        for(int i=0;i<[UserModel sharedInstance].hobbies.count;++i){
            sql=[[[sql stringByAppendingString:@" or type like '%"] stringByAppendingString:[UserModel sharedInstance].hobbies[i]] stringByAppendingString:@"%'"];
            sql=[[[sql stringByAppendingString:@" or name like '%"] stringByAppendingString:[UserModel sharedInstance].hobbies[i]] stringByAppendingString:@"%'"];
        }
    }
    NSLog(@"%@",sql);
    sqlite3_stmt *stmt=nil;
    result=sqlite3_prepare_v2(self.db, [sql UTF8String], -1,&stmt, nil);
    if(result==SQLITE_OK){
        while (sqlite3_step(stmt)==SQLITE_ROW){
            const unsigned char *type=sqlite3_column_text(stmt, 0);
            NSString *modelType=[NSString stringWithUTF8String:(const char*)type];
            [self.typeArray addObject:modelType];
        }
    }
    else{
        NSLog(@"查询失败");
    }
}

-(void)showAllFittingTeam{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    //查看该用户的目前的队伍
    self.manager=[AFHTTPSessionManager manager];
    //向服务器发送消息
    self.hud=[MBProgressHUD showHUDAddedTo:window animated:YES];
    self.hud.mode=MBProgressHUDModeIndeterminate;
    
    //设置等待时间为20s
    self.manager.requestSerializer.timeoutInterval=20.f;
    NSData *jsonArrData = [NSJSONSerialization dataWithJSONObject:self.typeArray options:NSJSONWritingPrettyPrinted error:nil];
    NSString *dataTypeArr=[[NSString alloc] initWithData:jsonArrData encoding:NSUTF8StringEncoding];
    NSDictionary *dict=@{
                         @"typeList": dataTypeArr,
                         @"userID":[UserModel sharedInstance].userID
                         };
    [self.manager POST:[ipAddress stringByAppendingString:@"match_team/"] parameters:dict headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [MBProgressHUD hideHUDForView:window animated:YES];
        if([responseObject[@"status"] integerValue]==0){
            //加载失败提示Hub
            self.hud=[MBProgressHUD showHUDAddedTo:window animated:YES];
            self.hud.mode=MBProgressHUDModeText;
            self.hud.labelText=responseObject[@"error_message"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:window animated:YES];
            });
        }
        else{
            //操作成功
            //字典数组转换为模型数组
            [TeamModel mj_setupObjectClassInArray:^NSDictionary *{
                return @{@"captain":[UserModel class]};
            }];
            self.allTeams=[NSArray array];
            self.allTeams=[self.allTeams arrayByAddingObjectsFromArray:[TeamModel mj_objectArrayWithKeyValuesArray: responseObject[@"success_message"]]];
            [self.myTableView reloadData];
            [MBProgressHUD hideHUDForView:window animated:YES];
            NSLog(@"%@",self.allTeams);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [MBProgressHUD hideHUDForView:window animated:YES];
        NSLog(@"发送数据失败！%@",error);
        
        self.hud=[MBProgressHUD showHUDAddedTo:window animated:YES];
        self.hud.mode=MBProgressHUDModeText;
        self.hud.labelText=@"请检查联网情况!";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:window animated:YES];
        });
    }];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.allTeams.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    TeamCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TeamCellID"];
    if(!cell){
        cell = [[NSBundle mainBundle] loadNibNamed:@"TeamCell" owner:nil options:nil].lastObject;
        cell.userInteractionEnabled=YES;
        
        TeamModel *tmp=self.allTeams[indexPath.row];
        tmp.isAllTeam=YES;
        
        cell.teamModel=tmp;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    //动态cell
    TeamModel *tmp=self.allTeams[indexPath.row];
    return tmp.cellHeight;
}

- (IBAction)backBtnClicked {
    [UIView animateWithDuration:0.5 animations:^{
        self.frame=CGRectMake(-([UIScreen mainScreen].bounds.size.width), 80, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-127);
    } completion:^(BOOL finished) {
        self.hidden=YES;
    }];
}
#pragma mark - Table view cell event
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [[NSNotificationCenter defaultCenter]postNotificationName:@"goto_teamDetail2" object:self.allTeams[indexPath.row]];
}
@end
