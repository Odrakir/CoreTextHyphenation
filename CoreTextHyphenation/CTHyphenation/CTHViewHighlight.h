//
//  CTHViewHighlight.h
//  CoreTextHyphenation
//
//  Created by Ricardo on 20/09/13.
//  Copyright (c) 2013 Ricardo Sanchez Sotres. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CTHViewHighlight : NSObject
@property (nonatomic, assign) NSString * palabra;
@property (nonatomic, assign) CGFloat inicio;
@property (nonatomic, assign) CGFloat final;
@end
