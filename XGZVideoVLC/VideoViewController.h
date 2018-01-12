//
//  VideoViewController.h
//  XGZVideoVLC
//
//  Created by Tymon Shaw on 2018/1/11.
//  Copyright © 2018年 Tymon Shaw. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface VideoViewController : UIViewController

@property(nonatomic,copy)NSString *path;

@end
