//
//  BrowserMainWindow.m
//
//  Created by Alexandru Catighera on 10/28/13.
//
//

#import "BrowserMainWindow.h"

@implementation BrowserMainWindow

- (void)tapAndHoldAction:(NSTimer*)timer
{
    contextualMenuTimer = nil;
    NSDictionary *coord = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithFloat:tapLocation.x],@"x",
                           [NSNumber numberWithFloat:tapLocation.y],@"y",nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TapAndHoldNotification" object:coord];
}

- (void)sendEvent:(UIEvent *)event
{
    NSSet *touches = [event touchesForWindow:self];
    
    [super sendEvent:event];    // Call super to make sure the event is processed as usual
    
    if ([touches count] == 1) { // We're only interested in one-finger events
        UITouch *touch = [touches anyObject];
        
        switch ([touch phase]) {
            case UITouchPhaseBegan:  // A finger touched the screen
                tapLocation = [touch locationInView:self];
                [contextualMenuTimer invalidate];
                contextualMenuTimer = [NSTimer scheduledTimerWithTimeInterval:0.8
                                                                       target:self selector:@selector(tapAndHoldAction:)
                                                                     userInfo:nil repeats:NO];
                break;
                
            case UITouchPhaseEnded:
            case UITouchPhaseMoved:
            case UITouchPhaseStationary:
            case UITouchPhaseCancelled:
                [contextualMenuTimer invalidate];
                contextualMenuTimer = nil;
                break;
        }
    } else {                    // Multiple fingers are touching the screen
        [contextualMenuTimer invalidate];
        contextualMenuTimer = nil;
    }
}

@end
