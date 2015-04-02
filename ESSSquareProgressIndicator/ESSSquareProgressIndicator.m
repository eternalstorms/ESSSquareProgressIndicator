//
//  ESSSquareProgressIndicator.m
//
//  Created by Matthias Gansrigler on 14.10.2014.
//  Copyright (c) 2014 Eternal Storms Software. All rights reserved.
//

#import "ESSSquareProgressIndicator.h"

@interface ESSSquareProgressIndicator ()

/*!
 @property		shapeLayer
 @abstract		One of the shape layers used for animating the progress indicator.
 @discussion	Two shape layers are needed because -strokeEnd can not be animated beyond 1.0. With two layers, the illusion is created that the line moves endlessly around the rect.
 */
@property (strong) CAShapeLayer *shapeLayer;

/*!
 @property		shapeLayer2
 @abstract		One of the shape layers used for animating the progress indicator.
 @discussion	Two shape layers are needed because -strokeEnd can not be animated beyond 1.0. With two layers, the illusion is created that the line moves endlessly around the rect.
 */
@property (strong) CAShapeLayer *shapeLayer2;

/*!
 @property		shouldAnimate
 @abstract		Indicates whether animation should continue.
 @discussion	If set to NO, another round of animation is not started.
 */
@property (assign) BOOL shouldAnimate;

@end

@implementation ESSSquareProgressIndicator
#if !TARGET_INTERFACE_BUILDER
- (void)awakeFromNib
{
	self.shouldAnimate = !(self.isHidden);
	
	if (self.strokeWidth <= 2.0)
		self.strokeWidth = 2.0;
	
	CGFloat strokeWidthHalf = self.strokeWidth/2.0;
	
	//we do this instead of CGPathCreateWithRect() because if we did that, the direction would be counter-clockwise, but we want it clockwise.
#if (isiOS)
	CGMutablePathRef pathRef = CGPathCreateMutable();
	CGPathMoveToPoint(pathRef, nil, strokeWidthHalf, 0+strokeWidthHalf);
	CGPathAddLineToPoint(pathRef, nil, self.frame.size.width-strokeWidthHalf, 0+strokeWidthHalf);
	CGPathMoveToPoint(pathRef, nil, self.frame.size.width-strokeWidthHalf, 0+strokeWidthHalf);
	CGPathAddLineToPoint(pathRef, nil, self.frame.size.width-strokeWidthHalf, self.frame.size.height-strokeWidthHalf);
	CGPathMoveToPoint(pathRef, nil, self.frame.size.width-strokeWidthHalf, self.frame.size.height-strokeWidthHalf);
	CGPathAddLineToPoint(pathRef, nil, strokeWidthHalf, self.frame.size.height-strokeWidthHalf);
	CGPathMoveToPoint(pathRef, nil, strokeWidthHalf, self.frame.size.height-strokeWidthHalf);
	CGPathAddLineToPoint(pathRef, nil, strokeWidthHalf, 0+strokeWidthHalf);
	CGPathMoveToPoint(pathRef, nil, strokeWidthHalf, 0+strokeWidthHalf);
	CGPathCloseSubpath(pathRef);
#elif (isMac)
	CGMutablePathRef pathRef = CGPathCreateMutable();
	CGPathMoveToPoint(pathRef, nil, strokeWidthHalf, self.frame.size.height-strokeWidthHalf);
	CGPathAddLineToPoint(pathRef, nil, self.frame.size.width-strokeWidthHalf, self.frame.size.height-strokeWidthHalf);
	CGPathMoveToPoint(pathRef, nil, self.frame.size.width-strokeWidthHalf, self.frame.size.height-strokeWidthHalf);
	CGPathAddLineToPoint(pathRef, nil, self.frame.size.width-strokeWidthHalf, strokeWidthHalf);
	CGPathMoveToPoint(pathRef, nil, self.frame.size.width-strokeWidthHalf, strokeWidthHalf);
	CGPathAddLineToPoint(pathRef, nil, strokeWidthHalf, strokeWidthHalf);
	CGPathMoveToPoint(pathRef, nil, strokeWidthHalf, strokeWidthHalf);
	CGPathAddLineToPoint(pathRef, nil, strokeWidthHalf, self.frame.size.height-strokeWidthHalf);
	CGPathMoveToPoint(pathRef, nil, strokeWidthHalf, self.frame.size.height-strokeWidthHalf);
	CGPathCloseSubpath(pathRef);
#endif
	
	self.shapeLayer = [CAShapeLayer layer];
	self.shapeLayer2 = [CAShapeLayer layer];
	
	self.shapeLayer.path = pathRef;
	self.shapeLayer.lineWidth = self.strokeWidth;
	self.shapeLayer2.path = pathRef;
	self.shapeLayer2.lineWidth = self.strokeWidth;
	
	self.shapeLayer.strokeStart = 0.0;
	self.shapeLayer.strokeEnd = 0.125;
	self.shapeLayer2.strokeStart = 0.75+0.125;
	self.shapeLayer2.strokeEnd = 1.0;
	
#if (isiOS)
	self.backgroundColor = [UIColor clearColor];
	
	if (self.strokeColor == nil)
		self.strokeColor = [UIColor blackColor];
	
	self.shapeLayer.fillColor = [[UIColor clearColor] CGColor];
	self.shapeLayer2.fillColor = [[UIColor clearColor] CGColor];
#else //isMac
	if (self.strokeColor == nil)
		self.strokeColor = [NSColor whiteColor];
	
	self.shapeLayer.fillColor = [[NSColor clearColor] CGColor];
	self.shapeLayer2.fillColor = [[NSColor clearColor] CGColor];
#endif
	
	self.shapeLayer.strokeColor = self.strokeColor.CGColor;
	self.shapeLayer2.strokeColor = self.strokeColor.CGColor;
	[self.layer addSublayer:self.shapeLayer];
	[self.layer addSublayer:self.shapeLayer2];
	
	CGPathRelease(pathRef);
	
	[self addObserver:self forKeyPath:@"color" options:NSKeyValueObservingOptionNew context:nil];
	[self addObserver:self forKeyPath:@"lineWidth" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == self && [keyPath isEqualToString:@"color"])
	{
		self.shapeLayer.strokeColor = self.strokeColor.CGColor;
		self.shapeLayer2.strokeColor = self.strokeColor.CGColor;
		return;
	} else if (object == self && [keyPath isEqualToString:@"lineWidth"])
	{
		if (self.strokeWidth <= 2.0)
			self.strokeWidth = 2.0;
		
		self.shapeLayer.lineWidth = self.strokeWidth;
		self.shapeLayer2.lineWidth = self.strokeWidth;
		return;
	}
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)removeFromSuperview
{
	self.shouldAnimate = NO;
	
	[super removeFromSuperview];
}

