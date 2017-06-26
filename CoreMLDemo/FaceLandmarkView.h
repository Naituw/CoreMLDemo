//
//  FaceLandmarkView.h
//  CoreMLDemo
//
//  Created by wutian on 2017/6/26.
//  Copyright © 2017年 Weibo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Vision/Vision.h>

@interface FaceLandmarkView : UIView

@property (nonatomic, strong) VNFaceObservation * observation;

@end
