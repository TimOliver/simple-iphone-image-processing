/*
 *  Image.cpp
 *  ImageProcessing
 *
 *  Created by Chris Greening on 04/01/2009.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */
#import "Image.h"
#import "Region.h"
#include <stack>

@implementation ImageWrapper

@synthesize image;
@synthesize ownsImage;

// creates an Objective-C wrapper around a C++ image
+ (ImageWrapper *) imageWithCPPImage:(Image *) theImage;
{
	ImageWrapper *wrapper = [[ImageWrapper alloc] init];
	wrapper.image=theImage;
	wrapper.ownsImage=true;
	return [wrapper autorelease];
}

// override to specify if the wrapper should take ownership of the C++ image
+ (ImageWrapper *) imageWithCPPImage:(Image *) theImage ownsImage:(bool) ownsTheImage;
{
	ImageWrapper *wrapper = [[ImageWrapper alloc] init];
	wrapper.image=theImage;
	wrapper.ownsImage=ownsTheImage;
	return [wrapper autorelease];
}

// extract all connected regions from the image
// this probably belongs on Image not the wrapper
- (NSMutableArray*) regions
{
	NSMutableArray* answer = [NSMutableArray arrayWithCapacity: 10];
	// process the image building Regions from point vector
	// note that the process is destructive in that it marks all pixels foreground in the image
	std::vector<ImagePoint> points;
	int w = image->getWidth();
	int h = image->getHeight();
	for(int y=0; y<h; y++) {
		for(int x=0; x<w; x++) {
			// if we've found a point in the image then extract everything connected to it
			if(image->atXY(x,y)!=0) {
				image->extractConnectedRegion(x, y, &points);
				// construct a Region from these points
				std::vector<ImagePoint>::const_iterator pi;
				Region* region = [Region new];
				for(pi=points.begin(); pi!=points.end(); pi++)
				{
					[region addPoint: NSMakePoint(pi->x,pi->y)];
					//NSLog(@"added point %d p.x=%d p.y=%d",[ [region points] count],pi->x,pi->y);
				}
				[answer addObject: region];
				//NSLog(@"region %d points at x=%f y=%f width=%f height=%f area=%d", [[region points] count], [region bb].origin.x, [region bb].origin.y, [region bb].size.width, [region bb].size.height, [region area]); 
				points.clear();
			}
		}
	}
	return answer;
}


// cleanup
- (void) dealloc
{
	// delete the image that we have been holding onto
	if(ownsImage) delete image;
	[super dealloc];
}

@end

// these constructors are all private. Use the helper function defined below to create images

// extract a region of an image to a new image
Image::Image(ImageWrapper *other, int x1, int y1, int x2, int y2) {
	m_width=x2-x1;
	m_height=y2-y1;
	m_imageData=(uint8_t *) malloc(m_width*m_height);
	Image *otherImage=other.image;
	for(int y=y1; y<y2; y++) {
		for(int x=x1; x<x2; x++) {
			(*this)[y-y1][x-x1]=(*otherImage)[y][x];
		}
	}
	m_ownsData=true;
}

// create an empty image - note, memory is not intialised to zero
Image::Image(int width, int height) {
	m_imageData=(uint8_t *) malloc(width*height);
	m_width=width;
	m_height=height;
	m_ownsData=true;
}

// create an image from data
Image::Image(uint8_t *imageData, int width, int height, bool ownsData) {
	m_imageData=imageData;
	m_width=width;
	m_height=height;
	m_ownsData=ownsData;
}

