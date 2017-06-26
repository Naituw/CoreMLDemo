//
//  DemoPanel.m
//  CoreMLDemo
//
//  Created by wutian on 2017/6/26.
//  Copyright © 2017年 Weibo. All rights reserved.
//

#import "DemoPanel.h"

@interface DemoPanel ()

@property (nonatomic, strong) UIVisualEffectView * blurView;
@property (nonatomic, strong) UILabel * textLabel;
@property (nonatomic, strong) UISegmentedControl * segmentedControl;

@end

@implementation DemoPanel

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        self.layer.cornerRadius = 6.0;
        self.layer.masksToBounds = YES;
        
        UIBlurEffect * blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        
        UIVisualEffectView * vibView = [[UIVisualEffectView alloc] initWithEffect:[UIVibrancyEffect effectForBlurEffect:blurEffect]];
        vibView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_blurView.contentView addSubview:vibView];
        
        [self addSubview:_blurView];
        
        [self addSubview:self.textLabel];
        [vibView.contentView addSubview:self.segmentedControl];
    }
    return self;
}

- (UILabel *)textLabel
{
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        _textLabel.font = [UIFont boldSystemFontOfSize:32];
        _textLabel.textColor = [UIColor whiteColor];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.numberOfLines = 2;
    }
    return _textLabel;
}

- (UISegmentedControl *)segmentedControl
{
    if (!_segmentedControl) {
        _segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"CoreML", @"Vision"]];
        _segmentedControl.tintColor = [UIColor whiteColor];
        _segmentedControl.selectedSegmentIndex = 0;
    }
    return _segmentedControl;
}

- (void)setText:(NSString *)text
{
    _textLabel.text = text;
}

- (NSString *)text
{
    return _textLabel.text;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _blurView.frame = self.bounds;
    
    CGRect labelFrame = self.bounds;
    labelFrame.size.height = 100;
    labelFrame = CGRectInset(labelFrame, 10, 10);
    
    _textLabel.frame = labelFrame;
    
    CGRect segmentFrame = self.bounds;
    segmentFrame.size.height = 60;
    segmentFrame.origin.y = 100;
    segmentFrame = CGRectInset(segmentFrame, 10, 10);
    
    _segmentedControl.frame = segmentFrame;
}

@end
