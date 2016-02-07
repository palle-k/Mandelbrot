//
//  MandelbrotControlPanelViewController.m
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

#import "MandelbrotControlPanelViewController.h"
#import "AppDelegate.h"
#import "CLMandelbrotView.h"
#import "MandelbrotRenderViewController.h"

@interface MandelbrotControlPanelViewController ()

@property (nonatomic, weak) CLMandelbrotView *mandelbrotView;

@end

@implementation MandelbrotControlPanelViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	AppDelegate *del = (AppDelegate *)([NSApplication sharedApplication].delegate);
	_mandelbrotView = del.mainViewController.mandelbrotView;
	del = nil;
	
	_mandelbrotView.progressDelegate = self;
	
	_txtPositionX.doubleValue = _mandelbrotView.shift.x;
	_txtPositionY.doubleValue = _mandelbrotView.shift.y;
	_txtZoom.doubleValue = _mandelbrotView.zoom;
	_txtIterations.integerValue = _mandelbrotView.iterations;
	_txtColorFactor.doubleValue = _mandelbrotView.color_factor;
	_txtColorShift.doubleValue = _mandelbrotView.color_shift;
}

- (IBAction)fastRenderingToggled:(NSButton *)sender
{
	_mandelbrotView.optimizeSpeed = sender.state == NSOnState;
}

- (IBAction)applySettings:(id)sender
{
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	formatter.numberStyle = NSNumberFormatterDecimalStyle;
	
	_mandelbrotView.disableAutomaticUpdates = YES;
	
	cl_double2 pos;
	pos.x = [formatter numberFromString:_txtPositionX.stringValue].doubleValue;
	pos.y = [formatter numberFromString:_txtPositionY.stringValue].doubleValue;
	_mandelbrotView.shift = pos;
	_mandelbrotView.zoom = [formatter numberFromString:_txtZoom.stringValue].doubleValue;
	_mandelbrotView.iterations = [formatter numberFromString:_txtIterations.stringValue].unsignedIntValue;
	_mandelbrotView.color_factor = [formatter numberFromString:_txtColorFactor.stringValue].doubleValue;
	_mandelbrotView.color_shift = [formatter numberFromString:_txtColorShift.stringValue].doubleValue;
	
	[_mandelbrotView updateCL];
	_mandelbrotView.disableAutomaticUpdates = NO;
}

- (void)mandelbrotView:(CLMandelbrotView *)mandelbrotView didUpdateProgress:(NSProgress *)progress
{
	_piRenderProgress.maxValue = progress.totalUnitCount;
	_piRenderProgress.doubleValue = progress.completedUnitCount;
}

- (void)mandelbrotViewDidChangeSetup:(CLMandelbrotView *)mandelbrotView
{
	_txtPositionX.doubleValue = _mandelbrotView.shift.x;
	_txtPositionY.doubleValue = _mandelbrotView.shift.y;
	_txtZoom.doubleValue = _mandelbrotView.zoom;
	_txtIterations.integerValue = _mandelbrotView.iterations;
	_txtColorFactor.doubleValue = _mandelbrotView.color_factor;
	_txtColorShift.doubleValue = _mandelbrotView.color_shift;
}

@end
