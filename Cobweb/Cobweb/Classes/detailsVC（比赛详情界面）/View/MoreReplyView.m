//
//  MoreReplyView.m
//  Cobweb
//
//  Created by solist on 2019/3/11.
//  Copyright © 2019 solist. All rights reserved.
//

#import "MoreReplyView.h"
#import "MoreReplyCell.h"
#import "MJExtension.h"

@interface MoreReplyView ()<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *replyTableView;

@end

@implementation MoreReplyView

-(void)awakeFromNib{
    [super awakeFromNib];
    self.replyTableView.delegate=self;
    self.replyTableView.dataSource=self;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(closeChildComment) name:@"closeReplyView" object:nil];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}



-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section==0){
        return 1;
    }
    else{
        return self.childrenNum;
    }
}

//-(NSInteger)numberOfRowsInSection:(NSInteger)section{
//    if(section==0){
//        return 1;
//    }
//    else{
//        return self.childrenNum;
//    }
//}




-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section==0){
        //主评论
        MoreReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:@"moreReplyCellID"];
        if(!cell){
            cell = [[NSBundle mainBundle] loadNibNamed:@"MoreReplyCell" owner:nil options:nil].lastObject;
            cell.userInteractionEnabled=YES;
            cell.isMainComment=YES;
            cell.commentModel=self.mainComment;
            
        }
        return cell;
    }
    else{
        //子评论（二级评论）
        MoreReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:@"moreReplyCellID"];
        if(!cell){
            cell = [[NSBundle mainBundle] loadNibNamed:@"MoreReplyCell" owner:nil options:nil].lastObject;
            cell.userInteractionEnabled=YES;
            cell.isMainComment=NO;
            cell.commentModel=self.childInfoArray[indexPath.row];
            NSLog(@"%@", cell.commentModel);
        }
        return cell;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section==0){
        CommentCellModel *tmp=self.mainComment;
        return tmp.cellHeight;
    }
    else{
        CommentCellModel *tmp=self.childInfoArray[indexPath.row];
        return tmp.cellHeight;
    }
}

//-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
//    if(section==0){
//        return [NSString stringWithFormat:@"%ld条回复",(long)self.childrenNum];
//    }
//    else{
//        return @"";
//    }
//}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if(section==0){
        return 40;
    }
    else{
        return 15;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    NSLog(@"%ld",(long)section);
    if(section==0){
        UIView *mainCommentHeaderView=[[UIView alloc]init];
        UIButton *returnBtn=[[UIButton alloc]initWithFrame:CGRectMake(0, 0, 40, 40)];
        [returnBtn setImage:[UIImage imageNamed:@"returnBtn_normal"] forState:UIControlStateNormal];
        [returnBtn setImage:[UIImage imageNamed:@"returnBtn_highlight"] forState:UIControlStateHighlighted];
        [mainCommentHeaderView addSubview:returnBtn];
        
        [returnBtn addTarget:self action:@selector(closeChildComment) forControlEvents:UIControlEventTouchUpInside];
        
        UILabel *label=[[UILabel alloc]initWithFrame:CGRectMake(150, 0, 80, 40)];
        label.font=[UIFont boldSystemFontOfSize:17];
        label.text=@"评论详情";
        [mainCommentHeaderView addSubview:label];

        return mainCommentHeaderView;
    }
    else{
        UIView *childCommentHeaderView=[[UIView alloc]init];
        UILabel *label=[[UILabel alloc]initWithFrame:CGRectMake(10, -15, 100, 30)];
        label.font=[UIFont boldSystemFontOfSize:15];
        label.text=[NSString stringWithFormat:@"%ld条回复",(long)self.childrenNum];
        [childCommentHeaderView addSubview:label];

        return childCommentHeaderView;
    }
}

//关闭子评论
-(void) closeChildComment{
    [UIView animateWithDuration:0.5 animations:^{
        self.frame=CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    } completion:^(BOOL finished) {
        self.hidden=YES;
    }];
    
}



-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
//    if(indexPath.section==0){
//        //点击主评论
//        NSLog(@"点击主评论");
//        MoreReplyCell * cell = [tableView cellForRowAtIndexPath:indexPath];
//        [[NSNotificationCenter defaultCenter]postNotificationName:@"replyChild" object:cell];
//    }
//    else{
//        //点击子评论
//        NSLog(@"点击子评论");
//        [[NSNotificationCenter defaultCenter]postNotificationName:@"replyChild" object:nil];
//    }
    MoreReplyCell * cell = [tableView cellForRowAtIndexPath:indexPath];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"replyChild" object:cell];
}

@end
