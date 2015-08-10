//
//  ViewController.h
//  Mandelbrot2
//
//  Created by Palle Klewitz on 16.08.14.
//  Copyright (c) 2014 Palle Klewitz. All rights

@import Cocoa;
@class CLMandelbrotView;

@interface MandelbrotRenderViewController : NSViewController

@property (weak) IBOutlet CLMandelbrotView *mandelbrotView;

- (IBAction)didRecognizeMagnificationGesture:(NSMagnificationGestureRecognizer *)sender;
- (IBAction)didRecognizePanGesture:(NSPanGestureRecognizer *)sender;

- (void)resetZoom:(id)sender;
- (void)zoomIn:(id)sender;
- (void)zoomOut:(id)sender;

- (void)increaseIterations:(id)sender;
- (void)decreaseIterations:(id)sender;

- (void)increaseColorFactor:(id)sender;
- (void)decreaseColorFactor:(id)sender;

- (void)increaseColorShift:(id)sender;
- (void)decreaseColorShift:(id)sender;

- (void)saveSnapshot:(id)sender;
- (void)createAnimation:(id)sender;

@end

