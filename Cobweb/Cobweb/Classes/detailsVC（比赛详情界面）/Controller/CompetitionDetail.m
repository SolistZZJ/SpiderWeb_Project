//
//  CompetitionDetail.m
//  Cobweb
//
//  Created by solist on 2019/2/25.
//  Copyright © 2019 solist. All rights reserved.
//
#import "setting.h"
#import "CompetitionDetail.h"
#import "CompetitionCellModel.h"
#import "WebVC.h"
#import "BottomView.h"
#import "CommentSend.h"
#import "MBProgressHUD.h"
#import "AFNetworking.h"
#import "CommentCell.h"
#import "CommentCellModel.h"
#import "ReplyView.h"
#import "UserModel.h"
#import "MoreReplyCell.h"
#import <sqlite3.h>

@interface CompetitionDetail () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UILabel *compName;
@property (weak, nonatomic) IBOutlet UIImageView *myImage;
@property (weak, nonatomic) IBOutlet UILabel *introduction;
@property (weak, nonatomic) IBOutlet UIButton *webEnterBtn;
@property (assign, nonatomic) CGFloat keyboardY;
@property (strong, nonatomic) bottomView *bottomV;
@property (strong, nonatomic) CommentSend *commentView;
@property (strong, nonatomic) ReplyView *replyView;
@property (strong, nonatomic) MBProgressHUD *hud;

@property(weak,nonatomic) NSString* numOfComment;
@property(weak,nonatomic) NSString* web;
@property(assign,nonatomic) BOOL hasCollected;
@property(strong,nonatomic) UITextField *test;

@property(strong, nonatomic) NSMutableArray *commentArray;

@property(strong, nonatomic) NSString *commentNum;
@property(strong, nonatomic) NSString *collectNum;

//子线程（下载图片）
@property(strong,nonatomic) NSOperationQueue *queue;

@property(strong,nonatomic) AFHTTPSessionManager *manager;

@end

@implementation CompetitionDetail


-(void)viewWillAppear:(BOOL)animated{
//    self.tabBarController.tabBar.hidden = YES;
    //返回该界面显示bottomV
    self.tabBarController.hidesBottomBarWhenPushed = NO;
    //self.tabBarController.tabBar.hidden = NO;
    self.bottomV.hidden=NO;
    
    [self updateCommentAndCollect];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //到下一界面隐藏bottomV
    //self.tabBarController.hidesBottomBarWhenPushed = YES;
    self.bottomV.hidden=YES;
    //self.tabBarController.tabBar.hidden = YES;
}

-(void)updateCommentAndCollect{
    dispatch_queue_t queue =dispatch_queue_create("concurrent",DISPATCH_QUEUE_CONCURRENT);
    dispatch_sync(queue, ^{
        self.manager=[AFHTTPSessionManager manager];
        //设置等待时间为20s
        self.manager.requestSerializer.timeoutInterval=20.f;
        NSDictionary *dict=@{@"competition":self.cellModel.ID};
        [self.manager POST:[ipAddress stringByAppendingString:@"return_commentCount_and_collectCount/"] parameters:dict headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if([responseObject[@"status"] integerValue]==0 ){
                NSLog(@"获取评论数和收藏数失败");
            }
            else{
                NSDictionary* dict_info=responseObject[@"success_message"];
                self.commentNum=dict_info[@"comment_count"];
                self.collectNum=dict_info[@"collect_count"];
                NSLog(@"%@,%@",self.commentNum,self.collectNum);
                //存入本地sqlite数据库中
                sqlite3 *db;
                NSString *dbRootPath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                NSString *fileName=[dbRootPath stringByAppendingPathComponent:@"competition.db"];
//                NSString *fileName=[[NSBundle mainBundle]pathForResource:@"competition.db" ofType:nil];
                const char *cFileName=fileName.UTF8String;
                int result=sqlite3_open(cFileName, &db);
                if(result==SQLITE_OK){
                    NSLog(@"更新当前竞赛评论和收藏数时成功打开数据库");
                    NSString *sql=[NSString stringWithFormat:@"update competition set comment_times=%@, collect_times=%@ where id=%@",self.commentNum,self.collectNum,self.cellModel.ID];
                    char *errmsg=NULL;
                    sqlite3_exec(db, sql.UTF8String, NULL, NULL, &errmsg);
                    if(errmsg){
                        NSLog(@"更新数据失败--%s",errmsg);
                    }
                    else{
                        NSLog(@"更新数据成功");
                        NSLog(@"%@", sql);
                    }
                    sqlite3_close(db);
                }
                else{
                    NSLog(@"执行更新数据命令失败");
                }
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"获取评论数和收藏数失败");
        }];
    });
}

