//
//  CreditsTableViewController.m
//  BabyName
//
//  Created by Massimo Peri on 13/11/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "CreditsTableViewController.h"

#import "Acknowledgement.h"
#import "LicenseViewController.h"


@interface CreditsTableViewController ()

@property (nonatomic, strong) NSMutableArray *acknowledgements;

@property (nonatomic, copy) NSString *headerText;
@property (nonatomic, copy) NSString *footerText;

@end


@implementation CreditsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSDictionary *root = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Acknowledgements"
                                                                                                    ofType:@"plist"]];
    NSMutableArray *acknowledgmentsArray = [NSMutableArray arrayWithArray:root[@"PreferenceSpecifiers"]];
    
    self.headerText = ((NSDictionary *)acknowledgmentsArray[0])[@"FooterText"];
    [acknowledgmentsArray removeObjectAtIndex:0];
    
    self.footerText = ((NSDictionary *)[acknowledgmentsArray lastObject])[@"FooterText"];
    [acknowledgmentsArray removeLastObject];

    self.acknowledgements = [[NSMutableArray alloc] init];
    for (NSDictionary *dict in acknowledgmentsArray) {
        Acknowledgement *acknowledgement = [[Acknowledgement alloc] init];
        acknowledgement.name = dict[@"Title"];
        acknowledgement.license = dict[@"FooterText"];
        
        [self.acknowledgements addObject:acknowledgement];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

 #pragma mark - Navigation
 
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"ShowLicenseSegue"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)sender];
        
        LicenseViewController *viewController = [segue destinationViewController];
        
        Acknowledgement *selectedAcknowledgement = self.acknowledgements[indexPath.row];
        viewController.title = selectedAcknowledgement.name;
        viewController.license = selectedAcknowledgement.license;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.acknowledgements.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CreditsCell"
                                                            forIndexPath:indexPath];
    
    cell.textLabel.text = ((Acknowledgement *)self.acknowledgements[indexPath.row]).name;
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

@end
