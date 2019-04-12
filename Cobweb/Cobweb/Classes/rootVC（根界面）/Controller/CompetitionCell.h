//
//  CompetitionCell.h
//  Cobweb
//
//  Created by solist on 2019/2/24.
//  Copyright © 2019 solist. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class CompetitionCellModel;

@interface CompetitionCell : UITableViewCell

@property(strong,nonatomic) CompetitionCellModel *cellModel;
@property (weak, nonatomic) IBOutlet UIImageView *CompetitionImage;

@end

NS_ASSUME_NONNULL_END