-(void)updateCollectInfo{
    if([UserModel sharedInstance].isAnonymous){
        //匿名用户默认未收藏
        self.bottomV.collectImg.image=[UIImage imageNamed:@"noCollect"];
        self.hasCollected=NO;
    }
    else{
        //向服务器发送消息
//        self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
//        self.hud.mode=MBProgressHUDModeIndeterminate;
        
        //设置超时时间为3s
        AFHTTPSessionManager *manager=[AFHTTPSessionManager manager];
        manager.requestSerializer.timeoutInterval=3.f;
        NSDictionary *dict=@{
                             @"competitionID":self.cellModel.ID,
                             @"userID":[UserModel sharedInstance].userID
                             };
        [manager POST:[ipAddress stringByAppendingString:@"check_collect_cmp/"] parameters:dict headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//            [MBProgressHUD hideHUDForView:self.view animated:YES];
            NSLog(@"%@",responseObject[@"error_message"]);
            if([responseObject[@"status"] integerValue]==0 ){
                //加载失败默认未收藏
                self.bottomV.collectImg.image=[UIImage imageNamed:@"noCollect"];
                self.hasCollected=NO;
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            }
            else{
                NSLog(@"%@",responseObject[@"hasCollected"]);
                //查询成功，根据user收藏状态改变图标和BOOL数据
                if([responseObject[@"hasCollected"] boolValue]){
                    //属性为true说明该用户已收藏了该比赛
                    self.bottomV.collectImg.image=[UIImage imageNamed:@"yesCollect"];
                    self.hasCollected=YES;
                }
                else{
                    self.bottomV.collectImg.image=[UIImage imageNamed:@"noCollect"];
                    self.hasCollected=NO;
                }
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }];
        
    }
}

-(void)collectImgOnClickListener:(UITapGestureRecognizer *)recognizer{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if([UserModel sharedInstance].isAnonymous){
        //匿名提示无法收藏
        self.hud=[MBProgressHUD showHUDAddedTo:window animated:YES];
        self.hud.mode=MBProgressHUDModeText;
        self.hud.labelText=@"匿名用户无法收藏竞赛";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:window animated:YES];
        });
    }
    else{
        //向服务器发送消息
        self.hud=[MBProgressHUD showHUDAddedTo:window animated:YES];
        self.hud.mode=MBProgressHUDModeIndeterminate;
        
        //设置超时时间为3s
        self.manager.requestSerializer.timeoutInterval=3.f;
        NSDictionary *dict=@{
                             @"competitionID":self.cellModel.ID,
                             @"userID":[UserModel sharedInstance].userID
                             };
        [self.manager POST:[ipAddress stringByAppendingString:@"collect_cmp/"] parameters:dict headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [MBProgressHUD hideHUDForView:window animated:YES];
            if([responseObject[@"status"] integerValue]==0){
                //操作失败
                NSLog(@"%@",responseObject[@"error_message"]);
                
                //加载失败提示Hub
                self.hud=[MBProgressHUD showHUDAddedTo:window animated:YES];
                self.hud.mode=MBProgressHUDModeText;
                self.hud.labelText=responseObject[@"error_message"];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:window animated:YES];
                });
            }
            else{
                //加载成功提示Hub
                self.hud=[MBProgressHUD showHUDAddedTo:window animated:YES];
                self.hud.mode=MBProgressHUDModeText;
                NSLog(@"%@",responseObject[@"hasCollected"]);
                if([responseObject[@"hasCollected"] boolValue]){
                    //当返回的true说明已经收藏成功
                    self.bottomV.collectImg.image=[UIImage imageNamed:@"yesCollect"];
                    self.hasCollected=YES;
                    self.hud.labelText=@"收藏成功！";
                    NSLog(@"收藏成功！");
                }
                else{
                    //当返回的false说明已经取消收藏成功
                    self.bottomV.collectImg.image=[UIImage imageNamed:@"noCollect"];
                    self.hasCollected=NO;
                    self.hud.labelText=@"已取消收藏！";
                    NSLog(@"取消收藏成功！");
                }
                //更新主页面的收藏数
                [self updateCommentAndCollect];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:window animated:YES];
                });
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            NSLog(@"发送数据失败！%@",error);
            
            self.hud=[MBProgressHUD showHUDAddedTo:window animated:YES];
            self.hud.mode=MBProgressHUDModeText;
            self.hud.labelText=@"请检查联网情况!";
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:window animated:YES];
            });
        }];
    }
}

