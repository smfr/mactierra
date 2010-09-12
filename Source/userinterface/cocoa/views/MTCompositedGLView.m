//
//  MTCompositedGLView.m
//  MacTierra
//
//  Created by Simon Fraser on 8/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTCompositedGLView.h"

#include <libkern/OSAtomic.h>

@interface MTCompositedGLView(Private)

- (void)checkEnvironment;
- (void)reshapeOpenGL;
- (void)renderTexture:(BOOL)inForceRender;
- (void)globalFrameDidChange:(NSNotification*)notification;
- (void)displayProfileChanged:(NSNotification*)notification;
- (void)createWorkingColorSpace;

- (void)clearNeedsRender;

- (CGLContextObj)glContext;
- (CIContext*)context;

@end

#pragma mark -


@implementation MTCompositedGLView

- (id)initWithFrame:(NSRect)frame
{
    if ((self = [super initWithFrame:frame]) != nil)
    {
        NSOpenGLPixelFormatAttribute attributes[] = { NSOpenGLPFAAccelerated, NSOpenGLPFADoubleBuffer, 0};

        mGlPixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
        mGlContext = [[NSOpenGLContext alloc] initWithFormat:mGlPixelFormat shareContext:nil];

        // We "punch a hole" in the window, and have the WindowServer render the
        // OpenGL surface underneath so we can draw over it.
        GLint belowWindow =  -1;
        [mGlContext setValues:&belowWindow forParameter:NSOpenGLCPSurfaceOrder];
        
        mCGlContext = (CGLContextObj)[mGlContext CGLContextObj];
        mCGlPixelFormat = (CGLPixelFormatObj)[mGlPixelFormat CGLPixelFormatObj];
		
        {
            // Sync with screen refresh to avoid tearing
            GLint swapInterval = 1;
            [mGlContext setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];

            [self setGLOptions];

            [self checkEnvironment];
        }

        mDisplayMode = CVDisplayModeMaintainAspectRatio;
    }
    
    return self;
}

- (void)dealloc
{
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDistributedCenter(), self, NULL, NULL);
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [mGlContext release];
    [mGlPixelFormat release];

    [super dealloc];
}

-(void)setDelegate:(id)delegate
{
	mDelegate = delegate;
}

- (id)delegate
{
	return mDelegate;
}

- (CGLContextObj)cglContext
{
    return mCGlContext;
}

- (void)setGLOptions
{
}

- (CVDisplayMode)displayMode
{
	return mDisplayMode;
}

- (void)setDisplayMode:(CVDisplayMode)inDisplayMode
{
	if (inDisplayMode != mDisplayMode)
	{
		mDisplayMode = inDisplayMode;
		[self displayModeChanged];
		[self setNeedsDisplay:YES];
	}
}

- (BOOL)isOpaque
{
    return YES;
}

- (BOOL)wantsDefaultClipping
{
    return NO;
}

- (BOOL)displaysWhenScreenProfileChanges
{
    return YES;
}

- (void)viewWillMoveToWindow:(NSWindow*)newWindow
{
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:NSWindowDidChangeScreenProfileNotification object:nil];
    
    if (newWindow)
    {
	    // When using OpenGL, we should disable the window's "one-shot" feature
	    [newWindow setOneShot:NO];
	    // We're having the OpenGL surface render under the window, so the window needs
	    // to be not opaque.
	    [newWindow setOpaque:NO];
        
        [self reshapeOpenGL];
    }
    else
    {
    }
}

- (void)viewDidMoveToWindow
{
}

- (void)lockFocus
{
    [super lockFocus];
    
    // If we're using OpenGL, make sure it is connected and that the display link is running
    if ([mGlContext view] != self)
    {
        [mGlContext setView:self];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(globalFrameDidChange:) name:NSViewGlobalFrameDidChangeNotification object:self];
    }

    [mGlContext makeCurrentContext];
}

- (void)drawRect:(NSRect)rect
{
	const NSRect* dirtyRects;
	NSInteger dirtyRectCount;

	[self getRectsBeingDrawn:&dirtyRects count:&dirtyRectCount];
	// punch a hole so that the OpenGL view shows through.
	[[NSColor clearColor] set];
	NSRectFillList(dirtyRects, dirtyRectCount);
	
    CGLLockContext(mCGlContext);
    {
    	// when drawing the view, we always redraw the OpenGL contents
        [self renderTexture:YES];
    }
    CGLUnlockContext(mCGlContext);
}

- (void)renewGState
{
    // Synchronize with window server to avoid flashes or corrupt drawing
    [[self window] disableScreenUpdatesUntilFlush];
    [self globalFrameDidChange:nil];
    [super renewGState];
}

- (void)checkEnvironment
{
//    CGLContextObj cgl_ctx = mCGlContext;
    
    // CoreImage might be too slow if the current renderer doesn't support GL_ARB_fragment_program
//    const char* glExtensions = (const char*)glGetString(GL_EXTENSIONS);
}

