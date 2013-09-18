#import "CTHMarkupParser.h"
#import "CTHMarkupStyle.h"

@implementation CTHMarkupParser


+ (NSAttributedString*)attrStringFromMarkup:(NSString*)markup {
    NSMutableArray* estilos = [[NSMutableArray alloc] init];
    
    CTHMarkupStyle* estilo = [[CTHMarkupStyle alloc] init];
    UIFont* fuente = [UIFont fontWithName:@"Helvetica" size:17.0f];
    estilo.font = fuente.fontName;
    estilo.fontSize = 17.0f;
    estilo.color = [UIColor colorWithHue:0.0 saturation:0.0 brightness:0.0 alpha:0.8];
    estilo.bold = NO;
    
    [estilos addObject:estilo];
    
    
    NSMutableAttributedString* aString = [[NSMutableAttributedString alloc] initWithString:@""];
    
    NSRegularExpression* regex = [[NSRegularExpression alloc] initWithPattern:@"([^<]*?)(<[^>]+>|\\Z)"
                                                                      options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators
                                                                        error:nil]; //2
    NSArray* chunks = [regex matchesInString:markup
                                     options:0
                                       range:NSMakeRange(0, [markup length])];
    
    for (NSTextCheckingResult* b in chunks) {
        NSArray* parts = [[markup substringWithRange:b.range] componentsSeparatedByString:@"<"];
        
        CTHMarkupStyle* estilo = [estilos lastObject];
        
        CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)estilo.font, estilo.fontSize, NULL);

        
        CTTextAlignment alignment = kCTJustifiedTextAlignment;
        
        CTLineBreakMode breakMode = kCTLineBreakByWordWrapping;
        CGFloat spaceBetweenLines = 1.0;
        CTParagraphStyleSetting settings[]={
            {kCTParagraphStyleSpecifierAlignment, sizeof(alignment), &alignment},
            {kCTParagraphStyleSpecifierLineBreakMode, sizeof(breakMode), &breakMode},
            {kCTParagraphStyleSpecifierLineSpacing, sizeof(CGFloat), &spaceBetweenLines}
            
        };
        
        
        
        
        
        CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings,
                                                                    sizeof(settings)/sizeof(settings[0]));
        
        NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                               (id)estilo.color.CGColor, kCTForegroundColorAttributeName,
                               (__bridge id)fontRef, kCTFontAttributeName,
                               (__bridge id)paragraphStyle, kCTParagraphStyleAttributeName,
                               nil];
        
        
        [aString appendAttributedString:[[NSAttributedString alloc] initWithString:[parts objectAtIndex:0] attributes:attrs] ];
        
        CFRelease(fontRef);
        CFRelease(paragraphStyle);
        
        if ([parts count]>1) {
            NSString* tag = (NSString*)[parts objectAtIndex:1];
            
            if([tag hasPrefix:@"/"]) {
                
                if(estilos.count>1)
                    [estilos removeLastObject];
            } else {
                CTHMarkupStyle* estilo = [[CTHMarkupStyle alloc] initWithStyle:(CTHMarkupStyle*)[estilos lastObject]];
                
                if ([tag hasPrefix:@"font"]) {
                    
                    //color
                    NSRegularExpression* colorRegex = [[NSRegularExpression alloc] initWithPattern:@"(?<=color=\")\\w+" options:0 error:NULL];
                    [colorRegex enumerateMatchesInString:tag options:0 range:NSMakeRange(0, [tag length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                        SEL colorSel = NSSelectorFromString([NSString stringWithFormat: @"%@Color", [tag substringWithRange:match.range]]);
                        estilo.color = [UIColor performSelector:colorSel];
                    }];
                    
                    //face
                    NSRegularExpression* faceRegex = [[NSRegularExpression alloc] initWithPattern:@"(?<=face=\")[^\"]+" options:0 error:NULL];
                    [faceRegex enumerateMatchesInString:tag options:0 range:NSMakeRange(0, [tag length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                        estilo.font = [tag substringWithRange:match.range];
                    }];
                    
                    //size
                    NSRegularExpression* sizeRegex = [[NSRegularExpression alloc] initWithPattern:@"(?<=size=\")[^\"]+" options:0 error:NULL];
                    [sizeRegex enumerateMatchesInString:tag options:0 range:NSMakeRange(0, [tag length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                        estilo.fontSize = [tag substringWithRange:match.range].floatValue;
                    }];
                }
                
                
                if ([tag hasPrefix:@"strong"]) {
                    UIFont* fuente = [UIFont fontWithName:@"Helvetica" size:17.0f];
                    estilo.font = fuente.fontName;
                }
                if ([tag hasPrefix:@"i"]||[tag hasPrefix:@"em"]) {
                    UIFont* fuente = [UIFont fontWithName:@"Helvetica" size:17.0f];
                    estilo.font = fuente.fontName;
                }
                
                
                
                [estilos addObject:estilo];
            }
        }
    }
    
    return (NSAttributedString*)aString;
}

@end