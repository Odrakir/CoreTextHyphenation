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
#import <QuartzCore/QuartzCore.h>

@interface CTHView()
@property (nonatomic, strong) NSAttributedString* stringToDraw;
@property (nonatomic, assign) CTFrameRef ctFrame;
@end

@implementation CTHView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        _hyphenate = NO;
        _autoSize = NO;
    }
    return self;
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
        
        if(newLine != lastChar) {
            
            double lineWidth = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
            
            if((lineWidth / self.bounds.size.width)<0.75 && start+count+1<length) { //La línea es muy corta, trae una palabra
                NSRange rangoSiguiente = NSMakeRange(start+count, length-start-count);
                NSString* siguienteTexto = [sourceString.string substringWithRange:rangoSiguiente];
                
                NSString* palabra = [[siguienteTexto componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] objectAtIndex:0];
                count += palabra.length;
                
                CFRelease(line);
                line = CTTypesetterCreateLine(ctTypeSetter, CFRangeMake(start, count));
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
                    
                    [lineAttrString replaceCharactersInRange:NSMakeRange(lineAttrString.length, 0) withString:@"-"];
                    
                    [resultString appendAttributedString:lineAttrString];
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
    
    if(self.hyphenate) {
        NSDictionary* attributes = [self.attString attributesAtIndex:0 effectiveRange:NULL];
        CTParagraphStyleRef paragraphStyle = (__bridge CTParagraphStyleRef)([attributes valueForKey:(id)kCTParagraphStyleAttributeName]);
        
        CTTextAlignment textAlignment;
        if (CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierAlignment, sizeof(textAlignment), &(textAlignment))) {
            if(textAlignment == kCTJustifiedTextAlignment) {
                self.stringToDraw = [self hyphenateAttributeString:self.attString];
            }
        }
    }
    
    if(self.autoSize) {
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.attString);
        CGSize frameSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, self.attString.length), NULL, CGSizeMake(self.bounds.size.width, CGFLOAT_MAX), NULL);
        
        CGRect viewFrame = self.frame;
        viewFrame.size = frameSize;
        self.frame = viewFrame;
        
        CFRelease(framesetter);
    }
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.stringToDraw);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds);
    
    self.ctFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, [self.stringToDraw length]), path, NULL);
    
    CGPathRelease(path);
    CFRelease(framesetter);
    
    [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CTFrameDraw(self.ctFrame, context);
    
    
}

/*
- (void) layoutSubviews {
    if(!self.attString)
        return;
}
 */

- (void) selectWordAtPoint:(CGPoint) punto withBlock:(void (^)(NSString * word, CGRect bbox)) returnBlock {
    
    CGRect wordFrame;
    
    CFArrayRef lines = CTFrameGetLines(self.ctFrame);
    size_t numOfLines = CFArrayGetCount(lines);
    CGPoint lineOrigins[numOfLines];
    CTFrameGetLineOrigins(self.ctFrame, CFRangeMake(0, 0), lineOrigins);
    
    CGRect lineFrame;
    NSString* palabra;
    
    for (CFIndex i = 0; i < numOfLines; i++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        
        CGFloat width = 0;
        CGFloat height = 0;
        CGFloat leading = 0;
        CGFloat ascent = 0;
        CGFloat descent = 0;
        CFRange strRange = CTLineGetStringRange(line);
        CGFloat offsetX = CTLineGetOffsetForStringIndex(line, strRange.location, NULL);
        
        width = (CGFloat)CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        width += leading;
        height = ascent + descent;
        lineFrame = CGRectMake(lineOrigins[i].x + offsetX, self.bounds.size.height - (lineOrigins[i].y - descent) - height, width, height);
        
        if(CGRectContainsPoint(lineFrame, punto)) {
            CFIndex stringIndex = CTLineGetStringIndexForPosition(line, CGPointMake(punto.x, 0));
            
            CFRange lineRange = CTLineGetStringRange(line);
            NSString * lineStr = [self.stringToDraw attributedSubstringFromRange:NSMakeRange(lineRange.location, lineRange.length)].string;
            NSArray* palabras = [lineStr componentsSeparatedByCharactersInSet:[[NSCharacterSet letterCharacterSet] invertedSet]];
            int numchar = 0;
            int indice = (int)stringIndex - (int)lineRange.location;
            int p = 0;
            
            BOOL encontrado = NO;
            while(!encontrado && numchar<lineStr.length) {
                palabra = [palabras objectAtIndex:p];
                if((numchar + palabra.length) > indice)
                    encontrado = YES;
                else {
                    numchar += palabra.length+1;
                    p += 1;
                }
            }
            
            CGFloat inicio = CTLineGetOffsetForStringIndex(line, numchar + lineRange.location, NULL);
            CGFloat final = CTLineGetOffsetForStringIndex(line, numchar+palabra.length  + lineRange.location, NULL);
            wordFrame = CGRectMake(inicio, self.bounds.size.height - (lineOrigins[i].y - descent) - height, final-inicio, height);
            
            break;
        }
    }
    
    returnBlock(palabra, wordFrame);
}

- (void)dealloc
{
    NSLog(@"dealloc");
    CFRelease(self.ctFrame);
}

@end
