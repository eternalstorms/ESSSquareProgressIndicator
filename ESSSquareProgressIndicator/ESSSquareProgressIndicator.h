//
//  ESSSquareProgressIndicator.h
//
//  Created by Matthias Gansrigler on 14.10.2014.
//  Copyright (c) 2014 Eternal Storms Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#define isMac (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
#define isiOS ((TARGET_OS_IPHONE || TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR))

#if (isiOS)

#import <UIKit/UIKit.h>

IB_DESIGNABLE @interface ESSSquareProgressIndicator : UIView

#else

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

IB_DESIGNABLE @interface ESSSquareProgressIndicator : NSView

#endif

/*!
 @class			ESSSquareProgressIndicator
 
 @abstract
 An indeterminate progress indicator that animates in a square form.
 
 @discussion
 Drop a UIView in your interface file and set its class to ESSSquareProgressIndicator. It will animate as long as it's a subview of a UIView or not hidden. The animation will stop when removed from the superview or when the view is hidden.
 
 The point of this class is that a CAShapeLayer can not animate beyond its 1.0 -strokeEnd value to make for a continuous animation. ESSSquareProgressIndicator hence uses two (2) CAShapeLayers to do its job.
 
 It was created in the process of developing the iOS game ReachZEN http://zen.gansrigler.com
 */

/*!
 @property		strokeColor
 @abstract		The NSColor/UIColor the progress indicator should be drawn in.
 */
#if isiOS
@property (strong) IBInspectable UIColor *strokeColor;
#else
@property (strong) IBInspectable NSColor *strokeColor;
#endif

/*!
 @property		strokeWidth
 @abstract		The width of the progress indicator's line.
 @discussion	Minimum value is 2.0.
 */
@property (assign) IBInspectable CGFloat strokeWidth;

@end