//
//  MTSoupView.mm
//  MacTierra
//
//  Created by Simon Fraser on 8/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <algorithm>

#import "MTSoupView.h"

#import "NSArrayAdditions.h"

#import "MT_Cellmap.h"
#import "MT_Soup.h"
#import "MT_World.h"

#import "MTCreature.h"
#import "MTInventoryGenotype.h"
#import "MTWorldController.h"

using namespace MacTierra;

struct RGBSoupColor {
    uint8_t red;
    uint8_t green;
    uint8_t blue;

    RGBSoupColor(uint8_t r = 0, uint8_t g = 0, uint8_t b = 0)
    : red(r), green(g), blue(b)
    { }
};

@interface MTSoupView ()

@property (nonatomic, weak) IBOutlet MTWorldController* worldController;
@property (nonatomic, weak) IBOutlet NSArrayController* genotypesArrayController;

@property (nonatomic, retain) NSMutableData* soupImageBackingStore;
@property (nonatomic, assign) CGContextRef soupContext;

- (void)setScalingCTM;
- (void)drawCells:(NSRect)inDirtyRect;
- (void)drawFecundity:(NSRect)inDirtyRect;
- (void)drawInstructionPointers:(NSRect)inDirtyRect;

- (CGRect)soupRect;
- (CGPoint)soupAddressToSoupPoint:(address_t)inAddr;
- (address_t)soupPointToSoupAddress:(CGPoint)inPoint;

- (CGAffineTransform)viewToSoupTransform;
- (CGAffineTransform)soupToViewTransform;

- (CGPoint)viewPointToSoupPoint:(CGPoint)inPoint;
- (CGPoint)soupPointToViewPoint:(CGPoint)inPoint;

- (void)startObservingSelectedGenotypes;
- (void)stopObservingSelectedGenotypes;

@end

#pragma mark -

static constexpr size_t colorsArraySize = 256;

@implementation MTSoupView {
    std::array<RGBSoupColor, colorsArraySize> _instructionColors;
}

- (id)initWithFrame:(NSRect)inFrame
{
    if ((self = [super initWithFrame:inFrame]))
    {
        _zoomToFit = YES;
        _showCells = NO;
        _showInstructionPointers = NO;
        self.focusedCreatureName = @"";

        [self registerForDraggedTypes:[NSArray arrayWithObjects:kGenotypeDataPasteboardType, NSPasteboardTypeString, nil]];

        [self buildColorLookupTable];
    }
    return self;
}

- (void)awakeFromNib
{
    [self startObservingSelectedGenotypes];
}

- (void)setWorld:(MacTierra::World*)inWorld
{
    _world = inWorld;

    if (_world)
    {
        const int kSoupWidth = 512;
        mSoupWidth = kSoupWidth;
        mSoupHeight = _world->soupSize() / kSoupWidth;
    }

    [self setNeedsDisplay:YES];
    [[self window] invalidateCursorRectsForView:self];
}

- (void)setShowCells:(BOOL)inShow
{
    if (inShow != _showCells)
    {
        [self willChangeValueForKey:@"showCells"];
        _showCells = inShow;
        [self didChangeValueForKey:@"showCells"];

        [self setNeedsDisplay:YES];
    }
}

- (void)setShowInstructionPointers:(BOOL)inShow
{
    if (inShow != _showInstructionPointers)
    {
        [self willChangeValueForKey:@"showInstructionPointers"];
        _showInstructionPointers = inShow;
        [self didChangeValueForKey:@"showInstructionPointers"];

        [self setNeedsDisplay:YES];
    }
}

- (void)setShowFecundity:(BOOL)inShow
{
    if (inShow != _showFecundity)
    {
        [self willChangeValueForKey:@"showFecundity"];
        _showFecundity = inShow;
        [self didChangeValueForKey:@"showFecundity"];

        [self setNeedsDisplay:YES];
    }
}

