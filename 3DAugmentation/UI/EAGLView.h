/*
 
 File: EAGLView.h
 
 Abstract: The EAGLView class is a UIView subclass that renders OpenGL scene.
 If the current hardware supports OpenGL ES 2.0, it draws using OpenGL ES 2.0;
 otherwise it draws using OpenGL ES 1.1.
 */

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@interface EAGLView : UIView
{    
	BOOL animating;
	double animationFrameInterval;
	id displayLink;
    NSTimer *animationTimer;
    
//    Renderer part
    EAGLContext *context;
	
	// The pixel dimensions of the CAEAGLLayer
	GLint backingWidth;
	GLint backingHeight;
	
	/* OpenGL names for the renderbuffer and framebuffers used to render to this view */
    GLuint viewRenderbuffer, viewFramebuffer;
    GLuint depthRenderbuffer;
    
//    Matrixes
    GLfloat             *projectionMatrix;
    GLfloat             *modelViewMatrix;
}

@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (atomic) BOOL isVisible;
@property (atomic) BOOL updateMatrixes;

- (void) startAnimation;
- (void) stopAnimation;

- (void)setModelViewMatrix:(GLfloat*)newMatrix;

@end
