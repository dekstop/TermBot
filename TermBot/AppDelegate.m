//
//  AppDelegate.m
//  TermBot
//
//  Created by mongo on 27/02/2013.
//  Copyright (c) 2013 martind. All rights reserved.
//

#import "AppDelegate.h"
#import "TermWindow.h"

#import <Carbon/Carbon.h>

@implementation AppDelegate

NSMutableArray *chars;
TermWindow *termWindow;

- (id)init {
    if (self = [super init]) {
        chars = [[NSMutableArray alloc] init];
        termWindow = [[TermWindow alloc] initWithColor:[NSColor redColor]];
    }
    return self;
}
        
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Register global event monitors -- may require assistive device access.
    [NSEvent addGlobalMonitorForEventsMatchingMask:NSKeyDownMask handler:^(NSEvent *event){
        if ([event type] == NSKeyDown) {
            if ([[event charactersIgnoringModifiers] isEqualToString:@"?"] ||
                [[event charactersIgnoringModifiers] isEqualToString:@""]) {
                NSLog(@"%d %@§§ %@", [event keyCode], [event characters], [event charactersIgnoringModifiers]);
            }
    //        NSUInteger printableModifierKeyMask = NSShiftKeyMask | NSAlternateKeyMask;
            NSUInteger unprintableModifierKeyMask = NSCommandKeyMask | NSControlKeyMask | NSFunctionKeyMask;
            NSUInteger modifierFlags = [event modifierFlags] & unprintableModifierKeyMask;
            if (modifierFlags == 0) {
                switch ([event keyCode]) {
                // Non-word chars: ignore
                    case kVK_Escape:
                        break;
                // Basic editing: replay
                    case kVK_Delete:
                        [chars removeLastObject];
                        break;
                // More complex edit attempts: abort.
                    // Cop-out: we're not attempting to replay entire edits.
                    // Instead we simply detect indicators of manual word editing
                    // and abort (discard the current word.)
                    case kVK_ForwardDelete:
                    case kVK_Home:
                    case kVK_PageUp:
                    case kVK_LeftArrow:
                    case kVK_RightArrow:
                    case kVK_UpArrow:
                    case kVK_DownArrow:
                    // This includes tab completion.
                    case kVK_Tab:
                        [chars removeAllObjects];
                        break;
                // Word boundaries: capture last word.
                    case kVK_Return:
                    case kVK_Space:
                        if ([chars count] > 0) {
                            [self showTerm:[chars componentsJoinedByString:@""]];
                        }
                        [chars removeAllObjects];
                        break;
                    default:
                        [chars addObject:[event charactersIgnoringModifiers]];
                }
            }
        }
    }];
}

- (void)showTerm:(NSString*)term
{
    NSLog(@"%@", term);
    [termWindow showTerm:term];
}

@end