- (void)viewDidMoveToWindow
{
    if ([self window])
        [[self window] setAcceptsMouseMovedEvents:YES];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)buildColorLookupTable
{
    NSString* colorListPath = [[NSBundle mainBundle] pathForResource:@"Instructions0" ofType:@"clr"];
    NSColorList* colorList = [[NSColorList alloc] initWithName:@"Instructions" fromFile:colorListPath];
    if (!colorList)
        return;

    NSColorSpace* rgbColorSpace = [NSColorSpace sRGBColorSpace];

    NSArray*   colorKeys = [colorList allKeys];
    NSUInteger numColors = [colorKeys count];
    if (numColors > colorsArraySize)
        numColors = colorsArraySize;

    for (NSUInteger n = 0; n < numColors; ++n)
    {
        NSString* curKey = [colorKeys objectAtIndex:n];
        // make sure we can get RGB
        NSColor* curColor = [[colorList colorWithKey:curKey] colorUsingColorSpace:rgbColorSpace];

        CGFloat red = 0, green = 0, blue = 0, alpha = 1;
        [curColor getRed:&red green:&green blue:&blue alpha:&alpha];
        _instructionColors[n] = RGBSoupColor(red * 255, green * 255, blue * 255);
    }
}

- (void)drawSoup
{
    if (!_world)
        return;

    const size_t bytesPerPixel = 4;
    if (!_soupImageBackingStore) {
        // FIXME: Deal with size change.
        size_t dataSize = mSoupWidth * mSoupHeight * bytesPerPixel;
        _soupImageBackingStore = [NSMutableData dataWithLength:dataSize];
        if (!_soupImageBackingStore)
            return;
    }

    MacTierra::Soup* soup = _world->soup();

    BOOST_ASSERT(soup->soupSize() * bytesPerPixel == _soupImageBackingStore.length);

    uint8_t* dataBytes = (uint8_t*)_soupImageBackingStore.bytes;

    for (u_int32_t i = 0; i < soup->soupSize(); ++i) {
        instruction_t instruction = soup->instructionAtAddress(i);
        auto color = _instructionColors[instruction];

        uint8_t* pixelPointer = dataBytes + i * bytesPerPixel;
        pixelPointer[0] = color.red;
        pixelPointer[1] = color.green;
        pixelPointer[2] = color.blue;
        pixelPointer[3] = 255; // Alpha
    }

    const size_t bitsPerComponent = 8;
    size_t bytesPerRow = mSoupWidth * bytesPerPixel;

    CGContextRef bitmapContext = CGBitmapContextCreate(dataBytes, mSoupWidth, mSoupHeight, bitsPerComponent, bytesPerRow, [NSColorSpace sRGBColorSpace].CGColorSpace, kCGImageAlphaPremultipliedLast);
    if (!bitmapContext)
        return;

    CGImageRef soupImage = CGBitmapContextCreateImage(bitmapContext);

    CGContextRef cgContext = (CGContextRef)[[NSGraphicsContext currentContext] CGContext];

    CGRect destRect = CGRectMake(0, 0, mSoupWidth, mSoupHeight);
    CGContextDrawImage(cgContext, destRect, soupImage);

    CFRelease(soupImage);
    CFRelease(bitmapContext);
}

- (void)drawRect:(NSRect)inDirtyRect
{
    [_worldController lockWorld];

    [super drawRect:inDirtyRect];
    
    [NSGraphicsContext saveGraphicsState];
    [self setScalingCTM];

    [self drawSoup];

    if (_showInstructionPointers || _showFecundity || _showCells)
    {
        [[NSColor colorWithCalibratedWhite:0.0f alpha:0.5f] set];
        NSRectFillUsingOperation(NSMakeRect(0, 0, mSoupWidth, mSoupHeight), NSCompositingOperationSourceOver);
    }
    
    if (_showFecundity)
        [self drawFecundity:inDirtyRect];
    else if (_showCells)
        [self drawCells:inDirtyRect];

    if (_showInstructionPointers)
        [self drawInstructionPointers:inDirtyRect];

    [NSGraphicsContext restoreGraphicsState];

    [_worldController unlockWorld];
}

- (void)setScalingCTM
{
    // set the CTM to match the zooming that GL does
    CGContextRef cgContext = (CGContextRef)[[NSGraphicsContext currentContext] CGContext];
    CGContextConcatCTM(cgContext, [self soupToViewTransform]);
}