-(void)linkImgOnClickListener:(UITapGestureRecognizer *)recognizer{
    NSString *textToShare = [NSString stringWithFormat:@"%@ [%@]",self.compName.text,self.introduction.text];
    UIImage *imageToShare = self.myImage.image;
    NSURL *urlToShare = [NSURL URLWithString:self.cellModel.webpage];
    
    NSArray *activityItems = @[textToShare, imageToShare, urlToShare];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc]initWithActivityItems:activityItems applicationActivities:nil];
    activityVC.excludedActivityTypes = @[UIActivityTypePostToFacebook,UIActivityTypeAirDrop,UIActivityTypeSaveToCameraRoll];
    [self presentViewController:activityVC animated:YES completion:nil];
}

-(void)commentViewOnClickListener:(UITapGestureRecognizer *)recognizer{
    NSLog(@"点击了评论");
    //从下往上显示commentView
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    self.commentView=[[[NSBundle mainBundle]loadNibNamed:@"CommentSend" owner:nil options:nil]lastObject];
    self.test.inputAccessoryView = self.commentView;
    [self.test becomeFirstResponder];
}

-(void)refreshTableView:(NSNotification *) notification{
    [self ShowComment];
}

- (void)dealloc {
    //移除观察者
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}
-(void)viewDidDisappear:(BOOL)animated{
    //重新显示上面的bar
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

-(void)ShowComment{
    //查看该比赛的评论
    self.manager=[AFHTTPSessionManager manager];
    //向服务器发送消息
    self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.mode=MBProgressHUDModeIndeterminate;
    //self.hud.label.text=@"正在刷新评论，请稍后";
    self.manager.requestSerializer.timeoutInterval=30.f;
    //cellModel.image为比赛ID*****
    NSDictionary *dict=@{@"competition":self.cellModel.image};
    [self.manager POST:[ipAddress stringByAppendingString:@"return_comment/"]
       parameters:dict headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
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
            NSLog(@"加载评论成功");
            //加载成功提示Hub
            NSArray *rootComment=responseObject[@"success_message"];
            //获得根评论数
            self.numOfComment= [NSString stringWithFormat: @"%lu", (unsigned long)rootComment.count];
            //数组字典转数组模型
            self.commentArray=[NSMutableArray array];
            for (int i=0; i<(unsigned long)rootComment.count; ++i) {
                CommentCellModel *tmpModel=[[CommentCellModel alloc]init];
                tmpModel.children=(rootComment[i])[@"children"];
                tmpModel.competition=(rootComment[i])[@"competition"];
                tmpModel.content=(rootComment[i])[@"content"];
                tmpModel.creationTime=(rootComment[i])[@"creationTime"];
                tmpModel.commentId=(rootComment[i])[@"commentId"];
                tmpModel.parent=(rootComment[i])[@"parent"];
                tmpModel.user=(rootComment[i])[@"user"];
                tmpModel.userName=(rootComment[i])[@"userName"];
                tmpModel.receiveName=(rootComment[i])[@"receiveName"];
                tmpModel.root=(rootComment[i])[@"root"];
                
//                NSURL *url=[NSURL URLWithString:[[@"http://119.23.190.159:8000/static/compress_images/" stringByAppendingString:tmpModel.user] stringByAppendingString:@"Image.png"]];
                
                NSURL *url=[NSURL URLWithString:[[[ipAddress stringByAppendingString:@"static/profiles/"] stringByAppendingString:tmpModel.user]stringByAppendingString:@"Image.png"]];
                NSData *imageData=[NSData dataWithContentsOfURL:url];
                
                if(tmpModel.children.count!=0){
//                    url=[NSURL URLWithString:[[@"http://119.23.190.159:8000/static/compress_images/" stringByAppendingString:(tmpModel.children[0])[@"user"]] stringByAppendingString:@"Image.png"]];
                    url=[NSURL URLWithString:[[[ipAddress stringByAppendingString:@"static/profiles/"] stringByAppendingString:(tmpModel.children[0])[@"user"]] stringByAppendingString:@"Image.png"]];
                    NSData *imageData2=[NSData dataWithContentsOfURL:url];
                    tmpModel.childProfile=imageData2;
                }
                
                NSLog(@"%@",tmpModel.children);
                tmpModel.profile=imageData;
                
                [self.commentArray addObject:tmpModel];
            }
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

-(void)changeFirstResponder{
    [self.commentView.contentTextView becomeFirstResponder];
    [self.replyView.replyContent becomeFirstResponder];
}

-(void)hideCommentView{
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.commentView.contentTextView resignFirstResponder];
    [self.replyView.replyContent resignFirstResponder];
    [self.test resignFirstResponder];
    
    //更新主页面的评论数
    [self updateCommentAndCollect];
}

//-(void)showMoreReplyView:(NSNotification *) notification{
//    CommentCell *cell=notification.object;
//    [self.view addSubview:cell.moreReplyView];
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //取消第一响应
    [self resignFirstResponder];
    
     self.tableView.estimatedRowHeight=200;
    self.tableView.rowHeight=UITableViewAutomaticDimension;
    //监听打开评论动作调出键盘
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeFirstResponder) name:UITextFieldTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeFirstResponder) name:UIKeyboardDidShowNotification object:nil];
    //监听关闭CommentView消息
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideCommentView) name:@"hideCommentView" object:nil];
    //监听是否更新评论数据
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTableView:) name:@"sendComment" object:nil];
    
    //监听是否要回复某个子评论
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(replyChild:) name:@"replyChild" object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMoreReplyView:) name:@"showMoreReplyView" object:nil];
    
    //更新评论
    [self ShowComment];
    //查看该用户是否收藏了比赛
    [self updateCollectInfo];
    
    //添加buttonView
    self.bottomV =[[[NSBundle mainBundle]loadNibNamed:@"BottomView" owner:nil options:nil] lastObject];
    [self.tabBarController.tabBar addSubview:self.bottomV];
    self.bottomV.frame=CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 47);
    self.test=self.bottomV.test;
    self.test.delegate=self;
    //设置bottomV的图片点击响应
    //self.bottomV.userInteractionEnabled=YES;
    self.bottomV.collectImg.userInteractionEnabled=YES;
    self.bottomV.linkImg.userInteractionEnabled=YES;
    self.bottomV.commentView.userInteractionEnabled=YES;
    
    UITapGestureRecognizer *collectImgOnClick= [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(collectImgOnClickListener:)];
    [self.bottomV.collectImg addGestureRecognizer:collectImgOnClick];

    UITapGestureRecognizer *linkImgOnClick= [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(linkImgOnClickListener:)];
    [self.bottomV.linkImg addGestureRecognizer:linkImgOnClick];
    
    UITapGestureRecognizer *commentViewOnClick= [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(commentViewOnClickListener:)];
    [self.bottomV.commentView addGestureRecognizer:commentViewOnClick];
    
    
    self.tableView.delaysContentTouches = NO;
    self.introduction.text=self.introductionText;
    
    NSString *cachePath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *imagePath=[[cachePath stringByAppendingPathComponent:self.cellModel.image] stringByAppendingString:@".png"];
    
    NSData *imageData=[NSData dataWithContentsOfFile:imagePath];
    UIImage *imagePic=[UIImage imageWithData:imageData];
    self.myImage.image=imagePic;
    
    [self.webEnterBtn addTarget:self action:@selector(buttonBackGroundNormal:) forControlEvents:UIControlEventTouchUpInside];
    [self.webEnterBtn addTarget:self action:@selector(buttonBackGroundHighlighted:) forControlEvents:UIControlEventTouchDown];
    [self.webEnterBtn addTarget:self action:@selector(buttonBackGroundNormal:) forControlEvents:UIControlEventTouchUpOutside];

    
    //监听commentView是否有获取当前比赛ID请求
    NSNotificationCenter *center=[NSNotificationCenter defaultCenter];
    //给消息发布者回复比赛ID
    [center addObserver:self selector:@selector(sendCompetitonID:) name:@"getCompetitionID" object:nil];
    
    
    //在用户偏好上增加此次访问记录
    if(![UserModel sharedInstance].isAnonymous){
        NSString *documentsPath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *plistPath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_PreferencesList.plist",[UserModel sharedInstance].userID]];
        NSMutableArray *competition_favor=[NSMutableArray arrayWithContentsOfFile:plistPath];
        NSLog(@"%@",plistPath);
        NSLog(@"比赛偏好：%@",competition_favor);
        if(competition_favor==nil){
            competition_favor=[[NSMutableArray alloc]init];
            [competition_favor addObject:self.cellModel.ID];
            NSLog(@"比赛偏好：%@",competition_favor);
            [competition_favor writeToFile:plistPath atomically:YES];
        }
        else{
            BOOL hasExisted=NO;
            for (NSString *comID in competition_favor) {
                if(self.cellModel.ID==comID){
                    [competition_favor removeObject:comID];
                    [competition_favor addObject:self.cellModel.ID];
                    [competition_favor writeToFile:plistPath atomically:YES];
                    hasExisted=YES;
                    break;
                }
            }
            if(!hasExisted){
                if(competition_favor.count==10){
                    [competition_favor removeObjectAtIndex:0];
                    [competition_favor addObject:self.cellModel.ID];
                }
                else{
                    [competition_favor addObject:self.cellModel.ID];
                }
                [competition_favor writeToFile:plistPath atomically:YES];
            }
        }
    }
    
}
//给消息发布者回复比赛ID
-(void)sendCompetitonID:(NSNotification *)note{
    CommentSend *tmp=note.object;
    tmp.competitionID=self.cellModel.image;
}

