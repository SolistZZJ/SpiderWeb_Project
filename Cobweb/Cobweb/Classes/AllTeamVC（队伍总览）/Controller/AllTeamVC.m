//
//  AllTeamVC.m
//  Cobweb
//
//  Created by solist on 2019/3/13.
//  Copyright © 2019 solist. All rights reserved.
//
#import "setting.h"
#import "AllTeamVC.h"
#import "TeamCell.h"
#import "AFNetworking.h"
#import "MBProgressHUD.h"
#import "MJExtension.h"
#import "TeamDetailVC.h"
#import "MJRefresh.h"
#import "MJAllTeamHeader.h"
#import "MJAllTeamFooter.h"
#import "ZZJ_PageView.h"
#import "XDSDropDownMenu.h"
#import <sqlite3.h>


@interface AllTeamVC ()<UISearchBarDelegate, XDSDropDownMenuDelegate>
@property (strong, nonatomic) MBProgressHUD *hud;

@property(nonatomic,strong) UISearchBar *searchBar;

//@property(nonatomic,assign) NSInteger numOfComp;
@property(nonatomic,assign) NSString *prev;

@property(nonatomic,strong) NSArray *allTeams;

@property(nonatomic,strong) AFHTTPSessionManager *manager;

@property(nonatomic,assign) BOOL showRefrechBtn;
@property(nonatomic,strong) MJAllTeamHeader *header;
@property(nonatomic,strong) MJAllTeamFooter *footer;

@property (weak, nonatomic) IBOutlet UIView *contentV;
@property(nonatomic,strong) ZZJ_PageView *pageView;

@property (weak, nonatomic) IBOutlet UIButton *downButton;
@property (strong, nonatomic) XDSDropDownMenu *downDropDownMenu;
@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSString *keyWord;
@end

@implementation AllTeamVC

//-(void)viewWillAppear:(BOOL)animated{
//    self.page=1;
//    [self showAllTeam];
//}


- (void)cancelRequest
{
    if ([self.manager.tasks count] > 0) {
        NSLog(@"返回时取消网络请求");
        [self.manager.tasks.firstObject cancel];
    }
}



-(void)updateTeamData{
    self.manager=[AFHTTPSessionManager manager];
    self.type=@"所有比赛";
    self.keyWord=@"";
    //向服务器发送消息
    //设置等待时间为20s
    self.manager.requestSerializer.timeoutInterval=20.f;
    NSDictionary *dict=@{@"prev": @""};
    [self.manager POST:[ipAddress stringByAppendingString:@"return_teamlist/"] parameters:dict headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if([responseObject[@"status"] integerValue]==0){
            //操作失败
            [self.header endRefreshing];
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
            
            //字典数组转换为模型数组
            [TeamModel mj_setupObjectClassInArray:^NSDictionary *{
                return @{@"captain":[UserModel class]};
            }];
            self.allTeams=[NSArray array];
            self.allTeams=[self.allTeams arrayByAddingObjectsFromArray:[TeamModel mj_objectArrayWithKeyValuesArray: responseObject[@"success_message"]]];

            //更新数据
            self.showRefrechBtn=YES;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.header endRefreshing];
                [self.tableView reloadData];
                
                TeamModel *tmp=self.allTeams.lastObject;
                self.prev=tmp.teamID;
            });
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"发送数据失败！%@",error);
        [self.header endRefreshing];
        self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.mode=MBProgressHUDModeText;
        self.hud.labelText=@"请检查联网情况!";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
    }];
    [self.footer resetNoMoreData];
}

