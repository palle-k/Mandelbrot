//
//  ViewController.m
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

#import "MandelbrotRenderViewController.h"
#import "AppDelegate.h"
#import "CLMandelbrotView.h"
#import "UnifiedTitleBarWindowController.h"

@interface MandelbrotRenderViewController ()

@property (nonatomic) BOOL magnificating;
@property (nonatomic) BOOL panning;

@property (nonatomic) double referenceMagnification;
@property (nonatomic) CGPoint referencePosition;

@end

@implementation MandelbrotRenderViewController
            
- (void)viewDidLoad
{
	[super viewDidLoad];
	AppDelegate *appDel = [NSApplication sharedApplication].delegate;
	appDel.mainViewController = self;
}

- (void)viewDidAppear
{
	[_mandelbrotView setup];
}

- (void)setRepresentedObject:(id)representedObject
{
	[super setRepresentedObject:representedObject];
	                            
}

- (IBAction)didRecognizeMagnificationGesture:(NSMagnificationGestureRecognizer *)sender
{
	if (_mandelbrotView.userInteractionDisabled)
		return;
	if (sender.state == NSGestureRecognizerStateBegan)
	{
		_magnificating = YES;
		[_mandelbrotView usePreviewMode:YES];
		_referenceMagnification = 0;
	}
	else if (sender.state == NSGestureRecognizerStateChanged)
	{
		_mandelbrotView.zoom *= (sender.magnification - _referenceMagnification) + 1;
		_referenceMagnification = sender.magnification;
	}
	else if (sender.state == NSGestureRecognizerStateEnded || sender.state == NSGestureRecognizerStateFailed || sender.state == NSGestureRecognizerStateCancelled)
	{
		_magnificating = NO;
		[_mandelbrotView usePreviewMode:_panning];
	}
}

- (IBAction)didRecognizePanGesture:(NSPanGestureRecognizer *)sender
{
	if (_mandelbrotView.userInteractionDisabled)
		return;
	if (sender.state == NSGestureRecognizerStateBegan)
	{
		_panning = YES;
		[_mandelbrotView usePreviewMode:YES];
		_referencePosition = [sender locationInView:_mandelbrotView];
	}
	else if (sender.state == NSGestureRecognizerStateChanged)
	{
		CGPoint newPoint = [sender locationInView:_mandelbrotView];
		[_mandelbrotView shiftBy:CGVectorMake(newPoint.x - _referencePosition.x, newPoint.y - _referencePosition.y)];
		_referencePosition = newPoint;
	}
	else if (sender.state == NSGestureRecognizerStateEnded || sender.state == NSGestureRecognizerStateFailed || sender.state == NSGestureRecognizerStateCancelled)
	{
		_panning = NO;
		[_mandelbrotView usePreviewMode:NO];
	}
}

- (void)resetZoom:(id)sender
{
	_mandelbrotView.zoom = 1;
}

- (void)zoomIn:(id)sender
{
	_mandelbrotView.zoom *= 2;
}

- (void)zoomOut:(id)sender
{
	_mandelbrotView.zoom *= 0.5;
}

- (void)increaseIterations:(id)sender
{
	_mandelbrotView.iterations *= 2;
}

- (void)decreaseIterations:(id)sender
{
	_mandelbrotView.iterations /= 2;
	if (_mandelbrotView.iterations == 0)
		_mandelbrotView.iterations = 1;
}

- (void)increaseColorFactor:(id)sender
{
	_mandelbrotView.color_factor *= 2;
}

- (void)decreaseColorFactor:(id)sender
{
	_mandelbrotView.color_factor *= 0.5;
}

- (void)increaseColorShift:(id)sender
{
	_mandelbrotView.color_shift += 0.5;
}

- (void)decreaseColorShift:(id)sender
{
	_mandelbrotView.color_shift -= 0.5;
}

- (void)saveSnapshot:(id)sender
{
	NSBitmapImageRep *bitmap = [_mandelbrotView getShnapshot];
	NSData *bitmapData = [bitmap representationUsingType:NSPNGFileType properties:[[NSDictionary alloc] init]];
	
	NSSavePanel *savePanel = [[NSSavePanel alloc] init];
	savePanel.title = @"Save Snapshot";
	savePanel.showsHiddenFiles = NO;
	savePanel.canCreateDirectories = YES;
	savePanel.nameFieldStringValue = @"MandelbrotSnapshot.png";
	savePanel.allowedFileTypes = @[@"png"];
	[savePanel beginSheetModalForWindow:self.view.window completionHandler:
	 ^(NSInteger result)
	{
		if (result == NSModalResponseOK)
		{
			if ([bitmapData writeToURL:savePanel.URL atomically:YES] == NO)
			{
				NSAlert *alert = [[NSAlert alloc] init];
				alert.messageText = @"Cannot Save Image";
				[alert runModal];
			}
		}
	}];
}

- (void)createAnimation:(id)sender
{
	NSWindowController *animationWindowController = [self.storyboard instantiateControllerWithIdentifier:CreateAnimationWindow];
	[animationWindowController showWindow:animationWindowController.window];
	AppDelegate *appDel = [NSApplication sharedApplication].delegate;
	appDel.mandelbrotAnimationWindow = animationWindowController;
}

- (void)showControlPanel:(id)sender
{
	NSWindowController *controlPanelWindowController = [self.storyboard instantiateControllerWithIdentifier:MandelbrotControlPanel];
	[controlPanelWindowController showWindow:controlPanelWindowController.window];
	AppDelegate *appDel = [NSApplication sharedApplication].delegate;
	appDel.mandelbrotControlPanel = controlPanelWindowController;
}

@end
