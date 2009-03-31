//
//  Region.m
//  ImageProcessing
//
//  Created by Alan Wostenberg on 3/30/09.
//  Copyright 2009 Wosterware.com. All rights reserved.
//

#import "Region.h"

@implementation Region

- (id) init {
	points = [NSMutableArray arrayWithCapacity: 2];
	return (self);
}

// answer area of bounding box
- (int) area {
	return self.bb.size.width * self.bb.size.height;
}

// answer the bounding box for the region
- (NSRect) bb {
	NSRect answer = { {0, 0}, {0, 0}};
	if (points.count < 2) {
		return answer;
	}

	NSPoint upperLeft = [[points objectAtIndex: 0] pointValue];
	NSPoint lowerRight = [[points lastObject] pointValue];
	// find smallest x, smallest y, largest x, largest y //
	NSEnumerator* e = [points objectEnumerator];
	id aValue;
	while (aValue = [e nextObject]) {
		if ([aValue pointValue].x < upperLeft.x) {upperLeft.x = [aValue pointValue].x;}
		if ([aValue pointValue].y < upperLeft.y) {upperLeft.y = [aValue pointValue].y;}
		if ([aValue pointValue].y > lowerRight.x) {lowerRight.x = [aValue pointValue].x;}
		if ([aValue pointValue].y > lowerRight.y) {lowerRight.y = [aValue pointValue].y;}
	}
	
	answer.size.height = lowerRight.x - upperLeft.x;
	answer.size.width = lowerRight.y - upperLeft.y;
	answer.origin.x = upperLeft.x;
	answer.origin.y = upperLeft.y;
	return answer;
}

// add a point to the region
- (void) addPoint: (NSPoint) p {
	[points addObject: [NSValue valueWithPoint:p]];
}

@end
