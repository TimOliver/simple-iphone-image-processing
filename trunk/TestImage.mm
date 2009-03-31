//
//  TestImage.mm
//
//  Created by Alan Wostenberg on 3/26/09.
//  Copyright 2009 Wosterware.com. All rights reserved.
//
// To add OCUnit on which this depends to an Xcode project, 
// see http://www.sente.ch/s/?p=535&lang=en and http://developer.apple.com/tools/unittest.html
// To set debugger break points in unit tests,
// see http://developer.apple.com/mac/articles/tools/unittestingwithxcode3.html

#import "TestImage.h"
// the image.h is a mix of Objective C and C++
#import "Image.h"
#import "Region.h"

@implementation TestImage

// constructors

- (void)testEmptyImageDimensions {
	ImageWrapper* im = Image::createImage(10,20);

	STAssertEquals(10, im.image->getWidth(), @"");
	STAssertEquals(20, im.image->getHeight(), @"");
}


- (void)testFromBytes {
	uint8_t imData[6] = {1,2,
						3,4, 
						5,6};
	ImageWrapper* im = Image::createImage(imData,2,3);
	
	STAssertEquals(2, im.image->getWidth(), @"");
	STAssertEquals(3, im.image->getHeight(), @"");
	STAssertTrue(im.image->atRow(0) == imData, @"");	
	//STAssertEquals(im.image->rowAt(0), imData, @"");
	STAssertEquals(im.image->atXY(0,0), 1, @"");
	STAssertEquals(im.image->atXY(1,0), 2, @"");
	STAssertEquals(im.image->atXY(0,1), 3, @"");
}


// greyscale conversion from a tiny image

- (void)testFromUIImage {
	// The image is of uniform color who's value is encoded in the filename.
	// The name r50g100b200 means red channel is 50, green is 100, blue is 200.
	UIImage* uim = [UIImage imageWithContentsOfFile: @"r50g100b200.png"];
	
	ImageWrapper* im = Image::createImage(uim,uim.size.width,uim.size.height);
	STAssertEquals(im.image->getWidth(),30,@"");
	STAssertEquals(im.image->getHeight(),40,@"");
	
	//default uses green channel, which in the sample image, is 100
	STAssertEquals(im.image->atXY(1,1), 100, @""); 

	//all channels averaged to grey
	im = Image::createImage(uim,uim.size.width,uim.size.height,false,Image::kRed|Image::kGreen|Image::kBlue);
	STAssertEquals(im.image->atXY(1,1),  (50 + 100 + 200) / 3, @""); 

	//red-green averaged to grey
	im = Image::createImage(uim,uim.size.width,uim.size.height,false,Image::kRed|Image::kGreen);
	STAssertEquals(im.image->atXY(1,1), (50+100)/2, @""); 
}


// inverting
- (void)testInvert {
	uint8_t imData[2] = {0, 255};
	ImageWrapper* im = Image::createImage(imData,2,1);
	im.image->invert();
	STAssertEquals(im.image->atXY(0,0), 255, @"");
	STAssertEquals(im.image->atXY(1,0), 0, @"");
}

// binary erosion
// Sample data uses ranges of numbers for test readability. Real world values are 0 or 255.
- (void)testErodeKeepsCentralPixel {
	uint8_t imData[9] = { 1,2,3, 4,5,6, 7,8,9};
	ImageWrapper* a = Image::createImage(imData,3,3);
	
	ImageWrapper* b = a.image->erode();
	STAssertEquals(b.image->atXY(0,0), 1, @"");
	STAssertEquals(b.image->atXY(1,1), 5, @"");
	STAssertEquals(b.image->atXY(2,2), 9, @"");
}

- (void)testErodeZerosCentralPixel {
	uint8_t imData[9] = {0,2,3, 4,5,6, 7,8,9};
	ImageWrapper* a = Image::createImage(imData,3,3);
	ImageWrapper* b = a.image->erode();
	STAssertEquals(b.image->atXY(0,0), 0, @"");
	STAssertEquals(b.image->atXY(1,1), 0, @"");
	STAssertEquals(b.image->atXY(2,2), 9, @"");
	
	STAssertEquals(a.image->atXY(1,1), 5, @"");
}

// binary dilation
- (void)testDilate {
	uint8_t imData[9] = {1,0,0, 0,0,0, 0,0,0};
	ImageWrapper* a = Image::createImage(imData,3,3);
	
	ImageWrapper* b = a.image->dilate();
	STAssertEquals(b.image->atXY(0,0), 1, @"");
	STAssertEquals(b.image->atXY(1,1), 255, @"");
	STAssertEquals(b.image->atXY(2,2), 0, @"");
}


// find connected regions

- (void)testImageNoRegions {
	uint8_t imData[9] = { 0,0,0, 0,0,0, 0,0,0};
	ImageWrapper* im = Image::createImage(imData,3,3);
	NSMutableArray* regions = [im regions];
	int n = [regions count];

	STAssertEquals(n,0,@"");	
}

- (void)testImageHavingOneRegion {
	uint8_t imData[9] = { 1,1,1, 1,0,0, 0,0,0};
	ImageWrapper* im = Image::createImage(imData,3,3);
	int n = [[im regions] count];
	STAssertEquals(n,1,@"");
	
}

- (void)testImageHavingTwoRegions {
	uint8_t imData[9] = { 
		1,0,1, 
		1,0,1, 
		1,0,1};
	ImageWrapper* im = Image::createImage(imData,3,3);
	int n = [[im regions] count];
	STAssertEquals(n,2,@"");
}

- (void)testImageHavingOneURegion {
	uint8_t imData[9] = { 
		1,0,1, 
		1,0,1, 
		1,1,1};
	ImageWrapper* im = Image::createImage(imData,3,3);
	int n = [[im regions] count];
	STAssertEquals(n,1,@"");
}

- (void)testImageHavingDiagonalRegion {
	uint8_t imData[9] = { 
		1,0,0, 
		0,1,0, 
		0,0,1};
	ImageWrapper* im = Image::createImage(imData,3,3);
	int n = [[im regions] count];
	STAssertEquals(n,1,@"");
	NSRect boundingBox = [[[im regions] lastObject] bb];
	int x = boundingBox.origin.x;
	STAssertEquals(x,0,@"");
}
@end
