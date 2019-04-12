//
//  bottomView.h
//  Cobweb
//
//  Created by solist on 2019/3/7.
//  Copyright © 2019 solist. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface bottomView : UIView

@property (weak, nonatomic) IBOutlet UITextField *test;

@property (weak, nonatomic) IBOutlet UIView *commentView;
@property (weak, nonatomic) IBOutlet UIImageView *collectImg;
@property (weak, nonatomic) IBOutlet UIImageView *linkImg;

@end

NS_ASSUME_NONNULL_END
