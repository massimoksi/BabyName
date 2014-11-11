//
//  CreditsViewController.m
//  BabyName
//
//  Created by Massimo Peri on 09/11/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "CreditsViewController.h"

#import "MMMarkDown.h"


static NSString * const kAcknowledgementsFileName = @"Acknowledgements";


@interface CreditsViewController ()

@property (nonatomic, weak) IBOutlet UITextView *ackTextView;

@end


@implementation CreditsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSError *error;
    
    NSString *acknowledgements = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:kAcknowledgementsFileName
                                                                                                    ofType:@"markdown"]
                                                           encoding:NSUTF8StringEncoding
                                                              error:&error];
    NSString *acknowledgementsHTML = [MMMarkdown HTMLStringWithMarkdown:acknowledgements
                                                                  error:&error];
    
    NSAttributedString *acknowledgementsText = [[NSAttributedString alloc] initWithData:[acknowledgementsHTML dataUsingEncoding:NSUTF8StringEncoding]
                                                                                options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType}
                                                                     documentAttributes:nil
                                                                                  error:&error];
    
    self.ackTextView.attributedText = acknowledgementsText;
    self.ackTextView.contentOffset = CGPointMake(0.0, -200.0);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
