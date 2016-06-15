//
//  annotationView.m
//  GaoDeDemo
//
//  Created by hgy on 16/6/14.
//  Copyright © 2016年 hgy. All rights reserved.
//

#import "annotationView.h"
#define kCalloutWidth       200.0
#define kCalloutHeight      70.0

@interface annotationView ()

@property (nonatomic , strong , readwrite) CallOutView *calloutViewl;

@end


@implementation annotationView

@synthesize calloutViewl = _calloutViewl;

#pragma mark - overide
-(void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (self.selected == selected) {
        return;
    }
    if (selected) {
        if (self.calloutViewl == nil)
        {
            self.calloutViewl = [[CallOutView alloc] initWithFrame:CGRectMake(0, 0, kCalloutWidth, kCalloutHeight)];
            self.calloutViewl.center = CGPointMake(CGRectGetWidth(self.bounds) / 2.f + self.calloutOffset.x,
                                                  -CGRectGetHeight(self.calloutViewl.bounds) / 2.f + self.calloutOffset.y);
        }
        
        self.calloutViewl.image = [UIImage imageNamed:@"buildin"];
        self.calloutViewl.title = self.annotation.title;
        self.calloutViewl.subtitle = self.annotation.subtitle;
        
        [self addSubview:self.calloutViewl];
        
        
        
    }else{
        [self.calloutViewl removeFromSuperview];
    }
    [super setSelected:selected animated:animated];
}
// 重新此函数，用以实现点击calloutView判断为点击该annotationView
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL inside = [super pointInside:point withEvent:event];
    
    if (!inside && self.selected)
    {
        inside = [self.calloutViewl pointInside:[self convertPoint:point toView:self.calloutViewl] withEvent:event];
    }
    
    return inside;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