// convert from a UIImage to a grey scale image by averaging red green blue
Image::Image(UIImage *srcImage, int width, int height, bool imageIsRotatedBy90degrees, int colors=kGreen) {
	NSDate *start=[NSDate date];
	if(imageIsRotatedBy90degrees) {
		int tmp=width;
		width=height;
		height=tmp;
	}
	m_width=width;
	m_height=height;
	// get hold of the image bytes
	uint32_t *rgbImage=(uint32_t *) malloc(m_width*m_height*sizeof(uint32_t));
	CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
	CGContextRef context=CGBitmapContextCreate(rgbImage,  m_width, m_height, 8, m_width*4, colorSpace, kCGBitmapByteOrder32Little|kCGImageAlphaNoneSkipLast);
	CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
	CGContextSetShouldAntialias(context, NO);
	CGContextDrawImage(context, CGRectMake(0,0, m_width, m_height), [srcImage CGImage]);
	CGContextRelease(context);
	CGColorSpaceRelease(colorSpace);
	
	start=[NSDate date];
	// now convert to grayscale
	m_imageData=(uint8_t *) malloc(m_width*m_height);
	m_ownsData=true;
	for(int y=0; y<m_height; y++) {
		for(int x=0; x<m_width; x++) {
			uint32_t rgbPixel=rgbImage[y*m_width+x];
			uint32_t sum=0,count=0;
			if (colors & kRed) {sum += (rgbPixel>>24)&255; count++;}
			if (colors & kGreen) {sum += (rgbPixel>>16)&255; count++;}
			if (colors & kBlue) {sum += (rgbPixel>>8)&255; count++;}
			m_imageData[y*m_width+x]=sum/count;
		}
	}
	free(rgbImage);
	if(imageIsRotatedBy90degrees) {
		uint8_t *tmpImage=(uint8_t *) malloc(m_width*m_height);
		for(int y=0; y<m_height; y++) {
			for(int x=0; x<m_width; x++) {
				tmpImage[x*m_height+y]=m_imageData[(m_height-y-1)*m_width+x];
			}
		}
		int tmp=m_width;
		m_width=m_height;
		m_height=tmp;
		free(m_imageData);
		m_imageData=tmpImage;
	}
}

// helper functions - use these to create images. They will give you an autoreleased Objective-C wrapper for easier memory handling

// copy a section of another image
ImageWrapper *Image::createImage(ImageWrapper *other, int x1, int y1, int x2, int y2)
{
	return [ImageWrapper imageWithCPPImage:new Image(other, x1, y1, x2, y2)];
}
// create an empty image of the required width and height
ImageWrapper *Image::createImage(int width, int height) {
	return [ImageWrapper imageWithCPPImage:new Image(width, height)];
}
// create an image from data
ImageWrapper *Image::createImage(uint8_t *imageData, int width, int height, bool ownsData) {
	return [ImageWrapper imageWithCPPImage:new Image(imageData, width, height, ownsData)];
}
// take a source UIImage and convert it to grayscale
ImageWrapper *Image::createImage(UIImage *srcImage, int width, int height, bool imageIsRotatedBy90degrees, int colors) {
	return [ImageWrapper imageWithCPPImage:new Image(srcImage, width, height, imageIsRotatedBy90degrees, colors)];
}

// stretch the image brightness so that it takes the range 0-255
// http://en.wikipedia.org/wiki/Normalization_(image_processing)
void Image::normalise() {
	int min=INT_MAX;
	int max=0;
	
	for(int i=0; i<m_width*m_height; i++) {
		if(m_imageData[i]>max) max=m_imageData[i];
		if(m_imageData[i]<min) min=m_imageData[i];
	}
	for(int i=0; i<m_width*m_height; i++) {
		m_imageData[i]=255*(m_imageData[i]-min)/(max-min);
	}
}

// invert the image polarity; object pixels become background and background, object
void Image::invert() {
	for(int i=0; i<m_width*m_height; i++) {
		m_imageData[i]=255-m_imageData[i];
	}
}


// binary erosion using a 3x3 square kernal
// http://en.wikipedia.org/wiki/Erosion_(morphology)
ImageWrapper* Image::erode() {
	Image *result=new Image(m_width, m_height);
	const int SESZ = 8;
	ImagePoint structuringElement[SESZ] = {
		ImagePoint(-1,-1), ImagePoint(0,-1), ImagePoint(1,-1),
		ImagePoint(-1, 0),                   ImagePoint(1, 0),
		ImagePoint(-1, 1), ImagePoint(0, 1), ImagePoint(1, 1)
	};
	// run erosion kernal over interior pixels using the square structuring element
	for(int y=0; y<m_height; y++) {
		for(int x=0; x<m_width; x++) {
			(*result)[y][x] = (*this)[y][x]; 
			if (y > 0 && y < m_height-1 && x > 0 && x < m_width-1) {
				//NSLog(@"CP x=%d,y=%d,pix=%d",x,y,(*this)[y][x]);
				for (int i=0; i<SESZ; i++) {
					int dx = structuringElement[i].x;
					int dy = structuringElement[i].y;
					int neighbor = (*this)[y+dy][x+dx];
					//NSLog(@"dx=%d, dy=%d, x=%d, y=%d, pix=%d",dx,dy,y+dy,x+dx,neighbor);
					if ( neighbor == 0) {
						(*result)[y][x] = 0;
					}
				}
			}
		}
	}
	
	return [ImageWrapper imageWithCPPImage:result];
}