- (void)setHidden:(BOOL)hidden
{
	self.shouldAnimate = !hidden;
	if (hidden)
		[super setHidden:hidden];
	else
	{
		[super setHidden:hidden];
		[self _animate];
	}
}

static CAMediaTimingFunction *tf = nil;
static CGFloat duration = 0.125;
- (void)_animate
{
	if (tf == nil)
		tf = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
	
	//second animation, to whole left line
	[CATransaction setCompletionBlock:^{
		[CATransaction begin];
		[CATransaction setAnimationDuration:0.0];
		self.shapeLayer2.strokeStart = 0.75;
		self.shapeLayer2.strokeEnd = 0.75;
		[CATransaction commit];
		[CATransaction flush];
		
		[CATransaction setCompletionBlock:^{
			[CATransaction begin];
			[CATransaction setAnimationDuration:0.0];
			self.shapeLayer2.strokeStart = 0.75;
			self.shapeLayer2.strokeEnd = 1.0;
			self.shapeLayer.strokeStart = 0.0;
			self.shapeLayer.strokeEnd = 0.0;
			[CATransaction commit];
			[CATransaction flush];
			//third animation, to half left line and half top line
			[CATransaction setCompletionBlock:^{
				if (self.shouldAnimate)
					[self _animate];
			}];
			[CATransaction begin];
			[CATransaction setAnimationTimingFunction:tf];
			[CATransaction setAnimationDuration:duration];
			self.shapeLayer2.strokeStart = 0.75+0.125;
			self.shapeLayer.strokeEnd = 0.125;
			[CATransaction commit];
			
			/* 4; animate back to initial position:
			 
			 | - - .
			 |     .
			 .     .
			 . . . .
			 
			 */
		}];
		[CATransaction begin];
		[CATransaction setAnimationTimingFunction:tf];
		[CATransaction setAnimationDuration:duration*6]; //*6 because it's 6 steps
		self.shapeLayer.strokeStart = 0.75;
		self.shapeLayer.strokeEnd = 1.0;
		[CATransaction commit];
		
		/* 3; animate to this (second animation, all done in one animation)
		 
		 . - - |
		 .     |
		 .     .
		 . . . .
		 
		 . . . |
		 .     |
		 .     |
		 . . . |
		 
		 . . . .
		 .     .
		 .     |
		 . _ _ |
		 
		 . . . .
		 .     .
		 .     .
		 _ _ _ _
		 
		 . . . .
		 |     .
		 |     .
		 _ _ . .
		 
		 | . . .
		 |     .
		 |     .
		 | . . .
		 
		 */
	}];
	
	//first animation, from left half and top half to top whole line
	/* 1; initial position:
	 
		| - - .
		|     .
		.     .
		. . . .
	 
	 */
	[CATransaction begin];
	[CATransaction setAnimationTimingFunction:tf];
	[CATransaction setAnimationDuration:duration];
	
	self.shapeLayer2.strokeStart = 1.0;
	self.shapeLayer2.strokeEnd = 1.0;
	
	self.shapeLayer.strokeStart = 0.0;
	self.shapeLayer.strokeEnd = 0.25;
	[CATransaction commit];
	
	/* 2; animated to this:
	 
		- - - -
		.     .
		.     .
		. . . .
	 
	 */
}

