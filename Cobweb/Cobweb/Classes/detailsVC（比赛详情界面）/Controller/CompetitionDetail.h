//
//  CompetitionDetail.h
//  Cobweb
//
//  Created by solist on 2019/2/25.
//  Copyright © 2019 solist. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN
@class CompetitionCellModel;

@interface CompetitionDetail : UITableViewController

@property(strong,nonatomic) CompetitionCellModel *cellModel;
@property(strong,nonatomic) NSString *introductionText;

@end

NS_ASSUME_NONNULL_END
