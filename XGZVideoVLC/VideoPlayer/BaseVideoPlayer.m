//
//  BaseVideoPlayer.m
//  XGZVideoVLC
//
//  Created by Tymon Shaw on 2018/1/11.
//  Copyright © 2018年 Tymon Shaw. All rights reserved.
//

#import "BaseVideoPlayer.h"

#import <MediaPlayer/MediaPlayer.h>

//整个屏幕代表的时间
#define TotalScreenTime 90
//移动最小距离
#define LeastDistance 15
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height


@interface BaseVideoPlayer()<VLCMediaPlayerDelegate>
{
    UITapGestureRecognizer *singleTap;
    //用来判断手势是否移动过
    BOOL _hasMoved;
    //记录触摸开始时的视频播放的时间
    float _touchBeginValue;
    //记录触摸开始亮度
    float _touchBeginLightValue;
    //记录触摸开始的音量
    float _touchBeginVoiceValue;
    //视频总时长
    NSInteger videoAllTime;
}
//记录touch开始的点
@property (nonatomic,assign)CGPoint touchBeginPoint;
//判断当前手势是在控制进度?声音?亮度?
@property (nonatomic, assign) VideoControlType controlType;
@property (nonatomic, strong)NSDateFormatter *dateFormatter;
//slider是否拖拽中
@property(nonatomic,assign)BOOL isDragingSlider;
//视频进度条的单击事件
@property (nonatomic, strong) UITapGestureRecognizer *tap;
//声音滑块
@property (nonatomic,strong) UISlider *volumeSlider;

@end

@implementation BaseVideoPlayer

- (void)dealloc
{
    _player = nil;
}
- (instancetype )initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self initBaseVideoPlayer];
    }
    return self;
}
/**
 *  初始化BaseVideoPlayer的控件，添加手势，添加通知，添加kvo等
 */
