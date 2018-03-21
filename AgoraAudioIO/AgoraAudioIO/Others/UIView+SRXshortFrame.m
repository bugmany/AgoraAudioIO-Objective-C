//
//  UIView+SRXshortFrame.m
//
//  Created by CavanSu on 23/02/2017.
//  Copyright © 2017 CavanSu. All rights reserved.
//

#import "UIView+SRXshortFrame.h"

@implementation UIView (SRXshortFrame)

-(void)setX_SRX:(CGFloat)x_SRX {
    CGRect frame = self.frame;
    frame.origin.x = x_SRX;
    self.frame = frame;
}

-(CGFloat)x_SRX {
    return self.frame.origin.x;
}

-(void)setY_SRX:(CGFloat)y_SRX {
    CGRect frame = self.frame;
    frame.origin.y = y_SRX;
    self.frame = frame;
}

-(CGFloat)y_SRX {
    return self.frame.origin.y;
}

-(void)setWidth_SRX:(CGFloat)width_SRX {
    CGRect frame = self.frame;
    frame.size.width = width_SRX;
    self.frame = frame;
}

-(CGFloat)width_SRX {
    return self.frame.size.width;
}

-(void)setHeight_SRX:(CGFloat)height_SRX {
    CGRect frame = self.frame;
    frame.size.height = height_SRX;
    self.frame = frame;
}

-(CGFloat)height_SRX {
    return self.frame.size.height;
}

-(void)setSize_SRX:(CGSize)size_SRX {
    CGRect frame = self.frame;
    frame.size = size_SRX;
    self.frame = frame;
}

-(CGSize)size_SRX {
    return self.frame.size;
}

-(void)setOrigin_SRX:(CGPoint)origin_SRX {
    CGRect frame = self.frame;
    frame.origin = origin_SRX;
    self.frame = frame;
}

-(CGPoint)origin_SRX {
    return self.frame.origin;
}

-(void)setCenterX_SRX:(CGFloat)centerX_SRX {
    CGPoint center = self.center;
    center.x = centerX_SRX;
    self.center = center;
}

-(CGFloat)centerX_SRX {
    return self.center.x;
}

-(void)setCenterY_SRX:(CGFloat)centerY_SRX {
    CGPoint center = self.center;
    center.y = centerY_SRX;
    self.center = center;
}

-(CGFloat)centerY_SRX {
    return self.center.y;
}


@end
