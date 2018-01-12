//
//  ViewController.m
//  XGZVideoVLC
//
//  Created by Tymon Shaw on 2018/1/12.
//  Copyright © 2018年 Tymon Shaw. All rights reserved.
//

#import "ViewController.h"

#import <MobileVLCKit/MobileVLCKit.h>
#import "VideoViewController.h"
#import "SDAutoLayout.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    NSArray *_dataArray;
    VLCMediaPlayer *_player;
    UIView *_headerView;
    UIButton *_networkBtn;
    UIButton *_localBtn;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0,0, SCREEN_WIDTH, SCREEN_HEIGHT-64)];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.estimatedRowHeight = 0;
    tableView.estimatedSectionHeaderHeight = 0;
    tableView.estimatedSectionFooterHeight = 0;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.view addSubview:tableView];
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    _dataArray = @[@"http://192.168.1.58/Kevin/生活大爆炸(第一季)/[生活大爆炸][第一季]第2集_hd.mp4",
                   @"rm",
                   @"asf",
                   @"flv",
                   @"wmv",
                   @"avi",
                   @"mpg",
                   @"dat",
                   @"f4v",
                   @"mkv",
                   @"rmvb"];
    
    [self creatHeaderView];
    tableView.tableHeaderView = _headerView;
    
}

-(void)creatHeaderView
{
    _headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 60)];
    
    _networkBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_networkBtn setTitle:@"网络视频" forState:UIControlStateNormal];
    _networkBtn.backgroundColor = [UIColor greenColor];
    _networkBtn.selected = YES;
    [_networkBtn addTarget:self action:@selector(networkBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [_headerView addSubview:_networkBtn];
    _networkBtn.sd_layout.leftSpaceToView(_headerView, 60)
    .topSpaceToView(_headerView, 10)
    .widthIs(100)
    .heightIs(40);
    
    _localBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _localBtn.frame = CGRectMake(60, 10, 100, 40);
    [_localBtn setTitle:@"本地视频" forState:UIControlStateNormal];
    _localBtn.backgroundColor = [UIColor lightGrayColor];
    _localBtn.selected = NO;
    [_localBtn addTarget:self action:@selector(localBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [_headerView addSubview:_localBtn];
    _localBtn.sd_layout.rightSpaceToView(_headerView, 60)
    .topSpaceToView(_headerView, 10)
    .widthIs(100)
    .heightIs(40);
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (indexPath.row == 0) {
        cell.textLabel.text = _dataArray[indexPath.row];
    }else{
        cell.textLabel.text = _dataArray[indexPath.row];
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *path = @"";
    if (_networkBtn.selected) {
        NSLog(@"网络");
        if (indexPath.row == 0) {
            path = _dataArray[indexPath.row];
        }else {
            path = [NSString stringWithFormat:@"http://192.168.1.58/Kevin/%@.%@",_dataArray[indexPath.row],_dataArray[indexPath.row]];
        }
    }else {
        NSLog(@"本地");
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"本地视频" message:@"视频没有放到项目中，想要更多的视频类型去我的百度网盘下载,放到项目中" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
        [alertC addAction:okAction];
        [self presentViewController:alertC animated:YES completion:nil];
        
        if (indexPath.row == 0) {
            path = [[[NSBundle mainBundle] URLForResource:@"mp4" withExtension:@"mp4"] absoluteString];
        }else {
            path = [[[NSBundle mainBundle] URLForResource:_dataArray[indexPath.row] withExtension:_dataArray[indexPath.row]] absoluteString];
        }
    }
    if (![path isEqualToString:@""]) {
        VideoViewController *videoVC = [[VideoViewController alloc] init];
        videoVC.path = path;
        [self.navigationController pushViewController:videoVC animated:YES];
    }
    
}

- (void)networkBtnAction:(UIButton *)sender {
    _networkBtn.selected = YES;
    _localBtn.selected = NO;
    _networkBtn.backgroundColor = [UIColor greenColor];
    _localBtn.backgroundColor = [UIColor lightGrayColor];
}

- (void)localBtnAction:(UIButton *)sender {
    _networkBtn.selected = NO;
    _localBtn.selected = YES;
    _networkBtn.backgroundColor = [UIColor lightGrayColor];
    _localBtn.backgroundColor = [UIColor greenColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
