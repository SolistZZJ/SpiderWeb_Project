//
//  TeamCell.m
//  Cobweb
//
//  Created by solist on 2019/3/13.
//  Copyright © 2019 solist. All rights reserved.
//

#import "setting.h"
#import "TeamCell.h"
#import "UserModel.h"
#import <sqlite3.h>
#import "MJExtension.h"


@interface TeamCell ()
@property (weak, nonatomic) IBOutlet UILabel *competitionName;
@property (weak, nonatomic) IBOutlet UILabel *captainName;
@property (weak, nonatomic) IBOutlet UILabel *numOfTeam;
@property (weak, nonatomic) IBOutlet UILabel *introduction;
@property (weak, nonatomic) IBOutlet UIImageView *captainImage;

@property (weak, nonatomic) IBOutlet UIView *applyHintView;

@property (strong, nonatomic) NSArray *memberList;

//子线程（下载图片）
@property(strong,nonatomic) NSOperationQueue *queue;
@end

@implementation TeamCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
}

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
                NSString *comName=[NSString stringWithUTF8String:(const char*)competitionName];
                self.competitionName.text=[NSString stringWithFormat:@"%@(%@)",self.teamModel.teamName,comName];
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

    self.applyHintView.hidden=YES;
    
    self.memberList=[UserModel mj_objectArrayWithKeyValuesArray:teamModel.join_list];
    
    self.competitionName.text=teamModel.competition;
    
    [self sqliteOperate:teamModel.competition];
    
    self.captainName.text=[NSString stringWithFormat:@"队长:%@",teamModel.captain.userName];
    self.numOfTeam.text=[NSString stringWithFormat:@"当前人数:%ld/%ld",(long)teamModel.nowNum,(long)teamModel.maxNum];
    
    if(teamModel.isAllTeam){
        //《所有队伍》界面的请求
        self.introduction.text=[NSString stringWithFormat:@"队伍宣言：%@",teamModel.introduction];
        
        //计算cellHeight
        CGFloat introductionY=CGRectGetMaxY(self.numOfTeam.frame)+40;
        CGFloat introductionX=5;
        NSDictionary *textAttribute=@{NSFontAttributeName:[UIFont systemFontOfSize:16]};
        CGSize textSize=CGSizeMake([UIScreen mainScreen].bounds.size.width-10, MAXFLOAT);
        CGFloat introductionH=[self.introduction.text boundingRectWithSize:textSize options:NSStringDrawingUsesLineFragmentOrigin attributes:textAttribute context:nil].size.height;
        CGFloat introductionW=[UIScreen mainScreen].bounds.size.width-10;
        self.introduction.frame=CGRectMake(introductionX, introductionY, introductionW, introductionH);
        
        //_teamModel.cellHeight=introductionH+introductionY;
        _teamModel.cellHeight=CGRectGetMaxY(self.introduction.frame);
    }
    else{
        //《我的队伍》界面的请求
        self.introduction.text=@"";
        self.introduction.hidden=YES;
        
        //当自己是队长时，且有人申请入队时，cell下方变红
        if(teamModel.captain.userID==[UserModel sharedInstance].userID){
            if(self.memberList.count>0){
                self.applyHintView.hidden=NO;
            }
        }
    }
    
    
    
    //图片待续
    NSString *imagePath=[[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]stringByAppendingPathComponent:teamModel.captain.userID] stringByAppendingString:@"Image.png"];
    self.captainImage.image=[UIImage imageWithContentsOfFile:imagePath];
    self.captainImage.layer.cornerRadius=30;
    self.captainImage.layer.masksToBounds=YES;
    if(!self.captainImage.image){
        //如果在本地找不到图片从网上下载
        //开子线程下载图片
        self.queue=[[NSOperationQueue alloc]init];
        NSBlockOperation *download=[NSBlockOperation blockOperationWithBlock:^{
            NSURL *url=[NSURL URLWithString:[[[ipAddress stringByAppendingString:@"static/compress_images/"]stringByAppendingString:teamModel.captain.userID]stringByAppendingString:@"Image.png"]];
            
            NSData *imageData=[NSData dataWithContentsOfURL:url];
            UIImage *image=[UIImage imageWithData:imageData];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self.captainImage.image=image;
                self.captainImage.layer.cornerRadius=30;
                self.captainImage.layer.masksToBounds=YES;
                
                //保存图片到沙盒缓存
                [imageData writeToFile:imagePath atomically:YES];
            }];
            
        }];
        
        [self.queue addOperation:download];
    }
}



- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setFrame:(CGRect)frame
{
    frame.origin.x = 10;//这里间距为10，可以根据自己的情况调整
    frame.size.width -= 2 * frame.origin.x;
    frame.size.height -= 2 * frame.origin.x;
    [super setFrame:frame];
}


@end
