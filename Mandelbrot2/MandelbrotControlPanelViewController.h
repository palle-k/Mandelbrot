//
//  MandelbrotControlPanelViewController.h
//  Mandelbrot2
//
//  Created by Palle Klewitz on 11.08.15.
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
#import "CLMandelbrotView.h"

@interface MandelbrotControlPanelViewController : NSViewController <CLMandelbrotViewControlDelegate>

@property (weak) IBOutlet NSTextField *txtPositionX;
@property (weak) IBOutlet NSTextField *txtPositionY;
@property (weak) IBOutlet NSTextField *txtZoom;
@property (weak) IBOutlet NSTextField *txtIterations;
@property (weak) IBOutlet NSTextField *txtColorFactor;
@property (weak) IBOutlet NSTextField *txtColorShift;
@property (weak) IBOutlet NSProgressIndicator *piRenderProgress;


- (IBAction)fastRenderingToggled:(NSButton *)sender;
- (IBAction)applySettings:(id)sender;

@end