#pragma mark - down按钮
- (IBAction)downBtnClick:(UIButton *)sender {
    //查询竞赛种类
    NSMutableArray *arr = [NSMutableArray array];
    [arr addObject:@"所有比赛"];
    sqlite3 *db;
    NSString *fileName=[[NSBundle mainBundle]pathForResource:@"competition.db" ofType:nil];
    const char *cFileName=fileName.UTF8String;
    int result=sqlite3_open(cFileName, &db);
    if(result==SQLITE_OK){
        NSLog(@"查询比赛Name时成功打开数据库");
        NSString *sql=@"select distinct type from competition";
        sqlite3_stmt *stmt=nil;
        result=sqlite3_prepare_v2(db, [sql UTF8String], -1,&stmt, nil);
        if(result==SQLITE_OK){
            while (sqlite3_step(stmt)==SQLITE_ROW){
                const unsigned char *competitionType=sqlite3_column_text(stmt, 0);
                NSString *type=[NSString stringWithUTF8String:(const char*)competitionType];
                [arr addObject:type];
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
    
    self.downDropDownMenu.delegate = self;//代理
    [self setupDropDownMenu:self.downDropDownMenu withTitleArray:arr andButton:sender andDirection:@"down"];
    
}

#pragma mark - 设置dropDownMenu

/*
 判断是显示dropDownMenu还是收回dropDownMenu
 */

- (void)setupDropDownMenu:(XDSDropDownMenu *)dropDownMenu withTitleArray:(NSArray *)titleArray andButton:(UIButton *)button andDirection:(NSString *)direction{
    //    CGRect btnFrame = button.frame; //如果按钮在UIIiew上用这个
    CGRect btnFrame = [self getBtnFrame:button];//如果按钮在UITabelView上用这个
    if(dropDownMenu.tag == 1000){
        
        /*
         如果dropDownMenu的tag值为1000，表示dropDownMenu没有打开，则打开dropDownMenu
         */
        
        //初始化选择菜单
        [dropDownMenu showDropDownMenu:button withButtonFrame:btnFrame arrayOfTitle:titleArray arrayOfImage:nil animationDirection:direction];
        
        //添加到主视图上
        [self.view addSubview:dropDownMenu];
        
        //将dropDownMenu的tag值设为2000，表示已经打开了dropDownMenu
        dropDownMenu.tag = 2000;
        
    }else {
        
        /*
         如果dropDownMenu的tag值为2000，表示dropDownMenu已经打开，则隐藏dropDownMenu
         */
        
        [dropDownMenu hideDropDownMenuWithBtnFrame:btnFrame];
        dropDownMenu.tag = 1000;
    }
}

#pragma mark - 隐藏其它DropDownMenu
/*
 在点击按钮的时候，隐藏其它打开的下拉菜单（dropDownMenu）
 */
- (void)hideDropDownMenu:(XDSDropDownMenu *)dropDownMenu{
    CGRect btnFrame = [self getBtnFrame:self.downButton];
    
    [self.downDropDownMenu hideDropDownMenuWithBtnFrame:btnFrame];
    self.downDropDownMenu.tag = 1000;
}

#pragma mark - 获取按钮在self.view的坐标(按钮在UITableView上使用这个方法)
/*
 因为按钮在UITableView上是放在cell的contentView上的，所以要通过以下方法获得其在self.view上坐标
 */

- (CGRect )getBtnFrame:(UIButton *)button{
    return [button.superview convertRect:CGRectMake(button.frame.origin.x, button.frame.origin.y+10, 150, 30) toView:self.view];
}

#pragma mark - 下拉菜单代理
/*
 在点击下拉菜单后，将其tag值重新设为1000
 */

- (void) setDropDownDelegate:(XDSDropDownMenu *)sender{
    sender.tag = 1000;
}

#pragma mark - 设置按钮边框和圆角
- (void)setButtons{
    self.downButton.layer.cornerRadius = 3;
    self.downButton.layer.borderColor = [[UIColor blackColor] CGColor];
    self.downButton.layer.borderWidth = 0.5;
    self.downButton.layer.masksToBounds = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];

}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    //刷新轮播图
    NSArray *imageNames=@[@"slideshow0",@"slideshow1",@"slideshow2",@"slideshow3",@"slideshow4",@"slideshow5"];
    self.pageView=[ZZJ_PageView pageView];
    self.pageView.imageNames=imageNames;
    self.pageView.backgroundColor=[UIColor grayColor];
    [self.contentV addSubview:self.pageView];
    
    
    CGRect frame = self.tableView.tableHeaderView.frame;
    frame.size.height = 1;
    UIView *headerView = [[UIView alloc] initWithFrame:frame];
    [self.tableView setTableHeaderView:headerView];

    //头部刷新
    self.header=[MJAllTeamHeader headerWithRefreshingTarget:self refreshingAction:@selector(updateTeamData)];
    // 设置刷新控件
    self.header.lastUpdatedTimeLabel.hidden=YES;
    self.header.gifView.hidden=YES;
    [self.header setTitle:@"刷新队伍中 ..." forState:MJRefreshStateRefreshing];
    [self.header setTitle:@"↓释放更新队伍" forState:MJRefreshStatePulling];
    [self.header setTitle:@"↑上拉更新队伍" forState:MJRefreshStateIdle];
    self.tableView.mj_header = self.header;

    //尾部刷新
    self.footer=[MJAllTeamFooter footerWithRefreshingTarget:self refreshingAction:@selector(showAllTeam)];
    self.footer.gifView.hidden=YES;
    [self.footer setTitle:@"刷新队伍中 ..." forState:MJRefreshStateRefreshing];
    [self.footer setTitle:@"↑松开查看更多" forState:MJRefreshStatePulling];
    [self.footer setTitle:@"↓下拉查看更多" forState:MJRefreshStateIdle];
    [self.footer setTitle:@"已加载所有队伍" forState:MJRefreshStateNoMoreData];
    self.tableView.mj_footer=self.footer;


    self.showRefrechBtn=false;
    self.tableView.delaysContentTouches=NO;
    //初始化数组
    self.allTeams=[NSMutableArray array];
    self.prev=@"";



    //初始化searchBars界面属性
    self.downDropDownMenu=[[XDSDropDownMenu alloc] init];
    self.downDropDownMenu.tag=1000;
    self.downButton.titleLabel.text=@"所有比赛";
    [self setButtons];//设置按钮边框和圆角

    UIView *searchTextField = nil;
    self.searchBar=[[UISearchBar alloc]init];
    self.searchBar.barTintColor=[UIColor whiteColor];
    searchTextField = [[[self.searchBar.subviews firstObject] subviews] lastObject];

    searchTextField.backgroundColor=[UIColor grayColor];
    searchTextField.alpha=0.5;
    self.searchBar.placeholder=@"填写队伍名/队长名";
    UITextField * searchField = [_searchBar valueForKey:@"_searchField"];
    [searchField setValue:[UIColor whiteColor] forKeyPath:@"_placeholderLabel.textColor"];
    [searchField setValue:[UIFont boldSystemFontOfSize:12] forKeyPath:@"_placeholderLabel.font"];
    searchField.textColor = [UIColor whiteColor];
    [self.searchBar addSubview:searchTextField];
    [self.searchBar setBackgroundColor:[UIColor blackColor]];
    self.navigationItem.titleView=self.searchBar;

    //添加搜索按钮
    UIBarButtonItem *rightBtn=[[UIBarButtonItem alloc]initWithImage:[self reSizeImage:[UIImage imageNamed:@"search"] toSize:CGSizeMake(30, 30)] style:UIBarButtonItemStyleDone target:self action:@selector(searchCompTeam)];
    rightBtn.tintColor=[UIColor whiteColor];
    self.navigationItem.rightBarButtonItem=rightBtn;

    //searchBar设置代理
    self.searchBar.delegate=self;

    //初始化搜索状态
    self.type=self.downButton.titleLabel.text;
    self.keyWord=self.searchBar.text;
    
    [self showAllTeam];

    
}
- (UIImage *)reSizeImage:(UIImage *)image toSize:(CGSize)reSize
{
    UIGraphicsBeginImageContext(CGSizeMake(reSize.width, reSize.height));
    [image drawInRect:CGRectMake(0, 0, reSize.width, reSize.height)];
    UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [reSizeImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

-(void)searchCompTeam{
    [self.searchBar resignFirstResponder];
    [self.footer resetNoMoreData];
    self.type=self.downButton.titleLabel.text;
    self.keyWord=self.searchBar.text;
    
    //向服务器发送消息
    self.manager=[AFHTTPSessionManager manager];
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    self.hud=[MBProgressHUD showHUDAddedTo:window animated:YES];
    self.hud.mode=MBProgressHUDModeIndeterminate;
    //设置等待时间为20s
    self.manager.requestSerializer.timeoutInterval=20.f;
    NSDictionary *dict;
    if([self.type isEqualToString:@"所有比赛"]){
        dict=@{
               @"keyWord":self.keyWord
               };
    }
    else{
        dict=@{
               @"type":self.type,
               @"keyWord":self.keyWord
               };
    }
    NSLog(@"type:%@",self.type);
    
    [self.manager POST:[ipAddress stringByAppendingString:@"find_team/"] parameters:dict headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [MBProgressHUD hideHUDForView:window animated:YES];
        if([responseObject[@"status"] integerValue]==0){
            //操作失败
            [self.footer endRefreshing];
            NSLog(@"%@",responseObject[@"error_message"]);
            
            //加载失败提示Hub
            self.hud=[MBProgressHUD showHUDAddedTo:window animated:YES];
            self.hud.mode=MBProgressHUDModeText;
            self.hud.labelText=responseObject[@"error_message"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:window animated:YES];
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
            
            if(self.allTeams.count<10){
                //第一次刷新
                [self.tableView reloadData];
                TeamModel *tmp=self.allTeams.lastObject;
                self.prev=tmp.teamID;
                [self.footer endRefreshingWithNoMoreData];
            }
            else if(self.allTeams.count==10){
                //第一次刷新
                [self.tableView reloadData];
                TeamModel *tmp=self.allTeams.lastObject;
                self.prev=tmp.teamID;
            }
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [MBProgressHUD hideHUDForView:window animated:YES];
        [self.footer endRefreshing];
        NSLog(@"发送数据失败！%@",error);
        
        self.hud=[MBProgressHUD showHUDAddedTo:window animated:YES];
        self.hud.mode=MBProgressHUDModeText;
        self.hud.labelText=@"请检查联网情况!";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:window animated:YES];
        });
    }];
}

