//
//  MTGenotypeImageView.m
//  MacTierra
//
//  Created by Simon Fraser on 10/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTGenotypeImageView.h"

#import "MTCreature.h"
#import "MTInventoryGenotype.h"
#import "MTWorldController.h"

@implementation MTGenotypeImageView

@synthesize creature;

- (id)initWithFrame:(NSRect)inFrame
{
    if ((self = [super initWithFrame:inFrame]))
    {
        [self registerForDraggedTypes:[NSArray arrayWithObjects:kCreatureReferencePasteboardType, nil]];
    }
    return self;
}

- (void)dealloc
{
    self.creature = nil;
    [super dealloc];
}

- (void)awakeFromNib
{
    [self registerForDraggedTypes:[NSArray arrayWithObjects:kCreatureReferencePasteboardType, nil]];
}

- (void)setCreature:(MTCreature*)inCreature
{
    if (inCreature != creature)
    {
        [self willChangeValueForKey:@"creature"];
        [creature release];
        creature = [inCreature retain];
        [self setImage:creature.genotype.genotypeImage];
        [self didChangeValueForKey:@"creature"];
    }
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
    return YES;
}

// required for mouseDragged to get called
- (BOOL)acceptsFirstResponder
{
    return YES;
}

// we have to override mouseDown to get mouseDragged to work
- (void)mouseDown:(NSEvent*)inEvent
{
}

- (void)mouseDragged:(NSEvent*)inEvent
{
    if (!creature)
        return;

    NSPoint localPoint = [self convertPoint:[inEvent locationInWindow] fromView:nil];

    MTSerializableCreature* serCreature = [[[MTSerializableCreature alloc] initWithName:[creature name] genome:[creature genome]] autorelease];

    NSPasteboard* pasteboard = [NSPasteboard pasteboardWithName:NSDragPboard];

    [pasteboard declareTypes:[NSArray arrayWithObjects:kCreatureReferencePasteboardType,
                                                       kCreatureDataPasteboardType,
                                                       NSStringPboardType,
                                                       nil]  owner:self];

    [pasteboard setPropertyList:[creature pasteboardData] forType:kCreatureReferencePasteboardType];
    [pasteboard setString:[serCreature stringRepresentation] forType:NSStringPboardType];
    [pasteboard setData:[serCreature archiveRepresentation] forType:kCreatureDataPasteboardType];

    // FIXME: scale the image so that it matches the soup scaling
    NSImage* theImage = creature.genotype.genotypeImage;
    
    [self dragImage:theImage
                 at:NSMakePoint(localPoint.x - [theImage size].width / 2.0, localPoint.y)
             offset:NSZeroSize
              event:inEvent
         pasteboard:pasteboard
             source:self
          slideBack:YES];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if (!worldController)
        return NSDragOperationNone;

    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];

    NSPasteboard* pasteboard = [sender draggingPasteboard];
    if ([[pasteboard types] containsObject:kCreatureDataPasteboardType])
    {
        if (sourceDragMask & (NSDragOperationCopy | NSDragOperationGeneric))
            return NSDragOperationCopy;
    }
    
    return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)sender
{
    return NSDragOperationCopy;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];

    if (worldController && sourceDragMask & (NSDragOperationCopy | NSDragOperationGeneric)) {
        return YES;
    }
    return NO;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
    if (!worldController)
        return;

    NSPasteboard* pasteboard = [sender draggingPasteboard];
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];

    if (sourceDragMask & (NSDragOperationCopy | NSDragOperationGeneric))
    {
        self.creature = [MTCreature creatureFromPasteboard:pasteboard inWorld:worldController.world];
    }
}

@end