// binary dilation using a 3x3 square kernal
// dilation is the dual of erosion -- the erosion of not background
// this is a naive implementation copy-pasted from above. Think about how to refactor to remove duplicated lines.
// The inner-most loop is the kernal that could be extracted as pointer to function.
// http://en.wikipedia.org/wiki/Erosion_(morphology)
ImageWrapper* Image::dilate() {
	Image *result=new Image(m_width, m_height);
	const int SESZ = 8;
	ImagePoint structuringElement[SESZ] = {
		ImagePoint(-1,-1), ImagePoint(0,-1), ImagePoint(1,-1),
		ImagePoint(-1, 0),                   ImagePoint(1, 0),
		ImagePoint(-1, 1), ImagePoint(0, 1), ImagePoint(1, 1)
	};
	// run kernal over interior pixels using the square structuring element
	for(int y=0; y<m_height; y++) {
		for(int x=0; x<m_width; x++) {
			(*result)[y][x] = (*this)[y][x]; 
			if (y > 0 && y < m_height-1 && x > 0 && x < m_width-1) {
				for (int i=0; i<SESZ; i++) {
					int dx = structuringElement[i].x;
					int dy = structuringElement[i].y;
					int neighbor = (*this)[y+dy][x+dx];
					if ( neighbor > 0) {		//kernel
						(*result)[y][x] = 255;	//kernel
					}
				}
			}
		}
	}
	
	return [ImageWrapper imageWithCPPImage:result];
}

// recursively extract connected region - this has been replace by the non recursive version
/*void Image::extractConnectedRegion(int x, int y, std::vector<short> *xpoints, std::vector<short> *ypoints) {
	// remove the current point from the image
	(*this)[y][x]=0;
	(*xpoints).push_back(x);
	(*ypoints).push_back(y);
	for(int ypos=y-1; ypos<=y+1; ypos++) {
		for(int xpos=x-1; xpos<=x+1; xpos++) {
			if(xpos>0 && ypos>0 && xpos<getWidth() && ypos<getHeight() && (*this)[ypos][xpos]!=0) {
				extractConnectedRegion(xpos, ypos, xpoints, ypoints);
			}
		}
	}
}
*/

// extract a connected region from an image - this uses a non-recursive algorithm to prevent us running out of stack
// space when extracting very large regions
void Image::extractConnectedRegion(int x, int y, std::vector<ImagePoint> *points) {
	
	// remove the current point from the image
	(*this)[y][x]=0;
	(*points).push_back(ImagePoint(x,y));
	
	std::stack<ImagePoint> myStack;
	std::stack<short> stackXpos;
	std::stack<short> stackYpos;
	myStack.push(ImagePoint(x,y));
	while(myStack.size()>0) {
		// get the entry at the top of the stack
		x=myStack.top().x;
		y=myStack.top().y;
		myStack.pop();
		// check the surrounding region for other points
		for(int ypos=y-1; ypos<=y+1; ypos++) {
			for(int xpos=x-1; xpos<=x+1; xpos++) {
				if(xpos>=0 && ypos>=0 && xpos<getWidth() && ypos<getHeight() && (*this)[ypos][xpos]!=0) {
					// found a point - add it to the list of points and change the x and y to reflect this new point
					(*points).push_back(ImagePoint(xpos,ypos));
					(*this)[ypos][xpos]=0;
					// push the current x and y onto the stack
					myStack.push(ImagePoint(x,y));
					// x and y are the new x and y
					x=xpos;
					y=ypos;
					// reset the loop counter
					ypos=y-1;
					xpos=x-1;
				}
			}
		}
	}
}

// find the largest structure in a thresholded image
void Image::findLargestStructure(std::vector<ImagePoint> *maxPoints) {
	// process the image
	std::vector<ImagePoint> points;
	for(int y=0; y<m_height; y++) {
		for(int x=0; x<m_width; x++) {
			// if we've found a point in the image then extract everything connected to it
			if((*this)[y][x]!=0) {
				extractConnectedRegion(x, y, &points);
				if(points.size()>maxPoints->size()) {
					maxPoints->clear();
					maxPoints->resize(points.size());
					std::copy(points.begin(), points.end(), maxPoints->begin());
				} 
				points.clear();
			}
		}
	}
}