- (void)initBaseVideoPlayer
{
    //默认值
    self.enableVolumeGesture = YES;
    self.enableFastForwardGesture = YES;
    
    self.playerView = [[UIView alloc] init];
    self.playerView.backgroundColor = [UIColor blackColor];
    self.playerView.frame = self.bounds;
    [self addSubview:self.playerView];
    
    self.thumbImgView = [[UIImageView alloc] init];
    self.thumbImgView.frame = self.bounds;
    [self addSubview:self.thumbImgView];
    
    self.contentView = [[UIView alloc]init];
    self.contentView.frame = self.bounds;
    self.contentView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.contentView];
    
    [self creatFF_View];
    
    
    //创建顶部操作工具栏
    self.topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.frame.size.width, 40)];
    self.topView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.7];
    [self.contentView addSubview:_topView];
    
    self.topView.sd_layout
    .widthIs(self.contentView.frame.size.width)
    .heightIs(40);
    
    //返回，关闭按钮
    self.closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeBtn.frame = CGRectMake(10, 10, 30, 30);
    [self.closeBtn setImage:[UIImage imageNamed:@"BaseVideoPlayer.bundle/ba_back"] forState:UIControlStateNormal];
    [self.closeBtn addTarget:self action:@selector(colseTheVideo:) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:_closeBtn];
    
    //标题
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 0, SCREEN_WIDTH-50, 40)];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont systemFontOfSize:17];
    [self.topView addSubview:self.titleLabel];
    
    //创建底部操作工具栏
    self.bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, self.contentView.frame.size.height-50, self.contentView.frame.size.width, 50)];
    self.bottomView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.7];
    [self.contentView addSubview:_bottomView];
    
    self.bottomView.sd_layout
    .widthIs(self.contentView.frame.size.width)
    .bottomSpaceToView(self.contentView, 0)
    .heightIs(50);
    
    //播放暂停按钮
    self.playOrPauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.playOrPauseBtn addTarget:self action:@selector(PlayOrPause:) forControlEvents:UIControlEventTouchUpInside];
    [self.playOrPauseBtn setImage:[UIImage imageNamed:@"BaseVideoPlayer.bundle/play"] forState:UIControlStateNormal];
    [self.playOrPauseBtn setImage:[UIImage imageNamed:@"BaseVideoPlayer.bundle/pause"] forState:UIControlStateSelected];
    [self.bottomView addSubview:_playOrPauseBtn];
    self.playOrPauseBtn.sd_layout
    .leftSpaceToView(self.bottomView, 10)
    .centerYEqualToView(self.bottomView)
    .widthIs(30)
    .heightIs(30);
    
    //控制全屏按钮
    self.fullScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.fullScreenBtn addTarget:self action:@selector(fullScreenAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.fullScreenBtn setImage:[UIImage imageNamed:@"BaseVideoPlayer.bundle/fullscreen"] forState:UIControlStateNormal];
    [self.fullScreenBtn setImage:[UIImage imageNamed:@"BaseVideoPlayer.bundle/nonfullscreen"] forState:UIControlStateSelected];
    [self.bottomView addSubview:self.fullScreenBtn];
    
    self.fullScreenBtn.sd_layout
    .rightSpaceToView(self.bottomView, 10)
    .centerYEqualToView(self.bottomView)
    .widthIs(30)
    .heightIs(30);
    
    //进度条
    self.progressSlider = [[UISlider alloc] init];
    [self.progressSlider setThumbImage:[UIImage imageNamed:@"BaseVideoPlayer.bundle/dot"]  forState:UIControlStateNormal];
    self.progressSlider.minimumTrackTintColor = [UIColor orangeColor];
    self.progressSlider.maximumTrackTintColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
    self.progressSlider.value = 0.0;//指定初始值
    [self.bottomView addSubview:self.progressSlider];
    
    //进度条的拖拽事件
    [self.progressSlider addTarget:self action:@selector(stratDragSlide:)  forControlEvents:UIControlEventValueChanged];
    //进度条的点击事件
    [self.progressSlider addTarget:self action:@selector(updateProgress:) forControlEvents:UIControlEventTouchUpInside];
    
    //给进度条添加单击手势
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionTapGesture:)];
    [self.progressSlider addGestureRecognizer:self.tap];
    
    self.progressSlider.sd_layout
    .centerYEqualToView(self.playOrPauseBtn)
    .rightSpaceToView(self.fullScreenBtn, 10)
    .leftSpaceToView(self.playOrPauseBtn, 10)
    .heightIs(30);
    
    //音量
    MPVolumeView *volumeView = [[MPVolumeView alloc]init];
    for (UIControl *view in volumeView.subviews) {
        if ([view.superclass isSubclassOfClass:[UISlider class]]) {
            self.volumeSlider = (UISlider *)view;
        }
    }
    
    //视频播放时长
    self.leftTimeLabel = [[UILabel alloc] init];
    self.leftTimeLabel.text = @"00:00";
    self.leftTimeLabel.textColor = [UIColor whiteColor];
    self.leftTimeLabel.font = [UIFont systemFontOfSize:11];
    [self.bottomView addSubview:self.leftTimeLabel];
    self.leftTimeLabel.sd_layout
    .leftEqualToView(self.progressSlider)
    .bottomSpaceToView(self.bottomView, 0)
    .widthIs(100)
    .heightIs(20);
    
    //视频总时长
    self.rightTimeLabel = [[UILabel alloc] init];
    self.rightTimeLabel.text = @"00:00";
    self.rightTimeLabel.textColor = [UIColor whiteColor];
    self.rightTimeLabel.textAlignment = NSTextAlignmentRight;
    self.rightTimeLabel.font = [UIFont systemFontOfSize:11];
    [self.bottomView addSubview:self.rightTimeLabel];
    
    self.rightTimeLabel.sd_layout
    .rightEqualToView(self.progressSlider)
    .bottomSpaceToView(self.bottomView, 0)
    .widthIs(100)
    .heightIs(20);
    
    
    // 单击的 Recognizer
    singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTap.numberOfTapsRequired = 1; // 单击
    singleTap.numberOfTouchesRequired = 1;
    [self.contentView addGestureRecognizer:singleTap];
    
    // 双击的 Recognizer
    UITapGestureRecognizer* doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTouchesRequired = 1; //手指数
    doubleTap.numberOfTapsRequired = 2; // 双击
    // 解决点击当前view时候响应其他控件事件
    [singleTap setDelaysTouchesBegan:YES];
    [doubleTap setDelaysTouchesBegan:YES];
    [singleTap requireGestureRecognizerToFail:doubleTap];//如果双击成立，则取消单击手势（双击的时候不回走单击事件）
    [self.contentView addGestureRecognizer:doubleTap];
    
    //添加通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appwillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

