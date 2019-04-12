//
//  WebVC.m
//  Cobweb
//
//  Created by solist on 2019/2/27.
//  Copyright © 2019 solist. All rights reserved.
//
#import "setting.h"
#import "WebVC.h"
#import <WebKit/WebKit.h>
#import "CompetitionCellModel.h"

@interface WebVC ()<WKUIDelegate, WKNavigationDelegate>
@property (weak, nonatomic) IBOutlet WKWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *waitView;


@property (nonatomic,weak) CALayer *progressLayer;

@property (nonatomic, strong) UISwipeGestureRecognizer *rightSwipeGestureRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *leftSwipeGestureRecognizer;


@end

@implementation WebVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.webView.UIDelegate=self;
    self.webView.navigationDelegate=self;
    self.webView.allowsBackForwardNavigationGestures = YES;
    
    WKBackForwardList * backForwardList = [_webView backForwardList];
    //页面后退
    [_webView goBack];
    //页面前进
    [_webView goForward];
    //刷新当前页面
    [_webView reload];

    NSLog(@"%@",self.cellModel.webpage);
    if(![self.cellModel.webpage isEqual:@"0"]){
        NSURL *url = [NSURL URLWithString:self.cellModel.webpage];
        [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
        
    }
    else{
        //        NSURL *url = [NSURL URLWithString:@"http://119.23.190.159:8000/not_found_html"];
        NSURL *url=[NSURL URLWithString:[ipAddress stringByAppendingString:@"not_found_html"]];
        [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    }
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc]init];
    config.selectionGranularity = WKSelectionGranularityDynamic;
    config.allowsInlineMediaPlayback = YES;
    
    [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [self setupProgress];
    
    self.rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)];
    self.leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)];
    
    self.rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    self.leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    
    [self.view addGestureRecognizer:self.rightSwipeGestureRecognizer];
    [self.view addGestureRecognizer:self.leftSwipeGestureRecognizer];
    
}
- (void)handleSwipes:(UISwipeGestureRecognizer *)sender
{
    if (sender.direction == UISwipeGestureRecognizerDirectionRight) {
        if (_webView.canGoBack) {
            [_webView goBack];
        }
    }
    if (sender.direction == UISwipeGestureRecognizerDirectionLeft) {
        if (_webView.canGoForward) {
            [_webView goForward];
        }
    }
}

-(void)setupProgress{
    UIView *progress = [[UIView alloc]init];
    progress.frame = CGRectMake(0, 64, self.view.frame.size.width, 3);
    progress.backgroundColor = [UIColor  clearColor];
    [self.view addSubview:progress];
    
    CALayer *layer = [CALayer layer];
    layer.frame = CGRectMake(0, 0, 0, 3);
    layer.backgroundColor = [UIColor blueColor].CGColor;
    [progress.layer addSublayer:layer];
    self.progressLayer = layer;
}

#pragma mark - KVO回馈
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        self.progressLayer.opacity = 1;
        if ([change[@"new"] floatValue] <[change[@"old"] floatValue]) {
            return;
        }
        self.progressLayer.frame = CGRectMake(0, 0, self.view.frame.size.width*[change[@"new"] floatValue], 3);
        if ([change[@"new"]floatValue] == 1.0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.progressLayer.opacity = 0;
                self.progressLayer.frame = CGRectMake(0, 0, 0, 3);
            });
        }
    }
}

///// 是否允许加载网页，也可获取js要打开的url，通过截取此url可与js交互
//- (BOOL)webView:(WKWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
//
//    NSString *urlString = [[request URL] absoluteString];
//    urlString = [urlString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//
//    NSArray *urlComps = [urlString componentsSeparatedByString:@"://"];
//    NSLog(@"urlString=%@---urlComps=%@",urlString,urlComps);
//    return YES;
//}

-(void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    
}

-(void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    self.waitView.alpha=1;
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveLinear  animations:^{
        self.waitView.alpha=0;
    } completion:nil];
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
