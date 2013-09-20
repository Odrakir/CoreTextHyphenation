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
#import "CTHViewHighlight.h"

@interface CTHView()
@property (nonatomic, strong) NSArray* lineas;
@property (nonatomic, strong) NSArray* textoLineas;
@end

@implementation CTHView {
    CGFloat lineSpacing;
    CTTextAlignment textAlignment;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        _hyphenate = NO;
        _autoSize = NO;
    }
    return self;
}

- (void) hyphenateAttributeString:(NSAttributedString *) sourceString {
    NSMutableArray * lineasMutable = [[NSMutableArray alloc] init];
    NSMutableArray * textoLineasMutable = [[NSMutableArray alloc] init];
    
    CTTypesetterRef ctTypeSetter = CTTypesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(sourceString));
    
    CFStringRef localeIdent = CFSTR("es_PE");
    CFLocaleRef localeRef = CFLocaleCreate(kCFAllocatorDefault, localeIdent);
    
    CFIndex start = 0;
    CTLineRef line;
    NSMutableAttributedString* lineAttrString;
    
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
                    
                    lineAttrString = [sourceString attributedSubstringFromRange:lineRange].mutableCopy;
                    
                    [lineAttrString replaceCharactersInRange:NSMakeRange(lineAttrString.length, 0) withString:@"-"];
                    
                    
                } else { //No se ha encontrado corte
                    NSRange lineRange = NSMakeRange(start, count);
                    lineAttrString = [sourceString attributedSubstringFromRange:lineRange].copy;
                }
            } else { //La línea entra bien
                NSRange lineRange = NSMakeRange(start, count);
                lineAttrString = [sourceString attributedSubstringFromRange:lineRange].copy;
            }
        }
        
        CFRelease(line);
        line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)(lineAttrString));
        
        
        CTLineRef justifiedLine = CTLineCreateJustifiedLine(line, 1.0, self.bounds.size.width);
        if(!justifiedLine)
            justifiedLine = CFRetain(line);
        CFRelease(line);
        
        [lineasMutable addObject:(__bridge id)(justifiedLine)];
        [textoLineasMutable addObject:lineAttrString];
        start += count;
    }
    
    self.lineas = lineasMutable.copy;
    self.textoLineas = textoLineasMutable.copy;
    
    CFRelease(localeRef);
    CFRelease(ctTypeSetter);
}

