//
//  Tets.m
//  osxdraggable
//
//  Created by Botov on 5/18/16.
//  Copyright © 2016 IB. All rights reserved.
//

#import "DraggableButton.h"

//http://stackoverflow.com/a/19866029/6197308

@implementation NSControl (DragControl)

- (NSDraggingSession*)beginDraggingSessionWithDraggingCell:(NSActionCell <NSDraggingSource> *)cell event:(NSEvent*) theEvent
{
    NSImage* image = [self imageForCell:cell];
    NSDraggingItem* di = [[NSDraggingItem alloc] initWithPasteboardWriter:image];
    NSRect dragFrame = [self frameForCell:cell];
    dragFrame.size = image.size;
    [di setDraggingFrame:dragFrame contents:image];
    
    NSArray* items = [NSArray arrayWithObject:di];
    
    [self setHidden:YES];
    return [self beginDraggingSessionWithItems:items event:theEvent source:cell];
}

- (NSRect)frameForCell:(NSCell*)cell
{
    // override in multi-cell cubclasses!
    return self.bounds;
}

- (NSImage*)imageForCell:(NSCell*)cell
{
    return [self imageForCell:cell highlighted:[cell isHighlighted]];
}

- (NSImage*)imageForCell:(NSCell*)cell highlighted:(BOOL) highlight
{
    // override in multicell cubclasses to just get an image of the dragged cell.
    // for any single cell control we can just make sure that cell is the controls cell
    
    if (cell == self.cell || cell == nil) { // nil signifies entire control
        // basically a bitmap of the control
        // NOTE: the cell is irrelevant when dealing with a single cell control
        BOOL isHighlighted = [cell isHighlighted];
        [cell setHighlighted:highlight];
        
        NSRect cellFrame = [self frameForCell:cell];
        
        // We COULD just draw the cell, to an NSImage, but button cells draw their content
        // in a special way that would complicate that implementation (ex text alignment).
        // subclasses that have multiple cells may wish to override this to only draw the cell
        NSBitmapImageRep* rep = [self bitmapImageRepForCachingDisplayInRect:cellFrame];
        NSImage* image = [[NSImage alloc] initWithSize:rep.size];
        
        [self cacheDisplayInRect:cellFrame toBitmapImageRep:rep];
        [image addRepresentation:rep];
        // reset the original cell state
        [cell setHighlighted:isHighlighted];
        return image;
    }
    // cell doesnt belong to this control!
    return nil;
}

#pragma mark NSDraggingDestination
- (void)draggingEnded:(id < NSDraggingInfo >)sender
{
    // implement whatever you want to do here.
    [self setHidden:NO];
}

@end


@implementation NSActionCell (DragCell)

- (void)setControlView:(NSView *)view
{
    // this is a bit of a hack, but the easiest way to make the control dragging work.
    // force the control to accept image drags.
    // the control will forward us the drag destination events via our DragControl category
    
    [view registerForDraggedTypes:[NSImage imageTypes]];
    [super setControlView:view];
}

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp
{
    BOOL result = NO;
    NSPoint currentPoint = theEvent.locationInWindow;
    BOOL done = NO;
    BOOL trackContinously = [self startTrackingAt:currentPoint inView:controlView];
    
    BOOL mouseIsUp = NO;
    NSEvent *event = nil;
    while (!done)
    {
        NSPoint lastPoint = currentPoint;
        
        event = [NSApp nextEventMatchingMask:(NSLeftMouseUpMask|NSLeftMouseDraggedMask)
                                   untilDate:[NSDate distantFuture]
                                      inMode:NSEventTrackingRunLoopMode
                                     dequeue:YES];
        
        if (event)
        {
            currentPoint = event.locationInWindow;
            
            // Send continueTracking.../stopTracking...
            if (trackContinously)
            {
                if (![self continueTracking:lastPoint
                                         at:currentPoint
                                     inView:controlView])
                {
                    done = YES;
                    [self stopTracking:lastPoint
                                    at:currentPoint
                                inView:controlView
                             mouseIsUp:mouseIsUp];
                }
                if (self.isContinuous)
                {
                    [NSApp sendAction:self.action
                                   to:self.target
                                 from:controlView];
                }
            }
            
            mouseIsUp = (event.type == NSLeftMouseUp);
            done = done || mouseIsUp;
            
            if (untilMouseUp)
            {
                result = mouseIsUp;
            } else {
                // Check if the mouse left our cell rect
                result = NSPointInRect([controlView
                                        convertPoint:currentPoint
                                        fromView:nil], cellFrame);
                if (!result)
                    done = YES;
            }
            
            if (done && result && ![self isContinuous])
                [NSApp sendAction:self.action
                               to:self.target
                             from:controlView];
            else {
                done = YES;
                result = YES;
                
                // this initiates the control drag event using NSDragging protocols
                NSControl* cv = (NSControl*)self.controlView;
                NSDraggingSession* session = [cv beginDraggingSessionWithDraggingCell:(NSActionCell<NSDraggingSource>*)self
                                                                                event:theEvent];
                // _dragImageOffset = [cv convertPoint:[theEvent locationInWindow] fromView:nil];
                // Note that you will get an ugly flash effect when the image returns if this is set to yes
                // you can work around it by setting NO and faking the release by animating an NSWindowSubclass with the image as the content
                // create the window in the drag ended method for NSDragOperationNone
                // there is [probably a better and easier way around this behavior by playing with view animation properties.
                session.animatesToStartingPositionsOnCancelOrFail = NO;
            }
            
        }
    }
    return result;
}

#pragma mark - NSDraggingSource Methods
- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
    switch(context) {
        case NSDraggingContextOutsideApplication:
            return NSDragOperationNone;
            break;
            
        case NSDraggingContextWithinApplication:
        default:
            return NSDragOperationPrivate;
            break;
    }
}

- (void)draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
    CGRect r = self.controlView.frame;
    r = [self.controlView.window convertRectFromScreen:CGRectMake(screenPoint.x - r.size.width / 2, screenPoint.y - r.size.height / 2, r.size.width, r.size.height)];
    self.controlView.frame = r;
    [self.controlView draggingEnded:nil];
}

@end