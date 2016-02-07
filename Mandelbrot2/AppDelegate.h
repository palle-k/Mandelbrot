//
//  AppDelegate.h
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
@class MandelbrotRenderViewController;

#define CreateAnimationWindow @"CreateAnimationWindow"
#define MandelbrotRenderWindow @"MandelbrotRenderWindow"
#define MandelbrotControlPanel @"MandelbrotControlPanel"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong) NSWindowController *mandelbrotRenderWindow;
@property (nonatomic, strong) NSWindowController *mandelbrotControlPanel;
@property (nonatomic, strong) NSWindowController *mandelbrotAnimationWindow;
@property (nonatomic, weak) MandelbrotRenderViewController *mainViewController;
@property (weak) IBOutlet NSMenuItem *miIterationBasedColoring;
@property (weak) IBOutlet NSMenuItem *miZeroPointBasedColoring;
@property (weak) IBOutlet NSMenuItem *miCombinedColoring;
@property (weak) IBOutlet NSMenuItem *miLinearColoring;
@property (weak) IBOutlet NSMenuItem *miLogarithmicColoring;
@property (weak) IBOutlet NSMenuItem *miInverseColoring;
@property (weak) IBOutlet NSMenuItem *miRootColoring;

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

- (IBAction)setColorMode:(NSMenuItem *)sender;
- (IBAction)setColorScale:(NSMenuItem *)sender;
- (IBAction)setSmoothColor:(NSMenuItem *)sender;

@end

