//
//  FaceLandmarkView.m
//  CoreMLDemo
//
//  Created by wutian on 2017/6/26.
//  Copyright © 2017年 Weibo. All rights reserved.
//

#import "FaceLandmarkView.h"

@implementation FaceLandmarkView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.opaque = NO;
    }
    return self;
}

- (void)setObservation:(VNFaceObservation *)observation
{
    if (_observation != observation) {
        _observation = observation;
        
        [self setNeedsDisplay];
    }
}

- (void)drawFaceRegion:(VNFaceLandmarkRegion2D *)faceRegion boundingBox:(CGRect)boundingBox
{
    UIBezierPath * path = [[UIBezierPath alloc] init];
    
    const vector_float2 * points = faceRegion.points;
    NSUInteger pointCount = faceRegion.pointCount;
    
    BOOL first = YES;
    
    for (NSUInteger i = 0; i < pointCount; i++) {
        vector_float2 vector = points[i];
        CGPoint point = CGPointMake(vector[0], vector[1]);
        
        point.x *= boundingBox.size.width;
        point.y *= boundingBox.size.height;
        
        point.x += boundingBox.origin.x;
        point.y += boundingBox.origin.y;
        
        if (first) {
            [path moveToPoint:point];
            first = NO;
        } else {
            [path addLineToPoint:point];
        }
    }
    
    [path closePath];
    
    [path setLineWidth:2];
    
    [path stroke];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGSize size = self.bounds.size;
    
    CGContextTranslateCTM(ctx, size.width, size.height);
    CGContextScaleCTM(ctx, -1, -1);
    
    CGRect bounding = _observation.boundingBox;
    bounding.origin.x *= size.width;
    bounding.origin.y *= size.height;
    
    bounding.size.width *= size.width;
    bounding.size.height *= size.height;
    
    UIBezierPath * path = [UIBezierPath bezierPathWithRect:bounding];
    [path setLineWidth:3];
    
    [[UIColor greenColor] setStroke];
    [path stroke];
    
    VNFaceLandmarks2D * landmarks = _observation.landmarks;
    
    [[UIColor whiteColor] setStroke];
    
    [self drawFaceRegion:landmarks.leftEyebrow boundingBox:bounding];
    [self drawFaceRegion:landmarks.rightEyebrow boundingBox:bounding];
    
    [[UIColor greenColor] setStroke];
    
    [self drawFaceRegion:landmarks.leftEye boundingBox:bounding];
    [self drawFaceRegion:landmarks.rightEye boundingBox:bounding];
    
    [[UIColor yellowColor] setStroke];
    
    [self drawFaceRegion:landmarks.faceContour boundingBox:bounding];
    
    [self drawFaceRegion:landmarks.nose boundingBox:bounding];
    [self drawFaceRegion:landmarks.noseCrest boundingBox:bounding];
    [self drawFaceRegion:landmarks.medianLine boundingBox:bounding];
    
    [self drawFaceRegion:landmarks.leftPupil boundingBox:bounding];
    [self drawFaceRegion:landmarks.rightPupil boundingBox:bounding];
    
    [[UIColor redColor] setStroke];
    
    [self drawFaceRegion:landmarks.outerLips boundingBox:bounding];
    [self drawFaceRegion:landmarks.innerLips boundingBox:bounding];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    self.alpha = 0.0;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    self.alpha = 1.0;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    self.alpha = 1.0;
}

@end
