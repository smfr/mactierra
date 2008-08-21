//
//  MTSoupView.mm
//  MacTierra
//
//  Created by Simon Fraser on 8/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTSoupView.h"

#import "MT_Cellmap.h"
#import "MT_Soup.h"
#import "MT_World.h"

#import "MTCreature.h"
#import "MTWorldController.h"

using namespace MacTierra;

@interface MTSoupView(Private)

- (void)setScalingCTM;
- (void)drawCells:(NSRect)inDirtyRect;
- (void)drawInstructionPointers:(NSRect)inDirtyRect;

- (CGPoint)soupAddressToSoupPoint:(address_t)inAddr;
- (address_t)soupPointToSoupAddress:(CGPoint)inPoint;

- (CGAffineTransform)viewToSoupTransform;
- (CGAffineTransform)soupToViewTransform;

- (CGPoint)viewPointToSoupPoint:(CGPoint)inPoint;
- (CGPoint)soupPointToViewPoint:(CGPoint)inPoint;

@end

#pragma mark -

@implementation MTSoupView

@synthesize zoomToFit;
@synthesize showCells;
@synthesize showInstructionPointers;
@synthesize focusedCreatureName;

- (id)initWithFrame:(NSRect)inFrame
{
    if ((self = [super initWithFrame:inFrame]))
    {
        zoomToFit = YES;
        showCells = NO;
        showInstructionPointers = NO;
        self.focusedCreatureName = @"";
    }
    return self;
}

- (void)dealloc
{
    self.focusedCreatureName = nil;
    [super dealloc];
}

- (void)setWorld:(MacTierra::World*)inWorld
{
    mWorld = inWorld;
    
    if (mWorld)
    {
        const int kSoupWidth = 512;
        mSoupWidth = kSoupWidth;
        mSoupHeight = mWorld->soupSize() / kSoupWidth;
        
        [self setGLOptions];
    }
}

- (MacTierra::World*)world
{
    return mWorld;
}

- (void)setShowCells:(BOOL)inShow
{
    if (inShow != showCells)
    {
        showCells = inShow;
        [self setNeedsDisplay:YES];
    }
}

