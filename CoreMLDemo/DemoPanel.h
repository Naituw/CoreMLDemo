//
//  DemoPanel.h
//  CoreMLDemo
//
//  Created by wutian on 2017/6/26.
//  Copyright © 2017年 Weibo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DemoPanel : UIView

@property (nonatomic, strong) NSString * text;
@property (nonatomic, strong, readonly) UISegmentedControl * segmentedControl;

@end
