/*
 * This is the source code of Telegram for iOS v. 1.1
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Peter Iakovlev, 2013.
 */

#import "TGMessageImageViewOverlayView.h"

typedef enum {
    TGMessageImageViewOverlayViewTypeDownload = 1,
    TGMessageImageViewOverlayViewTypeProgress = 2,
    TGMessageImageViewOverlayViewTypePlay = 3
} TGMessageImageViewOverlayViewType;

@interface TGMessageImageViewOverlayLayer : CALayer
{
}

@property (nonatomic) int overlayStyle;
@property (nonatomic) CGFloat progress;
@property (nonatomic) int type;
@property (nonatomic, strong) UIImage *blurredBackgroundImage;
@property (nonatomic, strong) UIColor *imageBackgroundColor;

@end

@implementation TGMessageImageViewOverlayLayer

- (instancetype)initWithLayer:(id)layer
{
    self = [super init];
    if (self != nil)
    {
        if ([layer isKindOfClass:[TGMessageImageViewOverlayLayer class]])
        {
            _type = ((TGMessageImageViewOverlayLayer *)layer).type;
            _overlayStyle = ((TGMessageImageViewOverlayLayer *)layer).overlayStyle;
        }
    }
    return self;
}

+ (BOOL)needsDisplayForKey:(NSString *)key
{
    if ([key isEqualToString:@"progress"])
        return true;
    
    return [super needsDisplayForKey:key];
}

- (void)setOverlayStyle:(int)overlayStyle
{
    if (_overlayStyle != overlayStyle)
    {
        _overlayStyle = overlayStyle;
        [self setNeedsDisplay];
    }
}

- (void)setBlurredBackgroundImage:(UIImage *)blurredBackgroundImage
{
    if (_blurredBackgroundImage != blurredBackgroundImage)
    {
        _blurredBackgroundImage = blurredBackgroundImage;
        [self setNeedsDisplay];
    }
}

- (void)setImageBackgroundColor:(UIColor *)imageBackgroundColor
{
    if (_imageBackgroundColor != imageBackgroundColor)
    {
        _imageBackgroundColor = imageBackgroundColor;
        [self setNeedsDisplay];
    }
}

- (void)setDownload
{
    if (_type != TGMessageImageViewOverlayViewTypeDownload)
    {
        _type = TGMessageImageViewOverlayViewTypeDownload;
        [self setNeedsDisplay];
        
        [self removeAnimationForKey:@"progress"];
    }
}

- (void)setPlay
{
    if (_type != TGMessageImageViewOverlayViewTypePlay)
    {
        _type = TGMessageImageViewOverlayViewTypePlay;
        [self setNeedsDisplay];
        
        [self removeAnimationForKey:@"progress"];
    }
}

- (void)setProgress:(float)progress animated:(BOOL)animated
{
    if (_type != TGMessageImageViewOverlayViewTypeProgress || ABS(_progress - progress) > FLT_EPSILON)
    {
        float previousProgress = _progress;
        if ([self animationForKey:@"progress"] != nil)
            previousProgress = ((TGMessageImageViewOverlayLayer *)self.presentationLayer).progress;
        
        _type = TGMessageImageViewOverlayViewTypeProgress;
        _progress = progress;
        
        if (animated)
        {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"progress"];
            animation.fromValue = @(previousProgress);
            animation.toValue = @(_progress);
            animation.duration = _progress >= 1.0f - FLT_EPSILON ? 0.1 : 0.2;
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
            animation.removedOnCompletion = true;
            animation.fillMode = kCAFillModeForwards;
            [self addAnimation:animation forKey:@"progress"];
        }
        else
            [self setNeedsDisplay];
    }
}

