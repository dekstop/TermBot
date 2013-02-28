//
//  TermWindow.m
//  TermBot
//
//  Created by mongo on 28/02/2013.
//  Copyright (c) 2013 martind. All rights reserved.
//

#import "TermWindow.h"
#import "TermView.h"

@implementation TermWindow

TermView *termView;
NSTimer *timer;

float initialAlpha;
double startTime = 0;

- (id)initWithColor:(NSColor*)color
{
    self = [super
            initWithContentRect:NSMakeRect(0, 0, 100, 100)
            styleMask:NSBorderlessWindowMask
            backing:NSBackingStoreBuffered defer:NO
            //            screen:screen
            ];
    if (self)
    {
        initialAlpha = 0.5;
        timerInterval = 0.02;
        duration = 1.5;
        
        NSScreen *screen = [NSScreen mainScreen];
        [self setFrame:[screen frame] display:NO];
        
        [self setReleasedWhenClosed:NO];
        [self setLevel:NSScreenSaverWindowLevel];
        [self setIgnoresMouseEvents:YES];
        [self setOpaque:NO];
        [self setAlphaValue:0.0];
        
        termView = [[TermView alloc] initWithFrame:[self frame] color:color];
        [self.contentView addSubview:termView];
        [termView setText:@""];
    }
    return self;
}

- (void) showTerm:(NSString*)term
{
    if ([timer isValid]) {
        [timer invalidate]; // Stop active timer
    }

    [self setAlphaValue:0.0];
    [termView setText:term];
    
    startTime = CACurrentMediaTime();
    timer = [NSTimer scheduledTimerWithTimeInterval:timerInterval
                                             target:self
                                           selector:@selector(updateDisplayTimer)
                                           userInfo:nil
                                            repeats:YES];
    [self orderFront:nil];
}

- (void) updateDisplayTimer
{
    double elapsedTime = CACurrentMediaTime() - startTime;
    
    if (elapsedTime >= duration) {
        [self setAlphaValue:0];
        [timer invalidate];
        [self close];
    } else {
        float delta = elapsedTime / duration;
        [self setAlphaValue:initialAlpha*(1.0-delta)*(1.0-delta)];
    }
    
    [self display];
}

@end
