//
//  SignUpVC.m
//  Cobweb
//
//  Created by solist on 2019/2/28.
//  Copyright © 2019 solist. All rights reserved.
//

#import "SignUpVC.h"
#import "MajorModel.h"
#import "SecondSignUp.h"
#import "UserModel.h"
#import "ErrorView.h"
#import "AFNetworking.h"
#import "MBProgressHUD.h"
#import "UserModel.h"
#import "setting.h"

@interface SignUpVC ()<UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate>


@property (weak, nonatomic) IBOutlet UIView *LoginView;
@property (weak, nonatomic) IBOutlet UITextField *userID;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UITextField *passwordAgain;
@property (weak, nonatomic) IBOutlet UITextField *userName;
@property (weak, nonatomic) IBOutlet UITextField *Email;
@property (weak, nonatomic) IBOutlet UITextField *university;

@property (weak, nonatomic) IBOutlet UITextField *majorText;
@property (weak, nonatomic) IBOutlet UITextField *sexText;
@property (weak,nonatomic) MBProgressHUD *hud;

@property(retain, nonatomic) UIPickerView *pickerMajor;
@property(retain, nonatomic) UIPickerView *pickerSex;

@property(strong, nonatomic) NSArray *dataArray;

//当前选择的大类专业角标
@property(assign, nonatomic) NSInteger index;

//view
@property (weak, nonatomic) IBOutlet UIView *myView;



@end

@implementation SignUpVC

-(NSArray *)dataArray{
    if(_dataArray==nil){
        NSArray *array=[NSArray arrayWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"MajorList.plist" ofType:nil]];
        NSMutableArray *tmpArray=[NSMutableArray array];
        for (NSDictionary *dict in array) {
            //字典转模型
            MajorModel *item=[MajorModel itemWithDict:dict];
            [tmpArray addObject:item];
        }
        _dataArray=tmpArray;
    }
    return _dataArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.pickerMajor=[[UIPickerView alloc]init];
    self.pickerMajor.delegate=self;
    self.pickerMajor.dataSource=self;
    self.pickerSex=[[UIPickerView alloc]init];
    self.pickerSex.delegate=self;
    self.pickerSex.dataSource=self;
    
    self.majorText.inputView=self.pickerMajor;
    self.sexText.inputView=self.pickerSex;
    
    self.majorText.delegate=self;
    self.sexText.delegate=self;

}

//设置picker位不能编辑
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    return NO;
}


-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    if(pickerView==self.pickerMajor){
        return 2;
    }
    else{
        return 1;
    }
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    if(pickerView==self.pickerMajor){
        if(component==0){
            return self.dataArray.count;
        }
        else{
            MajorModel *item= self.dataArray[self.index];
            return item.major.count;
            
        }
    }
    else{
        return 2;
    }
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    if(pickerView==self.pickerMajor)
    {
        if(component==0){
            self.index=row;
            //第一列选中第0行
            [pickerView selectRow:0 inComponent:1 animated:YES];
            
            //刷新数据
            [pickerView reloadAllComponents];
        }
        MajorModel *item=self.dataArray[self.index];
        NSInteger majorRow=[pickerView selectedRowInComponent:1];
        self.majorText.text=item.major[majorRow];
    }
    else{
        if(row==0)
        {
            self.sexText.text=@"男";
        }
        else{
            self.sexText.text=@"女";
        }
    }
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    if(pickerView==self.pickerMajor){
        if(component==0)
        {
            MajorModel *item =self.dataArray[row];
            return item.type;
        }
        else{
            MajorModel *item=self.dataArray[self.index];
            NSString *major=item.major[row];
            return major;
        }
    }
    else{
        if(row==0){
            return @"男";
        }
        else{
            return @"女";
        }
    }
}


