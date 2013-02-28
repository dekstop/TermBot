//
//  TermView.m
//  TermBot
//
//  Created by mongo on 28/02/2013.
//  Copyright (c) 2013 martind. All rights reserved.
//

#import "TermView.h"

@implementation TermView

NSString *term;
NSFont *font;
NSMutableDictionary *fontAttrs;
NSPoint screenCenter;
NSPoint drawOffset;

- (id)initWithFrame:(NSRect)frame color:(NSColor*)color;
{
    self = [super initWithFrame:frame];
    if (self) {
        screenCenter.x = frame.origin.x + frame.size.width/2;
        screenCenter.y = frame.origin.y + frame.size.height/2;
        font = [NSFont fontWithName:@"Helvetica" size:100]; // Some arbitrary default size
        fontAttrs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                     font, NSFontAttributeName,
                     color, NSForegroundColorAttributeName,
                     nil];
    }
    
    return self;
}

- (void)setText:(NSString*)_term
{
    term = _term;
    [self updateFontAttrs];
}

- (void) updateFontAttrs
{
    if ([term length]==0) {
        return;
    }
    float viewWidth = [self frame].size.width;
    float viewHeight = [self frame].size.width;

    NSSize textSize;
    float mulX, mulY;
    do {
        textSize = [term sizeWithAttributes:fontAttrs];
        mulX = viewWidth / textSize.width;
        mulY = viewHeight / textSize.height;
    
        NSLog(@"%f %f %f", mulX, mulY, MAX(ABS(1-mulX), ABS(1-mulY)));

        float fontSize = [font pointSize] * MIN(mulX, mulY);
        
        font = [NSFont fontWithName:[font fontName] size:fontSize];
        [fontAttrs setValue:font forKey:NSFontAttributeName];

    } while (MIN(ABS(1-mulX), ABS(1-mulY))>0.1); // Max. 10% deviation

    drawOffset.x = screenCenter.x - textSize.width / 2;
    drawOffset.y = screenCenter.y - textSize.height / 2;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor clearColor] set];
    NSRectFill([self frame]);
    
    [term drawAtPoint:drawOffset withAttributes:fontAttrs];
}

@end
