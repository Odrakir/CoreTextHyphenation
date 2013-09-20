//
//  MarkupStyle.h
//  CoreTextMagazine
//
//  Created by Ricardo Sánchez Sotres on 19/02/13.
//  Copyright (c) 2013 Ricardo Sánchez Sotres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

@interface CTHMarkupParser : NSObject

+ (NSAttributedString*)attrStringFromMarkup:(NSString*)html;
+ (void) setFont:(UIFont *) regular bold:(UIFont *) bold italic:(UIFont *) italic;

@end