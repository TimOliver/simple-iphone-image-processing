//
//  ResultViewController.h
//  ImageProcessing
//
//  Created by Chris Greening on 08/03/2009.
//

#import <UIKit/UIKit.h>

@interface ResultViewController : UIViewController {
	IBOutlet UIImageView *originalImage;
	IBOutlet UIImageView *resultImage;
}

@property(retain, nonatomic) UIImageView *resultImage;
@property(retain, nonatomic) UIImageView *originalImage;


-(void) setImage:(UIImage *) srcImage;

@end
