//
//  ChatListViewController.m
//  Cobweb
//
//  Created by solist on 2019/3/20.
//  Copyright © 2019 solist. All rights reserved.
//

#import "ChatListViewController.h"
#import <LCChatKit.h>
#import <AVIMClient.h>

@interface ChatListViewController ()

@end

@implementation ChatListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    // clientId 是聊天对象 AUser 对象的 objectId。例如下面这个是用户「李四」的 objectId：
//    NSString *clientId = @"5c93559d0237d700737674a5";
//    [[LCChatKit sharedInstance].client createConversationWithName:@"队伍讨论组" clientIds:@[clientId] callback:^(AVIMConversation * _Nullable conversation, NSError * _Nullable error) {
//        [conversation joinWithCallback:^(BOOL succeeded, NSError * _Nullable error) {
//            if (succeeded) {
//                //创建会话成功，跳转到聊天详情页
//                LCCKConversationViewController *conversationViewController = [[LCCKConversationViewController alloc] initWithConversationId:conversation.conversationId];
//                [self.navigationController pushViewController:conversationViewController animated:YES];
//            }
//        }];
//        
//    }];
    
//    AVIMConversation *conversation=[[LCChatKit sharedInstance].client conversationForId:@"5c9457bbc05a800070a1e10b"];
//    NSLog(@"%@",conversation);
//    [[LCChatKit sharedInstance] insertRecentConversation:conversation];
    
    //点击cell进入聊天界面
    [[LCChatKit sharedInstance] setDidSelectConversationsListCellBlock:^(NSIndexPath *indexPath, AVIMConversation *conversation, LCCKConversationListViewController *controller) {
        LCCKConversationViewController *conversationVC = [[LCCKConversationViewController alloc] initWithConversationId:conversation.conversationId];
        self.hidesBottomBarWhenPushed=YES;
        [conversationVC setFetchConversationHandler:^(AVIMConversation *conversation, LCCKConversationViewController *conversationController) {
            self.hidesBottomBarWhenPushed=NO;
        }];
        [controller.navigationController pushViewController:conversationVC animated:YES];
    }];

}






/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


@end
