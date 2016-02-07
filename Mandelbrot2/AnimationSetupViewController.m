//
//  AnimationSetupViewController.m
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

#import "AnimationSetupViewController.h"
#import "MandelbrotRenderer.h"
#import "AppDelegate.h"
#import "MandelbrotRenderViewController.h"

@interface AnimationSetupViewController ()

@property (nonatomic, strong) MandelbrotRenderer *renderer;

@end

@implementation AnimationSetupViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	_piRenderProgress.hidden = YES;
	
	AppDelegate *del = (AppDelegate *)([NSApplication sharedApplication].delegate);
	CLMandelbrotView *mandelbrotView = del.mainViewController.mandelbrotView;
	del = nil;
	
	_txtStartPositionX.doubleValue = mandelbrotView.shift.x;
	_txtStartPositionY.doubleValue = mandelbrotView.shift.y;
	_txtStartZoom.doubleValue = mandelbrotView.zoom;
	_txtStartIterations.integerValue = mandelbrotView.iterations;
	_txtStartColorFactor.doubleValue = mandelbrotView.color_factor;
	_txtStartColorShift.doubleValue = mandelbrotView.color_shift;
	
	_txtEndPositionX.doubleValue = mandelbrotView.shift.x;
	_txtEndPositionY.doubleValue = mandelbrotView.shift.y;
	_txtEndZoom.doubleValue = mandelbrotView.zoom;
	_txtEndIterations.integerValue = mandelbrotView.iterations;
	_txtEndColorFactor.doubleValue = mandelbrotView.color_factor;
	_txtEndColorShift.doubleValue = mandelbrotView.color_shift;
}

- (IBAction)renderButtonClicked:(id)sender
{
	NSSavePanel *savePanel = [[NSSavePanel alloc] init];
	savePanel.title = @"Save Animation";
	savePanel.showsHiddenFiles = NO;
	savePanel.canCreateDirectories = YES;
	savePanel.nameFieldStringValue = @"MandelbrotAnimation.mov";
	savePanel.allowedFileTypes = @[@"mov"];
	[savePanel beginSheetModalForWindow:self.view.window completionHandler:
	 ^(NSInteger result)
	 {
		 if (result == NSModalResponseOK)
		 {
			 _renderer = [[MandelbrotRenderer alloc] init];
			 _renderer.delegate = self;
			 _renderer.targetFile = [NSURL URLWithString:@"file:///Users/Palle/Desktop/mandelbrotanim.mov"];
			 [self startRendering];
		 }
	 }];
}

- (void) startRendering
{
	_piRenderProgress.hidden = NO;
	
	AppDelegate *del = (AppDelegate *)([NSApplication sharedApplication].delegate);
	_renderer.mandelbrotView = del.mainViewController.mandelbrotView;
	del = nil;
	
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	formatter.numberStyle = NSNumberFormatterDecimalStyle;
	
	_renderer.startX = [formatter numberFromString:_txtStartPositionX.stringValue].doubleValue;
	_renderer.startY = [formatter numberFromString:_txtStartPositionY.stringValue].doubleValue;
	_renderer.startZoom = [formatter numberFromString:_txtStartZoom.stringValue].doubleValue;
	_renderer.startIterations = (unsigned int)[formatter numberFromString:_txtStartIterations.stringValue].integerValue;
	_renderer.startColorFactor = [formatter numberFromString:_txtStartColorFactor.stringValue].doubleValue;;
	_renderer.startColorShift = [formatter numberFromString:_txtStartColorShift.stringValue].doubleValue;
	
	_renderer.endX = [formatter numberFromString:_txtEndPositionX.stringValue].doubleValue;
	_renderer.endY = [formatter numberFromString:_txtEndPositionY.stringValue].doubleValue;
	_renderer.endZoom = [formatter numberFromString:_txtEndZoom.stringValue].doubleValue;
	_renderer.endIterations = (unsigned int)[formatter numberFromString:_txtEndIterations.stringValue].integerValue;
	_renderer.endColorFactor = [formatter numberFromString:_txtEndColorFactor.stringValue].doubleValue;;
	_renderer.endColorShift = [formatter numberFromString:_txtEndColorShift.stringValue].doubleValue;
	
	_renderer.frames_per_second = _txtVideoFramesPerSecond.doubleValue;
	_renderer.video_length = _txtVideoLength.doubleValue;
	
	[_renderer startRendering];
}

- (void)didUpdateProgress
{
	dispatch_async(dispatch_get_main_queue(),
	^{
		_piRenderProgress.doubleValue = (double)_renderer.frame / (double) (_renderer.frames_per_second * _renderer.video_length) * 100;
	});
	
}

- (void)didFinishRendering
{
	dispatch_async(dispatch_get_main_queue(),
	^{
		_piRenderProgress.hidden = YES;
	});
}

- (void)mandelbrotRenderer:(MandelbrotRenderer *)renderer didFailWithError:(NSError *)error
{
	
}

@end