- (void)setShowInstructionPointers:(BOOL)inShow
{
    if (inShow != showInstructionPointers)
    {
        showInstructionPointers = inShow;
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

- (void)drawRect:(NSRect)inDirtyRect
{
    [super drawRect:inDirtyRect];
    
    [NSGraphicsContext saveGraphicsState];
    [self setScalingCTM];

    if (showCells)
        [self drawCells:inDirtyRect];

    if (showInstructionPointers)
        [self drawInstructionPointers:inDirtyRect];

    [NSGraphicsContext restoreGraphicsState];
}

- (void)setScalingCTM
{
    // set the CTM to match the zooming that GL does
    CGContextRef cgContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextConcatCTM(cgContext, [self soupToViewTransform]);
}

- (void)drawCells:(NSRect)inDirtyRect
{
    CGContextRef cgContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];

    NSColor* adultColor  = [[NSColor blueColor] colorWithAlphaComponent:0.5];
    NSColor* embryoColor = [[NSColor grayColor] colorWithAlphaComponent:0.5];

    CGContextSetLineWidth(cgContext, 1.0f);
    
    CellMap*    cellMap = mWorld->cellMap();
    const u_int32_t soupSize = mWorld->soupSize();
    
    CellMap::CreatureList::const_iterator iterEnd = cellMap->cells().end();
    for (CellMap::CreatureList::const_iterator it = cellMap->cells().begin(); it != iterEnd; ++it)
    {
        const CellMap::CreatureCell curCell = *it;
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
            [adultColor set];

        CGContextStrokePath(cgContext);
    }
}

- (void)drawInstructionPointers:(NSRect)inDirtyRect
{
    CGContextRef cgContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];

    const CGFloat kInstPointerRectBorderWidth = 1.0f;
    CGContextSetLineWidth(cgContext, kInstPointerRectBorderWidth);
    
    NSColor* withinColor  = [[NSColor greenColor] colorWithAlphaComponent:0.5];
    NSColor* outsideColor = [[NSColor orangeColor] colorWithAlphaComponent:0.5];
    
    CellMap*    cellMap = mWorld->cellMap();
    const u_int32_t soupSize = mWorld->soupSize();
    
    CellMap::CreatureList::const_iterator iterEnd = cellMap->cells().end();
    for (CellMap::CreatureList::const_iterator it = cellMap->cells().begin(); it != iterEnd; ++it)
    {
        const CellMap::CreatureCell curCell = *it;
        const Creature* curCreature = curCell.mData;
        
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
    return CGPointMake(inAddr * mSoupWidth, inAddr / mSoupWidth);
}

- (address_t)soupPointToSoupAddress:(CGPoint)inPoint
{
    return ((address_t)inPoint.x + inPoint.y * mSoupWidth);
}

- (CGAffineTransform)soupToViewTransform
{
    return zoomToFit ? CGAffineTransformMakeScale((CGFloat)mGlWidth / mSoupWidth, (CGFloat)mGlHeight / mSoupHeight)
                     : CGAffineTransformMakeTranslation((mGlWidth - (float)mSoupWidth) / 2.0, (mGlHeight - (float)mSoupHeight) / 2.0);
}

- (CGAffineTransform)viewToSoupTransform
{
    return CGAffineTransformInvert([self soupToViewTransform]);
}

- (BOOL)viewPointInSoup:(CGPoint)inPoint
{
    CGRect soupExtent = zoomToFit ? CGRectMake(0, 0, mGlWidth, mGlHeight)
                                  : CGRectMake((mGlWidth - (float)mSoupWidth) / 2.0, (mGlHeight - (float)mSoupHeight) / 2.0, mSoupWidth, mSoupHeight);

    return CGRectContainsPoint(soupExtent, inPoint);
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

#pragma mark -

- (void)mouseMoved:(NSEvent*)inEvent
{
    NSPoint localPoint = [self convertPoint:[inEvent locationInWindow] fromView:nil];
    CGPoint thePoint = *(CGPoint*)&localPoint;

    if (mWorld && [self viewPointInSoup:thePoint])
    {
        CGPoint soupPoint = [self viewPointToSoupPoint:*(CGPoint*)&localPoint];
        address_t soupAddr = [self soupPointToSoupAddress:soupPoint];

        MacTierra::Creature* theCreature = mWorld->cellMap()->creatureAtAddress(soupAddr);
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
    else
    {
        self.focusedCreatureName = @"";
    }
}

- (void)mouseDown:(NSEvent*)inEvent
{
    NSPoint localPoint = [self convertPoint:[inEvent locationInWindow] fromView:nil];

    CGPoint thePoint = *(CGPoint*)&localPoint;

    if (mWorld && [self viewPointInSoup:thePoint])
    {
        CGPoint soupPoint = [self viewPointToSoupPoint:*(CGPoint*)&localPoint];
        address_t soupAddr = [self soupPointToSoupAddress:soupPoint];

        MacTierra::Creature* theCreature = mWorld->cellMap()->creatureAtAddress(soupAddr);
        if (theCreature && !theCreature->isEmbryo())
        {
            MTCreature* creatureObj = [[[MTCreature alloc] initWithCreature:theCreature] autorelease];
//            [creatureObj genotype]; // force the genotype to be created
            mWorldController.selectedCreature = creatureObj;
            return;
        }
    }

    mWorldController.selectedCreature = nil;
}

- (void)mouseDragged:(NSEvent*)inEvent
{
    NSPoint localPoint = [self convertPoint:[inEvent locationInWindow] fromView:nil];
    NSLog(@"dragging");
}


#pragma mark -

- (NSRect)contentsRect
{
	NSRect viewBounds = [self bounds];
	NSRect imageDestRect = viewBounds;

	if (mWorld && mWorld->soup())
        imageDestRect = [self contentsRectForSize:NSMakeSize(mSoupWidth, mSoupHeight)];
    
	return imageDestRect;
}

- (BOOL)checkForGLError
{
    CGLContextObj cgl_ctx = mCGlContext;

    GLenum gl_err;
    if ((gl_err = glGetError()))
    {
        NSLog(@"OpenGL error %d", gl_err);
        return true;
    }
    return false;
}

- (void)setGLOptions
{
    CGLContextObj cgl_ctx = mCGlContext;

    GLint i;
    GLfloat map[256];

    glPixelTransferf(GL_ALPHA_SCALE, 0.0);
    glPixelTransferf(GL_ALPHA_BIAS,  1.0);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

    /* define accelerated bgr233 to RGBA pixelmaps.  */
    for(i = 0; i < 256; i++)
        map[i] = (i & 0x7) / 7.0;

    glPixelMapfv(GL_PIXEL_MAP_I_TO_R, 256, map);
    for (i = 0; i < 256; i++)
        map[i] = ((i & 0x38) >> 3) / 7.0;

    glPixelMapfv(GL_PIXEL_MAP_I_TO_G, 256, map);
    for(i = 0; i < 256; i++)
        map[i] = ((i & 0xc0) >> 6) / 3.0;

    glPixelMapfv(GL_PIXEL_MAP_I_TO_B, 256, map);

    GLfloat constantAlpha = 1.0;
    glPixelMapfv(GL_PIXEL_MAP_I_TO_A, 1, &constantAlpha);

    glPixelTransferi(GL_INDEX_SHIFT, 0);
    glPixelTransferi(GL_INDEX_OFFSET, 0);
    glPixelTransferi(GL_MAP_COLOR, GL_TRUE);
    glDisable(GL_DITHER);

    [self checkForGLError];

    glClearColor(0.3, 0.3, 0.3, 1.0);
}

- (void)render
{
    CGLContextObj cgl_ctx = mCGlContext;

    glClear(GL_COLOR_BUFFER_BIT);

    if (!mWorld || !mWorld->soup())
        return;

    if (zoomToFit)
    {
        glPixelZoom((GLfloat)mGlWidth / mSoupWidth, -(GLfloat)mGlHeight / mSoupHeight);
        glRasterPos2f(0, mGlHeight);
    }
    else
    {
        glPixelZoom(1, -1);
        glRasterPos2f((mGlWidth - (float)mSoupWidth) / 2.0, mSoupHeight - (((float)mSoupHeight - mGlHeight) / 2.0));
    }
    glDrawPixels(mSoupWidth, mSoupHeight, GL_COLOR_INDEX, GL_UNSIGNED_BYTE, mWorld->soup()->soup());

    [self checkForGLError];
}



@end
