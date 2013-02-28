//
//  TermView.h
//  TermBot
//
//  Created by mongo on 28/02/2013.
//  Copyright (c) 2013 martind. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TermView : NSView

- (id)initWithFrame:(NSRect)frame color:(NSColor*)color;
- (void)setText:(NSString*)term;

@end
