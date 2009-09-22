//
//  ImageProcessingAppDelegate.h
//  ImageProcessing
//
//  Created by Chris Greening on 14/03/2009.
//

#import <UIKit/UIKit.h>

@interface ImageProcessingAppDelegate : NSObject <UIApplicationDelegate> {
    
    UIWindow *window;
    UINavigationController *navigationController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

@end

