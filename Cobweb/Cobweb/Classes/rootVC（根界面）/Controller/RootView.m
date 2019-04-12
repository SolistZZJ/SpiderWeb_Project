//
//  RootView.m
//  Cobweb
//
//  Created by solist on 2019/2/22.
//  Copyright © 2019 solist. All rights reserved.
//
#import "setting.h"
#import "RootView.h"
#import "CompetitionCell.h"
#import "CompetitionCellModel.h"
#import "CompetitionDetail.h"
#import "MJExtension.h"
#import "CommentSend.h"
#import <sqlite3.h>
#import "UserModel.h"
#import "MBProgressHUD.h"
#import "AFNetworking.h"
#import "MatchingBestTeamView.h"
#import "TeamModel.h"
#import "TeamDetailVC.h"


@interface RootView ()<UISearchBarDelegate>



@property (weak, nonatomic) IBOutlet UIScrollView *topicScrollView;

@property(strong,nonatomic) NSMutableArray *btnArr;

@property(assign,nonatomic) sqlite3 *db;

@property(strong,nonatomic) NSMutableArray *cellArray;

//内存缓存
@property(strong,nonatomic) NSMutableDictionary *imagesMemory;

//子线程（下载图片）
@property(strong,nonatomic) NSOperationQueue *queue;

@property (strong, nonatomic) CommentSend *commentView;

@property (weak, nonatomic) IBOutlet UITextField *test;

@property (strong, nonatomic) MBProgressHUD *hud;

@property(nonatomic,strong) AFHTTPSessionManager *manager;

@property (strong, nonatomic) MatchingBestTeamView *matchingView;
@end

@implementation RootView

-(NSMutableDictionary *)imagesMemory{
    if(_imagesMemory==nil){
        _imagesMemory=[NSMutableDictionary dictionary];
    }
    return _imagesMemory;
}

-(NSOperationQueue *)queue{
    if(_queue==nil)
    {
        _queue=[[NSOperationQueue alloc]init];
        //设置最大并发数
        _queue.maxConcurrentOperationCount=5;
    }
    return _queue;
}

-(void)hideCommentView{
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.commentView.contentTextView resignFirstResponder];
    [self.test resignFirstResponder];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tabBarController.tabBar.hidden = NO;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(gotoTeamDetail2:) name:@"goto_teamDetail2" object:nil];
    
    //监听关闭CommentView消息
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideCommentView) name:@"hideCommentView" object:nil];
    
    //初始化数据
    self.cellArray=[NSMutableArray array];
//    NSString *doc=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
//    NSString *fileName=[doc stringByAppendingPathComponent:@"competition.db"];
//    NSLog(@"%@",doc);
    NSString *dbRootPath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName=[dbRootPath stringByAppendingPathComponent:@"competition.db"];
