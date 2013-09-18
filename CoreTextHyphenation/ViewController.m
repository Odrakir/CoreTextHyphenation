//
//  ViewController.m
//  CoreTextHyphenation
//
//  Created by Ricardo on 18/09/13.
//  Copyright (c) 2013 Ricardo Sanchez Sotres. All rights reserved.
//

#import "ViewController.h"
#import "CTHMarkupParser.h"
#import "CTHView.h"

@interface ViewController ()
@property (strong, nonatomic) IBOutlet CTHView *textView;
@end

@implementation ViewController {
    CGPoint inicio;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString* markup = @"En un lugar de la Mancha, de cuyo nombre no quiero acordarme, no ha mucho tiempo que vivía un hidalgo de los de lanza en astillero, adarga antigua, rocín flaco y galgo <font color=\"red\">corredor</font>. Una olla de algo más vaca que carnero, salpicón las más noches, duelos y quebrantos los sábados, lantejas los viernes, algún palomino de añadidura los domingos, consumían las tres partes de su hacienda. El resto della concluían sayo de velarte, calzas de velludo para las fiestas, con sus pantuflos de lo mesmo, y los días de entresemana se honraba con su vellorí de lo más fino. Tenía en su casa una ama que pasaba de los cuarenta, y una sobrina que no llegaba a los veinte, y un mozo de campo y plaza, que así ensillaba el rocín como tomaba la podadera.\n\nEn un lugar de la Mancha, de cuyo nombre no quiero acordarme, no ha mucho tiempo que vivía un hidalgo de los de lanza en astillero, adarga antigua, rocín flaco y galgo <font color=\"red\">corredor</font>. Una olla de algo más vaca que carnero, salpicón las más noches, duelos y quebrantos los sábados, lantejas los viernes, algún palomino de añadidura los domingos, consumían las tres partes de su hacienda. El resto della concluían sayo de velarte, calzas de velludo para las fiestas, con sus pantuflos de lo mesmo, y los días de entresemana se honraba con su vellorí de lo más fino. Tenía en su casa una ama que pasaba de los cuarenta, y una sobrina que no llegaba a los veinte, y un mozo de campo y plaza, que así ensillaba el rocín como tomaba la podadera.";
    
    NSAttributedString* attString = [CTHMarkupParser attrStringFromMarkup:markup];
    
    //CTHView* vistaTexto = [[CTHView alloc] initWithFrame:CGRectMake(20, 20, self.view.bounds.size.width-40, self.view.bounds.size.height-40)];
    self.textView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.5];

    self.textView.hyphenate = YES;
    [self.textView setAttString:attString];
    [self.view addSubview:self.textView];


}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch* touch = [touches anyObject];
    inicio = [touch locationInView:self.view];
    
    self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y, inicio.x - self.textView.frame.origin.x, inicio.y - self.textView.frame.origin.y);

}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
