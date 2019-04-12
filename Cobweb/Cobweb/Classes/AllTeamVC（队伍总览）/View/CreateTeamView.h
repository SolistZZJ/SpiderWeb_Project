//
//  CreateTeamView.h
//  Cobweb
//
//  Created by solist on 2019/3/14.
//  Copyright © 2019 solist. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CreateTeamView : UIView
@property (weak, nonatomic) IBOutlet UITextField *teamTextField;
@property (weak, nonatomic) IBOutlet UITextField *competitionChooseTextField;
@property (weak, nonatomic) IBOutlet UITextView *introductionTextView;
@property (weak, nonatomic) IBOutlet UITextField *maxNumTextField;
@property (strong, nonatomic) NSString *competitionID;

@end

NS_ASSUME_NONNULL_END