//搜索事件代理
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [self searchCompTeam];
}

-(void)showAllTeam{
    //UIWindow *window = [UIApplication sharedApplication].keyWindow;
    //查看该用户的目前的队伍
    self.manager=[AFHTTPSessionManager manager];
    //向服务器发送消息
    self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.mode=MBProgressHUDModeIndeterminate;
    
    //设置等待时间为20s
    self.manager.requestSerializer.timeoutInterval=20.f;
    if([self.type isEqualToString:@"所有比赛"]&&[self.keyWord isEqualToString:@""]){
        NSDictionary *dict=@{@"prev": self.prev,
                             };
        [self.manager POST:[ipAddress stringByAppendingString:@"return_teamlist/"] parameters:dict headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if([responseObject[@"status"] integerValue]==0){
                //操作失败
                [self.footer endRefreshing];
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
                //字典数组转换为模型数组
                [TeamModel mj_setupObjectClassInArray:^NSDictionary *{
                    return @{@"captain":[UserModel class]};
                }];
                
                NSInteger preCount=self.allTeams.count;
                self.allTeams=[self.allTeams arrayByAddingObjectsFromArray:[TeamModel mj_objectArrayWithKeyValuesArray: responseObject[@"success_message"]]];
                
                if(self.allTeams.count<10){
                    //第一次刷新
                    [self.tableView reloadData];
                    TeamModel *tmp=self.allTeams.lastObject;
                    self.prev=tmp.teamID;
                    [self.footer endRefreshingWithNoMoreData];
                }
                else if(self.allTeams.count==10){
                    //第一次刷新
                    [self.tableView reloadData];
                    TeamModel *tmp=self.allTeams.lastObject;
                    self.prev=tmp.teamID;
                }
                else{
                    //非第一次刷新
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self.footer endRefreshing];
                        [self.tableView reloadData];
                        TeamModel *tmp=self.allTeams.lastObject;
                        self.prev=tmp.teamID;
                        
                        //更新数据
                        if(self.allTeams.count%10==0){
                            if(preCount==self.allTeams.count){
                                //刚好以发送包的尾部结尾，如果下次发送的数据和这次一样说明无可刷新队伍
                                [self.footer endRefreshingWithNoMoreData];
                            }
                        }
                        else{
                            [self.footer endRefreshingWithNoMoreData];
                        }
                    });
                    
                }
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [self.footer endRefreshing];
            NSLog(@"发送数据失败！%@",error);
            
            self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
            self.hud.mode=MBProgressHUDModeText;
            self.hud.labelText=@"请检查联网情况!";
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
        }];
    }
    else{
        NSDictionary *dict;
        if([self.type isEqualToString:@"所有比赛"]){
            dict=@{@"prev": self.prev,
                   @"keyWord": self.keyWord
                   };
        }
        else{
            dict=@{@"prev": self.prev,
                   @"type": self.type,
                   @"keyWord": self.keyWord
                   };
        }
        NSLog(@"%@",dict);
        [self.manager POST:[ipAddress stringByAppendingString:@"find_team/"] parameters:dict headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if([responseObject[@"status"] integerValue]==0){
                //操作失败
                [self.footer endRefreshing];
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
                //字典数组转换为模型数组
                [TeamModel mj_setupObjectClassInArray:^NSDictionary *{
                    return @{@"captain":[UserModel class]};
                }];
                
                NSInteger preCount=self.allTeams.count;
                self.allTeams=[self.allTeams arrayByAddingObjectsFromArray:[TeamModel mj_objectArrayWithKeyValuesArray: responseObject[@"success_message"]]];
                
                if(self.allTeams.count<10){
                    //第一次刷新
                    [self.tableView reloadData];
                    TeamModel *tmp=self.allTeams.lastObject;
                    self.prev=tmp.teamID;
                    [self.footer endRefreshingWithNoMoreData];
                }
                else if(self.allTeams.count==10){
                    //第一次刷新
                    [self.tableView reloadData];
                    TeamModel *tmp=self.allTeams.lastObject;
                    self.prev=tmp.teamID;
                }
                else{
                    //非第一次刷新
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self.footer endRefreshing];
                        [self.tableView reloadData];
                        TeamModel *tmp=self.allTeams.lastObject;
                        self.prev=tmp.teamID;
                        
                        //更新数据
                        if(self.allTeams.count%10==0){
                            if(preCount==self.allTeams.count){
                                //刚好以发送包的尾部结尾，如果下次发送的数据和这次一样说明无可刷新队伍
                                [self.footer endRefreshingWithNoMoreData];
                            }
                        }
                        else{
                            [self.footer endRefreshingWithNoMoreData];
                        }
                    });
                    
                }
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [self.footer endRefreshing];
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

#pragma mark - Table view data source
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 1){
        //动态cell
        return self.allTeams.count;
    }
    return [super tableView:tableView numberOfRowsInSection:section];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section == 1){
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
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section == 1){
        //动态cell
        TeamModel *tmp=self.allTeams[indexPath.row];
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

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0;
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
// 滑动的时候回收键盘
- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView
{
    [self.searchBar resignFirstResponder];
    [self hideDropDownMenu:self.downDropDownMenu];
}
#pragma mark - Table view cell event
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.searchBar resignFirstResponder];
    [self hideDropDownMenu:self.downDropDownMenu];
    
    if(indexPath.section==1){
        [self performSegueWithIdentifier:@"teamDetail2" sender:self.allTeams[indexPath.row]];
    }
}
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    TeamDetailVC *sonView=(TeamDetailVC *)segue.destinationViewController;
    sonView.teamModel=sender;
    
}

//-(void)viewDidDisappear:(BOOL)animated{
//    //离开页面时，清空tableView
//    self.allTeams=[NSArray array];
//    [self.tableView reloadData];
//}
-(void)viewWillDisappear:(BOOL)animated{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self hideDropDownMenu:self.downDropDownMenu];
    [self cancelRequest];
}

@end
