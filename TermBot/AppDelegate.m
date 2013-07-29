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

@synthesize isActive;
NSAttributedString *menuTitleActive = nil;
NSAttributedString *menuTitleInactive = nil;
@synthesize isRecording;

NSMutableArray *chars;
NSMutableSet *history;
TermWindow *termWindow;

NSString *logFilePath;
NSDateFormatter *dateFormatter;
NSFileHandle *logFile;

- (id)init {
    if (self = [super init]) {
        chars = [[NSMutableArray alloc] init];
        history = [[NSMutableSet alloc] init];
        termWindow = [[TermWindow alloc] initWithColor:[NSColor lightGrayColor]];

        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
        logFilePath = [NSString stringWithFormat:@"%@/Library/Logs/TermBot.log", NSHomeDirectory()];
        logFile = OpenUserLog(logFilePath);
        
        menuTitleActive = [[NSMutableAttributedString alloc] initWithString:@"T" attributes:@{NSForegroundColorAttributeName:[NSColor blackColor], NSFontAttributeName:[NSFont systemFontOfSize:14.0]}];
        menuTitleInactive = [[NSMutableAttributedString alloc] initWithString:@"T" attributes:@{NSForegroundColorAttributeName:[NSColor grayColor], NSFontAttributeName:[NSFont systemFontOfSize:14.0]}];
    }
    return self;
}
        
- (IBAction)toggleIsActive:(id)pId
{
    isActive = !isActive;
    [[NSUserDefaults standardUserDefaults] setBool:isActive forKey:@"isActive"];
    [self updateIsActiveDisplay];
}

- (void)updateIsActiveDisplay
{
    [isActiveMenuItem setState:(isActive ? NSOnState : NSOffState)];
    [statusItem setAttributedTitle:(isActive ? menuTitleActive : menuTitleInactive)];
}

- (IBAction)toggleIsRecording:(id)pId
{
    isRecording = !isRecording;
    [[NSUserDefaults standardUserDefaults] setBool:isRecording forKey:@"isRecording"];
    [self updateIsRecordingDisplay];
}

- (void)updateIsRecordingDisplay
{
    [isRecordingMenuItem setState:(isRecording ? NSOnState : NSOffState)];
}

- (IBAction)openLog:(id)pId
{
    [[NSWorkspace sharedWorkspace] openFile:logFilePath];
}

- (IBAction)toggleLaunchOnStartup:(id)pId
{
    if ([self isLoginItem]) {
        [self removeAsLoginItem];
        [launchOnStartupMenuItem setState:NSOffState];
    } else {
        [self addAsLoginItem];
        [launchOnStartupMenuItem setState:NSOnState];
    }
}

- (IBAction)about:(id)pId
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/dekstop/TermBot"]];
}

- (IBAction)quit:(id)pId
{
    [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    SEL action = [menuItem action];
    
    if (action == @selector(toggleIsRecording:)) {
        return (isActive ? YES : NO);
    }
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // App preferences
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"isActive"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    
    isActive = [[NSUserDefaults standardUserDefaults] boolForKey:@"isActive"];
    isRecording = [[NSUserDefaults standardUserDefaults] boolForKey:@"isRecording"];
    [launchOnStartupMenuItem setState:([self isLoginItem] ? NSOnState : NSOffState)];

    // Status bar / tray icon
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:statusMenu];
    [statusItem setHighlightMode:YES];
    [self updateIsActiveDisplay];
    [self updateIsRecordingDisplay];
    
    // Register global event monitors -- may require assistive device access.
    [NSEvent addGlobalMonitorForEventsMatchingMask:NSKeyDownMask handler:^(NSEvent *event){
        if (!isActive) {
            return;
        }
        if ([event type] == NSKeyDown) {
//            if ([[event charactersIgnoringModifiers] isEqualToString:@"?"] ||
//                [[event charactersIgnoringModifiers] isEqualToString:@""]) {
//                NSLog(@"%d %@§§ %@", [event keyCode], [event characters], [event charactersIgnoringModifiers]);
//            }
    //        NSUInteger printableModifierKeyMask = NSShiftKeyMask | NSAlternateKeyMask;
            NSUInteger unprintableModifierKeyMask = NSCommandKeyMask | NSControlKeyMask | NSFunctionKeyMask;
            NSUInteger modifierFlags = [event modifierFlags] & unprintableModifierKeyMask;
            if (modifierFlags == NSFunctionKeyMask) {
                switch ([event keyCode]) {
                // Navigating away: capture last word.
                    case kVK_UpArrow:
                    case kVK_DownArrow:
                        [self recordCurrentTerm];
                        break;
                // More complex edit attempts: abort.
                    case kVK_LeftArrow:
                    case kVK_RightArrow:
                        [chars removeAllObjects];
                        break;
                    default:
                        break;
                }
            } else if (modifierFlags == 0) {
                switch ([event keyCode]) {
                // Non-word chars: ignore.
                    case kVK_Escape:
                        break;
                // Basic editing: replay.
                    case kVK_Delete:
                        [chars removeLastObject];
                        break;
                // Word boundaries, or navigating away: capture last word.
                    case kVK_Return:
                    case kVK_Space:
                    case kVK_Home:
                    case kVK_PageUp:
                    case kVK_PageDown:
                        [self recordCurrentTerm];
                        break;
                // More complex edit attempts: abort.
                    // Cop-out: we're not attempting to replay entire edits.
                    // Instead we simply detect indicators of manual word editing
                    // and abort (discard the current word.)
                    case kVK_ForwardDelete:
                    case kVK_Tab: // Tab completion.
                        [chars removeAllObjects];
                        break;
                        
                    default:
                        [chars addObject:[event charactersIgnoringModifiers]];
                }
            }
        }
    }];
}