- (void)reshapeOpenGL
{
    CGLContextObj cgl_ctx = mCGlContext;
    float uiScale = [[self window] userSpaceScaleFactor];

    // Calculate the pixel-aligned rectangle in which OpenGL will render
    NSRect glRect;
    glRect.size = NSIntegralRect([self convertRect:[self bounds] toView:nil]).size;
    glRect.origin = [self convertRect:NSIntegralRect([self convertRect:[self visibleRect] toView:nil]) fromView:nil].origin;

    GLint viewportLeft   = glRect.origin.x > 0 ? -glRect.origin.x * uiScale : 0;
    GLint viewportBottom = glRect.origin.y > 0 ? -glRect.origin.y * uiScale : 0;

    mGlWidth = glRect.size.width;
    mGlHeight = glRect.size.height;
    glViewport(viewportLeft, viewportBottom, mGlWidth, mGlHeight);
    
    // set the background to grey
    glClearColor(0.3, 0.3, 0.3, 1.0);
    
    // Set up our coordinate system with lower-left=(0,0) and upper-right=(mGlWidth,mGlHeight)
    // since CoreImage works best when coordinates are 1:1 with pixels
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, mGlWidth, 0, mGlHeight, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    // Configure OpenGL to get vertex and texture coordinates from our two arrays
//    glEnableClientState(GL_VERTEX_ARRAY);
//    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
#if 0
    // XXX do we need these?
    glVertexPointer(2, GL_FLOAT, 0, _vertices);
    glTexCoordPointer(2, GL_FLOAT, 0, _texCoords);

    // Specify video rectangle vertices counter-clockwise from (0,0)
    _vertices[1][0] = _vertices[2][0] = mGlWidth;
    _vertices[2][1] = _vertices[3][1] = mGlHeight;
#endif
}


- (CGLContextObj)glContext
{
	return mCGlContext;
}

- (NSRect)contentsRectForSize:(NSSize)inSize
{
	NSRect viewBounds = [self bounds];
	NSRect contentRect = [self bounds];
	
	switch (mDisplayMode)
	{
		case CVDisplayModeMaintainAspectRatio:
			{
				// maintain aspect ratio mode (other modes to come)
				float imageAspectRatio 	= inSize.width / inSize.height;
				float viewAspectRatio	= viewBounds.size.width / viewBounds.size.height;
				
				if (imageAspectRatio > viewAspectRatio)		// image wider than view
				{
					// fit width
					contentRect.size.height = viewBounds.size.width / imageAspectRatio;
					contentRect.origin.x = 0.0;
					contentRect.origin.y = (NSHeight(viewBounds) - NSHeight(contentRect)) / 2.0;
				}
				else
				{
					// fit height
					contentRect.size.width = viewBounds.size.height * imageAspectRatio;

					contentRect.origin.x = (NSWidth(viewBounds) - NSWidth(contentRect)) / 2.0;
					contentRect.origin.y = 0.0;
				}
			}

		case CVDisplayModeFitInWindow:
			// nothing to do
			break;

		case CVDisplayModeActualSize:
			contentRect.size = inSize;
			
			contentRect.origin.x = (viewBounds.size.width - inSize.width) / 2.0;
			contentRect.origin.y = (viewBounds.size.height - inSize.height) / 2.0;
			break;
	}

	return contentRect;
}

// override in subclasses
- (NSRect)contentsRect
{
    return [self bounds];
}

// override in subclasses
- (void)render
{
    CGLContextObj cgl_ctx = mCGlContext;
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)setNeedsRender:(BOOL)inNeedsRender
{
	int32_t	renderFlag = inNeedsRender;
	OSAtomicOr32(renderFlag, (uint32_t*)&mNeedsRender);
}

- (BOOL)needsRender
{
	return mNeedsRender;
}

- (void)clearNeedsRender
{
	OSAtomicTestAndClear(0, &mNeedsRender);	// XX does this hit the right bit on intel?
}

#pragma mark -

// this is called inside the CGL lock
- (void)renderTexture:(BOOL)inForceRender
{   
    CGLContextObj cgl_ctx = mCGlContext;

	[self reshapeOpenGL];

    if (mNeedsRender || inForceRender)
    {
        [self clearNeedsRender];
        [self render];
    }

    // Flush drawing to the screen
    //[_glContext flushBuffer]; // this needs to acquire the global AppKit lock the first time it's called - very prone to deadlock
	CGLFlushDrawable(cgl_ctx);
}

- (void)globalFrameDidChange:(NSNotification*)notification
{
    CGLLockContext(mCGlContext);
    {
        [mGlContext update];
        [self checkEnvironment];
    }
    CGLUnlockContext(mCGlContext);
}

- (void)displayModeChanged
{
	// base class does nothing
}

@end