- (IBAction)nextBtn {
    if([self.userID.text isEqual:@""]||[self.password.text isEqual:@""]||[self.passwordAgain.text isEqual:@""]||[self.userName.text isEqual:@""]||[self.Email.text isEqual:@""]||[self.university.text isEqual:@""]||[self.majorText.text isEqual:@""]||[self.sexText.text isEqual:@""]){
        //有textfield未填写
        
        //初始化提示框
        ErrorView *errorInfo=[[NSBundle mainBundle]loadNibNamed:@"ErrorView" owner:nil options:nil][0];
        [errorInfo setText:(@"请将信息填写完整")];
        errorInfo.layer.cornerRadius=10;
        errorInfo.alpha=0;
        [self.view addSubview:errorInfo];
        errorInfo.center=CGPointMake(errorInfo.superview.center.x,errorInfo.superview.center.y);
        
        //设置动画，动画结束后提示框消失
        [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            errorInfo.alpha=1;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:1 delay:1.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                errorInfo.alpha=0;
            } completion:^(BOOL finished){
                [errorInfo removeFromSuperview];
            }];
        }];
        
        
        
    }
    else{
        if([self.passwordAgain.text isEqual:self.password.text]){
            
            //与服务器交换数据（查看用户名或者邮箱是否已被使用）
            //服务器响应
            AFHTTPSessionManager *manager=[AFHTTPSessionManager manager];
            NSDictionary *dict=@{
                                 @"userID":self.userID.text,
                                 @"email":self.Email.text
                                 };
            //准备发送请求
            self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
            self.hud.mode=MBProgressHUDModeIndeterminate;
            manager.requestSerializer.timeoutInterval=20.f;
            [manager POST:[ipAddress stringByAppendingString:@"verify/"] parameters:dict headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                if([responseObject[@"status"] integerValue]==1){
                    //验证成功进入下一步
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                        [self performSegueWithIdentifier:@"finalIdentify" sender:nil];
                    });
                }
                else{
                    //发现用户名重复或者邮箱重复
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    self.hud.mode=MBProgressHUDModeText;
                    self.hud.labelText=responseObject[@"error_message"];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                    });
                }
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                self.hud=[MBProgressHUD showHUDAddedTo:self.view animated:YES];
                self.hud.mode=MBProgressHUDModeText;
                self.hud.labelText=@"请检查联网情况!";
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
            }];
        }
        else{
            //两次输入的密码不一致
            //初始化提示框
            ErrorView *errorInfo=[[NSBundle mainBundle]loadNibNamed:@"ErrorView" owner:nil options:nil][0];
            [errorInfo setText:(@"两次密码输入不一致")];
            errorInfo.layer.cornerRadius=10;
            errorInfo.alpha=0;
            [self.view addSubview:errorInfo];
            errorInfo.center=CGPointMake(errorInfo.superview.center.x,errorInfo.superview.center.y);
            
            //设置动画，动画结束后提示框消失
            [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                errorInfo.alpha=1;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:1 delay:1.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    errorInfo.alpha=0;
                } completion:^(BOOL finished){
                    [errorInfo removeFromSuperview];
                }];
            }];
        }
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"finalIdentify"]){
        
        //将当前界面信息传递到下一界面
        SecondSignUp *sonView=(SecondSignUp *)segue.destinationViewController;
        sonView.tmpUser=[[UserModel alloc]init];
        
        sonView.tmpUser.userID=self.userID.text;
        sonView.tmpUser.password=self.password.text;
        sonView.tmpUser.userName=self.userName.text;
        sonView.tmpUser.university=self.university.text;
        sonView.tmpUser.major=self.majorText.text;
        sonView.tmpUser.email=self.Email.text;
        sonView.tmpUser.sex=self.sexText.text;
        sonView.tmpUser.isAnonymous=NO;
        
        NSLog(@"--------%@--------",(NSString *)sonView.tmpUser.userID);
    }
}




-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.userID resignFirstResponder];
    [self.password resignFirstResponder];
    [self.passwordAgain resignFirstResponder];
    [self.userName resignFirstResponder];
    [self.Email resignFirstResponder];
    [self.university resignFirstResponder];
    [self.majorText resignFirstResponder];
    [self.sexText resignFirstResponder];

}


-(void)textFieldDidBeginEditing:(UITextField *)textField{
    if(textField==self.sexText)
    {
        NSTimeInterval animationDuration=0.30f;
        [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
        [UIView setAnimationDuration:animationDuration];
        float width = self.view.frame.size.width;
        float height = self.view.frame.size.height;
        //上移n个单位，按实际情况设置
        CGRect rect=CGRectMake(0.0f,-100,width,height);
        self.view.frame=rect;
        [UIView commitAnimations];
    }
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    if(textField==self.sexText)
    {
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
}

- (IBAction)teacherBtn {
//    NSMutableArray *hobbies=@[@"刘岱0",@"刘岱1",@"刘岱2"];
//    NSData *jsonData=[NSJSONSerialization dataWithJSONObject:hobbies options:kNilOptions error:nil];
//    NSString *jsonString=[[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
//
//    NSURL *url=[NSURL URLWithString:@"http://192.168.43.85:8000/test/"];
//    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url];
//    request.HTTPMethod=@"POST";
//    NSString *a=[NSString stringWithFormat:@"json=%@",jsonString];
//    //request.HTTPBody=jsonData;
//    request.HTTPBody=[a dataUsingEncoding:NSUTF8StringEncoding];
//    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
//        if(connectionError)
//        {
//            NSLog(@"sb");
//        }
//        else
//        {
//            NSLog(@"aaa");
//        }
//    }];
}

@end
