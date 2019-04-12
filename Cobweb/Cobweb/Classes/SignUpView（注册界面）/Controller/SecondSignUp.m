//
//  SecondSignUp.m
//  Cobweb
//
//  Created by solist on 2019/3/1.
//  Copyright © 2019 solist. All rights reserved.
//

#import "setting.h"
#import "SecondSignUp.h"
#import "UserModel.h"
#import <SMS_SDK/SMSSDK.h>
#import "ErrorView.h"
#import "AFNetworking.h"
#import "MBProgressHUD.h"
#import "MeVC.h"
#import <AVUser.h>
#import <AVFile.h>

@interface SecondSignUp ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate>
@property (assign,nonatomic) BOOL isClicked_computer;
@property (assign,nonatomic) BOOL isClicked_design;
@property (assign,nonatomic) BOOL isClicked_setup;
@property (assign,nonatomic) BOOL isClicked_finance;
@property (assign,nonatomic) BOOL isClicked_music;
@property (assign,nonatomic) BOOL isClicked_tech;
@property (assign,nonatomic) BOOL isClicked_science;
@property (assign,nonatomic) BOOL isClicked_creation;
@property (assign,nonatomic) BOOL isClicked_animation;
@property (assign,nonatomic) BOOL isClicked_foreign;
@property (weak,nonatomic) MBProgressHUD *hud;

@property (weak, nonatomic) IBOutlet UIButton *getIdentifyCodeBtn;


@property (weak, nonatomic) IBOutlet UITextField *phoneNumber;
@property (weak, nonatomic) IBOutlet UITextField *identifyingCode;
@property (weak, nonatomic) IBOutlet UIImageView *iconImage;
@property (strong, nonatomic)  UITapGestureRecognizer *changeUserIconTap;
@property (weak, nonatomic) IBOutlet UIView *bigView;
@property (strong,nonatomic) UIImage *compressImg;
@property (strong,nonatomic) NSData *imageData;

@end

@implementation SecondSignUp

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //为textField设置代理
    self.identifyingCode.delegate=self;
    self.phoneNumber.delegate=self;
    //初始化默认头像
    self.compressImg=self.iconImage.image;
    
    //初始化按钮状态
    self.isClicked_computer=NO;
    self.isClicked_design=NO;
    self.isClicked_setup=NO;
    self.isClicked_finance=NO;
    self.isClicked_music=NO;
    self.isClicked_tech=NO;
    self.isClicked_science=NO;
    self.isClicked_creation=NO;
    self.isClicked_animation=NO;
    self.isClicked_foreign=NO;
    
    
    //为头像图片添加手势
    self.changeUserIconTap =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeUserIconAction:)];
    [self.iconImage addGestureRecognizer:self.changeUserIconTap];
}

-(void)errorShow:(NSString *)info{
    //初始化提示框
    ErrorView *errorInfo=[[NSBundle mainBundle]loadNibNamed:@"ErrorView" owner:nil options:nil][0];
    [errorInfo setText:(info)];
    errorInfo.layer.cornerRadius=10;
    errorInfo.alpha=0;
    [self.view addSubview:errorInfo];
//    errorInfo.center=CGPointMake(errorInfo.superview.center.x,errorInfo.superview.center.y);
    CGFloat w = [UIScreen mainScreen].bounds.size.width;
    CGFloat h = [UIScreen mainScreen].bounds.size.height;
    errorInfo.center=CGPointMake(w/2.0, h/2.0);    //设置动画，动画结束后提示框消失
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        errorInfo.alpha=1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:1 delay:1.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            errorInfo.alpha=0;
        } completion:^(BOOL finished){
            [errorInfo removeFromSuperview];
        }];
    }];
}





- (IBAction)changeBtn {
    [self changeUserIconAction:self.changeUserIconTap];
}

//更换头像
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
    self.iconImage.image = img;
    [self.iconImage.layer setCornerRadius:CGRectGetHeight([self.iconImage bounds])/2];
    self.iconImage.layer.masksToBounds=YES;
    self.compressImg = [self imageWithImageSimple:img scaledToSize:CGSizeMake(128, 128)];//对选取的图片进行大小上的压缩
    
