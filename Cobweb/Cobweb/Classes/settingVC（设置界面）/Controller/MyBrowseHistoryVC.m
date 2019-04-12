//
//  MyBrowseHistoryVC.m
//  Cobweb
//
//  Created by zyp on 2019/4/10.
//  Copyright © 2019 solist. All rights reserved.
//

#import "MyBrowseHistoryVC.h"
#import "UserModel.h"
#import "AFNetworking.h"
#import "MBProgressHUD.h"
#import "CompetitionCell.h"
#import "CompetitionCellModel.h"
#import <sqlite3.h>
#import "CompetitionDetail.h"
#import "setting.h"

@interface MyBrowseHistoryVC ()
@property(strong, nonatomic) NSMutableArray *cmpArray;
@property(strong, nonatomic) NSMutableArray *cmpModelArray;
@property(assign,nonatomic) sqlite3 *db;

@property (strong, nonatomic) MBProgressHUD *hud;

//内存缓存
@property(strong,nonatomic) NSMutableDictionary *imagesMemory;
//子线程（下载图片）
@property(strong,nonatomic) NSOperationQueue *queue;

@end

@implementation MyBrowseHistoryVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //初始化可变数组
    self.cmpArray=[NSMutableArray array];
    self.cmpModelArray=[NSMutableArray array];
    
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]){
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
    
    [self showMyBrowseHistory];
    [self.tableView reloadData];
}

