//
//  MajorModel.m
//  Cobweb
//
//  Created by solist on 2019/2/28.
//  Copyright © 2019 solist. All rights reserved.
//

#import "MajorModel.h"

@implementation MajorModel


+(instancetype)itemWithDict:(NSDictionary *)dict{
    MajorModel *item=[[MajorModel alloc]init];
    [item setValuesForKeysWithDictionary:dict];
    
    return item;
}

@end