// helper for autoLocalThreshold computes average intensity of pixels in the region
int findThresholdAtPosition(int startx, int starty, int size, Image* src) {
	int total=0;
	for(int y=starty; y<starty+size; y++) {
		for(int x=startx; x<startx+size; x++) {
			total+=(*src)[y][x];
		}
	}
	int threshold=total/(size*size);
	return threshold;
};

// threshold an image using a threshold that is computed at every pixel point
// http://en.wikipedia.org/wiki/Thresholding_(image_processing)
// This is designed for text segmentation. Dark pixels are set to 255, light pixels to 0
ImageWrapper* Image::autoLocalThreshold(const int local_size) {
	// now produce the thresholded image
	Image *result=new Image(m_width, m_height);
	// process the image
	int threshold=0;
	for(int y=local_size/2; y<m_height-local_size/2; y++) {
		for(int x=local_size/2; x<m_width-local_size/2; x++) {
			threshold=findThresholdAtPosition(x-local_size/2, y-local_size/2, local_size, this);
			int val=(*this)[y][x];
			// to remove noise we only accept pixels that are less than 90% of the threshold
			if(val>threshold*0.9)
					(*result)[y][x]=0;
				else
					(*result)[y][x]=255;
		}
	}
	return [ImageWrapper imageWithCPPImage:result];
}

// Threshold using the average value of the entire image intensity
ImageWrapper *Image::autoThreshold() {
	int total=0;
	int count=0;
	for(int y=0; y<m_height; y++) {
		for(int x=0; x<m_width; x++) {
			total+=(*this)[y][x];
			count++;
		}
	}
	int threshold=total/count;
	Image *result=new Image(m_width, m_height);
	for(int y=0; y<m_height; y++) {
		for(int x=0; x<m_width; x++) {
			if((*this)[y][x]>threshold*0.9) {
				(*result)[y][x]=0;
			} else {
				(*result)[y][x]=255;
			}
		}
	}
	return [ImageWrapper imageWithCPPImage:result];
}


// skeletonise an image
void Image::skeletonise() {
	bool changes=true;
	while(changes) {
		changes=false;
		for(int y=1; y<m_height-1; y++) {
			for(int x=1; x<m_width-1; x++) {
				if((*this)[y][x]!=0) {
					bool val[8];
					val[0]=(*this)[y-1][x-1]!=0;
					val[1]=(*this)[y-1][x]!=0;
					val[2]=(*this)[y-1][x+1]!=0;
					val[3]=(*this)[y][x+1]!=0;
					val[4]=(*this)[y+1][x+1]!=0;
					val[5]=(*this)[y+1][x]!=0;
					val[6]=(*this)[y+1][x-1]!=0;
					val[7]=(*this)[y][x-1]!=0;
					
					bool remove=false;
					for(int i=0; i<7 && !remove;i++) {
						remove=(val[(0+i)%8] && val[(1+i)%8] && val[(7+i)%8] && val[(6+i)%8] && val[(5+i)%8] && !(val[(2+i)%8] || val[(3+i)%8] || val[(4+i)%8]))
						|| (val[(0+i)%8] && val[(1+i)%8] && val[(7+i)%8] && !(val[(3+i)%8] || val[(6+i)%8] || val[(5+i)%8] || val[(4+i)%8])) ||
						!(val[(0+i)%8] || val[(1+i)%8] || val[(2+i)%8]  || val[(3+i)%8]  || val[(4+i)%8]  || val[(5+i)%8]  || val[(6+i)%8] || val[(7+i)%8]);
					}
					if(remove) {
						(*this)[y][x]=0;
						changes=true;
					}
				}
			}
		}
	}
}

// Canny edge detection - this code is a bit of a mess

#define NOEDGE 255
#define POSSIBLE_EDGE 128
#define EDGE 0

