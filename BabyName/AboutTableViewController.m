//
//  AboutTableViewController.m
//  BabyName
//
//  Created by Massimo Peri on 09/11/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "AboutTableViewController.h"

#import <MessageUI/MessageUI.h>

#import "Constants.h"


@interface AboutTableViewController () <MFMailComposeViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UILabel *versionLabel;

@end


@implementation AboutTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.versionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Version %@ (%@)", @"About: version."), [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private methods

- (void)sendEmail
{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
        mailComposer.navigationBar.barTintColor = [UIColor bbn_barTintColor];
        mailComposer.navigationBar.tintColor = [UIColor bbn_tintColor];
        mailComposer.navigationBar.translucent = NO;
        mailComposer.mailComposeDelegate = self;
        [mailComposer setToRecipients:@[@"massimo.peri@icloud.com"]];
        
        [self presentViewController:mailComposer
                           animated:YES
                         completion:nil];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((indexPath.section == 0) && (indexPath.row == 0)) {
        [self sendEmail];
    }
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
}

#pragma mark - Mail composer view controller delegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

@end
