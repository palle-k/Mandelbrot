//
//  UnifiedTitleBarWindowController.m
//  Mandelbrot2
//
//  Created by Palle Klewitz on 06.08.15.
//  Copyright © 2015 Palle Klewitz. All rights reserved.
//

#import "UnifiedTitleBarWindowController.h"

@interface UnifiedTitleBarWindowController ()

@end

@implementation UnifiedTitleBarWindowController

- (void) windowDidLoad
{
    [super windowDidLoad];
	self.window.titleVisibility = _shouldHideTitle ? NSWindowTitleHidden : NSWindowTitleVisible;
	self.window.titlebarAppearsTransparent = YES;
}

- (void)setTitleVisibility:(NSWindowTitleVisibility)titleVisibility
{
	self.window.titleVisibility = titleVisibility;
	_titleVisibility = titleVisibility;
}

- (void)setShouldHideTitle:(BOOL)shouldHideTitle
{
	_shouldHideTitle = shouldHideTitle;
	self.window.titleVisibility = _shouldHideTitle ? NSWindowTitleHidden : NSWindowTitleVisible;
}

@end