//    //服务器响应
//    [self transportImgToServerWithImg:compressImg]; //将裁剪后的图片上传至服务器
    
    
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
    //NSData *imageData;
    NSString *mimetype;
    //判断下图片是什么格式
    if (UIImagePNGRepresentation(img) != nil) {
        mimetype = @"image/png";
        self.imageData = UIImagePNGRepresentation(img);
    }else{
        mimetype = @"image/jpeg";
        self.imageData = UIImageJPEGRepresentation(img, 1.0);
    }
    //NSString *urlString = @"http://119.23.190.159:8000/get_user_profiles/";
    NSString *urlString = [ipAddress stringByAppendingString:@"get_user_profiles/"];
    //NSDictionary *params = @{@"login_token":@"220"};
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
//    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:urlString parameters:nil headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSString *str = [self.tmpUser.userID stringByAppendingString:@"Image"];
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
        [formData appendPartWithFileData:self.imageData name:str fileName:fileName mimeType:mimetype];
    } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"上传凭证成功:%@",responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"上传图片失败，失败原因是:%@", error);
    }];
}






//用户取消选取时调用,可以用来做一些事情
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

//验证手机号码格式是否正确
- (BOOL)isMobileNumberOnly:(NSString *)mobileNum{
    NSString * MOBILE = @"^(13[0-9]|14[579]|15[0-3,5-9]|16[6]|17[0135678]|18[0-9]|19[89])\\d{8}$";
    NSPredicate *regextestmobile = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MOBILE];
    if ([regextestmobile evaluateWithObject:mobileNum] == YES){
        return YES;
    }
    else{
        return NO;
    }
}

//点击获取手机验证码
- (IBAction)identifyPhone {
    if(self.phoneNumber.text.length==0)
    {
        [self errorShow:@"手机号不能为空！"];
        return;
    }
    if(![self isMobileNumberOnly:self.phoneNumber.text])
    {
        [self errorShow:@"请输入正确的手机号！"];
        return;
    }
    
    [self startTime];
    [SMSSDK getVerificationCodeByMethod:SMSGetCodeMethodSMS phoneNumber:self.phoneNumber.text zone:@"86" template:nil result:^(NSError *error) {
        if(!error){
            NSLog(@"请求成功");
        }
        else{
            NSLog(@"请求失败%@",error);
            //初始化提示框
            [self errorShow:@"发送失败，请稍后再试！"];
            
        }
    }];
}

-(void)startTime{
    __block int timeout= 59; //倒计时时间
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_source_t _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
    
    dispatch_source_set_timer(_timer,dispatch_walltime(NULL, 0),1.0*NSEC_PER_SEC, 0); //每秒执行
    
    dispatch_source_set_event_handler(_timer, ^{
        
        if(timeout<=0){ //倒计时结束，关闭
            
            dispatch_source_cancel(_timer);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                //设置界面的按钮显示 根据自己需求设置
                [self.getIdentifyCodeBtn setTitle:@"获取验证码" forState:UIControlStateNormal];
                self.getIdentifyCodeBtn.userInteractionEnabled = YES;
                self.getIdentifyCodeBtn.backgroundColor=[UIColor orangeColor];
            });
        }else{
            //            int minutes = timeout / 60;
            
            int seconds = timeout % 60;
            
            NSString *strTime = [NSString stringWithFormat:@"%.2d", seconds];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                //设置界面的按钮显示 根据自己需求设置
                
                [UIView beginAnimations:nil context:nil];
                
                [UIView setAnimationDuration:1];
                
                [self.getIdentifyCodeBtn setTitle:[NSString stringWithFormat:@"%@秒后重发",strTime] forState:UIControlStateNormal];
                
                [UIView commitAnimations];
                
                self.getIdentifyCodeBtn.userInteractionEnabled = NO;
                self.getIdentifyCodeBtn.backgroundColor=[UIColor grayColor];
            });
            timeout--;
        }
    });
    dispatch_resume(_timer);
}

-(NSMutableArray *)getHobbies{
    NSMutableArray *tmp=[NSMutableArray array];
    if(self.isClicked_computer){
        [tmp addObject:@"计算机"];
    }
    if(self.isClicked_design){
        [tmp addObject:@"设计"];
    }
    if(self.isClicked_setup){
        [tmp addObject:@"创业"];
    }
    if(self.isClicked_finance){
        [tmp addObject:@"金融"];
    }
    if(self.isClicked_music){
        [tmp addObject:@"音"];
    }
    if(self.isClicked_tech){
        [tmp addObject:@"科技"];
    }
    if(self.isClicked_science){
        [tmp addObject:@"科"];
    }
    if(self.isClicked_creation){
        [tmp addObject:@"创新"];
    }
    if(self.isClicked_animation){
        [tmp addObject:@"漫"];
    }
    if (self.isClicked_foreign){
        [tmp addObject:@"语"];
    }
    return tmp;
}

