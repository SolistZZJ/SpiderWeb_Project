//
//  competitionModel.h
//  Cobweb
//
//  Created by solist on 2019/3/14.
//  Copyright © 2019 solist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "competitionDetailModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface competitionModel : NSObject

@property(nonatomic,strong) NSString *type;
@property(nonatomic,strong) NSMutableArray *competitionArr;


@end

NS_ASSUME_NONNULL_END