- (void)drawCells:(NSRect)inDirtyRect
{
    if (!_world)
        return;

    MTInventoryGenotype* selectedGenotype = nil;
    if ([[_genotypesArrayController selectedObjects] count] == 1)
    {
        selectedGenotype = [[_genotypesArrayController selectedObjects] firstObject];
    }
    
    CGContextRef cgContext = (CGContextRef)[[NSGraphicsContext currentContext] CGContext];

    NSColor* adultColor  = [[NSColor blueColor] colorWithAlphaComponent:0.5];
    NSColor* embryoColor = [[NSColor grayColor] colorWithAlphaComponent:0.5];
    NSColor* selectedGenotypeColor = [[NSColor orangeColor] colorWithAlphaComponent:0.9];

    CGContextSetLineWidth(cgContext, 1.0f);
    
    CellMap*    cellMap = _world->cellMap();
    const u_int32_t soupSize = _world->soupSize();
    
    CellMap::CreatureList::const_iterator iterEnd = cellMap->cells().end();
    for (CellMap::CreatureList::const_iterator it = cellMap->cells().begin(); it != iterEnd; ++it)
    {
        const CreatureRange& curCell = *it;
        const Creature* curCreature = curCell.mData;
        
        int startLine   = curCell.start() / mSoupWidth;
        int endLine     = curCell.wrappedEnd(soupSize) / mSoupWidth;
        
        int startCol    = curCell.start() % mSoupWidth;
        int endCol      = curCell.wrappedEnd(soupSize) % mSoupWidth;
        
        CGContextBeginPath(cgContext);
        
        if (curCell.wraps(soupSize))
        {
            int numLines = mSoupHeight;
            
            for (int i = startLine; i < numLines; ++i)
            {
                CGPoint startPoint = CGPointMake((i == startLine) ? startCol : 0, i);
                CGPoint endPoint   = CGPointMake(mSoupWidth, i);
                
                CGContextMoveToPoint(cgContext, startPoint.x, startPoint.y + 0.5);
                CGContextAddLineToPoint(cgContext, endPoint.x, endPoint.y + 0.5);
            }

            for (int i = 0; i <= endLine; ++i)
            {
                CGPoint startPoint = CGPointMake(0, i);
                CGPoint endPoint   = CGPointMake((i == endLine) ? endCol : mSoupWidth, i);
                
                CGContextMoveToPoint(cgContext, startPoint.x, startPoint.y + 0.5);
                CGContextAddLineToPoint(cgContext, endPoint.x, endPoint.y + 0.5);
            }
        }
        else
        {
            for (int i = startLine; i <= endLine; ++i)
            {
                CGPoint startPoint = CGPointMake((i == startLine) ? startCol : 0, i);
                CGPoint endPoint   = CGPointMake((i == endLine) ? endCol : mSoupWidth, i);
                
                CGContextMoveToPoint(cgContext, startPoint.x, startPoint.y + 0.5);
                CGContextAddLineToPoint(cgContext, endPoint.x, endPoint.y + 0.5);
            }
        }

        if (curCreature->isEmbryo())
            [embryoColor set];
        else
        {
            if (curCreature->genotype() == selectedGenotype.genotype)
                [selectedGenotypeColor set];
            else
                [adultColor set];
        }
        
        CGContextStrokePath(cgContext);
    }
}

- (NSColor*)colorForOffspring:(NSInteger)inNumOffspring identicalOffspring:(NSInteger)inIdenticalOffspring
{
    // TODO: blend of yellow and red
    
    const float kSingleOffspringOpacity = 0.3;
    const NSInteger kMaxFecundity = 10;

    float opacity = kSingleOffspringOpacity + (1.0 - kSingleOffspringOpacity) * (std::min(inNumOffspring, kMaxFecundity) / (float)kMaxFecundity);
    float identicalFraction = std::min(inIdenticalOffspring, kMaxFecundity) / (float)kMaxFecundity;
    
    return [NSColor colorWithCalibratedRed:1.0 green:identicalFraction blue:0 alpha:opacity];
}