////实现通知方法
//- (void)textDidChanged
//{
//    self.commentView.sendCommentBtn.enabled = self.commentView.contentTextView.text.length > 0;;
//}
//


////移除通知监听者
//- (void)dealloc
//{
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//}



-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self hideCommentView];
    
    
    
    //0.1s后取消选中
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    });
}

- (void)buttonBackGroundNormal:(UIButton *)sender{
    sender.backgroundColor = [UIColor orangeColor];
}

- (void)buttonBackGroundHighlighted:(UIButton *)sender{
    sender.backgroundColor = [UIColor purpleColor];
}

-(void)setCellModel:(CompetitionCellModel *)cellModel{
    _cellModel=cellModel;
    self.navigationItem.title=cellModel.name;
}

//title初始化
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if(section==0){
        NSString *title=[NSString stringWithFormat:@"竞赛种类：%@",self.cellModel.type];
        return title;
    }
    else{
        return @"评论";
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if(section==0){
        return 30;
    }
    else return 10;
}

-(void)viewDidLayoutSubviews{
    self.compName.text=self.cellModel.name;
//    if(self.cellModel.image ==nil){
//        self.myImage.image=[UIImage imageNamed:@"defaultImage"];
//    }
//    else{
//        self.myImage.image=[UIImage imageNamed:self.cellModel.image];
//    }
    self.numOfComment=self.cellModel.numOfComment;
    self.web=self.cellModel.webpage;
}