void non_max_supp(int *mag, int *gradx, int *grady, int nrows, int ncols,
			 uint8_t *result) 
{
    int rowcount, colcount,count;
    int *magrowptr,*magptr;
    int *gxrowptr,*gxptr;
    int *gyrowptr,*gyptr,z1,z2;
    int m00,gx,gy;
    float mag1,mag2,xperp,yperp;
    uint8_t *resultrowptr, *resultptr;
    
	
	/****************************************************************************
	 * Zero the edges of the result image.
	 ****************************************************************************/
    for(count=0,resultrowptr=result,resultptr=result+ncols*(nrows-1); 
        count<ncols; resultptr++,resultrowptr++,count++){
        *resultrowptr = *resultptr = (unsigned char) 0;
    }
	
    for(count=0,resultptr=result,resultrowptr=result+ncols-1;
        count<nrows; count++,resultptr+=ncols,resultrowptr+=ncols){
        *resultptr = *resultrowptr = (unsigned char) 0;
    }
	
	/****************************************************************************
	 * Suppress non-maximum points.
	 ****************************************************************************/
	for(rowcount=1,magrowptr=mag+ncols+1,gxrowptr=gradx+ncols+1,
		gyrowptr=grady+ncols+1,resultrowptr=result+ncols+1;
		rowcount<nrows-2; 
		rowcount++,magrowptr+=ncols,gyrowptr+=ncols,gxrowptr+=ncols,
		resultrowptr+=ncols){   
		for(colcount=1,magptr=magrowptr,gxptr=gxrowptr,gyptr=gyrowptr,
			resultptr=resultrowptr;colcount<ncols-2; 
			colcount++,magptr++,gxptr++,gyptr++,resultptr++){   
			m00 = *magptr;
			if(m00 == 0){
				*resultptr = (unsigned char) NOEDGE;
			}
			else{
				xperp = -(gx = *gxptr)/((float)m00);
				yperp = (gy = *gyptr)/((float)m00);
			}
			
			if(gx >= 0){
				if(gy >= 0){
                    if (gx >= gy)
                    {  
                        /* 111 */
                        /* Left point */
                        z1 = *(magptr - 1);
                        z2 = *(magptr - ncols - 1);
						
                        mag1 = (m00 - z1)*xperp + (z2 - z1)*yperp;
                        
                        /* Right point */
                        z1 = *(magptr + 1);
                        z2 = *(magptr + ncols + 1);
						
                        mag2 = (m00 - z1)*xperp + (z2 - z1)*yperp;
                    }
                    else
                    {    
                        /* 110 */
                        /* Left point */
                        z1 = *(magptr - ncols);
                        z2 = *(magptr - ncols - 1);
						
                        mag1 = (z1 - z2)*xperp + (z1 - m00)*yperp;
						
                        /* Right point */
                        z1 = *(magptr + ncols);
                        z2 = *(magptr + ncols + 1);
						
                        mag2 = (z1 - z2)*xperp + (z1 - m00)*yperp; 
                    }
                }
                else
                {
                    if (gx >= -gy)
                    {
                        /* 101 */
                        /* Left point */
                        z1 = *(magptr - 1);
                        z2 = *(magptr + ncols - 1);
						
                        mag1 = (m00 - z1)*xperp + (z1 - z2)*yperp;
						
                        /* Right point */
                        z1 = *(magptr + 1);
                        z2 = *(magptr - ncols + 1);
						
                        mag2 = (m00 - z1)*xperp + (z1 - z2)*yperp;
                    }
                    else
                    {    
                        /* 100 */
                        /* Left point */
                        z1 = *(magptr + ncols);
                        z2 = *(magptr + ncols - 1);
						
                        mag1 = (z1 - z2)*xperp + (m00 - z1)*yperp;
						
                        /* Right point */
                        z1 = *(magptr - ncols);
                        z2 = *(magptr - ncols + 1);
						
                        mag2 = (z1 - z2)*xperp  + (m00 - z1)*yperp; 
                    }
                }
            }
            else
            {
                if ((gy = *gyptr) >= 0)
                {
                    if (-gx >= gy)
                    {          
                        /* 011 */
                        /* Left point */
                        z1 = *(magptr + 1);
                        z2 = *(magptr - ncols + 1);
						
                        mag1 = (z1 - m00)*xperp + (z2 - z1)*yperp;
						
                        /* Right point */
                        z1 = *(magptr - 1);
                        z2 = *(magptr + ncols - 1);
						
                        mag2 = (z1 - m00)*xperp + (z2 - z1)*yperp;
                    }
                    else
                    {
                        /* 010 */
                        /* Left point */
                        z1 = *(magptr - ncols);
                        z2 = *(magptr - ncols + 1);
						
                        mag1 = (z2 - z1)*xperp + (z1 - m00)*yperp;
						
                        /* Right point */
                        z1 = *(magptr + ncols);
                        z2 = *(magptr + ncols - 1);
						
                        mag2 = (z2 - z1)*xperp + (z1 - m00)*yperp;
                    }
                }
                else
                {
                    if (-gx > -gy)
                    {
                        /* 001 */
                        /* Left point */
                        z1 = *(magptr + 1);
                        z2 = *(magptr + ncols + 1);
						
                        mag1 = (z1 - m00)*xperp + (z1 - z2)*yperp;
						
                        /* Right point */
                        z1 = *(magptr - 1);
                        z2 = *(magptr - ncols - 1);
						
                        mag2 = (z1 - m00)*xperp + (z1 - z2)*yperp;
                    }
                    else
                    {
                        /* 000 */
                        /* Left point */
                        z1 = *(magptr + ncols);
                        z2 = *(magptr + ncols + 1);
						
                        mag1 = (z2 - z1)*xperp + (m00 - z1)*yperp;
						
                        /* Right point */
                        z1 = *(magptr - ncols);
                        z2 = *(magptr - ncols - 1);
						
                        mag2 = (z2 - z1)*xperp + (m00 - z1)*yperp;
                    }
                }
            } 
			
            /* Now determine if the current point is a maximum point */
			
            if ((mag1 > 0.0) || (mag2 > 0.0))
            {
                *resultptr = (unsigned char) NOEDGE;
            }
            else
            {    
                if (mag2 == 0.0)
                    *resultptr = (unsigned char) NOEDGE;
                else
                    *resultptr = (unsigned char) POSSIBLE_EDGE;
            }
        } 
    }
}