- (void) setAttString:(NSAttributedString *)attString {
    _attString = attString;

    if(!_attString)
        return;
    
    NSDictionary* attributes = [self.attString attributesAtIndex:0 effectiveRange:NULL];
    CTParagraphStyleRef paragraphStyle = (__bridge CTParagraphStyleRef)([attributes valueForKey:(id)kCTParagraphStyleAttributeName]);

    CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierLineSpacing, sizeof(lineSpacing), &(lineSpacing));
    CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierAlignment, sizeof(textAlignment), &(textAlignment));
    
    if(self.hyphenate) {
        if (textAlignment) {
            if(textAlignment == kCTJustifiedTextAlignment) {
                [self hyphenateAttributeString:self.attString];
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
    
    [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    
    CGFloat ypos_ant = 0;
    CGFloat descent_ant = 0;
    for (CFIndex i = 0; i < self.lineas.count; i++) {
        CTLineRef line = (__bridge CTLineRef)([self.lineas objectAtIndex:i]);
        
        CGFloat ascent = 0;
        CGFloat descent = 0;
        CGFloat leading = 0;
        
        CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        
        CGFloat posy;
        if(i==0)
            posy = ascent+leading;
        else
            posy = ypos_ant+descent_ant+ascent+lineSpacing+leading;
        
        CGContextSetTextPosition(context, 0.0, self.frame.size.height - posy);
        CTLineDraw(line, context);
        
        ypos_ant = posy;
        descent_ant = descent;
    }
    
}

/*
 - (void) layoutSubviews {
 if(!self.attString)
 return;
 }
 */

- (CTHViewHighlight *) selectWordAtPoint:(CGPoint)punto fromLine:(int) l {
    CTLineRef line = (__bridge CTLineRef)([self.lineas objectAtIndex:l]);
    
    NSString* palabra;
    
    CFIndex stringIndex = CTLineGetStringIndexForPosition(line, CGPointMake(punto.x, 0));
    
    CFRange lineRange = CTLineGetStringRange(line);
    
    NSString * lineStr = [[self.textoLineas objectAtIndex:l] attributedSubstringFromRange:NSMakeRange(lineRange.location, lineRange.length)].string;
    NSArray* palabras = [lineStr componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    int numchar = 0;
    int indice = (int)stringIndex;// - (int)lineRange.location;
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
    
    CTHViewHighlight* highlight = [[CTHViewHighlight alloc] init];
    highlight.palabra = palabra;
    highlight.inicio = CTLineGetOffsetForStringIndex(line, numchar + lineRange.location, NULL);
    highlight.final = CTLineGetOffsetForStringIndex(line, numchar+palabra.length  + lineRange.location, NULL);
    
    return highlight;
}

- (void) selectWordAtPoint:(CGPoint) punto withBlock:(void (^)(NSString * word, NSArray* frames)) returnBlock {
    CGRect lineFrame;
    
    CGFloat ypos_ant = 0;
    CGFloat descent_ant = 0;
    
    for (CFIndex i = 0; i < self.lineas.count; i++) {
        CTLineRef line = (__bridge CTLineRef)([self.lineas objectAtIndex:i]);
        
        CGFloat leading = 0;
        CGFloat ascent = 0;
        CGFloat descent = 0;
        
        CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        CGFloat posy;
        if(i==0)
            posy = ascent+leading;
        else
            posy = ypos_ant+descent_ant+ascent+lineSpacing+leading;
        
        lineFrame = CGRectMake(0, posy-ascent, self.bounds.size.width, ascent+descent);
        ypos_ant = posy;
        descent_ant = descent;
        
        NSString* palabra;
        if(CGRectContainsPoint(lineFrame, punto)) {
            CTHViewHighlight * highlight = [self selectWordAtPoint:CGPointMake(punto.x, 0) fromLine:i];
            palabra = highlight.palabra;
            
            unichar lastChar = [palabra characterAtIndex:palabra.length-1];
            if(lastChar == [@"-" characterAtIndex:0]) {
                palabra = [palabra substringToIndex:palabra.length-1];
                CGRect firstFrame = CGRectMake(highlight.inicio, posy-ascent, highlight.final-highlight.inicio, ascent+descent);
                
                CTLineRef line = (__bridge CTLineRef)([self.lineas objectAtIndex:i+1]);
                
                CGFloat leading = 0;
                CGFloat ascent = 0;
                CGFloat descent = 0;
                
                CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
                CGFloat posy;
                posy = ypos_ant+descent_ant+ascent+lineSpacing+leading;
                
                CTHViewHighlight * secondHighlight = [self selectWordAtPoint:CGPointMake(0, 0) fromLine:i+1];
                CGRect secondFrame = CGRectMake(secondHighlight.inicio, posy-ascent, secondHighlight.final-secondHighlight.inicio, ascent+descent);
                
                returnBlock([palabra stringByAppendingString:secondHighlight.palabra], [NSArray arrayWithObjects:[NSValue valueWithCGRect:firstFrame], [NSValue valueWithCGRect:secondFrame], nil]);

            } else {
                if(![[NSCharacterSet alphanumericCharacterSet] characterIsMember:lastChar]) {
                    palabra = [palabra substringToIndex:palabra.length-1];
                }
                
                CGRect wordFrame = CGRectMake(highlight.inicio, posy-ascent, highlight.final-highlight.inicio, ascent+descent);
                returnBlock(palabra, [NSArray arrayWithObject:[NSValue valueWithCGRect:wordFrame]]);
            }
            
            break;
        }
    }
}

- (void)dealloc
{
    NSLog(@"dealloc");
    for (CFIndex i = 0; i < self.lineas.count; i++) {
        CTLineRef line = (__bridge CTLineRef)([self.lineas objectAtIndex:i]);
        CFRelease(line);
    }
}

@end
