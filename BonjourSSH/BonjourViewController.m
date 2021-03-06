//
//  BonjourViewController.m
//  BonjourSSH
//
//  Created by Eugene on 3/26/14.
//  Copyright (c) 2014 www.eugenehp.tk. All rights reserved.
//

#import "BonjourViewController.h"
#include <arpa/inet.h>

#import "ServiceViewController.h"

@interface BonjourViewController ()
@property(nonatomic, retain) NSNetServiceBrowser *serviceBrowser;
@property(nonatomic, retain) NSNetService *serviceResolver;
@property(nonatomic, retain) NSMutableArray* services;
@property(nonatomic, retain) NSString* serviceName;
@end

@implementation BonjourViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"viewDidLoad");
    
    self.services = [[NSMutableArray alloc] init];
    self.serviceBrowser = [[NSNetServiceBrowser alloc] init];
    [self.serviceBrowser setDelegate:self];
    
    [self searchForBonjourServices];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
     ServiceViewController *serviceViewController = segue.destinationViewController;
     serviceViewController.serviceName = self.serviceName;
//     NSLog(@"prepareForSegue, %@",[self serviceName]);
 }

- (void)searchForBonjourServices
{
    NSString* allServices = @"_services._dns-sd._udp.";
    [self.serviceBrowser searchForServicesOfType:allServices inDomain:@"local."];
    NSLog(@"searchForBonjourServices");
}

#pragma mark UITableViewDataSourceDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int count = [self.services count];
    if (count == 0) {
        return 1;
    } else {
        return count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SimpleTableItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    int count = [self.services count];
    NSString* displayString;
    
    if (count == 0) {
        displayString = @"Searching...";
    } else {
        NSNetService *service = [self.services objectAtIndex:indexPath.row];
        displayString = [NSString stringWithFormat:@"%@.%@",[service name],[service type]];
    }
    
    cell.textLabel.text = displayString;
    return cell;
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNetService *service = [self.services objectAtIndex:indexPath.row];
    self.serviceName = [NSString stringWithFormat:@"%@.%@",[service name],[service type]];
    
        [self performSegueWithIdentifier:@"showService" sender:self];
//    if (self.serviceResolver) {
//        [self.serviceResolver stop];
//    }
//    
//    int count = [self.services count];
//    if (count != 0) {
//        self.serviceResolver = [self.services objectAtIndex:indexPath.row];
//        self.serviceResolver.delegate = self;
//        [self.serviceResolver resolveWithTimeout:0.0];
//    }
}

#pragma mark NSNetServiceDelegate
- (void)netServiceDidResolveAddress:(NSNetService *)service {
    [self.serviceResolver stop];
    NSLog(@"%ld", (long)service.port);
    
    for (NSData* data in [service addresses]) {
        char addressBuffer[100];
        struct sockaddr_in* socketAddress = (struct sockaddr_in*) [data bytes];
        int sockFamily = socketAddress->sin_family;
        if (sockFamily == AF_INET) {
            const char* addressStr = inet_ntop(sockFamily,
                                               &(socketAddress->sin_addr), addressBuffer,
                                               sizeof(addressBuffer));
            
            int port = ntohs(socketAddress->sin_port);
            if (addressStr && port) {
                NSLog(@"Found service at %s:%d", addressStr, port);
                NSString *urlString = [NSString stringWithFormat:@"http://%s:%d", addressStr, port];
                NSURL *url = [ [ NSURL alloc ] initWithString: urlString];
                [[UIApplication sharedApplication] openURL:url];
            }
        }
    }
    
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    NSLog(@"netService didNotResolve");
    [self.serviceResolver stop];
}

#pragma mark NSNetserviceBrowserDelegate
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    [self.services addObject:aNetService];
    
    if (!moreComing) {
        [self.tableView reloadData];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreServicesComing
{
    if (self.serviceResolver && [aNetService isEqual:self.serviceResolver]) {
        [self.serviceResolver stop];
    }
    
    [self.services removeObject:aNetService];
    if (!moreServicesComing) {
        [self.tableView reloadData];
    }
}

@end