-(void)showMyBrowseHistory{
    NSString *documentsPath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *plistPath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_PreferencesList.plist",[UserModel sharedInstance].userID]];
    NSMutableArray *competition_favor=[NSMutableArray arrayWithContentsOfFile:plistPath];
    if(competition_favor==nil){
        
    }
    else{
        //逆序排列preferences数组
        for(int i=(int)competition_favor.count-1;i>=0;--i){
            [self.cmpArray addObject:competition_favor[i]];
        }
        //self.cmpArray=[[competition_favor reverseObjectEnumerator] allObjects];
        NSInteger cmpCount=self.cmpArray.count;
        if(cmpCount>0){
            //从sqlite数据库找到匹配的比赛Model
            NSString *fileName=[[NSBundle mainBundle]pathForResource:@"competition.db" ofType:nil];
            const char *cFileName=fileName.UTF8String;
            int result=sqlite3_open(cFileName, &_db);
            if(result==SQLITE_OK){
                NSLog(@"成功打开数据库");
                //查询字符串拼接
                NSString *sql=@"select * from competition where ";
                for(int i=0;i<cmpCount;++i){
                    sql=[[sql stringByAppendingString:@"id="]stringByAppendingString:
                         [self.cmpArray[i] description]];
                    sqlite3_stmt *stmt=nil;
                    result=sqlite3_prepare_v2(self.db, [sql UTF8String], -1,&stmt, nil);
                    if(result==SQLITE_OK){
                        while (sqlite3_step(stmt)==SQLITE_ROW){
                            const unsigned char *ID=sqlite3_column_text(stmt, 0);
                            NSString *modelID=[NSString stringWithUTF8String:(const char*)ID];
                            
                            const unsigned char *name=sqlite3_column_text(stmt, 1);
                            NSString *modelName=[NSString stringWithUTF8String:(const char*)name];
                            
                            const unsigned char *type=sqlite3_column_text(stmt, 2);
                            NSString *modelType=[NSString stringWithUTF8String:(const char*)type];
                            
                            const unsigned char *date=sqlite3_column_text(stmt, 3);
                            NSString *modelDate=[NSString stringWithUTF8String:(const char*)date];
                            
                            const unsigned char *numOfCollection=sqlite3_column_text(stmt, 4);
                            NSString *modelNumOfCollection=[NSString stringWithUTF8String:(const char*)numOfCollection];
                            
                            const unsigned char *numOfComment=sqlite3_column_text(stmt, 5);
                            NSString *modelNumOfComment=[NSString stringWithUTF8String:(const char*)numOfComment];
                            
                            const unsigned char *webpage=sqlite3_column_text(stmt, 6);
                            NSString *modelWebpage;
                            if(webpage==nil){
                                modelWebpage=@"";
                            }
                            else{
                                modelWebpage=[NSString stringWithUTF8String:(const char*)webpage];
                            }
                            
                            const unsigned char *introduction=sqlite3_column_text(stmt, 7);
                            NSString *modelIntroduction=[NSString stringWithUTF8String:(const char*)introduction];
                            
                            CompetitionCellModel *tmp=[[CompetitionCellModel alloc]init];
                            tmp.ID=modelID;
                            tmp.image=modelID;
                            tmp.name=modelName;
                            tmp.type=modelType;
                            tmp.date=modelDate;
                            tmp.numOfCollection=modelNumOfCollection;
                            tmp.numOfComment=modelNumOfComment;
                            tmp.webpage=modelWebpage;
                            tmp.introduction=modelIntroduction;
                            [self.cmpModelArray addObject:tmp];
                        }
                    }
                    else{
                        NSLog(@"查询失败");
                    }
                    
                    //为下一次查询数据库做准备
                    sql=@"select * from competition where ";
                }
                sqlite3_close(self.db);
            }
            else{
                NSLog(@"打开数据库失败");
            }
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cmpModelArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    //动态cell
    CompetitionCell *cell;
    if(self.cmpModelArray.count==0){
        cell = [tableView dequeueReusableCellWithIdentifier:@"BlankCellID"];
        
    }
    else{
        cell = [tableView dequeueReusableCellWithIdentifier:@"CompetitionCellID"];
    }
    if(!cell){
        if(self.cmpModelArray.count==0){
            cell = [[NSBundle mainBundle] loadNibNamed:@"BlankCell" owner:nil options:nil].lastObject;
            cell.selectionStyle=UITableViewCellSelectionStyleNone;
            cell.userInteractionEnabled=NO;
        }
        else{
            cell = [[NSBundle mainBundle] loadNibNamed:@"CompetitionCell" owner:nil options:nil].lastObject;
            cell.cellModel=self.cmpModelArray[indexPath.row];
            
            
            //获取评论数
            
            //从服务器下载图片
            //先去查看内存缓存中该图片是否已经存在，如果存在就直接用，否则再去下载/从cache中读取
            UIImage *image=[self.imagesMemory objectForKey:cell.cellModel.image];
            if(image){
                //图片存在
                cell.CompetitionImage.image=image;
            }
            else{
                //内存中不存在
                
                //检查沙盒是否有缓存
                NSString *cachePath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
                NSString *imagePath=[[cachePath stringByAppendingPathComponent:cell.cellModel.image] stringByAppendingString:@".png"];
                NSData *imageData=[NSData dataWithContentsOfFile:imagePath];
                if(imageData){
                    //沙盒中有数据
                    image=[UIImage imageWithData:imageData];
                    cell.CompetitionImage.image=image;
                    
                    //保存图片到内存缓存
                    [self.imagesMemory setObject:image forKey:cell.cellModel.image];
                }
                else{
                    //无缓存
                    
                    //开子线程下载图片
                    self.queue=[[NSOperationQueue alloc]init];
                    NSBlockOperation *download=[NSBlockOperation blockOperationWithBlock:^{
                        //                            NSURL *url=[NSURL URLWithString:[[@"http://119.23.190.159:8000/static/competition_images/" stringByAppendingString:cell.cellModel.image] stringByAppendingString:@".png"]];
                        NSURL *url=[NSURL URLWithString:[[[ipAddress stringByAppendingString:@"static/competition_images/"]stringByAppendingString:cell.cellModel.image]stringByAppendingString:@".png"]];
                        
                        NSData *imageData=[NSData dataWithContentsOfURL:url];
                        UIImage *image=[UIImage imageWithData:imageData];
                        
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            cell.CompetitionImage.image=image;
                        }];
                        
                        
                        //保存图片到内存缓存
                        [self.imagesMemory setObject:image forKey:cell.cellModel.image];
                        
                        //保存图片到沙盒缓存
                        [imageData writeToFile:imagePath atomically:YES];
                    }];
                    
                    [self.queue addOperation:download];
                    
                }
            }
            cell.selectionStyle=UITableViewCellSelectionStyleDefault;
            cell.userInteractionEnabled=YES;
        }
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 100;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //0.1s后取消选中
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
    
    [self performSegueWithIdentifier:@"detail" sender:nil];
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"detail"]){
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        CompetitionCellModel *nowModel=self.cmpModelArray[indexPath.row];
        
        
        CompetitionDetail *detailVC=(CompetitionDetail *)segue.destinationViewController;
        detailVC.cellModel=nowModel;
        
        detailVC.introductionText=nowModel.introduction;
        //NSLog(@"%@",detailVC.introduction.text);
    }
}


@end
