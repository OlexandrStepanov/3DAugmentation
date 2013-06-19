3DAugmentation
==============

iOS Augmented reality project.

This sample app demonstrates the Augmented reality technology, it detects and tracks the marker (image-based), augments the 3D scene above the marker surface, and displays simple cube rotation animation above the surface.
Marker for this sample can be found here: https://github.com/OlexandrStepanov/3DAugmentation/blob/master/3DAugmentation/Resources/monaLisa.jpg

Detection implemented using [FERNS](http://cvlab.epfl.ch/software/ferns) algorithm, tracking - Template matching based tracker.
Project also uses [OpenCV framework](http://opencv.org/), and [Isgl3D library](http://isgl3d.com/) as 3D engine for augmentation.
