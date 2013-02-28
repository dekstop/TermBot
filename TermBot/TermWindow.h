//
//  TermWindow.h
//  TermBot
//
//  Created by mongo on 28/02/2013.
//  Copyright (c) 2013 martind. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TermWindow : NSWindow {
    float timerInterval;
    float duration;
}

- (id)initWithColor:(NSColor*)color;
- (void)showTerm:(NSString*)term;

@end