- (void)drawInContext:(CGContextRef)context
{
    UIGraphicsPushContext(context);

    switch (_type)
    {
        case TGMessageImageViewOverlayViewTypeDownload:
        {
            const CGFloat diameter = 50.0f;
            const CGFloat lineWidth = 2.0f;
            const CGFloat height = 24.0f;
            const CGFloat width = 20.0f;
            
            CGContextSetBlendMode(context, kCGBlendModeCopy);
            
            if (_overlayStyle == TGMessageImageViewOverlayStyleDefault)
            {
                CGContextSetFillColorWithColor(context, UIColorRGBA(0xffffffff, 0.8f).CGColor);
                CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, diameter, diameter));
            }
            else
            {
                CGContextSetStrokeColorWithColor(context, UIColorRGB(0xeaeaea).CGColor);
                CGContextSetLineWidth(context, 1.5f);
                CGContextStrokeEllipseInRect(context, CGRectMake(1.5f / 2.0f, 1.5f / 2.0f, diameter - 1.5f, diameter - 1.5f));
            }
            
            if (_overlayStyle == TGMessageImageViewOverlayStyleDefault)
                CGContextSetStrokeColorWithColor(context, UIColorRGBA(0xff000000, 0.55f).CGColor);
            else
                CGContextSetStrokeColorWithColor(context, TGAccentColor().CGColor);
            
            CGContextSetLineCap(context, kCGLineCapRound);
            CGContextSetLineWidth(context, lineWidth);
            
            CGPoint mainLine[] = {
                CGPointMake((diameter - lineWidth) / 2.0f + lineWidth / 2.0f, (diameter - height) / 2.0f + lineWidth / 2.0f),
                CGPointMake((diameter - lineWidth) / 2.0f + lineWidth / 2.0f, (diameter + height) / 2.0f - lineWidth / 2.0f)
            };
            
            CGPoint arrowLine[] = {
                CGPointMake((diameter - lineWidth) / 2.0f + lineWidth / 2.0f - width / 2.0f, (diameter + height) / 2.0f + lineWidth / 2.0f - width / 2.0f),
                CGPointMake((diameter - lineWidth) / 2.0f + lineWidth / 2.0f, (diameter + height) / 2.0f + lineWidth / 2.0f),
                CGPointMake((diameter - lineWidth) / 2.0f + lineWidth / 2.0f, (diameter + height) / 2.0f + lineWidth / 2.0f),
                CGPointMake((diameter - lineWidth) / 2.0f + lineWidth / 2.0f + width / 2.0f, (diameter + height) / 2.0f + lineWidth / 2.0f - width / 2.0f),
            };
            
            if (_overlayStyle == TGMessageImageViewOverlayStyleDefault)
                CGContextSetStrokeColorWithColor(context, [UIColor clearColor].CGColor);
            CGContextStrokeLineSegments(context, mainLine, sizeof(mainLine) / sizeof(mainLine[0]));
            CGContextStrokeLineSegments(context, arrowLine, sizeof(arrowLine) / sizeof(arrowLine[0]));
            
            if (_overlayStyle == TGMessageImageViewOverlayStyleDefault)
            {
                CGContextSetBlendMode(context, kCGBlendModeNormal);
                CGContextSetStrokeColorWithColor(context, UIColorRGBA(0x000000, 0.55f).CGColor);
                CGContextStrokeLineSegments(context, arrowLine, sizeof(arrowLine) / sizeof(arrowLine[0]));
                
                CGContextSetBlendMode(context, kCGBlendModeCopy);
                CGContextStrokeLineSegments(context, mainLine, sizeof(mainLine) / sizeof(mainLine[0]));
            }
            
            break;
        }
        case TGMessageImageViewOverlayViewTypeProgress:
        {
            const CGFloat diameter = 50.0f;
            const CGFloat lineWidth = 2.0f;
            const CGFloat crossSize = 16.0f;
            
            CGContextSetBlendMode(context, kCGBlendModeCopy);
            
            if (_overlayStyle == TGMessageImageViewOverlayStyleDefault)
            {
                CGContextSetFillColorWithColor(context, UIColorRGBA(0x000000, 0.7f).CGColor);
                CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, diameter, diameter));
            }
            else
            {
                CGContextSetStrokeColorWithColor(context, UIColorRGB(0xeaeaea).CGColor);
                CGContextSetLineWidth(context, 1.5f);
                CGContextStrokeEllipseInRect(context, CGRectMake(1.5f / 2.0f, 1.5f / 2.0f, diameter - 1.5f, diameter - 1.5f));
            }
            
                CGContextSetLineCap(context, kCGLineCapRound);
            CGContextSetLineWidth(context, lineWidth);
            
            CGPoint crossLine[] = {
                CGPointMake((diameter - crossSize) / 2.0f, (diameter - crossSize) / 2.0f),
                CGPointMake((diameter + crossSize) / 2.0f, (diameter + crossSize) / 2.0f),
                CGPointMake((diameter + crossSize) / 2.0f, (diameter - crossSize) / 2.0f),
                CGPointMake((diameter - crossSize) / 2.0f, (diameter + crossSize) / 2.0f),
            };
            
            if (_overlayStyle == TGMessageImageViewOverlayStyleDefault)
                CGContextSetStrokeColorWithColor(context, [UIColor clearColor].CGColor);
            else
                CGContextSetStrokeColorWithColor(context, TGAccentColor().CGColor);
            CGContextStrokeLineSegments(context, crossLine, sizeof(crossLine) / sizeof(crossLine[0]));
            
            if (_overlayStyle == TGMessageImageViewOverlayStyleDefault)
            {
                CGContextSetBlendMode(context, kCGBlendModeNormal);
                CGContextSetStrokeColorWithColor(context, UIColorRGBA(0xffffff, 1.0f).CGColor);
                CGContextStrokeLineSegments(context, crossLine, sizeof(crossLine) / sizeof(crossLine[0]));
            }
            
            CGContextSetBlendMode(context, kCGBlendModeCopy);
            
            CGFloat start_angle = 2.0f * ((CGFloat)M_PI) * 0.0f - ((CGFloat)M_PI_2);
            CGFloat end_angle = 2.0f * ((CGFloat)M_PI) * _progress - ((CGFloat)M_PI_2);
            
            CGFloat pathLineWidth = _overlayStyle == TGMessageImageViewOverlayStyleDefault ? 2.0f : 2.0f;
            CGFloat pathDiameter = diameter - pathLineWidth;
            UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(diameter / 2.0f, diameter / 2.0f) radius:pathDiameter / 2.0f startAngle:start_angle endAngle:end_angle clockwise:true];
            path.lineWidth = pathLineWidth;
            path.lineCapStyle = kCGLineCapRound;
            [path stroke];
            
            break;
        }
        case TGMessageImageViewOverlayViewTypePlay:
        {
            const CGFloat diameter = 50.0f;
            const CGFloat width = 20.0f;
            const CGFloat height = width + 4.0f;
            const CGFloat offset = 3.0f;
            
            CGContextSetBlendMode(context, kCGBlendModeCopy);
            
            CGContextSetFillColorWithColor(context, UIColorRGBA(0xffffffff, 0.8f).CGColor);
            CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, diameter, diameter));
            
            CGContextBeginPath(context);
            CGContextMoveToPoint(context, offset + CGFloor((diameter - width) / 2.0f), CGFloor((diameter - height) / 2.0f));
            CGContextAddLineToPoint(context, offset + CGFloor((diameter - width) / 2.0f) + width, CGFloor(diameter / 2.0f));
            CGContextAddLineToPoint(context, offset + CGFloor((diameter - width) / 2.0f), CGFloor((diameter + height) / 2.0f));
            CGContextClosePath(context);
            CGContextSetFillColorWithColor(context, UIColorRGBA(0xff000000, 0.45f).CGColor);
            CGContextFillPath(context);
            
            break;
        }
        default:
            break;
    }
    
    UIGraphicsPopContext();
}

