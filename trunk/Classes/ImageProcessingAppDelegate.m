//
//  ImageProcessingAppDelegate.m
//  ImageProcessing
//
//  Created by Chris Greening on 14/03/2009.
//

#import "ImageProcessingAppDelegate.h"
#import "RootViewController.h"


@implementation ImageProcessingAppDelegate

@synthesize window;
@synthesize navigationController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {
	
	// Configure and show the window
	[window addSubview:[navigationController view]];
	[window makeKeyAndVisible];
}


- (void)applicationWillTerminate:(UIApplication *)application {
	// Save data if appropriate
}


- (void)dealloc {
	[navigationController release];
	[window release];
	[super dealloc];
}

@end
