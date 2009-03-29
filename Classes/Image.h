/*
 *  Image.h
 *  ImageProcessing
 *
 *  Created by Chris Greening on 02/01/2009.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#import <UIKit/UIImage.h>

#include <vector>

class Image;
// objective C wrapper for our C++ image class - makes memory management with autorelease pools a lot easier
@interface ImageWrapper : NSObject {
	// the C++ image
	Image *image;
	// do we own the image - ie should we delete it when we dealloc
	bool ownsImage;
}

@property(assign, nonatomic) Image *image;
@property(assign, nonatomic) bool ownsImage;
+ (ImageWrapper *) imageWithCPPImage:(Image *) theImage;

@end

// simple class for holding an image point
class ImagePoint {
public:
	short x,y;
	inline ImagePoint(short xpos, short ypos) {
		x=xpos;
		y=ypos;
	}
	inline ImagePoint(int xpos, int ypos) {
		x=xpos;
		y=ypos;
	}
	inline ImagePoint(const ImagePoint &other) {
		x=other.x;
		y=other.y;
	}
	inline ImagePoint() {
		x=0; y=0;
	}
};


// image class - handles grey scale images

class Image {
public:
	
	typedef enum {
		kRed=1,
		kGreen=2,
		kBlue=4} ColorMask;
	
private:

	// pointer to the image data
	uint8_t *m_imageData;
	// do we actually own the image
	bool m_ownsData;
	// width and height
	int m_width;
	int m_height;
	// constructors used internally by the static helper
	Image(ImageWrapper *other, int x1, int y1, int x2, int y2);
	Image(int width, int height);
	Image(uint8_t *imageData, int width, int height, bool ownsData=false);
	Image(UIImage *srcImage, int width, int height, bool imageIsRotatedBy90degrees=false,int colors);
public:

	
	
	// destructor
	~Image() {
		if(m_ownsData)
			free(m_imageData);
	}	
	// static helpers for creating images - these all return an Objective-C wrapper to the resulting image
	
	// copy a section of another image
	static ImageWrapper *createImage(ImageWrapper *other, int x1, int y1, int x2, int y2);
	// create an empty image of the required width and height
	static ImageWrapper *createImage(int width, int height);
	// create an image from data
	static ImageWrapper *createImage(uint8_t *imageData, int width, int height, bool ownsData=false);
	// take a source UIImage and convert it to grayscale
	static ImageWrapper *createImage(UIImage *srcImage, int width, int height, bool imageIsRotatedBy90degrees=false, int colors=kGreen);
	
	// edge detection
	ImageWrapper *cannyEdgeExtract(float tlow, float thigh);
	// local thresholding
	ImageWrapper* autoLocalThreshold(const int local_size=10);
	// threshold using integral
	ImageWrapper *autoIntegratingThreshold();
	// threshold an image automatically
	ImageWrapper *autoThreshold();
	// gaussian smooth the image
	ImageWrapper *gaussianBlur();
	// exrtact a connected area from the image
	void extractConnectedRegion(int x, int y, std::vector<ImagePoint> *points);
	// find the largest connected region in the image
	void findLargestStructure(std::vector<ImagePoint> *maxPoints);
	// normalise an image
	void normalise();
	// shrink to a new size
	ImageWrapper *resize(int newX, int newY);
	// histogram equalisation
	void HistogramEqualisation();
	// skeltonize
	void skeletonise();
	// invert pixels
	void invert();
	// binary erosion and dilation with a 3x3 square kernal
	ImageWrapper *erode();
	ImageWrapper *dilate();
	
	// convert back to a UIImage for display
	UIImage *toUIImage();
	// access the image data
	inline uint8_t* operator[](const int rowIndex) {
		return (m_imageData+rowIndex*m_width);
	}
	inline int getWidth() {
		return m_width;
	}
	inline int getHeight() {
		return m_height;
	}
	// helper functions for resizing
	static float Interpolate1(float a, float b, float c);
	static float Interpolate2(float a, float b, float c, float d, float x, float y);
	// test jig support
	inline uint8_t* atRow(const int rowIndex) {
		return (*this)[rowIndex];
	}
	inline int atXY(const int x, const int y) {
		return (*this)[y][x];
	}
};


