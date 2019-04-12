//
//  CompetitionCellModel.h
//  Cobweb
//
//  Created by solist on 2019/2/24.
//  Copyright © 2019 solist. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CompetitionCellModel : NSObject

@property(copy,nonatomic) NSString* ID;
@property(copy,nonatomic) NSString* name;
@property(copy,nonatomic) NSString* image;
@property(copy,nonatomic) NSString* numOfComment;
@property(copy,nonatomic) NSString* numOfCollection;
@property(copy,nonatomic) NSString* type;
@property(copy,nonatomic) NSString* date;
@property(copy,nonatomic) NSString* webpage;
@property(copy,nonatomic) NSString* introduction;


@end

NS_ASSUME_NONNULL_END
