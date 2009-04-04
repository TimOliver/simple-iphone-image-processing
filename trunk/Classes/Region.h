//
//  Region.h
//  ImageProcessing
//
//  Created by Alan Wostenberg on 3/30/09.
//  Copyright 2009 Wosterware.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Region : NSObject {
	NSMutableArray* points;
}

// answer area of bounding box of region
- (int) area;
- (NSRect) bb;

// add a point to the region
- (void) addPoint: (NSPoint) p;
- (NSMutableArray*) points;

@end
