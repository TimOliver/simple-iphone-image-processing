I've written a simple C++ class with an Objective-C wrapper that provides a set of common image processing tasks along with conversion to and from UIImage.

The code supports the following operations:

  * Canny edge detection - http://en.wikipedia.org/wiki/Canny_edge_detection
  * Histogram equalisation - http://en.wikipedia.org/wiki/Histogram_equalisation
  * Skeletonisation - http://en.wikipedia.org/wiki/Topological_skeleton
  * Thresholding, adaptive and global - http://en.wikipedia.org/wiki/Thresholding_(image_processing)
  * Gaussian blur (used as a preprocessing step for canny edge detection) - http://en.wikipedia.org/wiki/Gaussian_blur
  * Brightness normalisation - http://en.wikipedia.org/wiki/Normalization_(image_processing)
  * Connected region extraction - http://en.wikipedia.org/wiki/Blob_extraction
  * Resizing - uses interpolation

You can give it a UIImage and it converts it to a greyscale image ready for processing. At the moment I'm taking a shortcut and just taking the green channel from the image (my images tend to be of newspapers so there's no colour). You might want to uncomment the lines that take the average of the r,g and b channels.

With the sample project you can add images to your resources and they show up in the list of images to process.

A typical usage of the classes would be:
```
    // convert to grey scale and shrink the image by 4 - this makes processing a lot faster!
    ImageWrapper *greyScale=Image::createImage(srcImage, srcImage.size.width/4, srcImage.size.height/4);

    // do a gaussian blur and then extract edges using the canny edge detector
    // you can play around with the numbers to see how it effects the edge extraction
    // typical numbers are  tlow 0.20-0.50, thigh 0.60-0.90
    ImageWrapper *edges=greyScale.image->gaussianBlur().image->cannyEdgeExtract(0.3,0.7);
    // show the results
    resultImage.image=edges.image->toUIImage();
```

The Objective-C image wrapper class takes care of memory management for you. All the methods on the C++ class either return you one of these wrapper objects or operate directly on the current image.

The code is currently being used in my Sudoku Grab project for the iPhone http://sudokugrab.blogspot.com/ and will be used in future projects.

You can see the kind of thing that this project could be used for here: http://www.youtube.com/watch?v=oImMJ6p6mKE