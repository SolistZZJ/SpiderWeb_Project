//
//  AccountInfoVC.m
//  Cobweb
//
//  Created by solist on 2019/3/6.
//  Copyright © 2019 solist. All rights reserved.
//

#import "setting.h"
#import "AccountInfoVC.h"
#import "UserModel.h"
#import "AFNetworking.h"
#import "MBProgressHUD.h"
#import <AVFile.h>
#import <AVUser.h>
#import <LCChatKit.h>

@interface AccountInfoVC ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *myImage;

@property (weak, nonatomic) IBOutlet UILabel *userNameLB0;

@property (weak,nonatomic) IBOutlet UILabel
*userNameLB1;
@property (weak, nonatomic) IBOutlet UILabel *sexLB;
@property (weak, nonatomic) IBOutlet UILabel *universityLB;
@property (weak, nonatomic) IBOutlet UILabel *majorLB;
@property (weak, nonatomic) IBOutlet UILabel *emailLB;
@property (weak, nonatomic) IBOutlet UILabel *phoneLB;
@property (strong, nonatomic) UserModel *user;

@end

@implementation AccountInfoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.myImage.layer setCornerRadius:CGRectGetHeight([self.myImage bounds])/2];
    self.myImage.layer.masksToBounds=YES;
    self.user=[UserModel sharedInstance];
    self.compressImg=self.myImage.image;
    
    //初始化界面信息
    NSString *imagePath=[[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]stringByAppendingPathComponent:self.user.profileImage] stringByAppendingString:@".png"];
    
    NSLog(@"%@",imagePath);
    self.myImage.image=[UIImage imageWithData: [NSData dataWithContentsOfFile:imagePath]];
    self.userNameLB0.text=self.user.userName;
    self.userNameLB1.text=self.user.userName;
    self.sexLB.text=self.user.sex;
    self.universityLB.text=self.user.university;
    self.majorLB.text=self.user.major;
    self.emailLB.text=self.user.email;
    self.phoneLB.text=self.user.phone;
    
    //为头像图片添加手势
    self.myImage.userInteractionEnabled=YES;
    UITapGestureRecognizer *changeUserIconTap =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeUserIconAction:)];
    [self.myImage addGestureRecognizer:changeUserIconTap];
}

- (void)changeUserIconAction:(UITapGestureRecognizer *)tap{
    //底部弹出来个actionSheet来选择拍照或者相册选择
    UIAlertController *userIconActionSheet = [UIAlertController alertControllerWithTitle:@"请选择上传类型" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    //相册选择
    UIAlertAction *albumAction = [UIAlertAction actionWithTitle:@"手机相册选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //WKLog(@"相册选择");
        //这里加一个判断，是否是来自图片库
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]){
            
            
            UIImagePickerController * imagePicker = [[UIImagePickerController alloc]init];
            imagePicker.allowsEditing=YES;
            imagePicker.delegate = self;            //协议
            imagePicker.allowsEditing = YES;
            imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
            [self presentViewController:imagePicker animated:YES completion:nil];
        }
    }];
    //系统相机拍照
    UIAlertAction *photoAction = [UIAlertAction actionWithTitle:@"相机" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //WKLog(@"相机选择");
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
            UIImagePickerController * imagePicker = [[UIImagePickerController alloc]init];
            imagePicker.delegate = self;
            imagePicker.allowsEditing = YES;
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            [self presentViewController:imagePicker animated:YES completion:nil];
        }
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        //取消
        //WKLog(@"取消");
    }];
    [userIconActionSheet addAction:albumAction];
    [userIconActionSheet addAction:photoAction];
    [userIconActionSheet addAction:cancelAction];
    [self presentViewController:userIconActionSheet animated:YES completion:nil];
    
}

#pragma mark 调用系统相册及拍照功能实现方法
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    UIImage *img = [info objectForKey:UIImagePickerControllerEditedImage];//获取到所选择的照片
    
    self.compressImg = [self imageWithImageSimple:img scaledToSize:CGSizeMake(128, 128)];//对选取的图片进行大小上的压缩
    
    //    //服务器响应
    [self transportImgToServerWithImg:self.compressImg]; //将裁剪后的图片上传至服务器
    
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

//压缩图片方法
- (UIImage*)imageWithImageSimple:(UIImage*)image scaledToSize:(CGSize)newSize{
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

//上传图片至服务器后台
- (void)transportImgToServerWithImg:(UIImage *)img{
    NSData *imageData;
    NSString *mimetype;
    //判断下图片是什么格式
    if (UIImagePNGRepresentation(img) != nil) {
        mimetype = @"image/png";
        imageData = UIImagePNGRepresentation(img);
    }else{
        mimetype = @"image/jpeg";
        imageData = UIImageJPEGRepresentation(img, 1.0);
    }
    
    //将更改后的图片传入leancloud中
    AVFile *file=[AVFile fileWithData:imageData];
    [[AVUser currentUser] setObject:file forKey:@"avatar"];
    [[AVUser currentUser] saveInBackground];
    //清除缓存
    [[LCChatKit sharedInstance] removeAllCachedProfiles];
    [[LCChatKit sharedInstance] removeAllCachedRecentConversations];
    
    //NSString *urlString = @"http://119.23.190.159:8000/get_user_profiles/";
    NSString *urlString =[ipAddress stringByAppendingString:@"get_user_profiles/"];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    //    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:urlString parameters:nil headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSString *str = [self.user.userID stringByAppendingString:@"Image"];
        NSString *fileName = [[NSString alloc] init];
        if (UIImagePNGRepresentation(img) != nil) {
            fileName = [NSString stringWithFormat:@"%@.png", str];
        }else{
            fileName = [NSString stringWithFormat:@"%@.jpg", str];
        }
        // 上传图片，以文件流的格式
        /**
         *filedata : 图片的data
         *name     : 后台的提供的字段
         *mimeType : 类型
         */
        [formData appendPartWithFileData:imageData name:str fileName:fileName mimeType:mimetype];
    } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"上传凭证成功:%@",responseObject);
        
       
        self.myImage.image = img;
        [self.myImage.layer setCornerRadius:CGRectGetHeight([self.myImage bounds])/2];
        self.myImage.layer.masksToBounds=YES;
        //将更改后的头像存入硬盘缓存
        NSString *imagePath=[[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]stringByAppendingPathComponent:self.user.profileImage] stringByAppendingString:@".png"];
        [UIImagePNGRepresentation(self.compressImg)writeToFile:imagePath   atomically:YES];
        
        NSNotificationCenter *center=[NSNotificationCenter defaultCenter];
        [center postNotificationName:@"changeProfileImage" object:self];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"上传图片失败，失败原因是:%@", error);
    }];
}






//用户取消选取时调用,可以用来做一些事情
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}



-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if(indexPath.row==0||indexPath.row==1){
        UITableViewCell * cell = (UITableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    //0.1s后取消选中
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
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
