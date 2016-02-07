//
//  ViewController.h
//  Mandelbrot2
//
//  Created by Palle Klewitz on 16.08.14.
//  Copyright (c) 2014 - 2016 Palle Klewitz.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is furnished
//  to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

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

- (void)showControlPanel:(id)sender;

@end

