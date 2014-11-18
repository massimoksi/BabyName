//
//  AboutTableViewController.m
//  BabyName
//
//  Created by Massimo Peri on 09/11/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "AboutTableViewController.h"

#import <MessageUI/MessageUI.h>


static NSString * const kMailAddress = @"massimo.peri@icloud.com";
static NSString * const kAppStoreURL = @"itms-apps://itunes.apple.com/app/id";
#if DEBUG
static NSString * const kAppID = @"438027793"; // Smokeless App ID for testing before the app is released on the App Store.
#else
static NSString * const kAppID = @"939636819";
#endif


@interface AboutTableViewController () <MFMailComposeViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UILabel *versionLabel;

@end


@implementation AboutTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
//        mailComposer.navigationBar.barTintColor = [UIColor bbn_barTintColor];
//        mailComposer.navigationBar.tintColor = [UIColor bbn_tintColor];
//        mailComposer.navigationBar.translucent = NO;
        mailComposer.mailComposeDelegate = self;
        [mailComposer setToRecipients:@[kMailAddress]];
        
        [self presentViewController:mailComposer
                           animated:YES
                         completion:nil];
//                         completion:^{
//                            // Make the status bar white.
//                            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
//                         }];
    }
}

- (void)rateApp
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kAppStoreURL, kAppID]]];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;

    if (section == 1) {
        if (row == 0) {
            [self sendEmail];
        }
        else if (row == 1) {
            [self rateApp];
        }
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