void follow_edges(uint8_t *edgemapptr, int *edgemagptr, short lowval,
			 int cols)
{
	int *tempmagptr;
	uint8_t *tempmapptr;
	int i;
	int x[8] = {1,1,0,-1,-1,-1,0,1},
	y[8] = {0,1,1,1,0,-1,-1,-1};
	
	for(i=0;i<8;i++){
		tempmapptr = edgemapptr - y[i]*cols + x[i];
		tempmagptr = edgemagptr - y[i]*cols + x[i];
		
		if((*tempmapptr == POSSIBLE_EDGE) && (*tempmagptr > lowval)){
			*tempmapptr = (unsigned char) EDGE;
			follow_edges(tempmapptr,tempmagptr, lowval, cols);
		}
	}
}

void apply_hysteresis(int *mag, uint8_t *nms, int rows, int cols,
					  float tlow, float thigh, uint8_t *edge)
{
	int r, c, pos, numedges, highcount, lowthreshold, highthreshold,hist[32768];
	int maximum_mag;
	
	/****************************************************************************
	 * Initialize the edge map to possible edges everywhere the non-maximal
	 * suppression suggested there could be an edge except for the border. At
	 * the border we say there can not be an edge because it makes the
	 * follow_edges algorithm more efficient to not worry about tracking an
	 * edge off the side of the image.
	 ****************************************************************************/
	for(r=0,pos=0;r<rows;r++){
		for(c=0;c<cols;c++,pos++){
			if(nms[pos] == POSSIBLE_EDGE) edge[pos] = POSSIBLE_EDGE;
			else edge[pos] = NOEDGE;
		}
	}
	
	for(r=0,pos=0;r<rows;r++,pos+=cols){
		edge[pos] = NOEDGE;
		edge[pos+cols-1] = NOEDGE;
	}
	pos = (rows-1) * cols;
	for(c=0;c<cols;c++,pos++){
		edge[c] = NOEDGE;
		edge[pos] = NOEDGE;
	}
	
	/****************************************************************************
	 * Compute the histogram of the magnitude image. Then use the histogram to
	 * compute hysteresis thresholds.
	 ****************************************************************************/
	for(r=0;r<32768;r++) hist[r] = 0;
	for(r=0,pos=0;r<rows;r++){
		for(c=0;c<cols;c++,pos++){
			if(edge[pos] == POSSIBLE_EDGE) hist[mag[pos]]++;
		}
	}
	
	/****************************************************************************
	 * Compute the number of pixels that passed the nonmaximal suppression.
	 ****************************************************************************/
	for(r=1,numedges=0;r<32768;r++){
		if(hist[r] != 0) maximum_mag = r;
		numedges += hist[r];
	}
	
	highcount = (int)(numedges * thigh + 0.5);
	
	/****************************************************************************
	 * Compute the high threshold value as the (100 * thigh) percentage point
	 * in the magnitude of the gradient histogram of all the pixels that passes
	 * non-maximal suppression. Then calculate the low threshold as a fraction
	 * of the computed high threshold value. John Canny said in his paper
	 * "A Computational Approach to Edge Detection" that "The ratio of the
	 * high to low threshold in the implementation is in the range two or three
	 * to one." That means that in terms of this implementation, we should
	 * choose tlow ~= 0.5 or 0.33333.
	 ****************************************************************************/
	r = 1;
	numedges = hist[1];
	while((r<(maximum_mag-1)) && (numedges < highcount)){
		r++;
		numedges += hist[r];
	}
	highthreshold = r;
	lowthreshold = (int)(highthreshold * tlow + 0.5);
/*	
	if(VERBOSE){
		printf("The input low and high fractions of %f and %f computed to\n",
			   tlow, thigh);
		printf("magnitude of the gradient threshold values of: %d %d\n",
			   lowthreshold, highthreshold);
	}
*/	
	/****************************************************************************
	 * This loop looks for pixels above the highthreshold to locate edges and
	 * then calls follow_edges to continue the edge.
	 ****************************************************************************/
	for(r=0,pos=0;r<rows;r++){
		for(c=0;c<cols;c++,pos++){
			if((edge[pos] == POSSIBLE_EDGE) && (mag[pos] >= highthreshold)){
				edge[pos] = EDGE;
				follow_edges((edge+pos), (mag+pos), lowthreshold, cols);
			}
		}
	}
	
	/****************************************************************************
	 * Set all the remaining possible edges to non-edges.
	 ****************************************************************************/
	for(r=0,pos=0;r<rows;r++){
		for(c=0;c<cols;c++,pos++) if(edge[pos] != EDGE) edge[pos] = NOEDGE;
	}
}

