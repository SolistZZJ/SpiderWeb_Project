//
//  CommentCellModel.h
//  Cobweb
//
//  Created by solist on 2019/3/9.
//  Copyright © 2019 solist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface CommentCellModel : NSObject

@property(copy,nonatomic) NSArray* children;
@property(copy,nonatomic) NSString* competition;
@property(copy,nonatomic) NSString* content;
@property(copy,nonatomic) NSString* creationTime;
@property(copy,nonatomic) NSString* commentId;
@property(copy,nonatomic) NSString* parent;
@property(copy,nonatomic) NSString* user;
@property(copy,nonatomic) NSString* userName;
@property(copy,nonatomic) NSString* receiveName;
@property(copy,nonatomic) NSData* profile;
@property(copy,nonatomic) NSData* childProfile;
@property(assign,nonatomic) CGFloat cellHeight;


@property(copy,nonatomic) NSString *root;



@end

NS_ASSUME_NONNULL_END
