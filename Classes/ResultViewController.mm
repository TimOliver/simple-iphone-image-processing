//
//  ResultViewController.m
//  WhiteBoardGrab
//
//  Created by Chris Greening on 08/03/2009.
//

#import "ResultViewController.h"
#import "Image.h"

@implementation ResultViewController

@synthesize originalImage;
@synthesize resultImage;

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

-(void) setImage:(UIImage *) srcImage {
	originalImage.image=srcImage;
	// convert to grey scale and shrink the image by 4 - this makes processing a lot faster!
	ImageWrapper *greyScale=Image::createImage(srcImage, srcImage.size.width/4, srcImage.size.height/4);
	// you can play around with the numbers to see how it effects the edge extraction
	// typical numbers are  tlow 0.20-0.50, thigh 0.60-0.90
	ImageWrapper *edges=greyScale.image->gaussianBlur().image->cannyEdgeExtract(0.3,0.7);
	// show the results
	resultImage.image=edges.image->toUIImage();
}


- (void)dealloc {
	[originalImage release];
	[resultImage release];
    [super dealloc];
}


@end