/*
 Canny edge detection - http://en.wikipedia.org/wiki/Canny_edge_detector

 These are suitable values for tlow and thigh:
 tlow 0.20-0.50
 thigh 0.60-0.90
*/
ImageWrapper *Image::cannyEdgeExtract(float tlow, float thigh) {
	// masks for sobel edge detection
	int gx[3][3]={ 
		{ -1, 0, 1 },
		{ -2, 0, 2 },
		{ -1, 0, 1 }};
	int gy[3][3]={
		{  1,  2,  1 },
		{  0,  0,  0 },
		{ -1, -2, -1 }};
	int resultWidth=m_width-3;
	int resultHeight=m_height-3;
	int *diffx=(int *) malloc(sizeof(int)*resultHeight*resultWidth);
	int *diffy=(int *) malloc(sizeof(int)*resultHeight*resultWidth);
	int *mag=(int *) malloc(sizeof(int)*resultHeight*resultWidth);
	memset(diffx, 0, sizeof(int)*resultHeight*resultWidth);
	memset(diffy, 0, sizeof(int)*resultHeight*resultWidth);
	memset(mag, 0, sizeof(int)*resultHeight*resultWidth);
	
	// compute the magnitute and the x and y differences in the image
	for(int y=0; y<m_height-3; y++) {
		for(int x=0; x<m_width-3; x++) {
			int resultX=0;
			int resultY=0;
			for(int dy=0; dy<3; dy++) {
				for(int dx=0; dx<3; dx++) {
					int pixel=(*this)[y+dy][x+dx];
					resultX+=pixel*gx[dy][dx];
					resultY+=pixel*gy[dy][dx];
				}
			}
			mag[y*resultWidth+x]=abs(resultX)+abs(resultY);
			diffx[y*resultWidth+x]=resultX;
			diffy[y*resultWidth+x]=resultY;
		}
	}
	uint8_t*nms=(uint8_t *) malloc(sizeof(uint8_t)*resultHeight*resultWidth);
	memset(nms, 0, sizeof(uint8_t)*resultHeight*resultWidth);
	non_max_supp(mag, diffx, diffy, resultHeight, resultWidth, nms);

	free(diffx);
	free(diffy);
	
	uint8_t *edge=(uint8_t *) malloc(sizeof(uint8_t)*resultHeight*resultWidth);
	memset(edge, 0, sizeof(uint8_t)*resultHeight*resultWidth);
	apply_hysteresis(mag, nms, resultHeight, resultWidth, tlow, thigh, edge);
	
	free(nms);
	free(mag);
	
	Image *result=new Image(edge, resultWidth, resultHeight, true);
	return [ImageWrapper imageWithCPPImage:result];	
}

