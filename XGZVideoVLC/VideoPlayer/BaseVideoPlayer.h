//
//  BaseVideoPlayer.h
//  XGZVideoVLC
//
//  Created by Tymon Shaw on 2018/1/11.
//  Copyright © 2018年 Tymon Shaw. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MobileVLCKit/MobileVLCKit.h>
#import "FastForwardView.h"
#import "SDAutoLayout.h"

// 播放器的几种状态
typedef NS_ENUM(NSInteger, BaseVideoState) {
    BaseVideoStateFailed,        // 播放失败
    BaseVideoStateBuffering,     // 缓冲中
    BaseVideoStatePlaying,       // 播放中
    BaseVideoStateStopped,        //暂停播放
    BaseVideoStateFinished,        //暂停播放
    BaseVideoStatePause,       // 暂停播放
};
// 枚举值，包含播放器左上角的关闭按钮的类型
typedef NS_ENUM(NSInteger, CloseBtnStyle){
    CloseBtnStylePop, //pop箭头<-
    CloseBtnStyleClose  //关闭（X）
};
///手势操作的类型
typedef NS_ENUM(NSUInteger,VideoControlType) {
    progressControl,//视频进度调节操作
    voiceControl,//声音调节操作
    lightControl,//屏幕亮度调节操作
    noneControl//无任何操作
} ;

@class BaseVideoPlayer;

@protocol BaseVideoPlayerDelegate <NSObject>

@optional
///播放器事件
//点击播放暂停按钮代理方法
-(void)videoPlayer:(BaseVideoPlayer *)player clickedPlayOrPauseButton:(UIButton *)playOrPauseBtn;
//点击关闭按钮代理方法
-(void)videoPlayer:(BaseVideoPlayer *)player clickedCloseButton:(UIButton *)closeBtn;
//点击全屏按钮代理方法
-(void)videoPlayer:(BaseVideoPlayer *)player clickedFullScreenButton:(UIButton *)fullScreenBtn;
//单击Player的代理方法
-(void)videoPlayer:(BaseVideoPlayer *)player singleTaped:(UITapGestureRecognizer *)singleTap;
//双击Player的代理方法
-(void)videoPlayer:(BaseVideoPlayer *)player doubleTaped:(UITapGestureRecognizer *)doubleTap;
//Player的的操作栏隐藏和显示
-(void)videoPlayer:(BaseVideoPlayer *)player isHiddenTopAndBottomView:(BOOL )isHidden;
///播放状态
//播放失败的代理方法
-(void)videoPlayerFailedPlay:(BaseVideoPlayer *)player playerStatus:(BaseVideoState )state;
//准备播放的代理方法
-(void)videoPlayerReadyToPlay:(BaseVideoPlayer *)player playerStatus:(BaseVideoState )state;
//播放完毕的代理方法
-(void)videoPlayerFinishedPlay:(BaseVideoPlayer *)player;

@end

/**
 播放器
 */
@interface BaseVideoPlayer : UIView

#pragma mark ---------- 控件


/**
 未播放时的图片
 */
@property(nonatomic,strong)UIImageView *thumbImgView;
/**
 播放器
 */
@property(nonatomic,strong)VLCMediaPlayer *player;

/**
 播放器视图
 */
@property(nonatomic,strong)UIView *playerView;
/**
 BaseVideoPlayer内部一个UIView，所有的控件统一管理在此view中
 */
@property(nonatomic,strong)UIView *contentView;
/**
 顶部操作工具栏
 */
@property (nonatomic,strong)UIView *topView;

/**
 左上角关闭按钮
 */
@property (nonatomic,strong)UIButton *closeBtn;

/**
 视频标题
 */
@property (nonatomic,strong)UILabel *titleLabel;
/**
 底部操作工具栏
 */
@property (nonatomic,strong ) UIView  *bottomView;

/**
 播放暂停按钮
 */
@property(nonatomic,strong)UIButton *playOrPauseBtn;

/**
 视频播放时长
 */
@property(nonatomic,strong)UILabel *leftTimeLabel;

/**
 视频总时长
 */
@property(nonatomic,strong)UILabel *rightTimeLabel;

/**
 进度条
 */
@property(nonatomic,strong)UISlider *progressSlider;

/**
 控制全屏的按钮
 */
@property(nonatomic,strong)UIButton *fullScreenBtn;
/**
 菊花（加载框）
 */
@property (nonatomic,strong) UIActivityIndicatorView *loadingView;
/**
 这个用来显示滑动屏幕时的时间
 */
@property (nonatomic,strong) FastForwardView * FF_View;
/**
 定时器
 */
@property (nonatomic, retain) NSTimer *autoDismissTimer;
/**
 *  是否使用手势控制音量
 */
@property (nonatomic,assign) BOOL  enableVolumeGesture;
/**
 *  是否使用手势控制进度
 */
@property (nonatomic,assign) BOOL  enableFastForwardGesture;
/**
 *  BOOL值判断当前是否全屏
 */
@property (nonatomic,assign ) BOOL            isFullscreen;
#pragma mark ---------- 数据
/**
 *  设置播放视频的USRLString，可以是本地的路径也可以是http的网络路径
 */
@property (nonatomic,copy)NSString *URLString;

/**
 播放器的代理
 */
@property (nonatomic, weak)id <BaseVideoPlayerDelegate> delegate;

/**
 跳转到什么时间播放
 */
@property (nonatomic, assign) NSInteger seekTime;

#pragma mark ---------- 状态
/**
 播放器状态
 */
@property (nonatomic, assign) BaseVideoState state;

/**
 播放器左上角按钮的类型
 */
@property (nonatomic, assign) CloseBtnStyle closeBtnStyle;

#pragma mark ---------- 方法

/**
 播放
 */
- (void)play;

/**
 暂停
 */
- (void)pause;

/**
 销毁了
 */
- (void)dismissPlayer;
@end