//    NSString *fileName=[[NSBundle mainBundle]pathForResource:@"competition.db" ofType:nil];
    
    const char *cFileName=fileName.UTF8String;
    int result=sqlite3_open(cFileName, &_db);
    if(result==SQLITE_OK){
        NSLog(@"成功打开数据库");
        NSString *sql=@"select * from competition";
        sqlite3_stmt *stmt=nil;
        result=sqlite3_prepare_v2(self.db, [sql UTF8String], -1,&stmt, nil);
        if(result==SQLITE_OK){
            NSLog(@"查询成功");
            while (sqlite3_step(stmt)==SQLITE_ROW) {
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
                [self.cellArray addObject:tmp];
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
    
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    //初始化tableView
//    self.topicScrollView.contentSize=CGSizeMake(1500, self.topicScrollView.frame.size.height);
    self.tableView.separatorStyle = UITableViewCellEditingStyleNone; 
    self.tableView.delaysContentTouches = NO;
    self.topicScrollView.delaysContentTouches=NO;
    self.tableView.keyboardDismissMode=UIScrollViewKeyboardDismissModeOnDrag;
    
    //初始化searchBars界面属性
    UIView *searchTextField = nil;
    self.searchBar=[[UISearchBar alloc]init];
    self.searchBar.barTintColor=[UIColor whiteColor];
    searchTextField = [[[self.searchBar.subviews firstObject] subviews] lastObject];
//    searchTextField.backgroundColor=[UIColor colorWithRed:1 green:0.5 blue:0.5 alpha:1];
    searchTextField.backgroundColor=[UIColor grayColor];
    searchTextField.alpha=0.5;
    self.searchBar.placeholder=@"中国计算机设计大赛";
    UITextField * searchField = [_searchBar valueForKey:@"_searchField"];
    [searchField setValue:[UIColor whiteColor] forKeyPath:@"_placeholderLabel.textColor"];
    [searchField setValue:[UIFont boldSystemFontOfSize:12] forKeyPath:@"_placeholderLabel.font"];
    searchField.textColor = [UIColor whiteColor];
    [self.searchBar addSubview:searchTextField];
    [self.searchBar setBackgroundColor:[UIColor blackColor]];
    self.navigationItem.titleView=self.searchBar;
    //searchBar设置代理
    self.searchBar.delegate=self;
    
    
    //添加搜索按钮
    UIBarButtonItem *rightBtn=[[UIBarButtonItem alloc]initWithImage:[self reSizeImage:[UIImage imageNamed:@"search"] toSize:CGSizeMake(30, 30)] style:UIBarButtonItemStyleDone target:self action:@selector(searchComp)];
    rightBtn.tintColor=[UIColor whiteColor];
    self.navigationItem.rightBarButtonItem=rightBtn;
    
    CGFloat BtnH=30;
    CGFloat firstX=20;
    CGFloat Y=(self.topicScrollView.frame.size.height-BtnH)/2;
    self.btnArr=[[NSMutableArray alloc]init];
    
    //初始化topicScrollView
    //allBtn初始化
    UIButton *allBtn=[[UIButton alloc]initWithFrame:CGRectMake(firstX, Y, 60, BtnH)];
    [self initBtn:allBtn title:@"全部"];
    [allBtn addTarget:self action:@selector(clickAllBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.topicScrollView addSubview:allBtn];
    allBtn.enabled=NO;
    
    //ITBtn初始化
    UIButton *ITBtn=[[UIButton alloc]initWithFrame:CGRectMake(firstX+60+20, Y, 150, BtnH)];
    [self initBtn:ITBtn title:@"计算机与互联网"];
    [ITBtn addTarget:self action:@selector(clickITBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.topicScrollView addSubview:ITBtn];
    
    //SUBBtn（创业）初始化
    UIButton *SUBBtn=[[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(ITBtn.frame)+20, Y, 90, BtnH)];
    [self initBtn:SUBBtn title:@"创业大赛"];
    [SUBBtn addTarget:self action:@selector(clickSUBBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.topicScrollView addSubview:SUBBtn];
    
    //saleBtn(科技大赛)初始化
    UIButton *techBtn=[[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(SUBBtn.frame)+20, Y, 90, BtnH)];
    [self initBtn:techBtn title:@"科技大赛"];
    [techBtn addTarget:self action:@selector(clickTechBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.topicScrollView addSubview:techBtn];
    
    //financeBtn(金融比赛)初始化
    UIButton *financeBtn=[[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(techBtn.frame)+20, Y, 90, BtnH)];
    [self initBtn:financeBtn title:@"金融比赛"];
    [financeBtn addTarget:self action:@selector(clickFinanceBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.topicScrollView addSubview:financeBtn];
    
    //scienceBtn(学科学术)初始化
    UIButton *scienceBtn=[[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(financeBtn.frame)+20, Y, 90, BtnH)];
    [self initBtn:scienceBtn title:@"学科学术"];
    [scienceBtn addTarget:self action:@selector(clickScienceBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.topicScrollView addSubview:scienceBtn];
    
    //animationBtn(动漫书画)初始化
    UIButton *animationBtn=[[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(scienceBtn.frame)+20, Y, 90, BtnH)];
    [self initBtn:animationBtn title:@"动漫书画"];
    [animationBtn addTarget:self action:@selector(clickAnimationBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.topicScrollView addSubview:animationBtn];
    
    //speechBtn(动漫书画)初始化
    UIButton *speechBtn=[[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(animationBtn.frame)+20, Y, 90, BtnH)];
    [self initBtn:speechBtn title:@"动漫书画"];
    [speechBtn addTarget:self action:@selector(clickSpeechBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.topicScrollView addSubview:speechBtn];
    
    //ADBtn(动漫书画)初始化
    UIButton *ADBtn=[[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(speechBtn.frame)+20, Y, 90, BtnH)];
    [self initBtn:ADBtn title:@"广告创意"];
    [ADBtn addTarget:self action:@selector(clickADBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.topicScrollView addSubview:ADBtn];
    
    //publicBtn(公益大赛)初始化
    UIButton *publicBtn=[[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(ADBtn.frame)+20, Y, 90, BtnH)];
    [self initBtn:publicBtn title:@"公益大赛"];
    [publicBtn addTarget:self action:@selector(clickPublicBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.topicScrollView addSubview:publicBtn];
    
    //designBtn（设计大赛）初始化
    UIButton *designBtn=[[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(publicBtn.frame)+20, Y, 90, BtnH)];
    [self initBtn:designBtn title:@"设计大赛"];
    [designBtn addTarget:self action:@selector(clickDesignBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.topicScrollView addSubview:designBtn];
    
    //movieBtn(影视摄影)初始化
    UIButton *movieBtn=[[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(designBtn.frame)+20, Y, 90, BtnH)];
    [self initBtn:movieBtn title:@"影视摄影"];
    [movieBtn addTarget:self action:@selector(clickMovieBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.topicScrollView addSubview:movieBtn];
    
    self.topicScrollView.contentSize=CGSizeMake(CGRectGetMaxX(movieBtn.frame)+20, self.topicScrollView.frame.size.height);
}

-(void)initBtn:(UIButton *)btn title:(NSString *)title {
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:0.6] forState:UIControlStateDisabled];
    [btn setBackgroundColor:[UIColor colorWithWhite:0.5 alpha:0.3]];
    btn.layer.cornerRadius=15;
    [self.btnArr addObject:btn];
}

-(void)updateModelData:(NSString *)type{
    //更新模型数据
    [self.cellArray removeAllObjects];
    //打开数据库
    NSString *fileName=[[NSBundle mainBundle]pathForResource:@"competition.db" ofType:nil];
    const char *cFileName=fileName.UTF8String;
    sqlite3_open(cFileName, &_db);
    NSString *sql=[NSString stringWithFormat:@"select * from competition where type='%@'",type];

    sqlite3_stmt *stmt=nil;
    int result=sqlite3_prepare_v2(self.db, [sql UTF8String], -1,&stmt, nil);
    if(result==SQLITE_OK){
        while (sqlite3_step(stmt)==SQLITE_ROW) {
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
            [self.cellArray addObject:tmp];
            NSLog(@"%@",modelName);
        }
        [self.tableView reloadData];
    }
    else{
        NSLog(@"查询失败");
    }
    sqlite3_close(self.db);
}

-(void)clickAllBtn:(UIButton *)btn {
    [self updateBtn:self.btnArr];
    btn.enabled=NO;
    
    //更新模型数据
    [self.cellArray removeAllObjects];
    NSString *sql=@"select * from competition";
    
    sqlite3_stmt *stmt=nil;
    int result=sqlite3_prepare_v2(self.db, [sql UTF8String], -1,&stmt, nil);
    if(result==SQLITE_OK){
        while (sqlite3_step(stmt)==SQLITE_ROW) {
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
            CompetitionCellModel *tmp=[[CompetitionCellModel alloc]init];
            tmp.ID=modelID;
            tmp.image=modelID;
            tmp.name=modelName;
            tmp.type=modelType;
            tmp.date=modelDate;
            tmp.numOfCollection=modelNumOfCollection;
            tmp.numOfComment=modelNumOfComment;
            tmp.webpage=modelWebpage;
            [self.cellArray addObject:tmp];
        }
        [self.tableView reloadData];
    }
    else{
        NSLog(@"查询失败");
    }
}

-(void)clickITBtn:(UIButton *)btn {
    [self updateBtn:self.btnArr];
    btn.enabled=NO;
    
    //更新模型数据
    [self updateModelData:@"计算机与互联网"];
}

-(void)clickSUBBtn:(UIButton *)btn {
    [self updateBtn:self.btnArr];
    btn.enabled=NO;
    //更新模型数据
    [self updateModelData:@"创业大赛"];
}

-(void)clickTechBtn:(UIButton *)btn {
    [self updateBtn:self.btnArr];
    btn.enabled=NO;
    //更新模型数据
    [self updateModelData:@"科技大赛"];
}

-(void)clickFinanceBtn:(UIButton *)btn {
    [self updateBtn:self.btnArr];
    btn.enabled=NO;
    //更新模型数据
    [self updateModelData:@"金融比赛"];
}

-(void)clickScienceBtn:(UIButton *)btn {
    [self updateBtn:self.btnArr];
    btn.enabled=NO;
    //更新模型数据
    [self updateModelData:@"学科学术"];
}

-(void)clickAnimationBtn:(UIButton *)btn {
    [self updateBtn:self.btnArr];
    btn.enabled=NO;
    //更新模型数据
    [self updateModelData:@"动漫书画"];
}

-(void)clickSpeechBtn:(UIButton *)btn {
    [self updateBtn:self.btnArr];
    btn.enabled=NO;
    //更新模型数据
    [self updateModelData:@"文学演讲"];
}

-(void)clickADBtn:(UIButton *)btn {
    [self updateBtn:self.btnArr];
    btn.enabled=NO;
    //更新模型数据
    [self updateModelData:@"广告创意"];
}

-(void)clickPublicBtn:(UIButton *)btn {
    [self updateBtn:self.btnArr];
    btn.enabled=NO;
    //更新模型数据
    [self updateModelData:@"公益大赛"];
}

-(void)clickDesignBtn:(UIButton *)btn {
    [self updateBtn:self.btnArr];
    btn.enabled=NO;
    //更新模型数据
    [self updateModelData:@"设计大赛"];
}

-(void)clickMovieBtn:(UIButton *)btn {
    [self updateBtn:self.btnArr];
    btn.enabled=NO;
    //更新模型数据
    [self updateModelData:@"影视摄影"];
}

-(void)updateBtn:(NSArray *)btnArr {
    for (UIButton* btn in btnArr) {
        btn.enabled=YES;
    }
}

//搜索事件代理
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [self searchComp];
}

- (UIImage *)reSizeImage:(UIImage *)image toSize:(CGSize)reSize
{
    UIGraphicsBeginImageContext(CGSizeMake(reSize.width, reSize.height));
    [image drawInRect:CGRectMake(0, 0, reSize.width, reSize.height)];
    UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [reSizeImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}






-(void)searchComp{
    //若打开了寻队窗口则关闭
    [self closeMatchingView];
    [self.searchBar resignFirstResponder];
    NSString *fileName=[[NSBundle mainBundle]pathForResource:@"competition.db" ofType:nil];
    const char *cFileName=fileName.UTF8String;
    int result=sqlite3_open(cFileName, &_db);
    if(result==SQLITE_OK){
        NSLog(@"连接数据库成功");
        [self updateBtn:self.btnArr];
        
        //更新模型数据
        [self.cellArray removeAllObjects];
        NSString *keyText=self.searchBar.text;
        NSString *sql=[NSString stringWithFormat:@"select * from competition where name like '%%%@%%'",keyText];
        
        sqlite3_stmt *stmt=nil;
        int result=sqlite3_prepare_v2(self.db, [sql UTF8String], -1,&stmt, nil);
        if(result==SQLITE_OK){
            while (sqlite3_step(stmt)==SQLITE_ROW) {
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
                [self.cellArray addObject:tmp];
            }
            [self.tableView reloadData];
            
        }
        else{
            
            NSLog(@"查询失败");
        }
        
        sqlite3_close(self.db);
    }
    else{
        NSLog(@"连接数据库失败");
    }
}






#pragma mark - Table view data source

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(section == 1){
        //动态cell
        if(self.cellArray.count==0){
            return 1;
        }
        else{
            return self.cellArray.count;
        }
        //return self.cellArray.count;
    }
    return [super tableView:tableView numberOfRowsInSection:section];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section == 1){
        //动态cell
        CompetitionCell *cell;
        if(self.cellArray.count==0){
            cell = [tableView dequeueReusableCellWithIdentifier:@"BlankCellID"];

        }
        else{
           cell = [tableView dequeueReusableCellWithIdentifier:@"CompetitionCellID"];
        }
        if(!cell){
            if(self.cellArray.count==0){
                cell = [[NSBundle mainBundle] loadNibNamed:@"BlankCell" owner:nil options:nil].lastObject;
                cell.selectionStyle=UITableViewCellSelectionStyleNone;
                cell.userInteractionEnabled=NO;
            }
            else{
                cell = [[NSBundle mainBundle] loadNibNamed:@"CompetitionCell" owner:nil options:nil].lastObject;
                cell.cellModel=self.cellArray[indexPath.row];
                
                
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
        
        
//        CompetitionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CompetitionCellID"];
//        if(!cell){
//            cell = [[NSBundle mainBundle] loadNibNamed:@"CompetitionCell" owner:nil options:nil].lastObject;
//            cell.cellModel=self.cellArray[indexPath.row];
//            cell.selectionStyle=UITableViewCellSelectionStyleDefault;
//            cell.userInteractionEnabled=YES;
//        }
        
        return cell;
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section == 1){
        //动态cell
        return 100;
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

-(void)collectOrNot:(NSIndexPath *)indexPath{
    CompetitionCellModel *nowModel=self.cellArray[indexPath.row];
    NSString *competitionID=nowModel.ID;
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
        self.manager=[AFHTTPSessionManager manager];
        self.manager.requestSerializer.timeoutInterval=10.f;
        NSDictionary *dict=@{
                             @"competitionID":competitionID,
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
                    self.hud.labelText=@"收藏成功！";
                    NSLog(@"收藏成功！");
                }
                else{
                    //当返回的false说明已经取消收藏成功

                    self.hud.labelText=@"已取消收藏！";
                    NSLog(@"取消收藏成功！");
                }
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

-(void)commentSend:(NSIndexPath *)indexPath{
    CompetitionCellModel *nowModel=self.cellArray[indexPath.row];
    NSString *competitionID=nowModel.ID;
    
    self.commentView=[[[NSBundle mainBundle]loadNibNamed:@"CommentSend" owner:nil options:nil]lastObject];
    self.commentView.competitionID=competitionID;
    self.test.inputAccessoryView = self.commentView;
    [self.test becomeFirstResponder];
    [self.commentView.contentTextView becomeFirstResponder];
}

-(UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if(indexPath.section==1){
        UIContextualAction *commentAction=[UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"评论" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [self commentSend:indexPath];
        }];
        commentAction.image=[UIImage imageNamed:@"writeComment2"];
        commentAction.backgroundColor=[UIColor orangeColor];
        
        UIContextualAction *collectAction=[UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"收藏" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [self collectOrNot:indexPath];
        }];
        collectAction.image=[UIImage imageNamed:@"collection2"];
        collectAction.backgroundColor=[UIColor brownColor];
        
        
        UISwipeActionsConfiguration *config=[UISwipeActionsConfiguration configurationWithActions:@[collectAction,commentAction]];
        return config;
    }
    UISwipeActionsConfiguration *config=nil;
    return config;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section==0) {
        return NO;
    }
    return YES;
}




//- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (indexPath.section==0) {
//        return UITableViewCellEditingStyleNone;
//    }
//    return UITableViewCellEditingStyleInsert;
//}



#pragma mark - Table view cell event
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.searchBar resignFirstResponder];
    
    if(indexPath.section == 1){
        [self performSegueWithIdentifier:@"detail" sender:nil];
    }
}




- (IBAction)recommend {
    if(![UserModel sharedInstance].isAnonymous){
        //根据用户注册时选择的爱好以及最近浏览的来进行推荐
        //更新模型数据
        [self.cellArray removeAllObjects];
        //打开数据库
        NSString *dbRootPath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *fileName=[dbRootPath stringByAppendingPathComponent:@"competition.db"];
//        NSString *fileName=[[NSBundle mainBundle]pathForResource:@"competition.db" ofType:nil];
        const char *cFileName=fileName.UTF8String;
        int result=sqlite3_open(cFileName, &_db);
        //查看用户最近浏览的比赛类型
        NSString *documentsPath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *plistPath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_PreferencesList.plist",[UserModel sharedInstance].userID]];
        NSMutableArray *competition_favor=[NSMutableArray arrayWithContentsOfFile:plistPath];
        //用来存用户经常访问的type的可变数组
        NSMutableArray *typeArr=[NSMutableArray array];
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
        sqlite3_stmt *stmt=nil;
        result=sqlite3_prepare_v2(self.db, [sql UTF8String], -1,&stmt, nil);
        if(result==SQLITE_OK){
            while (sqlite3_step(stmt)==SQLITE_ROW){
                const unsigned char *type=sqlite3_column_text(stmt, 0);
                NSString *modelType=[NSString stringWithUTF8String:(const char*)type];
                [typeArr addObject:modelType];
            }
        }
        else{
            NSLog(@"查询失败");
        }
        //对收集到的typeArr进行查询显示
        sql=@"select distinct * from competition where ";
        for(int i=0;i<typeArr.count;++i){
            if(i==0){
                //第一个字符不加or
                sql=[[[sql stringByAppendingString:@"type='"]stringByAppendingString:
                      [typeArr[i] description]]stringByAppendingString:@"'"] ;
            }
            else{
                sql=[[[sql stringByAppendingString:@" or type='"]stringByAppendingString:[typeArr[i] description]] stringByAppendingString:@"'"];
            }
        }
        for(int i=0;i<[UserModel sharedInstance].hobbies.count;++i){
            sql=[[[sql stringByAppendingString:@" or name like'%%"]stringByAppendingString:[[UserModel sharedInstance].hobbies[i] description]] stringByAppendingString:@"%%'"];
            NSLog(@"***%@***,",[UserModel sharedInstance].hobbies[i]);
        }
        stmt=nil;
        result=sqlite3_prepare_v2(self.db, [sql UTF8String], -1,&stmt, nil);
        if(result==SQLITE_OK){
            while (sqlite3_step(stmt)==SQLITE_ROW) {
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
                [self.cellArray addObject:tmp];
                NSLog(@"%@",modelName);
            }
            [self updateBtn:self.btnArr];
            [self.tableView reloadData];
        }
        else{
            NSLog(@"查询失败");
        }
        sqlite3_close(self.db);
    }
    else{
        //匿名用户推荐
    }
}

- (IBAction)allCmp {
    
}

- (IBAction)searchPartner {
    if([UserModel sharedInstance].isAnonymous){
        self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.mode=MBProgressHUDModeText;
        self.hud.labelText=@"抱歉，匿名下无法使用该功能～";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
    }
    else{
        self.matchingView=[[NSBundle mainBundle] loadNibNamed:@"MatchingBestTeamView" owner:nil options:nil].lastObject;
        self.matchingView.hidden=NO;
        self.matchingView.frame=CGRectMake(-([UIScreen mainScreen].bounds.size.width), 80, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-127);
        UIWindow * window = [UIApplication sharedApplication].keyWindow;
        [window addSubview:self.matchingView];
        [UIView animateWithDuration:0.5 animations:^{
            self.matchingView.frame=CGRectMake(0, 80, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-127);
        } completion:nil];
    }

}

-(void)viewWillAppear:(BOOL)animated{
    dispatch_queue_t queue =dispatch_queue_create("concurrent",DISPATCH_QUEUE_CONCURRENT);
    dispatch_sync(queue, ^{
        [self updateModelData_asyn];
    });
}

-(void)updateModelData_asyn{
    //更新模型数据
    [self.cellArray removeAllObjects];
    //打开数据库
    NSString *dbRootPath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName=[dbRootPath stringByAppendingPathComponent:@"competition.db"];
//    NSString *fileName=[[NSBundle mainBundle]pathForResource:@"competition.db" ofType:nil];
    const char *cFileName=fileName.UTF8String;
    sqlite3_open(cFileName, &_db);
    NSString *sql=@"select * from competition";
    
    sqlite3_stmt *stmt=nil;
    int result=sqlite3_prepare_v2(self.db, [sql UTF8String], -1,&stmt, nil);
    if(result==SQLITE_OK){
        while (sqlite3_step(stmt)==SQLITE_ROW) {
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
            [self.cellArray addObject:tmp];
            NSLog(@"%@",modelName);
        }
        [self.tableView reloadData];
    }
    else{
        NSLog(@"查询失败");
    }
    sqlite3_close(self.db);
}

-(void)viewWillDisappear:(BOOL)animated{
    [self closeMatchingView];
}

-(void) closeMatchingView{
    [UIView animateWithDuration:0.5 animations:^{
        self.matchingView.frame=CGRectMake(-([UIScreen mainScreen].bounds.size.width), 80, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-127);
    } completion:^(BOOL finished) {
        self.matchingView.hidden=YES;
    }];
}
//[self performSegueWithIdentifier:@"teamDetail2" sender:self.allTeams[indexPath.row]];
-(void)gotoTeamDetail2:(NSNotification *)notification{
    TeamModel *tmp=(TeamModel *)notification.object;
    NSLog(@"%@",tmp.introduction);
    [self performSegueWithIdentifier:@"teamDetail2" sender:tmp];
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"detail"]){
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        CompetitionCellModel *nowModel=self.cellArray[indexPath.row];
        
        
        CompetitionDetail *detailVC=(CompetitionDetail *)segue.destinationViewController;
        detailVC.cellModel=nowModel;
        
        detailVC.introductionText=nowModel.introduction;
        //NSLog(@"%@",detailVC.introduction.text);
    }
    else{
        TeamDetailVC *sonView=(TeamDetailVC *)segue.destinationViewController;
        sonView.teamModel=sender;
    }
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
