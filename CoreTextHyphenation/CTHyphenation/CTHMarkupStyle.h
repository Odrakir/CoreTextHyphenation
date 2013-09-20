//
//  MarkupStyle.h
//  CoreTextMagazine
//
//  Created by Ricardo Sánchez Sotres on 19/02/13.
//  Copyright (c) 2013 Ricardo Sánchez Sotres. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CTHMarkupStyle : NSObject
@property (nonatomic, strong) NSString* font;
@property (nonatomic, strong) UIColor* color;
@property (nonatomic, assign) BOOL bold;
@property (nonatomic, assign) BOOL italic;
@property (nonatomic, assign) float fontSize;

@property (nonatomic, assign) CTTextAlignment alignment;

- (id) initWithStyle:(CTHMarkupStyle *) estilo;
@end
