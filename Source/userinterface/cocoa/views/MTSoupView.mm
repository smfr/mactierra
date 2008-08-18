//
//  MTSoupView.mm
//  MacTierra
//
//  Created by Simon Fraser on 8/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTSoupView.h"

#import "mt_cellmap.h"
#import "mt_soup.h"
#import "mt_world.h"

using namespace MacTierra;

@interface MTSoupView(Private)

- (void)setScalingCTM;
- (void)drawCells:(NSRect)inDirtyRect;
- (void)drawInstructionPointers:(NSRect)inDirtyRect;

@end

#pragma mark -

@implementation MTSoupView

@synthesize zoomToFit;
@synthesize showCells;
@synthesize showInstructionPointers;

- (id)initWithFrame:(NSRect)inFrame
{
    if ((self = [super initWithFrame:inFrame]))
    {
        zoomToFit = YES;
        showCells = NO;
        showInstructionPointers = NO;
    }
    return self;
}

- (void)setWorld:(MacTierra::World*)inWorld
{
    mWorld = inWorld;
    
    const int kSoupWidth = 512;
    mSoupWidth = kSoupWidth;
    mSoupHeight = mWorld->soupSize() / kSoupWidth;
    
    [self setGLOptions];
}

- (MacTierra::World*)world
{
    return mWorld;
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

    if (zoomToFit)
    {
        // glPixelZoom((GLfloat)mGlWidth / mSoupWidth, (GLfloat)mGlHeight / mSoupHeight);

    }
    else
    {
        // glRasterPos2f((mGlWidth - (float)mSoupWidth) / 2.0, (mGlHeight - (float)mSoupHeight) / 2.0);
    }

}

- (void)drawCells:(NSRect)inDirtyRect
{
    CGContextRef cgContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];

    [[NSColor blueColor] set];
    
    CellMap*    cellMap = mWorld->cellMap();
    const u_int32_t soupSize = mWorld->soupSize();
    
    CellMap::CreatureList::const_iterator iterEnd = cellMap->cells().end();
    for (CellMap::CreatureList::const_iterator it = cellMap->cells().begin(); it != iterEnd; ++it)
    {
        const CellMap::CreatureCell curCell = *it;
        
        int startLine   = curCell.start() / mSoupWidth;
        int endLine     = curCell.wrappedEnd(soupSize) / mSoupWidth;
        
        int startCol    = curCell.start() % mSoupWidth;
        int endCol      = curCell.wrappedEnd(soupSize) % mSoupWidth;
        
        CGContextBeginPath(cgContext);
        
        if (curCell.wraps(soupSize))
        {
        }
        else
        {
        
            for (int i = startLine; i <= endLine; ++i)
            {
                CGPoint startPoint = CGPointMake((i == startLine) ? startCol : 0, i);
                CGPoint endPoint   = CGPointMake((i == endLine - 1) ? endCol : mSoupWidth, i);
                
                CGContextMoveToPoint(cgContext, startPoint.x, startPoint.y);
                CGContextAddLineToPoint(cgContext, endPoint.x, endPoint.y);
                
            }
        }

        CGContextStrokePath(cgContext);
    }
}

- (void)drawInstructionPointers:(NSRect)inDirtyRect
{
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
        glPixelZoom((GLfloat)mGlWidth / mSoupWidth, (GLfloat)mGlHeight / mSoupHeight);
        glRasterPos2f(0, 0);
    }
    else
    {
        glRasterPos2f((mGlWidth - (float)mSoupWidth) / 2.0, (mGlHeight - (float)mSoupHeight) / 2.0);
    }
    glDrawPixels(mSoupWidth, mSoupHeight, GL_COLOR_INDEX, GL_UNSIGNED_BYTE, mWorld->soup()->soup());

    [self checkForGLError];
}



@end
