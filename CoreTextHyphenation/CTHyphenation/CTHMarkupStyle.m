//
//  MarkupStyle.m
//  CoreTextMagazine
//
//  Created by Ricardo Sánchez Sotres on 19/02/13.
//  Copyright (c) 2013 Ricardo Sánchez Sotres. All rights reserved.
//

#import "CTHMarkupStyle.h"

@implementation CTHMarkupStyle
@synthesize font, color, bold, italic, fontSize;

- (id) initWithStyle:(CTHMarkupStyle *) estilo {
    self = [super init];
    if(self) {
        self.font = estilo.font.copy;
        self.color = estilo.color;//.copy;
        self.bold = estilo.bold;
        self.italic = estilo.italic;
        self.fontSize = estilo.fontSize;
    }
    
    return self;
}
@end
