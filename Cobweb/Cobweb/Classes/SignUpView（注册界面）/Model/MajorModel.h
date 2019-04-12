//
//  MajorModel.h
//  Cobweb
//
//  Created by solist on 2019/2/28.
//  Copyright © 2019 solist. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MajorModel : NSObject

@property(nonatomic,strong) NSArray *major;

@property(nonatomic,strong) NSString *type;


+(instancetype)itemWithDict:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