/**
 快进和后退的view
 */
-(void)creatFF_View{
    self.FF_View = [[NSBundle mainBundle] loadNibNamed:@"FastForwardView" owner:self options:nil].lastObject;
    self.FF_View.hidden = YES;
    self.FF_View.layer.cornerRadius = 10.0;
    [self.contentView addSubview:self.FF_View];
    
    self.FF_View.center = self.contentView.center;
    self.FF_View.sd_layout.widthIs(120).heightIs(60);
    
}
/**
 *  重写URLString的setter方法
 */
- (void)setURLString:(NSString *)URLString{
    if (_URLString == URLString) {
        return;
    }
    _URLString = URLString;
    _URLString = [_URLString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *url = [[NSURL alloc] initWithString:_URLString];
    VLCMedia *media = [VLCMedia mediaWithURL:url];
    [self.player setMedia:media];
}

- (void)setSeekTime:(NSInteger)seekTime{
    if (_seekTime == seekTime) {
        return;
    }
    _seekTime = seekTime;
    
}

/**
 显示操作栏
 */
- (void)showControlView{
    [UIView animateWithDuration:0.5 animations:^{
        self.bottomView.alpha = 1.0;
        self.topView.alpha = 1.0;
        if (self.delegate&&[self.delegate respondsToSelector:@selector(videoPlayer:isHiddenTopAndBottomView:)]) {
            [self.delegate videoPlayer:self isHiddenTopAndBottomView:NO];
        }
    } completion:^(BOOL finish){
        
    }];
}
/**
 隐藏操作栏
 */
- (void)hiddenControlView{
    [UIView animateWithDuration:0.5 animations:^{
        self.bottomView.alpha = 0.0;
        self.topView.alpha = 0.0;
        if (self.delegate&&[self.delegate respondsToSelector:@selector(videoPlayer:isHiddenTopAndBottomView:)]) {
            [self.delegate videoPlayer:self isHiddenTopAndBottomView:YES];
        }
    } completion:^(BOOL finish){
        
    }];
}
#pragma mark ---------- 开始拖曳sidle
- (void)stratDragSlide:(UISlider *)slider{
    NSLog(@"开始拖曳sidle");
    self.isDragingSlider = YES;
}
#pragma mark ---------- 播放进度
- (void)updateProgress:(UISlider *)slider{
    NSLog(@"播放进度");
    self.isDragingSlider = NO;
    // 根据拖动比例计算开始到播放节点的总秒数
    int allSec = (int)(videoAllTime * slider.value);
    [self seekToTimeToPlay:allSec];
}
#pragma mark ---------- 视频进度条的点击事件
- (void)actionTapGesture:(UITapGestureRecognizer *)sender {
    CGPoint touchLocation = [sender locationInView:self.progressSlider];
    CGFloat value =  (touchLocation.x/self.progressSlider.frame.size.width);
    [self.progressSlider setValue:value animated:YES];
    // 根据拖动比例计算开始到播放节点的总秒数
    int allSec = (int)(videoAllTime * value);
    [self seekToTimeToPlay:allSec];
    
}
#pragma mark ---------- 单击手势方法
- (void)handleSingleTap:(UITapGestureRecognizer *)sender{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autoDismissBottomView:) object:nil];
    if (self.delegate&&[self.delegate respondsToSelector:@selector(videoPlayer:singleTaped:)]) {
        [self.delegate videoPlayer:self singleTaped:sender];
    }
    
    [self.autoDismissTimer invalidate];
    self.autoDismissTimer = nil;
    self.autoDismissTimer = [NSTimer timerWithTimeInterval:5.0 target:self selector:@selector(autoDismissBottomView:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.autoDismissTimer forMode:NSDefaultRunLoopMode];
    [UIView animateWithDuration:0.3 animations:^{
        if (self.bottomView.alpha == 0.0) {
            [self showControlView];
        }else{
            [self hiddenControlView];
        }
    } completion:^(BOOL finish){
        
    }];
}
#pragma mark ---------- 双击手势方法
- (void)handleDoubleTap:(UITapGestureRecognizer *)doubleTap{
    if (self.delegate&&[self.delegate respondsToSelector:@selector(videoPlayer:doubleTaped:)]) {
        [self.delegate videoPlayer:self doubleTaped:doubleTap];
    }
    [self PlayOrPause:self.playOrPauseBtn];
    
    //    [self showControlView];
}
#pragma mark ---------- 关闭按钮点击方法
- (void)colseTheVideo:(UIButton *)button{
    if (self.delegate&&[self.delegate respondsToSelector:@selector(videoPlayer:clickedCloseButton:)]) {
        [self.delegate videoPlayer:self clickedCloseButton:button];
    }
}
#pragma mark - 全屏按钮点击func
-(void)fullScreenAction:(UIButton *)sender{
    sender.selected = !sender.selected;
    if (self.delegate&&[self.delegate respondsToSelector:@selector(videoPlayer:clickedFullScreenButton:)]) {
        [self.delegate videoPlayer:self clickedFullScreenButton:sender];
    }
}
#pragma mark ---------- 播放，暂停按钮点击方法
- (void)PlayOrPause:(UIButton *)sender{
    
    if ([self.delegate respondsToSelector:@selector(videoPlayer:clickedPlayOrPauseButton:)]) {
        [self.delegate videoPlayer:self clickedPlayOrPauseButton:sender];
    }else{
        if (self.state == BaseVideoStateStopped ||
            self.state == BaseVideoStateFailed ||
            self.state == BaseVideoStatePause) {
            [self play];
        } else if(self.state == BaseVideoStatePlaying){
            [self pause];
        }else if (self.state == BaseVideoStateBuffering){
            self.state = BaseVideoStateStopped;
            [self pause];
        }else if(self.state == BaseVideoStateFinished){
            self.state = BaseVideoStatePlaying;
            [self.player play];
        }
    }
}

