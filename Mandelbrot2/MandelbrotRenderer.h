//
//  MandelbrotRenderer.h
//  Mandelbrot2
//
//  Created by Palle Klewitz on 06.08.15.
//  Copyright © 2015 Palle Klewitz. All rights reserved.
//

@import Foundation;
@class CLMandelbrotView;
@class MandelbrotRenderer;
#import "CLMandelbrotView.h"

@protocol MandelbrotRendererDelegate <NSObject>

- (void) mandelbrotRenderer: (nonnull MandelbrotRenderer *) renderer didFailWithError:(nullable NSError *) error;
- (void) didUpdateProgress;
- (void) didFinishRendering;

@end

@interface MandelbrotRenderer : NSObject <CLMandelbrotViewDelegate, NSProgressReporting>

@property (nonatomic, weak) CLMandelbrotView *mandelbrotView;
@property (nonatomic, weak) id<MandelbrotRendererDelegate> delegate;

@property (nonatomic) double startX;
@property (nonatomic) double startY;
@property (nonatomic) double startZoom;
@property (nonatomic) unsigned int startIterations;
@property (nonatomic) double startColorFactor;
@property (nonatomic) double startColorShift;

@property (nonatomic) double endX;
@property (nonatomic) double endY;
@property (nonatomic) double endZoom;
@property (nonatomic) unsigned int endIterations;
@property (nonatomic) double endColorFactor;
@property (nonatomic) double endColorShift;

@property (nonatomic, strong, nullable) NSURL *targetFile;

@property (nonatomic) double frames_per_second;
@property (nonatomic) NSTimeInterval video_length;
@property (nonatomic, readonly) unsigned int frame;

- (void) startRendering;

@end