- (void)drawFecundity:(NSRect)inDirtyRect
{
    if (!_world)
        return;

    CGContextRef cgContext = (CGContextRef)[[NSGraphicsContext currentContext] CGContext];

    CGContextSetLineWidth(cgContext, 1.0f);
    
    CellMap*    cellMap = _world->cellMap();
    const u_int32_t soupSize = _world->soupSize();
    
    CellMap::CreatureList::const_iterator iterEnd = cellMap->cells().end();
    for (CellMap::CreatureList::const_iterator it = cellMap->cells().begin(); it != iterEnd; ++it)
    {
        const CreatureRange& curCell = *it;
        const Creature* curCreature = curCell.mData;
        
        if (curCreature->isEmbryo() || curCreature->numOffspring() == 0)
            continue;
        
        int startLine   = curCell.start() / mSoupWidth;
        int endLine     = curCell.wrappedEnd(soupSize) / mSoupWidth;
        
        int startCol    = curCell.start() % mSoupWidth;
        int endCol      = curCell.wrappedEnd(soupSize) % mSoupWidth;
        
        CGContextBeginPath(cgContext);
        
        if (curCell.wraps(soupSize))
        {
            int numLines = mSoupHeight;
            
            for (int i = startLine; i < numLines; ++i)
            {
                CGPoint startPoint = CGPointMake((i == startLine) ? startCol : 0, i);
                CGPoint endPoint   = CGPointMake(mSoupWidth, i);
                
                CGContextMoveToPoint(cgContext, startPoint.x, startPoint.y + 0.5);
                CGContextAddLineToPoint(cgContext, endPoint.x, endPoint.y + 0.5);
            }

            for (int i = 0; i <= endLine; ++i)
            {
                CGPoint startPoint = CGPointMake(0, i);
                CGPoint endPoint   = CGPointMake((i == endLine) ? endCol : mSoupWidth, i);
                
                CGContextMoveToPoint(cgContext, startPoint.x, startPoint.y + 0.5);
                CGContextAddLineToPoint(cgContext, endPoint.x, endPoint.y + 0.5);
            }
        }
        else
        {
            for (int i = startLine; i <= endLine; ++i)
            {
                CGPoint startPoint = CGPointMake((i == startLine) ? startCol : 0, i);
                CGPoint endPoint   = CGPointMake((i == endLine) ? endCol : mSoupWidth, i);
                
                CGContextMoveToPoint(cgContext, startPoint.x, startPoint.y + 0.5);
                CGContextAddLineToPoint(cgContext, endPoint.x, endPoint.y + 0.5);
            }
        }

        [[self colorForOffspring:curCreature->numOffspring() identicalOffspring:curCreature->numIdenticalOffspring()] set];
        CGContextStrokePath(cgContext);
    }
}

- (void)drawInstructionPointers:(NSRect)inDirtyRect
{
    if (!_world)
        return;

    CGContextRef cgContext = (CGContextRef)[[NSGraphicsContext currentContext] CGContext];

    const CGFloat kInstPointerRectBorderWidth = 1.0f;
    CGContextSetLineWidth(cgContext, kInstPointerRectBorderWidth);
    
    NSColor* withinColor  = [[NSColor greenColor] colorWithAlphaComponent:0.5];
    NSColor* outsideColor = [[NSColor orangeColor] colorWithAlphaComponent:0.5];
    
    CellMap*    cellMap = _world->cellMap();
    const u_int32_t soupSize = _world->soupSize();
    
    CellMap::CreatureList::const_iterator iterEnd = cellMap->cells().end();
    for (CellMap::CreatureList::const_iterator it = cellMap->cells().begin(); it != iterEnd; ++it)
    {
        const CreatureRange& curCell = *it;
        const Creature* curCreature = curCell.mData;
        if (curCreature->isEmbryo())
            continue;

        address_t instPointer = curCreature->referencedLocation();
        bool isInCreature = curCreature->containsAddress(instPointer, soupSize);

        if (isInCreature)
            [withinColor set];
        else
            [outsideColor set];
        
        CGRect pointerRect = CGRectMake(instPointer % mSoupWidth - kInstPointerRectBorderWidth,
                                        instPointer / mSoupWidth - kInstPointerRectBorderWidth,
                                        1 + 2 * kInstPointerRectBorderWidth,
                                        1 + 2 * kInstPointerRectBorderWidth);
        CGContextStrokeEllipseInRect(cgContext, pointerRect);
    }

}

