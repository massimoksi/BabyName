//
//  CreditsViewController.m
//  BabyName
//
//  Created by Massimo Peri on 09/11/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "CreditsViewController.h"


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
    self.ackTextView.text = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Acknowledgements"
                                                                                               ofType:@"markdown"]
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
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