/**
 *
 * Tools: logging.
 *
 **/

- (void)recordCurrentTerm
{
    if ([chars count] > 0) {
        [self recordTerm:[chars componentsJoinedByString:@""]];
    }
    [chars removeAllObjects];
}

- (void)recordTerm:(NSString*)term
{
    if (isRecording) {
        Log(@"%@", term);
    }
    
    if (![history containsObject:term]) {
        [termWindow showTerm:term];
        [history addObject:term];
    }
}

NSFileHandle *OpenUserLog(NSString *logFilePath)
{
    NSFileHandle *logFile;
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
//    NSLog(@"%@", formattedMessage);
    
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

/**
 *
 * Tools: add/remove login item.
 * Based on https://gist.github.com/boyvanamstel/1409312 (MIT license)
 *
 **/

- (BOOL)isLoginItem {
    // See if the app is currently in LoginItems.
    LSSharedFileListItemRef itemRef = [self itemRefInLoginItems];
    // Store away that boolean.
    BOOL isInList = itemRef != nil;
    // Release the reference if it exists.
    if (itemRef != nil) CFRelease(itemRef);
    
    return isInList;
}

- (void)addAsLoginItem {
    // Get the LoginItems list.
    LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItemsRef == nil) return;
    
    // Add the app to the LoginItems list.
    CFURLRef appUrl = (__bridge CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    LSSharedFileListItemRef itemRef = LSSharedFileListInsertItemURL(loginItemsRef, kLSSharedFileListItemLast, NULL, NULL, appUrl, NULL, NULL);
    if (itemRef) CFRelease(itemRef);
}

- (void)removeAsLoginItem {
    // Get the LoginItems list.
    LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItemsRef == nil) return;
    
    // Remove the app from the LoginItems list.
    LSSharedFileListItemRef itemRef = [self itemRefInLoginItems];
    LSSharedFileListItemRemove(loginItemsRef,itemRef);
    //    if (itemRef != nil) CFRelease(itemRef);
}

- (LSSharedFileListItemRef)itemRefInLoginItems {
    LSSharedFileListItemRef itemRef = nil;
    
	NSString * appPath = [[NSBundle mainBundle] bundlePath];
    
	// This will retrieve the path for the application
	// For example, /Applications/test.app
	CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
    
	// Create a reference to the shared file list.
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
	if (loginItems) {
		UInt32 seedValue;
		//Retrieve the list of Login Items and cast them to
		// a NSArray so that it will be easier to iterate.
		NSArray  *loginItemsArray = (__bridge NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
		for(int i = 0; i< [loginItemsArray count]; i++){
			LSSharedFileListItemRef currentItemRef = (__bridge LSSharedFileListItemRef)[loginItemsArray
                                                                                        objectAtIndex:i];
			//Resolve the item with URL
			if (LSSharedFileListItemResolve(currentItemRef, 0, (CFURLRef*) &url, NULL) == noErr) {
				NSString * urlPath = [(__bridge NSURL*)url path];
				if ([urlPath compare:appPath] == NSOrderedSame){
                    itemRef = currentItemRef;
				}
			}
		}
        CFRelease(loginItems);
	}
    return itemRef;
}

@end
