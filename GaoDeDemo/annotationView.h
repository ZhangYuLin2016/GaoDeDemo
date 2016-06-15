//
//  annotationView.h
//  GaoDeDemo
//
//  Created by hgy on 16/6/14.
//  Copyright © 2016年 hgy. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>
#import "CallOutView.h"
//实现自定义选中方法
@interface annotationView : MAAnnotationView
//气泡的属性
@property (nonatomic , readonly) CallOutView *calloutViewl;

@end
