//
//  AnimationSetupViewController.h
//  Mandelbrot2
//
//  Created by Palle Klewitz on 07.08.15.
//  Copyright © 2015 - 2016 Palle Klewitz.
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
#import "MandelbrotRenderer.h"

@interface AnimationSetupViewController : NSViewController <MandelbrotRendererDelegate>

@property (weak) IBOutlet NSTextField *txtStartPositionX;
@property (weak) IBOutlet NSTextField *txtStartPositionY;
@property (weak) IBOutlet NSTextField *txtStartZoom;
@property (weak) IBOutlet NSTextField *txtStartIterations;
@property (weak) IBOutlet NSTextField *txtStartColorFactor;
@property (weak) IBOutlet NSTextField *txtStartColorShift;

@property (weak) IBOutlet NSTextField *txtEndPositionX;
@property (weak) IBOutlet NSTextField *txtEndPositionY;
@property (weak) IBOutlet NSTextField *txtEndZoom;
@property (weak) IBOutlet NSTextField *txtEndIterations;
@property (weak) IBOutlet NSTextField *txtEndColorFactor;
@property (weak) IBOutlet NSTextField *txtEndColorShift;

@property (weak) IBOutlet NSTextField *txtVideoFramesPerSecond;
@property (weak) IBOutlet NSTextField *txtVideoLength;

@property (weak) IBOutlet NSProgressIndicator *piRenderProgress;

- (IBAction)renderButtonClicked:(id)sender;

@end
