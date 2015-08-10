//
//  UnifiedTitleBarWindowController.h
//  Mandelbrot2
//
//  Created by Palle Klewitz on 06.08.15.
//  Copyright © 2015 Palle Klewitz. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface UnifiedTitleBarWindowController : NSWindowController

@property (nonatomic) IBInspectable NSWindowTitleVisibility titleVisibility;
@property (nonatomic) IBInspectable BOOL shouldHideTitle;

@end