- (CGPoint)soupAddressToSoupPoint:(address_t)inAddr
{
    return CGPointMake(inAddr % mSoupWidth, inAddr / mSoupWidth);
}

- (address_t)soupPointToSoupAddress:(CGPoint)inPoint
{
    return ((address_t)inPoint.x + (address_t)inPoint.y * mSoupWidth);
}

- (CGAffineTransform)soupToViewTransform
{
    NSSize viewSize = self.bounds.size;
    return _zoomToFit ? CGAffineTransformMakeScale(viewSize.width / mSoupWidth, viewSize.height / mSoupHeight)
                      : CGAffineTransformMakeTranslation((viewSize.width - (float)mSoupWidth) / 2.0, (viewSize.height - (float)mSoupHeight) / 2.0);
}

- (CGAffineTransform)viewToSoupTransform
{
    return CGAffineTransformInvert([self soupToViewTransform]);
}

- (CGRect)soupRect
{
    NSSize viewSize = self.bounds.size;
    CGRect soupExtent = _zoomToFit ? CGRectMake(0, 0, viewSize.width, viewSize.height)
                                   : CGRectMake((viewSize.width - (float)mSoupWidth) / 2.0, (viewSize.height - (float)mSoupHeight) / 2.0, mSoupWidth, mSoupHeight);
    return soupExtent;
}

- (BOOL)viewPointInSoup:(CGPoint)inPoint
{
    return CGRectContainsPoint([self soupRect], inPoint);
}

- (CGPoint)viewPointToSoupPoint:(CGPoint)inPoint
{
    if (![self viewPointInSoup:inPoint])
        return CGPointZero;

    return CGPointApplyAffineTransform(inPoint, [self viewToSoupTransform]);
}

- (CGPoint)soupPointToViewPoint:(CGPoint)inPoint
{
    return CGPointApplyAffineTransform(inPoint, [self soupToViewTransform]);
}

- (void)setZoomToFit:(BOOL)inZoom
{
    if (inZoom != _zoomToFit)
    {
        [[self window] invalidateCursorRectsForView:self];
        [self setNeedsDisplay:YES];
        _zoomToFit = inZoom;
    }
}

#pragma mark -

- (MacTierra::Creature*)creatureForPoint:(NSPoint)inLocalPoint
{
    CGPoint thePoint = *(CGPoint*)&inLocalPoint;
    if (_world && [self viewPointInSoup:thePoint])
    {
        CGPoint soupPoint = [self viewPointToSoupPoint:thePoint];
        address_t soupAddr = [self soupPointToSoupAddress:soupPoint];

        MacTierra::Creature* theCreature = _world->cellMap()->creatureAtAddress(soupAddr);
        return theCreature;
    }

    return NULL;
}

- (void)mouseMoved:(NSEvent*)inEvent
{
    NSPoint localPoint = [self convertPoint:[inEvent locationInWindow] fromView:nil];
    MacTierra::Creature* theCreature = [self creatureForPoint:localPoint];
    if (theCreature && !theCreature->isEmbryo())
    {
        std::string creatureName = theCreature->creatureName();
        self.focusedCreatureName = [NSString stringWithUTF8String:creatureName.c_str()];
    }
    else
    {
        self.focusedCreatureName = @"";
    }
}

- (void)mouseDown:(NSEvent*)inEvent
{
    NSPoint localPoint = [self convertPoint:[inEvent locationInWindow] fromView:nil];
    MacTierra::Creature* theCreature = [self creatureForPoint:localPoint];
    if (theCreature && !theCreature->isEmbryo())
    {
        MTCreature* creatureObj = [[MTCreature alloc] initWithCreature:theCreature];
//            [creatureObj genotype]; // force the genotype to be created
        _worldController.selectedCreature = creatureObj;
        return;
    }

    _worldController.selectedCreature = nil;
}

