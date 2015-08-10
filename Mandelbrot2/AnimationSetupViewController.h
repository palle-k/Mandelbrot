//
//  AnimationSetupViewController.h
//  Mandelbrot2
//
//  Created by Palle Klewitz on 07.08.15.
//  Copyright © 2015 Palle Klewitz. All rights reserved.
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
