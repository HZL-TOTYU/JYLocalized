//
//  JYLanguageViewController.m
//  JYLocalizedExample
//
//  Created by 杨权 on 2016/11/3.
//  Copyright © 2016年 Job-Yang. All rights reserved.
//

#import "JYLanguageViewController.h"
#import "UIViewController+JYHUD.h"
#import "JYCellModel.h"
#import "JYTableViewCell.h"

static NSString *const kJYTableViewCell = @"JYTableViewCell";

@interface JYLanguageViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UIButton *saveButton;
@property (strong, nonatomic) NSMutableArray<JYCellModel *> *languageList;
@end

@implementation JYLanguageViewController

#pragma mark - life cycle
- (void)dealloc {
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setCurrentTitle:NSLocalizedString(@"语言设置", nil)];
    [self tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - setup methods

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.languageList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [JYTableViewCell heightWithData:self.languageList[indexPath.row]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    JYTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kJYTableViewCell];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:kJYTableViewCell owner:self options:nil] lastObject];
    }
    JYCellModel *model = self.languageList[indexPath.row];
    cell.accessoryType = model.enabled ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    [cell resetWithData:model];
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    for (int i = 0; i < self.languageList.count; i++) {
        JYCellModel *model = self.languageList[i];
        model.enabled = (indexPath.row == i);
    }
    [self.tableView reloadData];
}

#pragma mark - requests

#pragma mark - router

#pragma mark - event & response
- (void)saveButtonAction:(id)sender {
    NSString *key = [self getCurrentKey];
    NSString *currentLanguage = [[NSBundle localizedBundle] currentLanguage];
    if (key && ![key isEqualToString:currentLanguage]) {
        [self showHUD:NSLocalizedString(@"更换语言中...", nil)];
        @weakify(self);
        //这里延时是为了让用户觉得我们确实在费力的切换语言，不然很突兀
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @strongify(self);
            [self changeLanguageForKey:key];
        });
    }
}

#pragma mark - private methods
- (void)changeLanguageForKey:(NSString *)key {
    [self hideHUD];
    [[JYRouter router] popToRoot];
    [[NSBundle localizedBundle] setUserLanguage:key]; //将新的语言标示存入本地
    //延时操作，等POP动画结束
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kNotifyRootViewControllerReset" object:nil];//发送刷新页面通知
    });
}

- (NSString *)getCurrentKey {
    NSString *key;
    for (int i = 0; i < self.languageList.count; i++) {
        JYCellModel *model = self.languageList[i];
        if (self.languageList[i].enabled == YES) {
            key = model.key;
        }
    }
    return key;
}

#pragma mark - getter & setter
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SAFE_HEIGHT)];
        _tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.tableFooterView = self.saveButton;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        [self.view addSubview:_tableView];
    }
    return _tableView;
}

- (UIButton *)saveButton {
    if (!_saveButton) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, SCREEN_WIDTH, 60);
        [button setBackgroundColor:[UIColor whiteColor]];
        [button setTitleColor:RGB(130, 133, 139) forState:UIControlStateNormal];
        [button setTitle:NSLocalizedString(@"切换语言", nil) forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        [button addTarget:self action:@selector(saveButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _saveButton = button;
        [self.view addSubview:_saveButton];
    }
    return _saveButton;
}

- (NSMutableArray<JYCellModel *> *)languageList {
    if (!_languageList) {
        _languageList  = [NSMutableArray array];
        NSError *error = nil;
        NSString *path = [[NSBundle mainBundle] pathForResource:@"languageList" ofType:@"json"];
        NSData *data   = [[NSData alloc] initWithContentsOfFile:path];
        NSArray *array = [NSJSONSerialization JSONObjectWithData:data
                                                         options:NSJSONReadingAllowFragments
                                                           error:&error];
        for (NSDictionary *dic in array) {
            JYCellModel *model = [JYCellModel yy_modelWithJSON:dic];
            if ([model.key isEqualToString:[[NSBundle localizedBundle] currentLanguage]]) {
                model.enabled = YES;
            }
            [_languageList addObject:model];
        }
    }
    return _languageList;
}


@end
