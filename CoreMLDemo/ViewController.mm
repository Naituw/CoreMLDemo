//
//  ViewController.m
//  CoreMLDemo
//
//  Created by wutian on 2017/6/26.
//  Copyright © 2017年 Weibo. All rights reserved.
//

#import "ViewController.h"
#import "DemoPanel.h"
#import <AVFoundation/AVFoundation.h>
#import <Vision/Vision.h>
#import "Resnet50.h"
#import "FaceLandmarkView.h"

#define let auto const

typedef NS_ENUM(NSInteger, VisionMode) {
    VisionModeCoreML = 0,
    VisionModeFaceLandmark,
};

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession * session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * previewLayer;
@property (nonatomic, strong) dispatch_queue_t captureQueue;

@property (nonatomic, strong) DemoPanel * demoPanel;
@property (nonatomic, strong) FaceLandmarkView * faceLandmarkView;

@property (nonatomic, strong) VNRequest * visionCoreMLRequest;
@property (nonatomic, strong) VNRequest * visionFaceLandmarkRequest;

@property (nonatomic, assign) VisionMode visionMode;
@property (nonatomic, strong) AVCaptureInput * currentInput;
@property (nonatomic, strong) AVCaptureOutput * currentOutput;

@property (nonatomic, strong) VNSequenceRequestHandler * sequenceRequestHandler;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupVisionRequests];
    
    _captureQueue = dispatch_queue_create("com.wutian.CaptureQueue", DISPATCH_QUEUE_SERIAL);
    
    _session = [[AVCaptureSession alloc] init];
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
    
    [self.view.layer addSublayer:_previewLayer];
    
    let videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [videoOutput setSampleBufferDelegate:self queue:_captureQueue];
    [videoOutput setAlwaysDiscardsLateVideoFrames:YES];
    [videoOutput setVideoSettings:@{(NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}];
    
    _session.sessionPreset = AVCaptureSessionPresetHigh;
    
    _currentOutput = videoOutput;
    [_session addOutput:videoOutput];
    
    _visionMode = VisionModeFaceLandmark;
    self.visionMode = VisionModeCoreML;
    
    [_session startRunning];
    
    _faceLandmarkView = [[FaceLandmarkView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_faceLandmarkView];
    
    _demoPanel = [[DemoPanel alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [_demoPanel.segmentedControl addTarget:self action:@selector(segmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_demoPanel];
}

- (void)viewWillLayoutSubviews
{
    _previewLayer.frame = self.view.bounds;
    
    CGFloat panelPadding = 10;
    CGFloat panelHeight = 160;
    CGFloat panelAreaHeight = panelHeight + 2 * panelPadding;
    
    CGRect panelArea = CGRectMake(0, self.view.bounds.size.height - panelAreaHeight, self.view.bounds.size.width, panelAreaHeight);
    
    _faceLandmarkView.frame = self.view.bounds;
    _demoPanel.frame = CGRectInset(panelArea, panelPadding, panelPadding);
}

- (void)setupVisionRequests
{
    let model = [Resnet50 new];
    
    let visionModel = [VNCoreMLModel modelForMLModel:model.model error:NULL];
    
    let classificationRequest = [[VNCoreMLRequest alloc] initWithModel:visionModel completionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        
        if (_visionMode != VisionModeCoreML) {
            return;
        }
        
        if (error) {
            return NSLog(@"Failed: %@", error);
        }
        let observations = request.results;
        if (!observations.count) {
            return NSLog(@"No Results");
        }
        
        VNClassificationObservation * observation = nil;
        for (VNClassificationObservation * ob in observations) {
            if (![ob isKindOfClass:[VNClassificationObservation class]]) {
                continue;
            }
            if (!observation) {
                observation = ob;
                continue;
            }
            if (observation.confidence < ob.confidence) {
                observation = ob;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString * text = [NSString stringWithFormat:@"%@ (%.0f%%)", [[observation.identifier componentsSeparatedByString:@", "] firstObject], observation.confidence * 100];
            _demoPanel.text = text;
        });
    }];
    
    _visionCoreMLRequest = classificationRequest;
    
    let faceRequest = [[VNDetectFaceLandmarksRequest alloc] initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        
        if (_visionMode != VisionModeFaceLandmark) {
            return;
        }
        
        void (^finish)(VNFaceObservation *, NSString *) = ^(VNFaceObservation * ob, NSString * text) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _faceLandmarkView.observation = ob;
                _demoPanel.text = text;
            });
        };
        
        if (error) {
            return finish(nil, error.description);
        }
        let observations = request.results;
        if (!observations.count) {
            return finish(nil, @"未识别人脸");
        }
        
        VNFaceObservation * observation = nil;
        for (VNFaceObservation * ob in observations) {
            if (![ob isKindOfClass:[VNFaceObservation class]]) {
                continue;
            }
            if (!observation) {
                observation = ob;
                continue;
            }
            if (observation.confidence < ob.confidence) {
                observation = ob;
            }
        }
        
        finish(observation, [NSString stringWithFormat:@"(%.0f%%)", observation.confidence * 100]);
    }];
    
    _visionFaceLandmarkRequest = faceRequest;
}

- (AVCaptureDevice *)deviceWithPosition:(AVCaptureDevicePosition)position
{
    return [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:position];
}

- (void)setVisionMode:(VisionMode)visionMode
{
    if (_visionMode != visionMode) {
        _visionMode = visionMode;
        
        [_session beginConfiguration];
        
        if (_currentInput) {
            [_session removeInput:_currentInput];
            _currentInput = nil;
        }
        
        let camera = [self deviceWithPosition:(visionMode == VisionModeFaceLandmark) ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack];
        let cameraInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:NULL];
        _currentInput = cameraInput;
        [_session addInput:cameraInput];
        
        let conn = [_currentOutput connectionWithMediaType:AVMediaTypeVideo];
        conn.videoOrientation = AVCaptureVideoOrientationPortrait;
        
        [_session commitConfiguration];
    }
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (!pixelBuffer) {
        return;
    }
    
    AVCaptureInput * input = connection.inputPorts.firstObject.input;
    if (input != _currentInput) {
        return;
    }
    
    NSMutableDictionary * requestOptions = [NSMutableDictionary dictionary];
    let cameraIntrinsicData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil);
    if (cameraIntrinsicData) {
        requestOptions[VNImageOptionCameraIntrinsics] = (__bridge NSData *)cameraIntrinsicData;
    }
    
    if (!_sequenceRequestHandler) {
        _sequenceRequestHandler = [[VNSequenceRequestHandler alloc] init];
    }
    
    [_sequenceRequestHandler performRequests:(_visionMode == VisionModeFaceLandmark) ? @[_visionFaceLandmarkRequest] : @[_visionCoreMLRequest] onCVPixelBuffer:pixelBuffer error:NULL];
}

- (void)segmentedControlChanged:(id)sender
{
    self.visionMode = (VisionMode)_demoPanel.segmentedControl.selectedSegmentIndex;
    self.demoPanel.text = @"初始化...";
    self.faceLandmarkView.observation = nil;
    _sequenceRequestHandler = nil;
}

@end
