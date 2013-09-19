//
//  CTView.h
//  CoreTextTest
//
//  Created by Ricardo on 18/09/13.
//  Copyright (c) 2013 Ricardo Sanchez Sotres. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CTHView : UIView
@property (nonatomic, strong) NSAttributedString* attString;
@property (nonatomic, assign) BOOL hyphenate;
@property (nonatomic, assign) BOOL autoSize;
- (void) selectWordAtPoint:(CGPoint) punto withBlock:(void (^)(NSString * word, CGRect bbox)) returnBlock;
@end
