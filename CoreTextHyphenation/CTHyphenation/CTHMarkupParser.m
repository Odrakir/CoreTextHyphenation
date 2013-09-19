#import "CTHMarkupParser.h"
#import "CTHMarkupStyle.h"

@implementation CTHMarkupParser

static UIFont* defaultFont;
static UIFont* boldFont;
static UIFont* italicFont;

+ (void) setFont:(UIFont *) regular bold:(UIFont *) bold italic:(UIFont *) italic {
    defaultFont = regular;
    boldFont = bold;
    italic = italic;
}

+ (NSAttributedString*)attrStringFromMarkup:(NSString*)markup {
    if(!defaultFont)
        defaultFont = [UIFont fontWithName:@"Helvetica" size:12.0f];
    if(!boldFont)
        boldFont = [UIFont fontWithName:@"Helvetica-Bold" size:12.0f];
    if(!italicFont)
        italicFont = [UIFont fontWithName:@"Helvetica-Oblique" size:12.0f];
    
    NSMutableArray* estilos = [[NSMutableArray alloc] init];
    
    CTHMarkupStyle* estilo = [[CTHMarkupStyle alloc] init];
    UIFont* fuente = defaultFont;
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
                        
                        NSScanner *scanner = [NSScanner scannerWithString:[tag substringWithRange:match.range]];
                        uint baseColor;
                        [scanner scanUpToCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:nil];
                        [scanner scanHexInt:&baseColor];
                        CGFloat red   = ((baseColor & 0xFF0000) >> 16) / 255.0f;
                        CGFloat green = ((baseColor & 0x00FF00) >>  8) / 255.0f;
                        CGFloat blue  =  (baseColor & 0x0000FF) / 255.0f;

                        estilo.color = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];

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
                
                
                if ([tag hasPrefix:@"strong"]||[tag hasPrefix:@"b"]) {
                    UIFont* fuente = [boldFont fontWithSize:estilo.fontSize];
                    estilo.font = fuente.fontName;
                }
                if ([tag hasPrefix:@"i"]||[tag hasPrefix:@"em"]) {
                    UIFont* fuente = [italicFont fontWithSize:estilo.fontSize];
                    estilo.font = fuente.fontName;
                }
                
                [estilos addObject:estilo];
            }
        }
    }
    
    return (NSAttributedString*)aString;
}

@end