@end

@implementation TGMessageImageViewOverlayView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        self.opaque = false;
        self.backgroundColor = [UIColor clearColor];
        
        self.layer.contentsScale = [UIScreen mainScreen].scale;
    }
    return self;
}

+ (Class)layerClass
{
    return [TGMessageImageViewOverlayLayer class];
}

- (void)setOverlayStyle:(TGMessageImageViewOverlayStyle)overlayStyle
{
    [((TGMessageImageViewOverlayLayer *)self.layer) setOverlayStyle:overlayStyle];
}

- (void)setBlurredBackgroundImage:(UIImage *)blurredBackgroundImage
{
    [((TGMessageImageViewOverlayLayer *)self.layer) setBlurredBackgroundImage:blurredBackgroundImage];
}

- (void)setImageBackgroundColor:(UIColor *)imageBackgroundColor
{
    [((TGMessageImageViewOverlayLayer *)self.layer) setImageBackgroundColor:imageBackgroundColor];
}

- (void)setDownload
{
    [((TGMessageImageViewOverlayLayer *)self.layer) setDownload];
}

- (void)setPlay
{
    [((TGMessageImageViewOverlayLayer *)self.layer) setPlay];
}

- (void)setProgress:(float)progress animated:(bool)animated
{
    [((TGMessageImageViewOverlayLayer *)self.layer) setProgress:progress animated:animated];
}

@end