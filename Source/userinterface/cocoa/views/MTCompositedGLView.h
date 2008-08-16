//
//  MTCompositedGLView.h
//  MTCompositedGLView
//
//  Created by Simon Fraser on 8/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/CGLMacro.h>
#import <QuartzCore/QuartzCore.h>

typedef enum
{
	CVDisplayModeMaintainAspectRatio		= 0,
	CVDisplayModeFitInWindow,
	CVDisplayModeActualSize
} CVDisplayMode;

@interface MTCompositedGLView : NSView
{
@protected
	// OpenGL-specific
	NSOpenGLPixelFormat*    mGlPixelFormat;		 	// Cocoa-based OpenGL pixel format and context
	NSOpenGLContext*        mGlContext;
	CGLPixelFormatObj       mCGlPixelFormat;		// Handy references to the underlying CGL objects
	CGLContextObj           mCGlContext;
	GLsizei                 mGlWidth;				// Width and height, in pixels, of our OpenGL surface
	GLsizei                 mGlHeight;
	GLenum                  mGlTextureTarget;		// The currently-enabled OpenGL texture target
	GLfloat                 _vertices[4][2];		// Geometry and texture coordinates for OpenGL:
	GLfloat                 _texCoords[4][2];		// 4 corners of our video (counter-clockwise from origin)
		
	// this is really a BOOL, but we need to set it atomically
	int32_t                 mNeedsRender;			// non-zero when the images to be drawn have changed. Modified via atomic ops.

	CVDisplayMode           mDisplayMode;
	id                      mDelegate;
}

- (void)setDelegate:(id)delegate;
- (id)delegate;

- (CGLContextObj)cglContext;
- (void)setGLOptions;

- (CVDisplayMode)displayMode;
- (void)setDisplayMode:(CVDisplayMode)inDisplayMode;

// to do more complex drawing, override -render
- (void)render;

// return the rect (in view coords) within which to draw, which might depend on the display mode.
- (NSRect)contentsRect;
- (NSRect)contentsRectForSize:(NSSize)inSize;

// for subclassers
- (void)displayModeChanged;

- (void)setNeedsRender:(BOOL)inNeedsRender;
- (BOOL)needsRender;

@end