// smooth an image using gaussian blur - required before performing canny edge detection
ImageWrapper *Image::gaussianBlur() {
	int blur[5][5]={ 
		{ 1, 4, 7, 4, 1 },
		{ 4,16,26,16, 4 },
		{ 7,26,41,26, 7 },
		{ 4,16,26,16, 4 },
		{ 1, 4, 7, 4, 1 }};

	Image *result=new Image(m_width-5, m_height-5);
	for(int y=0; y<m_height-5; y++) {
		for(int x=0; x<m_width-5; x++) {
			int val=0;
			for(int dy=0; dy<5; dy++) {
				for(int dx=0; dx<5; dx++) {
					int pixel=(*this)[y+dy][x+dx];
					val+=pixel*blur[dy][dx];
				}
			}
			(*result)[y][x]=val/273;
		}
	}
	return [ImageWrapper imageWithCPPImage:result];	
}

// Histogram equalisation
// http://en.wikipedia.org/wiki/Histogram_equalisation
void Image::HistogramEqualisation() {
	std::vector<int> pdf(256);
	std::vector<int> cdf(256);
	// compute the pdf
	for(int i=0; i<m_height*m_width; i++) {
		pdf[m_imageData[i]]++;		
	}
	// compute the cdf
	cdf[0]=pdf[0];
	for(int i=1; i<256; i++) {
		cdf[i]=cdf[i-1]+pdf[i];
	}
	// now map the pixels to the new values
	for(int i=0; i<m_height*m_width; i++) {
		m_imageData[i]=255*cdf[m_imageData[i]]/cdf[255];
	}
}

// convert from a gray scale image back into a UIImage
UIImage *Image::toUIImage() {
	// generate space for the result
	uint8_t *result=(uint8_t *) calloc(m_width*m_height*sizeof(uint32_t),1);
	// process the image back to rgb
	for(int i=0; i<m_height*m_width; i++) {			
		result[i*4]=0;
		int val=m_imageData[i];
		result[i*4+1]=val;
		result[i*4+2]=val;
		result[i*4+3]=val;
	}
	// create a UIImage
	CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
	CGContextRef context=CGBitmapContextCreate(result, m_width, m_height, 8, m_width*sizeof(uint32_t), colorSpace, kCGBitmapByteOrder32Little|kCGImageAlphaNoneSkipLast);
	CGImageRef image=CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	CGColorSpaceRelease(colorSpace);
	UIImage *resultUIImage=[UIImage imageWithCGImage:image];
	CGImageRelease(image);
	// make sure the data will be released by giving it to an autoreleased NSData
	[NSData dataWithBytesNoCopy:result length:m_width*m_height];
	return resultUIImage;
}

// helper functions for resizing
float Image::Interpolate1(float a, float b, float c) {
	float mu=c-floor(c);
	return(a*(1-mu)+b*mu);
}

float Image::Interpolate2(float a, float b, float c, float d, float x, float y)
{
	float ab = Interpolate1(a,b,x);
	float cd = Interpolate1(c,d,x);
	return Interpolate1(ab,cd,y);
}

// shrink or stretch an image
ImageWrapper *Image::resize(int newX, int newY) {
	Image *result=new Image(newX, newY);
	for(float y=0; y<newY; y++) {
		for(float x=0; x<newX; x++) {
			float srcX0=x*(float)(m_width-1)/(float)newX;
			float srcY0=y*(float)(m_height-1)/(float)newY;
			float srcX1=(x+1)*(float)(m_width-1)/(float)newX;
			float srcY1=(y+1)*(float)(m_height-1)/(float)newY;
			float val=0,count=0;
			for(float srcY=srcY0; srcY<srcY1; srcY++) {
				for(float srcX=srcX0; srcX<srcX1; srcX++) {
					val+=Interpolate2((*this)[(int)srcY][(int) srcX], (*this)[(int)srcY][(int) srcX+1],
									  (*this)[(int)srcY+1][(int) srcX], (*this)[(int)srcY+1][(int) srcX+1],
									  srcX, srcY);
					count++;
				}
			}
			(*result)[(int) y][(int) x]=val/count;
		}
	}
	return [ImageWrapper imageWithCPPImage:result];
}

