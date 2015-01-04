//
//  FinishedViewController.m
//  BabyName
//
//  Created by Massimo Peri on 04/10/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "FinishedViewController.h"

#import "Constants.h"
#import "SuggestionsManager.h"


@interface FinishedViewController ()

@property (nonatomic, weak) IBOutlet UIButton *reviewAcceptedNamesButton;

@end


@implementation FinishedViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(updateSelection:)
                               name:kFetchingPreferencesChangedNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(updateSelection:)
                               name:kPreferredSuggestionChangedNotification
                             object:nil];
    
    // It's not possible to make the view transparent in Storyboard due to white labels.
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSUserDefaults standardUserDefaults] setBool:NO
                                            forKey:kStateReviewAcceptedNamesKey];
    
    if ([[SuggestionsManager sharedManager] acceptedSuggestions].count == 0) {
        self.reviewAcceptedNamesButton.hidden = YES;
    }
    else {
        self.reviewAcceptedNamesButton.hidden = NO;
    }
}

- (void)dealloc
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self
                                  name:kFetchingPreferencesChangedNotification
                                object:nil];
    [notificationCenter removeObserver:self
                                  name:kPreferredSuggestionChangedNotification
                                object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction)reviewAcceptedNames:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:YES
                                            forKey:kStateReviewAcceptedNamesKey];
    
    [self.containerViewController loadChildViewController];
}

- (IBAction)restartSelection:(id)sender
{
    if ([[SuggestionsManager sharedManager] shuffle]) {
        [self.containerViewController loadChildViewController];
    }
}

#pragma mark - Notification handlers

- (void)updateSelection:(NSNotification *)notification
{
    if ([notification.name isEqualToString:kFetchingPreferencesChangedNotification]) {
        [[SuggestionsManager sharedManager] update];
    }
    
    [self.containerViewController loadChildViewController];
}

#pragma mark - Embedded view controller

@synthesize containerViewController;

@end
