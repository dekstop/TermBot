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
NSMutableSet *history;
TermWindow *termWindow;

NSDateFormatter *dateFormatter;
NSFileHandle *logFile;

- (id)init {
    if (self = [super init]) {
        chars = [[NSMutableArray alloc] init];
        history = [[NSMutableSet alloc] init];
        termWindow = [[TermWindow alloc] initWithColor:[NSColor lightGrayColor]];

        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
        logFile = OpenUserLog(@"TermBot.log");
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
    if (![history containsObject:term]) {
        Log(@"%@", term);
        [termWindow showTerm:term];
        [history addObject:term];
    }
}

NSFileHandle *OpenUserLog(NSString *filename)
{
    NSFileHandle *logFile;
    NSString *logFilePath = [NSString stringWithFormat:@"%@/Library/Logs/%@", NSHomeDirectory(), filename];
    NSFileManager * mFileManager = [NSFileManager defaultManager];
    if([mFileManager fileExistsAtPath:logFilePath] == NO) {
        [mFileManager createFileAtPath:logFilePath contents:nil attributes:nil];
    }
    logFile = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
    [logFile seekToEndOfFile];
    return logFile;
}

void Log(NSString* format, ...)
{
    // Build string
    va_list argList;
    va_start(argList, format);
    NSString* formattedMessage = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    
    // Console
    NSLog(@"%@", formattedMessage);
    
    // File logging
    NSString *logMessage = [NSString stringWithFormat:@"%@ %@\n",
                            [dateFormatter stringFromDate:[NSDate date]],
                            formattedMessage];
    [logFile writeData:[logMessage dataUsingEncoding:NSUTF8StringEncoding]];
    [logFile synchronizeFile];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [logFile closeFile];
}

@end
