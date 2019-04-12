//
//  TopicScrollView.m
//  Cobweb
//
//  Created by solist on 2019/2/24.
//  Copyright © 2019 solist. All rights reserved.
//

#import "TopicScrollView.h"

@interface TopicScrollView ()<UIGestureRecognizerDelegate>

@end

@implementation TopicScrollView 

- (instancetype)initWithFrame:(CGRect)frame {
    if(self= [super initWithFrame:frame]){
        self.delaysContentTouches =NO;
        
    }
    return self;}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return gestureRecognizer.state !=0?YES:NO;
}


// scrollView需要设置的地方[scrollView setDelaysContentTouches:NO];        [scrollView setCanCancelContentTouches:NO];

//-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
//{
////    if([touch.view isDescendantOfView:self]){
////        NSLog(@"%@",[gestureRecognizer class]);
////        return NO;
////
////    }
////    return YES;
//}

//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
//{
//    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] || [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] ) {
//        return YES;
//    }
//    return NO;
//}

//- (BOOL)touchesShouldCancelInContentView:(UIView*)view {
//    if ([view isKindOfClass:UIButton.class]) {
//        return YES;
//
//    }
//    return[super touchesShouldCancelInContentView:view];
//
//}


//- (void)scrollViewDidScroll:(UIScrollView *)scrollView
//
//{
//    if([scrollView isKindOfClass:[UITableView class]])
//    {
//        //如果是tableview滑动
//        NSLog(@"1");
//    }
//    else
//    {
//        NSLog(@"2");
//        //否则是scrollView滑动
//     }
//}

//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
//{
//    NSLog(@"%@",[gestureRecognizer class]);
//    NSLog(@"%@",[otherGestureRecognizer class]);
//    return YES;
//}


//-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
//{
//    if (gestureRecognizer.state != 0)
//    {
//        NSLog(@"123");
//        return YES;
//    }
//    else
//    {
//        NSLog(@"+++++");
//        return NO;
//    }
//}

@end
