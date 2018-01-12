//
//  VideoViewController.m
//  XGZVideoVLC
//
//  Created by Tymon Shaw on 2018/1/11.
//  Copyright © 2018年 Tymon Shaw. All rights reserved.
//

#import "VideoViewController.h"

#import "BaseVideoPlayer.h"

@interface VideoViewController ()<BaseVideoPlayerDelegate>
{
    BaseVideoPlayer *videoPlayer;
}

@end

@implementation VideoViewController

- (void)dealloc
{
    [videoPlayer dismissPlayer];
}

- (void)viewWillDisappear:(BOOL)animated{
    if (videoPlayer) {
        [videoPlayer pause];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    videoPlayer = [[BaseVideoPlayer alloc] initWithFrame:CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.width/16*9)];
    videoPlayer.delegate = self;
    videoPlayer.closeBtnStyle = CloseBtnStylePop;
    videoPlayer.titleLabel.hidden = YES;
    videoPlayer.closeBtn.hidden = YES;
    videoPlayer.URLString = self.path;
    //    [videoPlayer.thumbImgView sd_setImageWithURL:[NSURL URLWithString:@""] placeholderImage:[UIImage imageNamed:@""]];
    videoPlayer.titleLabel.text = @"视频标题";
    
    [self.view addSubview:videoPlayer];
    
    
    //进入后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    //旋转屏幕通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
}

-(void)videoPlayer:(BaseVideoPlayer *)player clickedFullScreenButton:(UIButton *)fullScreenBtn{
    if (fullScreenBtn.isSelected) {
        //全屏显示
        [self setNeedsStatusBarAppearanceUpdate];
        [self toFullScreenWithInterfaceOrientation:UIInterfaceOrientationLandscapeLeft];
    }else{
        //小屏显示
        //        if (smallType == 1) {
        [self toSmallScreen];
        //        }else{
        //            [self toSmallVideoView];
        //        }
    }
}
/**
 视频全屏
 
 @param interfaceOrientation 方向
 */
-(void)toFullScreenWithInterfaceOrientation:(UIInterfaceOrientation )interfaceOrientation
{
    videoPlayer.transform = CGAffineTransformIdentity;
    if (interfaceOrientation==UIInterfaceOrientationLandscapeLeft) {
        videoPlayer.transform = CGAffineTransformMakeRotation(-M_PI_2);
    }else if(interfaceOrientation==UIInterfaceOrientationLandscapeRight){
        videoPlayer.transform = CGAffineTransformMakeRotation(M_PI_2);
    }
    videoPlayer.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    videoPlayer.playerView.frame =  CGRectMake(0,0, [UIScreen mainScreen].bounds.size.height,[UIScreen mainScreen].bounds.size.width);
    videoPlayer.contentView.frame = CGRectMake(0,0, [UIScreen mainScreen].bounds.size.height,[UIScreen mainScreen].bounds.size.width);
    videoPlayer.FF_View.sd_layout.centerXEqualToView(videoPlayer.contentView)
    .centerYEqualToView(videoPlayer.contentView);
    
    videoPlayer.topView.sd_layout.widthIs(SCREEN_HEIGHT)
    .heightIs(40);
    videoPlayer.bottomView.frame = CGRectMake(0, videoPlayer.contentView.height - 50, SCREEN_HEIGHT, 50);
    videoPlayer.bottomView.sd_layout.widthIs(SCREEN_HEIGHT)
    .bottomSpaceToView(videoPlayer.contentView, 0)
    .heightIs(50);
    
    
    
    [[UIApplication sharedApplication].keyWindow addSubview:videoPlayer];
    videoPlayer.fullScreenBtn.selected = YES;
    videoPlayer.isFullscreen = YES;
    videoPlayer.titleLabel.hidden = NO;
    videoPlayer.closeBtn.hidden = NO;
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark ---------- BasePlayerDelegate
-(void)videoPlayer:(BaseVideoPlayer *)player clickedPlayOrPauseButton:(UIButton *)playOrPauseBtn
{
    if (videoPlayer.state == BaseVideoStateStopped||videoPlayer.state== BaseVideoStateFailed) {
        [videoPlayer play];
    } else if(videoPlayer.state == BaseVideoStatePlaying){
        [videoPlayer pause];
    }else if (videoPlayer.state == BaseVideoStateBuffering){
        videoPlayer.state = BaseVideoStateStopped;
        [videoPlayer pause];
    }else if(videoPlayer.state == BaseVideoStateFinished){
        videoPlayer.state = BaseVideoStatePlaying;
        [videoPlayer.player play];
    }else if (videoPlayer.state == BaseVideoStatePause){
        videoPlayer.state = BaseVideoStatePlaying;
        [videoPlayer.player play];
    }
}
- (void)videoPlayer:(BaseVideoPlayer *)player clickedCloseButton:(UIButton *)closeBtn{
    if (videoPlayer.closeBtnStyle == CloseBtnStylePop) {
        [self toSmallScreen];
    }else{
        [videoPlayer pause];
        [self toSmallScreen];
    }
}

-(void)toSmallScreen
{
    [UIView animateWithDuration:0.3f animations:^{
        videoPlayer.transform = CGAffineTransformIdentity;
        videoPlayer.frame = CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.width/16*9);
        videoPlayer.playerView.frame =  videoPlayer.bounds;
        [self.view addSubview:videoPlayer];
        
        videoPlayer.contentView.frame = videoPlayer.bounds;
        videoPlayer.FF_View.center = videoPlayer.contentView.center;
        videoPlayer.topView.sd_layout.widthIs(videoPlayer.width)
        .heightIs(40);
        videoPlayer.bottomView.frame = CGRectMake(0, videoPlayer.contentView.height - 50, SCREEN_WIDTH, 50);
        videoPlayer.bottomView.sd_layout.widthIs(videoPlayer.width)
        .bottomSpaceToView(videoPlayer.contentView, 0)
        .heightIs(50);
        
    }completion:^(BOOL finished) {
        videoPlayer.isFullscreen = NO;
        videoPlayer.titleLabel.hidden = YES;
        videoPlayer.closeBtn.hidden = YES;
        videoPlayer.fullScreenBtn.selected = NO;
    }];
}

/**
 *  旋转屏幕通知
 */
- (void)onDeviceOrientationChange{
    if (videoPlayer==nil||videoPlayer.superview==nil){
        return;
    }
    if (videoPlayer.isFullscreen) {
        UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
        UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
        switch (interfaceOrientation) {
            case UIInterfaceOrientationLandscapeLeft:{
                videoPlayer.isFullscreen = YES;
                [self setNeedsStatusBarAppearanceUpdate];
                [self toFullScreenWithInterfaceOrientation:interfaceOrientation];
            }
                break;
            case UIInterfaceOrientationLandscapeRight:{
                videoPlayer.isFullscreen = YES;
                [self setNeedsStatusBarAppearanceUpdate];
                [self toFullScreenWithInterfaceOrientation:interfaceOrientation];
            }
                break;
            default:
                break;
        }
    }
}

- (void)appDidEnterBackground:(NSNotification*)note{
    if (videoPlayer.state == BaseVideoStatePlaying) {
        [videoPlayer pause];
    }
}

-(BOOL)prefersStatusBarHidden{
    if (videoPlayer) {
        if (videoPlayer.isFullscreen) {
            return YES;
        }else{
            return NO;
        }
    }else{
        return NO;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
