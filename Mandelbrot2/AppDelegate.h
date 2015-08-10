//
//  AppDelegate.h
//  Mandelbrot2
//
//  Created by Palle Klewitz on 16.08.14.
//  Copyright (c) 2014 Palle Klewitz. All rights reserved.
//

@import Cocoa;
@class MandelbrotRenderViewController;

#define CreateAnimationWindow @"CreateAnimationWindow"
#define MandelbrotRenderWindow @"MandelbrotRenderWindow"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, weak) MandelbrotRenderViewController *mainViewController;

- (IBAction)resetZoom:(id)sender;
- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;

- (IBAction)increaseIterations:(id)sender;
- (IBAction)decreaseIterations:(id)sender;

- (IBAction)increaseColorFactor:(id)sender;
- (IBAction)decreaseColorFactor:(id)sender;

- (IBAction)increaseColorShift:(id)sender;
- (IBAction)decreaseColorShift:(id)sender;

- (IBAction)saveSnapshot:(id)sender;
- (IBAction)createAnimation:(id)sender;

- (IBAction)showRenderView:(id)sender;
- (IBAction)showControlPanel:(id)sender;
@end

