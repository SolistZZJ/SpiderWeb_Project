//
//  ZZJ_PageView.h
//  ScrollView分页封装类
//
//  Created by solist on 2019/2/11.
//  Copyright © 2019 solist. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZZJ_PageView : UIView


@property(nonatomic,strong) NSArray *imageNames;

+(instancetype) pageView;

//-(instancetype)initWithImage:(NSArray *)imageNames;

@end

NS_ASSUME_NONNULL_END
