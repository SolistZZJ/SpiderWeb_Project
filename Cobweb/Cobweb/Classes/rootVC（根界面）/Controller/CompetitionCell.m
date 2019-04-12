//
//  CompetitionCell.m
//  Cobweb
//
//  Created by solist on 2019/2/24.
//  Copyright © 2019 solist. All rights reserved.
//

#import "CompetitionCell.h"
#import "CompetitionCellModel.h"


@interface CompetitionCell()

@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UIImageView *theImageView;
@property (weak, nonatomic) IBOutlet UILabel *numOfComment;
@property (weak, nonatomic) IBOutlet UILabel *numOfCollection;



@end


@implementation CompetitionCell

- (void)awakeFromNib {
    [super awakeFromNib];
    //self.name.font=[UIFont fontWithName:@"创艺简中圆" size:14];
    self.theImageView.layer.cornerRadius=25;
    self.theImageView.layer.masksToBounds=YES;
    // Initialization code
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setCellModel:(CompetitionCellModel *)cellModel{
    _cellModel=cellModel;
    self.name.text=cellModel.name;
    self.numOfComment.text=cellModel.numOfComment;
    self.numOfCollection.text=cellModel.numOfCollection;
    
//    NSString *path=[[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:cellModel.image]stringByAppendingString:@".png"];
//    self.CompetitionImage.image=[UIImage imageWithContentsOfFile:path];
//    
//    NSURL *url=[NSURL URLWithString:@"https://files-cdn.cnblogs.com/files/sfencs-hcy/test.bmp"];
//    NSData *imageData=[NSData dataWithContentsOfURL:url];
//    self.theImageView.image=[UIImage imageWithData:imageData];

}



@end
