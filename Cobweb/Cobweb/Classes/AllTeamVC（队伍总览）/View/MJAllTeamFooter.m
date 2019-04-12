//
//  MJAllTeamFooter.m
//  Cobweb
//
//  Created by solist on 2019/3/26.
//  Copyright © 2019 solist. All rights reserved.
//

#import "MJAllTeamFooter.h"

@implementation MJAllTeamFooter
//按比例缩放,size 是你要把图显示到 多大区域
- (UIImage *) imageCompressFitSizeScale:(UIImage *)sourceImage targetSize:(CGSize)size{
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = size.width;
    CGFloat targetHeight = size.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    
    if(CGSizeEqualToSize(imageSize, size) == NO){
        
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if(widthFactor > heightFactor){
            scaleFactor = widthFactor;
            
        }
        else{
            
            scaleFactor = heightFactor;
        }
        scaledWidth = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        if(widthFactor > heightFactor){
            
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }else if(widthFactor < heightFactor){
            
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    UIGraphicsBeginImageContext(size);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil){
        NSLog(@"scale image fail");
    }
    
    UIGraphicsEndImageContext();
    return newImage;
}
#pragma mark - 重写方法
#pragma mark 基本设置
-(void)prepare{
    [super prepare];
    self.mj_h=80;
    
    // 设置普通状态的动画图片
    NSMutableArray *nomalImages = [NSMutableArray array];
    UIImage *imageTmp=[UIImage imageNamed:@"allTeamRefresh1"];
    imageTmp=[self imageCompressFitSizeScale:imageTmp targetSize:CGSizeMake(60, 60)];
    [nomalImages addObject:imageTmp];
    [self setImages:nomalImages forState:MJRefreshStateRefreshing];
    
    // 设置即将刷新状态的动画图片和正在刷新状态的动画图片
    NSMutableArray *refreshingImages = [NSMutableArray array];
    for(NSInteger i=1;i<=27;i++){
        UIImage *image=[UIImage imageNamed:[NSString stringWithFormat:@"allTeamRefresh%zd",i]];
        NSLog(@"%@",image);
        image=[self imageCompressFitSizeScale:image targetSize:CGSizeMake(60, 60)];
        [refreshingImages addObject:image];
    }
    [self setImages:refreshingImages forState:MJRefreshStatePulling];
    [self setImages:refreshingImages forState:MJRefreshStateRefreshing];
}

-(void)beginRefreshing{
    [super beginRefreshing];
    self.gifView.hidden=NO;
}

-(void)endRefreshing{
    [super endRefreshing];
    self.gifView.hidden=YES;
}

//在这里设置子控件的位置和尺寸
- (void)placeSubviews
{
    [super placeSubviews];
    self.gifView.center=CGPointMake([UIScreen mainScreen].bounds.size.width/2.0-40, 0);
    self.stateLabel.center=CGPointMake([UIScreen mainScreen].bounds.size.width/2.0, self.gifView.center.y+30);
    
}

//-(void)resetNoMoreData{
//    [super resetNoMoreData];
//    self.mj_h=80;
//    self.gifView.center=CGPointMake([UIScreen mainScreen].bounds.size.width/2.0-40, self.mj_h/2.0);
//    self.stateLabel.center=CGPointMake([UIScreen mainScreen].bounds.size.width/2.0, self.gifView.center.y+30);
//}
//
//-(void)endRefreshingWithNoMoreData{
//    [super endRefreshingWithNoMoreData];
//    self.mj_h=30;
//    self.stateLabel.center=CGPointMake([UIScreen mainScreen].bounds.size.width/2.0, 10);
//}

@end
