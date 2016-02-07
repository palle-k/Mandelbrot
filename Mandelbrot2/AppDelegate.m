//
//  AppDelegate.m
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

#import "AppDelegate.h"
#import "MandelbrotRenderViewController.h"
#import "CLMandelbrotView.h"

@interface AppDelegate ()

@end

@implementation AppDelegate
            
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	// Insert code here to tear down your application
}

- (IBAction)resetZoom:(id)sender
{
	[_mainViewController resetZoom:sender];
}

- (IBAction)zoomIn:(id)sender
{
	[_mainViewController zoomIn:sender];
}

- (IBAction)zoomOut:(id)sender
{
	[_mainViewController zoomOut:sender];
}

- (IBAction)increaseIterations:(id)sender
{
	[_mainViewController increaseIterations:sender];
}

- (IBAction)decreaseIterations:(id)sender
{
	[_mainViewController decreaseIterations:sender];
}

- (IBAction)increaseColorFactor:(id)sender
{
	[_mainViewController increaseColorFactor:sender];
}

- (IBAction)decreaseColorFactor:(id)sender
{
	[_mainViewController decreaseColorFactor:sender];
}

- (IBAction)increaseColorShift:(id)sender
{
	[_mainViewController increaseColorShift:sender];
}

- (IBAction)decreaseColorShift:(id)sender
{
	[_mainViewController decreaseColorShift:sender];
}

- (IBAction)saveSnapshot:(id)sender
{
	[_mainViewController saveSnapshot:sender];
}

- (IBAction)createAnimation:(id)sender
{
	[_mainViewController createAnimation:sender];
}

- (IBAction)showRenderView:(id)sender
{
	if (_mainViewController)
	{
		[_mainViewController.view.window makeKeyWindow];
	}
	else
	{
		_mandelbrotRenderWindow = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateInitialController];
	}
}

- (IBAction)showControlPanel:(id)sender
{
	[_mainViewController showControlPanel:sender];
}

- (IBAction)setColorMode:(NSMenuItem *)sender
{
	if (sender == _miIterationBasedColoring)
	{
		_miZeroPointBasedColoring.state = NSOffState;
		_miZeroPointBasedColoring.enabled = YES;
		_miCombinedColoring.state = NSOffState;
		_miCombinedColoring.enabled = YES;
		_miIterationBasedColoring.enabled = NO;
		_mainViewController.mandelbrotView.color_mode = 0;
	}
	else if (sender == _miZeroPointBasedColoring)
	{
		_miIterationBasedColoring.state = NSOffState;
		_miIterationBasedColoring.enabled = YES;
		_miCombinedColoring.state = NSOffState;
		_miCombinedColoring.enabled = YES;
		_miZeroPointBasedColoring.enabled = NO;
		_mainViewController.mandelbrotView.color_mode = 1;
	}
	else
	{
		_miIterationBasedColoring.state = NSOffState;
		_miIterationBasedColoring.enabled = YES;
		_miZeroPointBasedColoring.state = NSOffState;
		_miZeroPointBasedColoring.enabled = YES;
		_miCombinedColoring.enabled = NO;
		_mainViewController.mandelbrotView.color_mode = 2;
	}
}

- (IBAction)setColorScale:(NSMenuItem *)sender
{
	if (sender == _miLinearColoring)
	{
		_miLogarithmicColoring.state = NSOffState;
		_miRootColoring.state = NSOffState;
		_miInverseColoring.state = NSOffState;
		_miLogarithmicColoring.enabled = YES;
		_miRootColoring.enabled = YES;
		_miInverseColoring.enabled = YES;
		_mainViewController.mandelbrotView.color_scale = 0;
	}
	else if (sender == _miLogarithmicColoring)
	{
		_miLinearColoring.state = NSOffState;
		_miRootColoring.state = NSOffState;
		_miInverseColoring.state = NSOffState;
		_miLinearColoring.enabled = YES;
		_miRootColoring.enabled = YES;
		_miInverseColoring.enabled = YES;
		_mainViewController.mandelbrotView.color_scale = 1;

	}
	else if (sender == _miInverseColoring)
	{
		_miLinearColoring.state = NSOffState;
		_miRootColoring.state = NSOffState;
		_miLogarithmicColoring.state = NSOffState;
		_miLinearColoring.enabled = YES;
		_miRootColoring.enabled = YES;
		_miLogarithmicColoring.enabled = YES;
		_mainViewController.mandelbrotView.color_scale = 2;
	}
	else
	{
		_miLinearColoring.state = NSOffState;
		_miInverseColoring.state = NSOffState;
		_miLogarithmicColoring.state = NSOffState;
		_miLinearColoring.enabled = YES;
		_miInverseColoring.enabled = YES;
		_miLogarithmicColoring.enabled = YES;
		_mainViewController.mandelbrotView.color_scale = 3;
	}
	sender.state = NSOnState;
	sender.enabled = NO;
	
}

- (IBAction)setSmoothColor:(NSMenuItem *)sender
{
	if (sender.state == NSOnState)
		sender.state = NSOffState;
	else
		sender.state = NSOnState;
	_mainViewController.mandelbrotView.smooth_coloring = sender.state == NSOnState;
}

@end