/**
 播放
 */
- (void)play{
    if (!self.player.media) {
        NSURL *url = [[NSURL alloc] initWithString:self.URLString];
        VLCMedia *media = [VLCMedia mediaWithURL:url];
        [self.player setMedia:media];
    }
    self.thumbImgView.hidden = YES;
    [self.player play];
    if (self.seekTime>0) {
        [self seekToTimeToPlay:self.seekTime];
    }
    self.playOrPauseBtn.selected = YES;
}

/**
 暂停
 */
- (void)pause{
    [self.player pause];
    self.playOrPauseBtn.selected = NO;
}

/**
 销毁了
 */
- (void)dismissPlayer{
    [self.player stop];
    self.player = nil;
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}
#pragma mark ---------- VLCMediaPlayer Delegate

/**
 播放器状态改变
 */
- (void)mediaPlayerStateChanged:(NSNotification *)aNotification{
    NSLog(@"播放器状态改变 %ld",self.player.state);
    if (self.player.state == VLCMediaPlayerStateStopped) {
        //停止播放状态
        self.state = BaseVideoStateStopped;
        [self.player stop];
        self.progressSlider.value = 0;
        self.leftTimeLabel.text = @"00:00";
        self.rightTimeLabel.text = @"00:00";
        self.playOrPauseBtn.selected = NO;
        [self.loadingView stopAnimating];
    }else if (self.player.state == VLCMediaPlayerStatePlaying){
        //正在播放
        self.state = BaseVideoStatePlaying;
        [self.loadingView stopAnimating];
        self.playOrPauseBtn.selected = YES;
    }else if (self.player.state == VLCMediaPlayerStateError){
        //播放失败
        self.state = BaseVideoStateFailed;
        [self.loadingView stopAnimating];
        self.playOrPauseBtn.selected = NO;
    }else if (self.player.state == VLCMediaPlayerStatePaused){
        //暂停播放
        self.state = BaseVideoStatePause;
        [self.loadingView stopAnimating];
        self.playOrPauseBtn.selected = NO;
    }else if (self.player.state == VLCMediaPlayerStateEnded){
        //播放结束
        self.state = BaseVideoStateFinished;
        [self.loadingView stopAnimating];
        self.playOrPauseBtn.selected = NO;
        if (_delegate && [_delegate respondsToSelector:@selector(videoPlayerFinishedPlay:)]) {
            [_delegate videoPlayerFinishedPlay:self];
        }
    }else if (self.player.state == VLCMediaPlayerStateBuffering){
        //正在加载
        self.playOrPauseBtn.selected = YES;
        self.state = BaseVideoStateBuffering;
        if (self.player.playing) {
            [self.loadingView stopAnimating];
        }else{
            [self.loadingView startAnimating];
        }
    }
}

