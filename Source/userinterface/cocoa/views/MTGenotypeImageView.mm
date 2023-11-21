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

@synthesize worldController;
@synthesize genotype;

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
    self.genotype = nil;
    [super dealloc];
}

- (void)awakeFromNib
{
    [self registerForDraggedTypes:[NSArray arrayWithObjects:kCreatureReferencePasteboardType, nil]];
}

- (void)setGenotype:(MTInventoryGenotype*)inGenotype
{
    if (inGenotype != genotype)
    {
        [self willChangeValueForKey:@"genotype"];
        [genotype release];
        genotype = [inGenotype retain];
        [self setImage:genotype.genotypeImage];
        [self didChangeValueForKey:@"genotype"];
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
    if (!genotype)
        return;

    NSPoint localPoint = [self convertPoint:[inEvent locationInWindow] fromView:nil];

    MTSerializableGenotype* serCreature = [MTSerializableGenotype serializableGenotypeFromGenotype:genotype];

    NSPasteboard* pasteboard = [NSPasteboard pasteboardWithName:NSPasteboardNameDrag];

    [pasteboard declareTypes:[NSArray arrayWithObjects:kGenotypeDataPasteboardType,
                                                       NSPasteboardTypeString,
                                                       nil]  owner:self];

    [pasteboard setString:[serCreature stringRepresentation] forType:NSPasteboardTypeString];
    [pasteboard setData:[serCreature archiveRepresentation] forType:kGenotypeDataPasteboardType];

    // FIXME: scale the image so that it matches the soup scaling
    NSImage* theImage = genotype.genotypeImage;
    
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
    if ([[pasteboard types] containsObject:kGenotypeDataPasteboardType])
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
        MTCreature* tempCreature = [MTCreature creatureFromPasteboard:pasteboard inWorld:worldController.world];
        self.genotype = tempCreature.genotype;
    }
}

@end
