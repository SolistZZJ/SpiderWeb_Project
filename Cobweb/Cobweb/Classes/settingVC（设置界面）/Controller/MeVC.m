//
//  MeVC.m
//  Cobweb
//
//  Created by solist on 2019/2/26.
//  Copyright © 2019 solist. All rights reserved.
//

#import "MeVC.h"
#import "AccountSettingVC.h"
#import "UserModel.h"
#import "AccountInfoVC.h"
#import "ErrorView.h"
#import "AFNetworking.h"
#import "setting.h"


@interface MeVC ()
@property(strong,nonatomic) UITapGestureRecognizer *tapGesture;


@end

@implementation MeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //发布通知消息，获取当前userAccount
//    [[NSNotificationCenter defaultCenter]postNotificationName:@"loginAccountInfo" object:self];
    self.user=[UserModel sharedInstance];
    
    //监听zmainVC中账户是否被注销
    NSNotificationCenter *center=[NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(updateLogoutAccountInfo:) name:@"updateLogoutAccountInfo" object:nil];
    [center addObserver:self selector:@selector(changeProfileImage:) name:@"changeProfileImage" object:nil];

    if(!self.user.isAnonymous){
        //更新显示的用户数据
        self.userName.text=self.user.userName;
        
        NSString *urlString =[ipAddress stringByAppendingString:@"static/profiles/"];
        NSString *picPath=[[urlString stringByAppendingString: self.user.profileImage]stringByAppendingString: @".png"];
        NSURL *picurl=[NSURL URLWithString:picPath];
        NSData *imageData=[NSData dataWithContentsOfURL:picurl];
        
        NSString *cachePath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSString *imagePath=[[cachePath stringByAppendingPathComponent:self.user.profileImage] stringByAppendingString:@".png"];
        NSLog(@"%@",imagePath);
        //保存图片到沙盒缓存
        [imageData writeToFile:imagePath atomically:YES];
        
        
//        //当用户不为游客时，加载对应的用户头像
//        NSString *fullPath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
//        NSString *imageFileName=[self.user.profileImage stringByAppendingString:@".png"];
//        NSString *finalPath=[fullPath stringByAppendingString:imageFileName];
//        NSLog(@"%@",finalPath);
//        self.profileImage.image=[UIImage imageWithContentsOfFile:finalPath];
        self.profileImage.image=[UIImage imageWithData:imageData];
        [self.profileImage.layer setCornerRadius:CGRectGetHeight([self.profileImage bounds])/2];
        self.profileImage.layer.masksToBounds=YES;
    }
    else{
        [self.profileImage.layer setCornerRadius:CGRectGetHeight([self.profileImage bounds])/2];
        self.profileImage.layer.masksToBounds=YES;
        self.userName.text=@"未登录";
    }
    //添加头像点击事件
    self.profileImage.userInteractionEnabled = YES;
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickImage:)];
    [self.profileImage addGestureRecognizer:self.tapGesture];
}

#pragma mark - LoginView
-(void)clickImage:(UIGestureRecognizer *)recognizer{
    if(self.user.isAnonymous){
        [self performSegueWithIdentifier:@"login" sender:nil];
    }else{
        //打开账号设置界面
        [self performSegueWithIdentifier:@"settingAccount" sender:nil];
    }
}

-(void)setting{
    if(self.user.isAnonymous){
        [self performSegueWithIdentifier:@"login" sender:nil];
    }else{
        //打开账号设置界面
        [self performSegueWithIdentifier:@"settingAccount" sender:nil];
    }
}

-(void)changeProfileImage:(NSNotification *)note{
    AccountInfoVC *infoVC=note.object;
    self.profileImage.image=infoVC.compressImg;
}

-(void)updateLogoutAccountInfo:(NSNotification *)note{
    self.userName.text=@"未登录";
    self.profileImage.image=[UIImage imageNamed:@"anonymous"];
}

-(void)dealloc{
    //移除通知
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    //0.1s后取消选中
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
    if(self.user.isAnonymous&&indexPath.section==1){
        //初始化提示框
        ErrorView *errorInfo=[[NSBundle mainBundle]loadNibNamed:@"ErrorView" owner:nil options:nil][0];
        [errorInfo setText:(@"请先登录")];
        errorInfo.layer.cornerRadius=10;
        errorInfo.alpha=0;
        [self.view addSubview:errorInfo];
        errorInfo.center=CGPointMake(errorInfo.superview.center.x,errorInfo.superview.center.y);
        
        //设置动画，动画结束后提示框消失
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            errorInfo.alpha=1;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.5 delay:1.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                errorInfo.alpha=0;
            } completion:^(BOOL finished){
                [errorInfo removeFromSuperview];
            }];
        }];
    }
    else{
        if(indexPath.section==1&&indexPath.row==1){
            //点击了我的队伍
            [self performSegueWithIdentifier:@"myTeam" sender:nil];
        }
        else if(indexPath.section==1&&indexPath.row==0){
            //点击了收藏
            [self performSegueWithIdentifier:@"showMyCollectCmp" sender:nil];
        }
        else if(indexPath.section==1&&indexPath.row==2){
            //点击了最近浏览
            [self performSegueWithIdentifier:@"showMyBrowseHistory" sender:nil];
        }
        else if(indexPath.section==2&&indexPath.row==0&&!self.user.isAnonymous)
        {
            //注册用户点击设置
            [self setting];
        }
        else if(indexPath.section==2&&indexPath.row==0&&self.user.isAnonymous)
        {
            //匿名点击设置
            [self performSegueWithIdentifier:@"login" sender:nil];
        }
    }
    
}

- (IBAction)setting:(id)sender {
    if(self.user.isAnonymous){
        [self performSegueWithIdentifier:@"login" sender:nil];
    }
    else{
        [self setting];
    }
}


//#pragma mark - Table view data source
//
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Incomplete implementation, return the number of sections
//    return 0;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete implementation, return the number of rows
//    return 0;
//}

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