/**
 播放器时间改变
 */
- (void)mediaPlayerTimeChanged:(NSNotification *)aNotification{
    
    if (!self.isDragingSlider) {
        [self.progressSlider setValue:self.player.position animated:YES];
    }
    VLCMedia *media = self.player.media;
    videoAllTime = media.length.intValue/1000;
    //    NSLog(@"--- %ld",videoAllTime);
    self.leftTimeLabel.text = [NSString stringWithFormat:@"%@",self.player.time.stringValue];
    self.rightTimeLabel.text = [NSString stringWithFormat:@"%@",self.player.media.length];
    
    if (self.autoDismissTimer==nil) {
        self.autoDismissTimer = [NSTimer timerWithTimeInterval:5.0 target:self selector:@selector(autoDismissBottomView:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.autoDismissTimer forMode:NSDefaultRunLoopMode];
    }
}
#pragma mark ---------- 定时器
-(void)autoDismissBottomView:(NSTimer *)timer{
    if (self.state==BaseVideoStatePlaying || self.state == BaseVideoStateBuffering) {
        if (self.bottomView.alpha==1.0) {
            [self hiddenControlView];//隐藏操作栏
        }
    }
}
#pragma mark ---------- Touchs
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    //这个是用来判断, 如果有多个手指点击则不做出响应
    UITouch * touch = (UITouch *)touches.anyObject;
    if (touches.count > 1 || [touch tapCount] > 1 || event.allTouches.count > 1) {
        return;
    }
    //    这个是用来判断, 手指点击的是不是本视图, 如果不是则不做出响应
    if (![[(UITouch *)touches.anyObject view] isEqual:self.contentView] &&  ![[(UITouch *)touches.anyObject view] isEqual:self]) {
        return;
    }
    [super touchesBegan:touches withEvent:event];
    
    //触摸开始, 初始化一些值
    _hasMoved = NO;
    _touchBeginValue = self.progressSlider.value;
    //位置
    _touchBeginPoint = [touches.anyObject locationInView:self];
    //亮度
    _touchBeginLightValue = [UIScreen mainScreen].brightness;
    //声音
    _touchBeginVoiceValue = _volumeSlider.value;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch * touch = (UITouch *)touches.anyObject;
    if (touches.count > 1 || [touch tapCount] > 1  || event.allTouches.count > 1) {
        return;
    }
    if (![[(UITouch *)touches.anyObject view] isEqual:self.contentView] && ![[(UITouch *)touches.anyObject view] isEqual:self]) {
        return;
    }
    [super touchesMoved:touches withEvent:event];
    
    
    //如果移动的距离过于小, 就判断为没有移动
    CGPoint tempPoint = [touches.anyObject locationInView:self];
    if (fabs(tempPoint.x - _touchBeginPoint.x) < LeastDistance && fabs(tempPoint.y - _touchBeginPoint.y) < LeastDistance) {
        return;
    }
    _hasMoved = YES;
    //如果还没有判断出使什么控制手势, 就进行判断
    //滑动角度的tan值
    float tan = fabs(tempPoint.y - _touchBeginPoint.y)/fabs(tempPoint.x - _touchBeginPoint.x);
    if (tan < 1/sqrt(3)) {    //当滑动角度小于30度的时候, 进度手势
        _controlType = progressControl;
        //            _controlJudge = YES;
    }else if(tan > sqrt(3)){  //当滑动角度大于60度的时候, 声音和亮度
        //判断是在屏幕的左半边还是右半边滑动, 左侧控制为亮度, 右侧控制音量
        if (_touchBeginPoint.x < self.bounds.size.width/2) {
            //亮度
            _controlType = lightControl;
        }else{
            //音量
            _controlType = voiceControl;
        }
    }else{     //如果是其他角度则不是任何控制
        _controlType = noneControl;
        return;
    }
    
    
    if (_controlType == progressControl) {     //如果是进度手势
        if (self.enableFastForwardGesture) {
            float value = [self moveProgressControllWithTempPoint:tempPoint];
            [self timeValueChangingWithValue:value];
        }
    }else if(_controlType == voiceControl){    //如果是音量手势
        if (self.isFullscreen) {//全屏的时候才开启音量的手势调节
            if (self.enableVolumeGesture) {
                //根据触摸开始时的音量和触摸开始时的点去计算出现在滑动到的音量
                float voiceValue = _touchBeginVoiceValue - ((tempPoint.y - _touchBeginPoint.y)/self.bounds.size.height);
                //判断控制一下, 不能超出 0~1
                if (voiceValue < 0) {
                    _volumeSlider.value = 0;
                }else if(voiceValue > 1){
                    _volumeSlider.value = 1;
                }else{
                    _volumeSlider.value = voiceValue;
                }
            }
        }else{
            return;
        }
    }else if(_controlType == lightControl){   //如果是亮度手势
        //显示音量控制的view
        //        [self hideTheLightViewWithHidden:NO];
        if (self.isFullscreen) {
            //根据触摸开始时的亮度, 和触摸开始时的点来计算出现在的亮度
            float tempLightValue = _touchBeginLightValue - ((tempPoint.y - _touchBeginPoint.y)/self.bounds.size.height);
            if (tempLightValue < 0) {
                tempLightValue = 0;
            }else if(tempLightValue > 1){
                tempLightValue = 1;
            }
            //        控制亮度的方法
            [UIScreen mainScreen].brightness = tempLightValue;
            //        实时改变现实亮度进度的view
            NSLog(@"亮度调节 = %f",tempLightValue);
        }else{
            
        }
    }
}
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    //    if (iOS8) {
    //        self.effectView.alpha = 0.0;
    //    }
    //判断是否移动过,
    if (_hasMoved) {
        if (_controlType == progressControl) { //进度控制就跳到响应的进度
            CGPoint tempPoint = [touches.anyObject locationInView:self];
            if (self.enableFastForwardGesture) {
                float value = [self moveProgressControllWithTempPoint:tempPoint];
                [self seekToTimeToPlay:value];
            }
            self.FF_View.hidden = YES;
        }else if (_controlType == lightControl){//如果是亮度控制, 控制完亮度还要隐藏显示亮度的view
            //            [self hideTheLightViewWithHidden:YES];
        }
    }else{
        //        if (self.topView.hidden) {
        //            [self controlViewOutHidden];
        //        }else{
        //            [self controlViewHidden];
        //        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    NSLog(@"touchesEnded");
    self.FF_View.hidden = YES;
    //    [self hideTheLightViewWithHidden:YES];
    [super touchesEnded:touches withEvent:event];
    //判断是否移动过,
    if (_hasMoved) {
        if (_controlType == progressControl) { //进度控制就跳到响应的进度
            if (self.enableFastForwardGesture) {
                CGPoint tempPoint = [touches.anyObject locationInView:self];
                float value = [self moveProgressControllWithTempPoint:tempPoint];
                [self seekToTimeToPlay:value];
                self.FF_View.hidden = YES;
            }
        }else if (_controlType == lightControl){
            //如果是亮度控制, 控制完亮度还要隐藏显示亮度的view
            //            [self hideTheLightViewWithHidden:YES];
        }
    }else{
        //        if (self.topView.hidden) {
        //            [self controlViewOutHidden];
        //        }else{
        //            [self controlViewHidden];
        //        }
    }
}
#pragma mark - 用来控制移动过程中计算手指划过的时间
-(float)moveProgressControllWithTempPoint:(CGPoint)tempPoint{
    //90代表整个屏幕代表的时间
    float tempValue = _touchBeginValue*videoAllTime + TotalScreenTime * ((tempPoint.x - _touchBeginPoint.x)/([UIScreen mainScreen].bounds.size.width));
    if (tempValue > videoAllTime) {
        tempValue = videoAllTime;
    }else if (tempValue < 0){
        tempValue = 0.0f;
    }
    return tempValue;
}
#pragma mark - 用来显示时间的view在时间发生变化时所作的操作
-(void)timeValueChangingWithValue:(float)value{
    if (value > _touchBeginValue*videoAllTime) {
        self.FF_View.sheetStateImageView.image = [UIImage imageNamed:@"BaseVideoPlayer.bundle/progress_icon_r"];
    }else if(value < _touchBeginValue*videoAllTime){
        self.FF_View.sheetStateImageView.image = [UIImage imageNamed:@"BaseVideoPlayer.bundle/progress_icon_l"];
    }
    self.FF_View.hidden = NO;
    self.FF_View.sheetTimeLabel.text = [NSString stringWithFormat:@"%@/%@", [self convertTime:value], [self convertTime:videoAllTime]];
    [self showControlView];
    
}
- (NSString *)convertTime:(float)second{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    if (second/3600 >= 1) {
        [[self dateFormatter] setDateFormat:@"HH:mm:ss"];
    } else {
        [[self dateFormatter] setDateFormat:@"mm:ss"];
    }
    return [[self dateFormatter] stringFromDate:d];
}
- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    }
    return _dateFormatter;
}
#pragma mark ---------- 跳转到某段时间播放
- (void)seekToTimeToPlay:(NSInteger )value{
    
    // 根据当前播放秒数计算需要seek的秒数
    int sec = labs(value - self.player.time.intValue/1000);
    // 如果为获取到时间信息
    if (sec == 0 && value == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"未获取到视频总时长" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
        return;
    }
    NSLog(@"sec:%d",sec);
    if (sec==0) { // 刚好等于视频总时间
        return;
    }
    if (self.player.time.intValue/1000 <= value) { // 快进滑动
        [self.player jumpForward:sec]; // 快进播放
    } else {
        [self.player jumpBackward:sec]; // 快退播放
    }
}
#pragma mark - lazy player
- (VLCMediaPlayer *)player{
    if (!_player) {
        _player = [[VLCMediaPlayer alloc] init];
        _player.delegate = self;
        _player.drawable = self.playerView;
    }
    return _player;
}
#pragma mark ---------- 通知
- (void)appwillResignActive:(NSNotification *)note
{
    NSLog(@"appwillResignActive");
    if (self.state == BaseVideoStatePlaying) {
        [self pause];
        self.state = BaseVideoStatePause;
    }
}
- (void)appBecomeActive:(NSNotification *)note
{
    NSLog(@"appBecomeActive");
    if (self.state == BaseVideoStatePause) {
        [self play];
    }else{
        self.state = BaseVideoStateStopped;
    }
}
/**
 进入后台
 */
- (void)appDidEnterBackground:(NSNotification*)note{
    if (self.state == BaseVideoStatePlaying) {
        [self pause];
        self.state = BaseVideoStatePause;
    }
}

/**
 进入前台
 */
- (void)appWillEnterForeground:(NSNotification*)note{
    if (self.state == BaseVideoStatePause) {
        [self play];
    }else{
        self.state = BaseVideoStateStopped;
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
