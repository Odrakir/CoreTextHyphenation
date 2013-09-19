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
@property (strong, nonatomic) CTHView *textView;
@property (nonatomic, strong) NSArray* glosario;
@property (nonatomic, strong) NSAttributedString* attString;
@end

@implementation ViewController

- (void)viewDidLoad  {
    [super viewDidLoad];

    NSString* markup = @"En un lugar de la Mancha, de cuyo nombre no quiero acordarme, no ha mucho tiempo que vivía un hidalgo de los de lanza en astillero, adarga antigua, rocín flaco y galgo corredor. Una olla de algo más vaca que carnero, salpicón las más noches, duelos y quebrantos los sábados, lantejas los viernes, algún palomino de añadidura los domingos, consumían las tres partes de su hacienda. El resto della concluían sayo de velarte, calzas de velludo para las fiestas, con sus pantuflos de lo mesmo, y los días de entresemana se honraba con su vellorí de lo más fino. Tenía en su casa una ama que pasaba de los cuarenta, y una sobrina que no llegaba a los veinte, y un mozo de campo y plaza, que así ensillaba el rocín como tomaba la podadera. Frisaba la edad de nuestro hidalgo con los cincuenta años; era de complexión recia, seco de carnes, enjuto de rostro, gran madrugador y amigo de la caza. Quieren decir que tenía el sobrenombre de Quijada, o Quesada, que en esto hay alguna diferencia en los autores que deste caso escriben; aunque, por conjeturas verosímiles, se deja entender que se llamaba Quejana. Pero esto importa poco a nuestro cuento; basta que en la narración dél no se salga un punto de la verdad.\n\nEs, pues, de saber que este sobredicho hidalgo, los ratos que estaba ocioso, que eran los más del año, se daba a leer libros de caballerías, con tanta afición y gusto, que olvidó casi de todo punto el ejercicio de la caza, y aun la administración de su hacienda. Y llegó a tanto su curiosidad y desatino en esto, que vendió muchas hanegas de tierra de sembradura para comprar libros de caballerías en que leer, y así, llevó a su casa todos cuantos pudo haber dellos; y de todos, ningunos le parecían tan bien como los que compuso el famoso Feliciano de Silva, porque la claridad de su prosa y aquellas entricadas razones suyas le parecían de perlas, y más cuando llegaba a leer aquellos requiebros y cartas de desafíos, donde en muchas partes hallaba escrito: La razón de la sinrazón que a mi razón se hace, de tal manera mi razón enflaquece, que con razón me quejo de la vuestra fermosura. Y también cuando leía: ...los altos cielos que de vuestra divinidad divinamente con las estrellas os fortifican, y os hacen merecedora del merecimiento que merece la vuestra grandeza.";
    
    self.glosario = [NSArray arrayWithObjects:@"libros", @"veinte", @"verosímies", @"velludo", @"podadera", @"ensillaba", @"rocín", @"escriben", @"aunque", nil];
    
    self.attString = [CTHMarkupParser attrStringFromMarkup:markup];
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch * touch = [touches anyObject];

    [self.textView selectWordAtPoint:[touch locationInView:self.textView] withBlock:^(NSString *word, CGRect bbox) {
        NSLog(@"palabra: %@", word);
        
        CGRect wordFrame = [self.view convertRect:bbox fromView:self.textView];
        UIView* vista = [[UIView alloc] initWithFrame:wordFrame];
        vista.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5];
        [self.view addSubview:vista];
    }];
    
}

- (void) tap:(UITapGestureRecognizer *) tap {
    [self.textView selectWordAtPoint:[tap locationInView:self.textView] withBlock:^(NSString *word, CGRect bbox) {
        NSLog(@"palabra: %@", word);
        
        CGRect wordFrame = [self.view convertRect:bbox fromView:self.textView];
        UIView* vista = [[UIView alloc] initWithFrame:wordFrame];
        vista.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5];
        [self.view addSubview:vista];
    }];
}

- (IBAction)botonDado:(id)sender {
    if(!self.textView) {
        self.textView = [[CTHView alloc] initWithFrame:CGRectMake(40, 30, 300, 600)];
        self.textView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.5];
        
        self.textView.hyphenate = YES;
        [self.textView setAttString:self.attString];
        [self.view addSubview:self.textView];
        
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        [self.view addGestureRecognizer:tap];
        
    } else {
        [self.textView removeGestureRecognizer:[self.textView.gestureRecognizers lastObject]];
        [self.textView removeFromSuperview];
        self.textView = nil;
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