- (IBAction)enterWeb {
    self.hidesBottomBarWhenPushed = YES;
    [self performSegueWithIdentifier:@"enterWebview" sender:nil];
    self.hidesBottomBarWhenPushed = NO;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"enterWebview"]){
        WebVC *theWebVC=(WebVC *)segue.destinationViewController;
        theWebVC.cellModel=self.cellModel;
    }
}

#pragma mark - Table view data source

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(section == 1){
        //动态cell
        return [self.numOfComment integerValue];
    }
    return [super tableView:tableView numberOfRowsInSection:section];

}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section == 1){
        //动态cell
        CommentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"commentCellID"];
        if(!cell){
            cell = [[NSBundle mainBundle] loadNibNamed:@"CommentCell" owner:nil options:nil].lastObject;
            cell.userInteractionEnabled=YES;
            
            cell.commentModel=self.commentArray[indexPath.row];
        }
        //为cell里的rootCommentTextField添加点击手势
        UITapGestureRecognizer *rootCommentTextFieldTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(rootCommentTouchUpInside:)];
        [cell.rootCommentTextField addGestureRecognizer:rootCommentTextFieldTapGestureRecognizer];
        [cell.rootCommentTextField setTag:indexPath.row];
        
        UITapGestureRecognizer *childCommentTextFieldTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(childCommentTouchUpInside:)];
        [cell.childCommentTextField addGestureRecognizer:childCommentTextFieldTapGestureRecognizer];
        [cell.childCommentTextField setTag:indexPath.row];
        return cell;
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

