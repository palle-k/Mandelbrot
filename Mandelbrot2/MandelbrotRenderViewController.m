//
//  ViewController.m
//  Mandelbrot2
//
//  Created by Palle Klewitz on 16.08.14.
//  Copyright (c) 2014 Palle Klewitz. All rights reserved.
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

@property (nonatomic, strong) UnifiedTitleBarWindowController *animationWindow;

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
	_animationWindow = [self.storyboard instantiateControllerWithIdentifier:CreateAnimationWindow];
	[_animationWindow showWindow:_animationWindow.window];
}

@end