- (IBAction)lauchAccount {
    
    if(self.phoneNumber.text.length==0){
        //初始化提示框
        [self errorShow:@"手机号不能为空！"];
        return;
    }
    else if(self.identifyingCode.text.length==0)
    {
        //初始化提示框
        [self errorShow:@"验证码不能为空！"];
        
        return;
    }
//    [self attemptLogin];
    [SMSSDK commitVerificationCode:self.identifyingCode.text phoneNumber:self.phoneNumber.text zone:@"86" result:^(NSError *error) {
        if(!error){
            [self attemptLogin];
        }
        else{
            NSLog(@"%@",error);
            //初始化提示框
            [self errorShow:@"验证码输入错误！"];
        }
    }];
}

//尝试与服务器交互（注册）
-(void)attemptLogin{
        //更新用户信息
        self.tmpUser.phone=self.phoneNumber.text;
        self.tmpUser.hobbies=[self getHobbies];
        NSDate *date=[NSDate date];
        NSDateFormatter *format=[[NSDateFormatter alloc] init];
        [format setDateFormat:@"yyyy-MM-dd"];
        NSString *dateStr;
        dateStr=[format stringFromDate:date];
        self.tmpUser.creationTime=dateStr;
    
        //服务器响应
        AFHTTPSessionManager *manager=[AFHTTPSessionManager manager];
    
        //            manager.requestSerializer=[AFHTTPRequest Serializerserializer];
        NSMutableArray *tmpArr=[self getHobbies];
        NSData *jsonArrData = [NSJSONSerialization dataWithJSONObject:tmpArr options:NSJSONWritingPrettyPrinted error:nil];
        NSString *hobbiesArr=[[NSString alloc] initWithData:jsonArrData encoding:NSUTF8StringEncoding];
        NSDictionary *dict=@{
                             @"userID":self.tmpUser.userID,
                             @"password":self.tmpUser.password,
                             @"userName":self.tmpUser.userName,
                             @"university":self.tmpUser.university,
                             @"major":self.tmpUser.major,
                             @"email":self.tmpUser.email,
                             @"creationTime":self.tmpUser.creationTime,
                             @"profileImage":[self.tmpUser.userID stringByAppendingString:@"Image"],
                             @"sex":self.tmpUser.sex,
                             @"hobbies":hobbiesArr,
                             @"phone":self.tmpUser.phone,
                             @"isAnonymous": [NSNumber numberWithBool:self.tmpUser.isAnonymous],
                             };
    
        //准备发送请求
        self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.mode=MBProgressHUDModeIndeterminate;
        self.hud.labelText=@"正在注册，请稍后";
    
    
    
        manager.requestSerializer.timeoutInterval=60.f;
        [manager POST:[ipAddress stringByAppendingString:@"registe/"]
           parameters:dict headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
    
            NSData *returnData=[NSJSONSerialization dataWithJSONObject:responseObject options:kNilOptions error:nil];
            NSDictionary *returnInfo=[NSJSONSerialization JSONObjectWithData:returnData options:kNilOptions error:nil];
            if([returnInfo[@"status"] integerValue]==0){
                //操作失败
                NSLog(@"%@",returnInfo[@"error_message"]);
    //            [self errorShow:returnInfo[@"error_message"]];
    
                //加载失败提示Hub
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
                self.hud.mode=MBProgressHUDModeText;
                self.hud.labelText=returnInfo[@"error_message"];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
            }
            else{
    
                NSLog(@"发送数据成功，准备发送图片");
                [self transportImgToServerWithImg:self.compressImg]; //将裁剪后的图片上传至服务器
    
                //加载成功提示Hub
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
                self.hud.mode=MBProgressHUDModeCustomView;
                UIImage *image = [[UIImage imageNamed:@"Checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                self.hud.customView = [[UIImageView alloc] initWithImage:image];
                self.hud.labelText = NSLocalizedString(@"注册成功！即将返回登陆界面", @"HUD done title");
                
                //AVUser 注册新用户
                AVUser *av_user=[AVUser user];
                av_user.username=self.tmpUser.userID;
                av_user.password=self.tmpUser.password;
                
                [av_user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if(succeeded){
                        AVFile *file=[AVFile fileWithData:self.imageData];
                        [av_user setObject:file forKey:@"avatar"];
                        [av_user setObject:self.tmpUser.userName forKey:@"nickname"];
                        [av_user saveInBackground];
                        NSLog(@"AVUser注册成功");
                    }
                    else{
                        NSLog(@"AVUser注册失败");
                    }
                }];
                
                
                
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    
                    //跳转到登陆界面
                    NSInteger index=[[self.navigationController viewControllers]indexOfObject:self];
                    [self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:index-2] animated:YES];
                });
    
            }
            NSLog(@"%@",returnInfo[@"status"]);
    
    
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