-(void) childCommentTouchUpInside:(UITapGestureRecognizer *)recognizer{
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    UILabel *rootComment=(UILabel*)recognizer.view;
    NSUInteger tag = rootComment.tag;
    
    self.replyView=[[[NSBundle mainBundle]loadNibNamed:@"ReplyView" owner:nil options:nil]lastObject];
    CommentCellModel *model=self.commentArray[tag];
    NSArray *childArr=model.children;
    self.replyView.fatherName.text=(childArr[0])[@"userName"];
//    CommentCellModel *tmp= model.children[0];
//    self.replyView.fatherName.text=tmp.userName;
    self.replyView.user=[UserModel sharedInstance].userID;
    self.replyView.parent=(childArr[0])[@"commentId"];
    NSLog(@"%@",self.replyView.parent);
    self.replyView.root=model.commentId;
    self.replyView.competition=model.competition;
    
    self.test.inputAccessoryView = self.replyView;
    [self.test becomeFirstResponder];
}

-(void) rootCommentTouchUpInside:(UITapGestureRecognizer *)recognizer{
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    UILabel *rootComment=(UILabel*)recognizer.view;
    NSUInteger tag = rootComment.tag;
    
    //从下往上显示commentView
    self.replyView=[[[NSBundle mainBundle]loadNibNamed:@"ReplyView" owner:nil options:nil]lastObject];
    CommentCellModel *model=self.commentArray[tag];
    self.replyView.fatherName.text=model.userName;
    self.replyView.user=[UserModel sharedInstance].userID;
    self.replyView.parent=model.commentId;
    self.replyView.root=model.commentId;
    NSLog(@"%@==%@==%@",model.userName,model.commentId,self.replyView.root);
    self.replyView.competition=model.competition;
    self.test.inputAccessoryView = self.replyView;
    [self.test becomeFirstResponder];
}

-(void)replyChild:(NSNotification *) notification{
    
    MoreReplyCell *cell=[notification object];
    
    self.replyView=[[[NSBundle mainBundle]loadNibNamed:@"ReplyView" owner:nil options:nil]lastObject];
    CommentCellModel *model=cell.commentModel;
    self.replyView.fatherName.text=model.userName;
    self.replyView.user=[UserModel sharedInstance].userID;
    self.replyView.parent=model.commentId;
    NSLog(@"%@",self.replyView.parent);
    self.replyView.root=model.root;
    NSLog(@"%@",self.replyView.root);
    self.replyView.competition=model.competition;
    
    self.test.inputAccessoryView = self.replyView;
    [self.test becomeFirstResponder];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section==0&&indexPath.row==1){
        NSDictionary *textAttribute=@{NSFontAttributeName:[UIFont systemFontOfSize:15]};
        CGSize textSize=CGSizeMake(333, MAXFLOAT);
        CGFloat contentH=[self.introduction.text boundingRectWithSize:textSize options:NSStringDrawingUsesLineFragmentOrigin attributes:textAttribute context:nil].size.height;
        return contentH+240;
    }
    if(indexPath.section == 1){
        //动态cell
        CommentCellModel *tmp=self.commentArray[indexPath.row];
        return tmp.cellHeight;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section == 1){
        //动态cell
        return [super tableView:tableView indentationLevelForRowAtIndexPath: [NSIndexPath indexPathForRow:0 inSection:1]];
    }
    return [super tableView:tableView indentationLevelForRowAtIndexPath:indexPath];
}





/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

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