- (void)mouseDragged:(NSEvent*)inEvent
{
    NSPoint localPoint = [self convertPoint:[inEvent locationInWindow] fromView:nil];

    MacTierra::Creature* theCreature = [self creatureForPoint:localPoint];

    if (theCreature && !theCreature->isEmbryo())
    {
        MTCreature* creatureObj = [[MTCreature alloc] initWithCreature:theCreature];

        MTSerializableGenotype* serCreature = [MTSerializableGenotype serializableGenotypeFromCreature:creatureObj];

        NSPasteboard* pasteboard = [NSPasteboard pasteboardWithName:NSPasteboardNameDrag];

        [pasteboard declareTypes:[NSArray arrayWithObjects:kCreatureReferencePasteboardType,
                                                           kGenotypeDataPasteboardType,
                                                           NSPasteboardTypeString,
                                                           nil]  owner:self];

        [pasteboard setPropertyList:[creatureObj pasteboardData] forType:kCreatureReferencePasteboardType];
        [pasteboard setString:[serCreature stringRepresentation] forType:NSPasteboardTypeString];
        [pasteboard setData:[serCreature archiveRepresentation] forType:kGenotypeDataPasteboardType];
    
        // FIXME: scale the image so that it matches the soup scaling
        NSImage* theImage = creatureObj.genotype.genotypeImage;
        
        [self dragImage:theImage
                     at:NSMakePoint(localPoint.x - [theImage size].width / 2.0, localPoint.y)
                 offset:NSZeroSize
                  event:inEvent
             pasteboard:pasteboard
                 source:self
              slideBack:YES];
    }
}

- (void)resetCursorRects
{
    [self addCursorRect:NSRectFromCGRect([self soupRect]) cursor:[NSCursor crosshairCursor]];
}

#pragma mark -

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];

    NSPasteboard* pasteboard = [sender draggingPasteboard];
    if ([[pasteboard types] containsObject:kGenotypeDataPasteboardType])
    {
        if (sourceDragMask & NSDragOperationCopy)
            return NSDragOperationCopy;
    }
    
    return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)sender
{
    return NSDragOperationCopy;
}

// perform the drop
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard* pasteboard = [sender draggingPasteboard];

    BOOL inserted = NO;

    MTSerializableGenotype* genotype = [MTSerializableGenotype serializableGenotypeFromPasteboard:pasteboard];
    if (genotype)
    {
        NSUInteger creatureLen = [genotype.genome length];
        
//        NSPoint localPoint = [self convertPoint:[sender draggingLocation] fromView:nil];
//        NSPoint dragImageTopLeft = [sender draggedImageLocation];
//        dragImageTopLeft.y -= [[sender draggedImage] size].height;

        NSPoint imagePoint = [self convertPoint:[sender draggingLocation] fromView:nil];
                
        CGPoint thePoint = *(CGPoint*)&imagePoint;
        if (_world && [self viewPointInSoup:thePoint])
        {
            CGPoint soupPoint = [self viewPointToSoupPoint:thePoint];
            address_t soupAddr = [self soupPointToSoupAddress:soupPoint];

            if (_world->cellMap()->spaceAtAddress(soupAddr, creatureLen))
            {
                RefPtr<Creature> newCreature = _world->insertCreature(soupAddr, (const instruction_t*)[genotype.genome bytes], creatureLen);
                NSAssert(newCreature, @"Should have been able to insert");
                inserted = YES;
                [self setNeedsDisplay:YES];
            }
        }
    }
    return inserted;
}

#pragma mark -

- (void)startObservingSelectedGenotypes
{
    [_genotypesArrayController addObserver:self
                                   forKeyPath:@"selection"
                                      options:0
                                      context:NULL];
}

- (void)stopObservingSelectedGenotypes
{
    [_genotypesArrayController removeObserver:self forKeyPath:@"selection"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"selection"])
    {
        [self setNeedsDisplay:YES];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


@end
