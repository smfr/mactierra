//
//  MTSoupView.mm
//  MacTierra
//
//  Created by Simon Fraser on 8/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTSoupView.h"

#import "mt_soup.h"


@implementation MTSoupView

- (id)initWithFrame:(NSRect)inFrame
{
    if ((self = [super initWithFrame:inFrame]))
    {
    }
    return self;
}

- (void)setSoup:(MacTierra::Soup*)inSoup
{
    mSoup = inSoup;
    
    const int kSoupWidth = 512;
    mSoupWidth = kSoupWidth;
    mSoupHeight = mSoup->soupSize() / kSoupWidth;
    
}

- (MacTierra::Soup*)soup
{
    return mSoup;
}

- (void)drawRect:(NSRect)inDirtyRect
{
    [super drawRect:inDirtyRect];
}

- (NSRect)contentsRect
{
	NSRect viewBounds = [self bounds];
	NSRect imageDestRect = viewBounds;

	if (mSoup)
        imageDestRect = [self contentsRectForSize:NSMakeSize(mSoupWidth, mSoupHeight)];
    
	return imageDestRect;
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


    glClearColor(0.3, 0.3, 0.3, 1.0);
}

// update the GL texture
- (void)render
{
    CGLContextObj cgl_ctx = mCGlContext;

    glClear(GL_COLOR_BUFFER_BIT);

    if (!mSoup)
        return;

    glRasterPos2f((mGlWidth - (float)mSoupWidth) / 2.0, (mGlHeight - (float)mSoupHeight) / 2.0);
    glDrawPixels(mSoupWidth, mSoupHeight, GL_COLOR_INDEX, GL_UNSIGNED_BYTE, mSoup->soup());

#if 1
    GLenum gl_err;
    if ((gl_err = glGetError()))
        NSLog(@"BinaryImageView got OpenGL error %d", gl_err);
#endif

}



@end
