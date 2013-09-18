//
//  CTView.m
//  CoreTextTest
//
//  Created by Ricardo on 18/09/13.
//  Copyright (c) 2013 Ricardo Sanchez Sotres. All rights reserved.
//

#import "CTHView.h"
#import "CTHMarkupParser.h"
#import <CoreText/CoreText.h>

@interface CTHView()
@property (nonatomic, strong) NSAttributedString* hyphenatedString;
@end

@implementation CTHView

- (void)awakeFromNib {
    _hyphenate = NO;
    _autoSize = NO;
}

- (NSAttributedString *) hyphenateAttributeString:(NSAttributedString *) sourceString {
    
    NSMutableAttributedString* resultString = [[NSMutableAttributedString alloc] initWithString:@""];
    
    CTTypesetterRef ctTypeSetter = CTTypesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(sourceString));
    
    CFStringRef localeIdent = CFSTR("es_PE");
    CFLocaleRef localeRef = CFLocaleCreate(kCFAllocatorDefault, localeIdent);
    
    CFIndex start = 0;
    CTLineRef line;
    
    unichar newLine = [@"\n" characterAtIndex:0];
    
    NSUInteger length = CFAttributedStringGetLength((__bridge CFAttributedStringRef)(sourceString));
    
    while (start < length) {
        
        CFIndex count = CTTypesetterSuggestLineBreak(ctTypeSetter, start, self.bounds.size.width);
        line = CTTypesetterCreateLine(ctTypeSetter, CFRangeMake(start, count));
        
        NSString* lineString = [sourceString attributedSubstringFromRange:NSMakeRange(start, count)].string;
        unichar lastChar = [lineString characterAtIndex:lineString.length-1];
        
        NSLog(@"------------------------------------");
        NSString* strLinea = [sourceString attributedSubstringFromRange:NSMakeRange(start, count)].string;
        NSLog(@"'%@'", strLinea);
        
        if(newLine != lastChar) {
            
            double lineWidth = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
            
            if((lineWidth / self.bounds.size.width)<0.75 && start+count+1<length) { //La línea es muy corta, trae una palabra
                NSString* strLinea = [sourceString attributedSubstringFromRange:NSMakeRange(start, count)].string;
                
                NSRange rangoSiguiente = NSMakeRange(start+count, length-start-count);
                NSString* siguienteTexto = [sourceString.string substringWithRange:rangoSiguiente];
                
                NSString* palabra = [[siguienteTexto componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] objectAtIndex:0];
                count += palabra.length;
                
                CFRelease(line);
                line = CTTypesetterCreateLine(ctTypeSetter, CFRangeMake(start, count));
                
                strLinea = [sourceString attributedSubstringFromRange:NSMakeRange(start, count)].string;
            }

            
            lineWidth = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
            
            if ((lineWidth / self.bounds.size.width) > 1.0) { //La línea se sale, córtala.
                NSString* lineString = [sourceString attributedSubstringFromRange:NSMakeRange(start, count)].string;
                NSUInteger breakAt = CFStringGetHyphenationLocationBeforeIndex((__bridge CFStringRef)lineString,
                                                                               lineString.length-1,
                                                                               CFRangeMake(0, lineString.length-1), 0, localeRef, 0);
                
                if(breakAt!=-1) { //Se ha encontrado corte
                    count = breakAt;
                    NSRange lineRange = NSMakeRange(start, count);
                    NSMutableAttributedString* lineAttrString = [sourceString attributedSubstringFromRange:lineRange].mutableCopy;
                    
                    [lineAttrString insertAttributedString:[[NSAttributedString alloc] initWithString:@"-"] atIndex:lineAttrString.length];
                    [resultString appendAttributedString:lineAttrString];
                    
                    line = CTTypesetterCreateLine(ctTypeSetter, CFRangeMake(start, count));
                    lineWidth = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
                } else { //No se ha encontrado corte
                    NSRange lineRange = NSMakeRange(start, count);
                    [resultString appendAttributedString:[sourceString attributedSubstringFromRange:lineRange]];
                }
            } else {
                NSRange lineRange = NSMakeRange(start, count);
                [resultString appendAttributedString:[sourceString attributedSubstringFromRange:lineRange]];
            }
        } else {
            NSRange lineRange = NSMakeRange(start, count);
            [resultString appendAttributedString:[sourceString attributedSubstringFromRange:lineRange]];
        }
        
        CFRelease(line);
        start += count;
    }
    
    CFRelease(localeRef);
    CFRelease(ctTypeSetter);
    
    return resultString.copy;
}

- (void) setAttString:(NSAttributedString *)attString {
    _attString = attString;
}


- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.hyphenatedString);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds);
    
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, [self.hyphenatedString length]), path, NULL);
    
    CTFrameDraw(frame, context);
    
    CFRelease(frame);
    CFRelease(path);
    CFRelease(framesetter);
}

- (void)layoutSubviews {
    if(self.hyphenate) {
        NSDictionary* attributes = [self.attString attributesAtIndex:0 effectiveRange:NULL];
        CTParagraphStyleRef paragraphStyle = (__bridge CTParagraphStyleRef)([attributes valueForKey:(id)kCTParagraphStyleAttributeName]);
        
        CTTextAlignment textAlignment;
        if (CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierAlignment, sizeof(textAlignment), &(textAlignment))) {
            if(textAlignment == kCTJustifiedTextAlignment) {
                self.hyphenatedString = [self hyphenateAttributeString:self.attString];
            }
        }
    }
    
    if(self.autoSize) {
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.attString);
        CGSize frameSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, self.attString.length), NULL, CGSizeMake(self.bounds.size.width, CGFLOAT_MAX), NULL);
        
        CGRect viewFrame = self.frame;
        viewFrame.size = frameSize;
        self.frame = viewFrame;
    }
    
    [self setNeedsDisplay];
}

@end
