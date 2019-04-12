//
//  ZZJ_PageView.m
//  ScrollView分页封装类
//
//  Created by solist on 2019/2/11.
//  Copyright © 2019 solist. All rights reserved.
//

#import "ZZJ_PageView.h"

@interface ZZJ_PageView()<UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;


/**
 定时器
 */
@property(weak,nonatomic) NSTimer *timer;

@property(nonatomic) NSInteger arrCount;

@end



@implementation ZZJ_PageView


+(instancetype)pageView{
    
    return [[[NSBundle mainBundle] loadNibNamed:@"ZZJ_PageView" owner:nil options:nil]lastObject];
}



-(void)setImageNames:(NSArray *)imageNames{
    _imageNames=imageNames;
    self.arrCount=imageNames.count;
    //将图片加载到scrollView中
    CGFloat scrollViewW=[UIScreen mainScreen].bounds.size.width;
    CGFloat scrollViewH=self.scrollView.frame.size.height;
    self.scrollView.contentSize=CGSizeMake(scrollViewW*self.arrCount, scrollViewH);
    for (int i=0; i<self.arrCount; i++) {
        UIImageView *tmpImageView=[[UIImageView alloc]init];
        tmpImageView.image=[UIImage imageNamed:imageNames[i]];
        tmpImageView.frame=CGRectMake(i*scrollViewW, 0, scrollViewW, scrollViewH);
        
        [self.scrollView addSubview:tmpImageView];
    }
    
    //设置pageControl
    self.pageControl.numberOfPages=self.arrCount;
}


-(void)awakeFromNib{
    [super awakeFromNib];
    
    self.pageControl.hidesForSinglePage=YES;
    
    //开启定时器
    [self startTimer];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    //更新当前页码
    self.pageControl.currentPage=self.scrollView.contentOffset.x/self.scrollView.frame.size.width+0.5;
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    //停止定时器
    [self stopTimer];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    [self startTimer];
}

-(void)startTimer{
    
    self.timer=[NSTimer scheduledTimerWithTimeInterval:3.5 target:self selector:@selector(nextPage) userInfo:nil repeats:YES];
    
    [[NSRunLoop mainRunLoop]addTimer:self.timer forMode:(NSRunLoopCommonModes)];
}

-(void) nextPage{
    NSInteger pageNum=self.pageControl.currentPage+1;
    
    if(pageNum==self.arrCount){
        pageNum=0;
    }
    
    //滚动到下一页
    [self.scrollView setContentOffset:CGPointMake(pageNum*self.scrollView.frame.size.width, 0) animated:YES];
}

-(void) stopTimer{
    [self.timer invalidate];
    self.timer=nil;
}

@end
