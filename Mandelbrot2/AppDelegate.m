//
//  AppDelegate.m
//  Mandelbrot2
//
//  Created by Palle Klewitz on 16.08.14.
//  Copyright (c) 2014 Palle Klewitz. All rights reserved.
//

#import "AppDelegate.h"
#import "MandelbrotRenderViewController.h"

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
		
	}
}

- (IBAction)showControlPanel:(id)sender
{
	
}
@end