- (void)dealloc
{
	[self removeObserver:self forKeyPath:@"color"];
	[self removeObserver:self forKeyPath:@"lineWidth"];
}

#else //is Interface Builder
#pragma mark - Interface Builder Mockup Drawing

#if (isiOS)
- (instancetype)initWithFrame:(CGRect)frameRect
#elif (isMac)
- (instancetype)initWithFrame:(NSRect)frameRect
#endif
{
	if (self = [super initWithFrame:frameRect])
	{
		[self inspectableDefaults];
		return self;
	}
	
	return nil;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
	if (self = [super initWithCoder:coder])
	{
		[self inspectableDefaults];
		return self;
	}
	
	return nil;
}

- (void)inspectableDefaults
{
#if (isiOS)
	_strokeColor = [UIColor blackColor];
#elif (isMac)
	_strokeColor = [NSColor blackColor];
#endif
	_strokeWidth = 2.0;
}

/*
 Draws a part of the path that will be animated in the built app.
 Animation with CALayer seems to be not supported by live rendering.
 */
#if (isiOS)
- (void)drawRect:(CGRect)rect
#elif (isMac)
- (void)drawRect:(NSRect)dirtyRect
#endif
{
	[_strokeColor set];
	CGFloat strokeWidthHalf = _strokeWidth/2.0;
	
#if (isiOS)
	UIBezierPath *bp = [UIBezierPath bezierPath];
	bp.lineWidth = _strokeWidth;
	[bp moveToPoint:CGPointMake(strokeWidthHalf, self.frame.size.height/2.0)];
	[bp addLineToPoint:CGPointMake(strokeWidthHalf, 0+strokeWidthHalf)];
	[bp moveToPoint:CGPointMake(strokeWidthHalf, 0+strokeWidthHalf)];
	[bp addLineToPoint:CGPointMake(self.frame.size.width/2.0, 0+strokeWidthHalf)];
#elif (isMac)
	NSBezierPath *bp = [NSBezierPath bezierPath];
	bp.lineWidth = _strokeWidth;
	[bp moveToPoint:NSMakePoint(strokeWidthHalf, self.frame.size.height/2.0)];
	[bp lineToPoint:NSMakePoint(strokeWidthHalf, self.frame.size.height-strokeWidthHalf)];
	[bp moveToPoint:NSMakePoint(strokeWidthHalf, self.frame.size.height-strokeWidthHalf)];
	[bp lineToPoint:NSMakePoint(self.frame.size.width/2.0, self.frame.size.height-strokeWidthHalf)];
#endif
	[bp closePath];
	[bp stroke];
}

#endif
@end
