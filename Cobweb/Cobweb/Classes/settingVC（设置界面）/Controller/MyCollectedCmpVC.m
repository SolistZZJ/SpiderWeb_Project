//
//  MyCollectedCmpVC.m
//  Cobweb
//
//  Created by solist on 2019/3/26.
//  Copyright © 2019 solist. All rights reserved.
//

#import "MyCollectedCmpVC.h"
#import "UserModel.h"
#import "AFNetworking.h"
#import "MBProgressHUD.h"
#import "CompetitionCell.h"
#import "CompetitionCellModel.h"
#import <sqlite3.h>
#import "CompetitionDetail.h"
#import "setting.h"

@interface MyCollectedCmpVC ()

@property(strong, nonatomic) NSMutableArray *cmpArray;
@property(strong, nonatomic) NSMutableArray *cmpModelArray;
@property(assign,nonatomic) sqlite3 *db;

@property (strong, nonatomic) MBProgressHUD *hud;

//内存缓存
@property(strong,nonatomic) NSMutableDictionary *imagesMemory;
//子线程（下载图片）
@property(strong,nonatomic) NSOperationQueue *queue;

@end

@implementation MyCollectedCmpVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //初始化可变数组
    self.cmpArray=[NSMutableArray array];
    self.cmpModelArray=[NSMutableArray array];
    
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]){
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }

    [self showMyCollectedCmp];

}

-(void)showMyCollectedCmp{
    self.hud=[MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
    self.hud.mode=MBProgressHUDModeIndeterminate;
    
    AFHTTPSessionManager *manager=[AFHTTPSessionManager manager];
    //设置等待时间为10s
    manager.requestSerializer.timeoutInterval=10.f;
    
    [manager POST:[ipAddress stringByAppendingString:@"my_collect_cmp/"] parameters:@{@"userID":[UserModel sharedInstance].userID} headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [MBProgressHUD hideHUDForView:self.tableView animated:YES];
        if([responseObject[@"status"] integerValue]==0){
            self.hud=[MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
            self.hud.mode=MBProgressHUDModeText;
            self.hud.labelText=responseObject[@"error_message"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.tableView animated:YES];
            });
        }
        else{
            self.cmpArray=responseObject[@"success_message"];
            NSInteger cmpCount=self.cmpArray.count;
            if(cmpCount>0){
                //从sqlite数据库找到匹配的比赛Model
                NSString *fileName=[[NSBundle mainBundle]pathForResource:@"competition.db" ofType:nil];
                const char *cFileName=fileName.UTF8String;
                int result=sqlite3_open(cFileName, &_db);
                if(result==SQLITE_OK){
                    NSLog(@"成功打开数据库");
                    //查询字符串拼接
                    NSString *sql=@"select * from competition where ";;
                    for(int i=0;i<cmpCount;++i){
                        if(i==0){
                            //第一个字符不加or
                            sql=[[sql stringByAppendingString:@"id="]stringByAppendingString:
                                 [self.cmpArray[i] description]];
                        }
                        else{
                            sql=[[sql stringByAppendingString:@" or id="]stringByAppendingString:[self.cmpArray[i] description]];
                        }
                    }
                    sqlite3_stmt *stmt=nil;
                    result=sqlite3_prepare_v2(self.db, [sql UTF8String], -1,&stmt, nil);
                    if(result==SQLITE_OK){
                        NSLog(@"查询成功");
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
                        
                        [self.tableView reloadData];
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

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"detail"]){
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        CompetitionCellModel *nowModel=self.cmpModelArray[indexPath.row];
        
        
        CompetitionDetail *detailVC=(CompetitionDetail *)segue.destinationViewController;
        detailVC.cellModel=nowModel;
        
        detailVC.introductionText=nowModel.introduction;
        //NSLog(@"%@",detailVC.introduction.text);
    }
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
