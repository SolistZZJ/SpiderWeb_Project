//
//  ApplyRequestVC.m
//  Cobweb
//
//  Created by solist on 2019/3/22.
//  Copyright © 2019 solist. All rights reserved.
//

#import "ApplyRequestVC.h"
#import "ApplyListCell.h"
#import "UserModel.h"
@interface ApplyRequestVC ()

@end

@implementation ApplyRequestVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    //接收消息更新cell
//    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updateApplyData:) name:@"updateApplyData" object:nil];
    
}

-(void)viewWillAppear:(BOOL)animated{
    //接收消息更新cell
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updateApplyData:) name:@"updateApplyData" object:nil];
    
    [self.tableView reloadData];
}

-(void)updateApplyData:(NSNotification *)notification{
    NSDictionary * infoDic = [notification object];
    NSString *userID=infoDic[@"userID"];
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
    
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.applyList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ApplyListCell *cell=[tableView dequeueReusableCellWithIdentifier:@"ApplyListCellID"];
    if(!cell){
        cell=[[NSBundle mainBundle]loadNibNamed:@"ApplyListCell" owner:nil options:nil].lastObject;
        UserModel *tmp=self.applyList[indexPath.row];
        cell.applicantInfo=tmp;
        cell.teamID=self.teamID;
        cell.conversationID=self.conversationID;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 155;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return [NSString stringWithFormat: @"申请名单(%ld人)",self.applyList.count];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
//    //0.1s后取消选中
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
//    });
    
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
- (void)dealloc {
    //移除观察者
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}
@end