//取消键盘第一响应
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.phoneNumber resignFirstResponder];
    [self.identifyingCode resignFirstResponder];
}

- (IBAction)computerBtn:(UIButton *)sender {
    self.isClicked_computer=!self.isClicked_computer;
    if(self.isClicked_computer==YES)
    {
        sender.backgroundColor=[UIColor orangeColor];
    }
    else{
        sender.backgroundColor=[UIColor lightGrayColor];
    }
}

//实现了UITextFieldDelegate中的方法，当对TextField进行编辑即键盘弹出时，自动将输入框上移

-(void)textFieldDidBeginEditing:(UITextField *)textField{
    NSTimeInterval animationDuration=0.30f;
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    float width = self.view.frame.size.width;
    float height = self.view.frame.size.height;
    //上移n个单位，按实际情况设置
    CGRect rect=CGRectMake(0.0f,-155,width,height);
    self.view.frame=rect;
    [UIView commitAnimations];
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    NSTimeInterval animationDuration=0.30f;
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    float width = self.view.frame.size.width;
    float height = self.view.frame.size.height;
    //上移n个单位，按实际情况设置
    CGRect rect=CGRectMake(0.0f,0,width,height);
    self.view.frame=rect;
    [UIView commitAnimations];
}

- (IBAction)designBtn:(UIButton *)sender {
    self.isClicked_design=!self.isClicked_design;
    if(self.isClicked_design==YES)
    {
        sender.backgroundColor=[UIColor orangeColor];
    }
    else{
        sender.backgroundColor=[UIColor lightGrayColor];
    }
}

- (IBAction)setupBtn:(UIButton *)sender {
    self.isClicked_setup=!self.isClicked_setup;
    if(self.isClicked_setup==YES)
    {
        sender.backgroundColor=[UIColor orangeColor];
    }
    else{
        sender.backgroundColor=[UIColor lightGrayColor];
    }
}

- (IBAction)financeBtn:(UIButton *)sender {
    self.isClicked_finance=!self.isClicked_finance;
    if(self.isClicked_finance==YES)
    {
        sender.backgroundColor=[UIColor orangeColor];
    }
    else{
        sender.backgroundColor=[UIColor lightGrayColor];
    }
}

- (IBAction)musicBtn:(UIButton *)sender {
    self.isClicked_music=!self.isClicked_music;
    if(self.isClicked_music==YES)
    {
        sender.backgroundColor=[UIColor orangeColor];
    }
    else{
        sender.backgroundColor=[UIColor lightGrayColor];
    }
}

- (IBAction)techBtn:(UIButton *)sender {
    self.isClicked_tech=!self.isClicked_tech;
    if(self.isClicked_tech==YES)
    {
        sender.backgroundColor=[UIColor orangeColor];
    }
    else{
        sender.backgroundColor=[UIColor lightGrayColor];
    }
}

- (IBAction)scienceBtn:(UIButton *)sender {
    self.isClicked_science=!self.isClicked_science;
    if(self.isClicked_science==YES)
    {
        sender.backgroundColor=[UIColor orangeColor];
    }
    else{
        sender.backgroundColor=[UIColor lightGrayColor];
    }
}

- (IBAction)animationBtn:(UIButton *)sender {
    self.isClicked_animation=!self.isClicked_animation;
    if(self.isClicked_animation==YES)
    {
        sender.backgroundColor=[UIColor orangeColor];
    }
    else{
        sender.backgroundColor=[UIColor lightGrayColor];
    }
}

- (IBAction)creationBtn:(UIButton *)sender {
    self.isClicked_creation=!self.isClicked_creation;
    if(self.isClicked_creation==YES)
    {
        sender.backgroundColor=[UIColor orangeColor];
    }
    else{
        sender.backgroundColor=[UIColor lightGrayColor];
    }
}

- (IBAction)foreignBtn:(UIButton *)sender {
    self.isClicked_foreign=!self.isClicked_foreign;
    if(self.isClicked_foreign==YES)
    {
        sender.backgroundColor=[UIColor orangeColor];
    }
    else{
        sender.backgroundColor=[UIColor lightGrayColor];
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
