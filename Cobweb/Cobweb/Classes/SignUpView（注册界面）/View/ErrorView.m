//
//  ErrorView.m
//  Cobweb
//
//  Created by solist on 2019/3/1.
//  Copyright © 2019 solist. All rights reserved.
//

#import "ErrorView.h"

@interface ErrorView()

@property (weak, nonatomic) IBOutlet UILabel *labelText;


@end

@implementation ErrorView



-(void)setText:(NSString *)text{
    self.labelText.text=text;
}

@end
