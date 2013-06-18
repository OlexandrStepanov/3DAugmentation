/*
 
 File: EAGLView.m
 
 Abstract: The EAGLView class is a UIView subclass that renders OpenGL scene.
 If the current hardware supports OpenGL ES 2.0, it draws using OpenGL ES 2.0;
 otherwise it draws using OpenGL ES 1.1.
 
 Version: 1.0
 */

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#define USE_DEPTH_BUFFER 0

#import "EAGLView.h"
#include "CameraIntrinsicMatrix.h"

#include <iostream>

using namespace cv;

@interface EAGLView(Private)
    - (BOOL)createFramebuffer;
    - (void) drawView;
    - (void)actualDraw;
    - (void)destroyFramebuffer;
    - (void)buildProjectionMatrix;
@end

@implementation EAGLView

@synthesize animating;
@synthesize isVisible, updateMatrixes;

// You must implement this method
+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

- (void) dealloc
{
    [self stopAnimation];
    [self destroyFramebuffer];
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    [context release];
    
    delete projectionMatrix;
    delete modelViewMatrix;
	
    [super dealloc];
}


//The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id) initWithFrame:(CGRect)frame
{    
    if ((self = [super initWithFrame:frame]))
	{
        // Get the layer
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        
        eaglLayer.opaque = NO;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
		
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        
        if (!context || ![EAGLContext setCurrentContext:context]) {
            [self release];
            return nil;
        }
		
		animating = FALSE;
		animationFrameInterval = 1.0/25.0;
		displayLink = nil;
		animationTimer = nil;
        self.isVisible = NO;
        self.updateMatrixes = NO;
        
        projectionMatrix = new GLfloat[16];
        modelViewMatrix = new GLfloat[16];
    }
	
    return self;
}

#pragma mark - Draw part

- (void) drawView
{
//  Preparation
    [EAGLContext setCurrentContext:context];
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
    
    if (self.updateMatrixes) {   
        glMatrixMode(GL_PROJECTION);
        glLoadMatrixf(projectionMatrix);
        
        glMatrixMode(GL_MODELVIEW);
        glLoadMatrixf(modelViewMatrix);
        
        self.updateMatrixes = NO;
    }
    
//    Clear background
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    if (self.isVisible) {
        [self actualDraw];
    }
    
// Switch the render buffer and framebuffer so our scene is displayed on the screen
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];    
}

- (void)actualDraw {
    const GLfloat squareVertices[] = {
        0.f, 0.f, 0.f,
        1.f, 0.f, 0.f,
        0.f, 0.f, 0.f,
        0.f, 1.f, 0.f,
        0.f, 0.f, 0.f,
        0.f, 0.f, 1.f,
    };
    const GLubyte squareColors[] = {
        255, 0,   0, 255,
        255, 0,   0, 255,
        0,   255, 0, 255,
        0,   255, 0, 255,
        0,   0, 255,    255,
        0,   0, 255,    255,
    };
    
    glLineWidth(2.0);
    
    glVertexPointer(3, GL_FLOAT, 0, squareVertices);
    glEnableClientState(GL_VERTEX_ARRAY);
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, squareColors);
    glEnableClientState(GL_COLOR_ARRAY);
    
    glDrawArrays(GL_LINES, 0, 6);
}

- (void)buildProjectionMatrix {    
    
    // Camera parameters
    double f_x = cameraMatrix[0]; // Focal length in x axis
    double f_y = cameraMatrix[4]; // Focal length in y axis (usually the same?)
    double c_x = cameraMatrix[2]; // Camera primary point x
    double c_y = cameraMatrix[5]; // Camera primary point y
    
    double screen_width = CAMERA_WIDTH; // In pixels
    double screen_height = CAMERA_HEIGHT; // In pixels
    
    double near = 0.1;  // Near clipping distance
    double far = 1000;  // Far clipping distance
    
    projectionMatrix[0] = 2.0 * f_x / screen_width;
	projectionMatrix[1] = 0.0;
	projectionMatrix[2] = 0.0;
	projectionMatrix[3] = 0.0;
    
	projectionMatrix[4] = 0.0;
	projectionMatrix[5] = 2.0 * f_y / screen_height;
	projectionMatrix[6] = 0.0;
	projectionMatrix[7] = 0.0;
	
	projectionMatrix[8] = 2.0 * c_x / screen_width - 1.0;
	projectionMatrix[9] = 2.0 * c_y / screen_height - 1.0;	
	projectionMatrix[10] = -( far+near ) / ( far - near );
	projectionMatrix[11] = -1.0;
    
	projectionMatrix[12] = 0.0;
	projectionMatrix[13] = 0.0;
	projectionMatrix[14] = -2.0 * far * near / ( far - near );		
	projectionMatrix[15] = 0.0;
}


#pragma mark -

- (void)layoutSubviews {
    [EAGLContext setCurrentContext:context];
    [self destroyFramebuffer];
    [self createFramebuffer];
    [self buildProjectionMatrix];
    [self drawView];
}


- (BOOL)createFramebuffer {
    
    glGenFramebuffersOES(1, &viewFramebuffer);
    glGenRenderbuffersOES(1, &viewRenderbuffer);
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
    
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
    
    if (USE_DEPTH_BUFFER) {
        glGenRenderbuffersOES(1, &depthRenderbuffer);
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
        glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
    }
    
    if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
    
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_DEPTH_TEST);
    
    return YES;
}


- (void)destroyFramebuffer {
    
    glDeleteFramebuffersOES(1, &viewFramebuffer);
    viewFramebuffer = 0;
    glDeleteRenderbuffersOES(1, &viewRenderbuffer);
    viewRenderbuffer = 0;
    
    if(depthRenderbuffer) {
        glDeleteRenderbuffersOES(1, &depthRenderbuffer);
        depthRenderbuffer = 0;
    }
}

- (void) startAnimation
{
	if (!animating)
	{
        displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(drawView)];
        [displayLink setFrameInterval:animationFrameInterval];
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		
        self.isVisible = NO;
		animating = TRUE;
	}
}

- (void)stopAnimation
{
	if (animating)
	{
        [displayLink invalidate];
        displayLink = nil;
		animating = FALSE;
	}
}

- (void)setModelViewMatrix:(GLfloat*)newMatrix {
//    Copy newMatrix
    for (int i=0; i<16; i++)
        modelViewMatrix[i] = newMatrix[i];
    
    self.updateMatrixes = YES;
}

@end
