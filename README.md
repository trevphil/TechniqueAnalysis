# TechniqueAnalysis

## Description

This is a CocoaPod which processes video footage of a user doing an exercise, and provides feedback on the user's form. The general idea is to capture a video and convert it to a timeseries, where each data point contains an array of body point locations in 2D space, along with a confidence level on the accuracy of each body point.

![pipeline](https://trevphil.com/assets/ta_pipeline.png)

It is already possible to estimate body points (called _pose estimation_), for example using the project [OpenPose](https://github.com/CMU-Perceptual-Computing-Lab/openpose). [tucan9389](https://github.com/tucan9389) has provided an excellent starting point for the code implemented here, based on [his project](https://github.com/tucan9389/PoseEstimation-CoreML) which predicts body points in real-time.

To translate from pose estimation to technique analysis, we need to train a model on timeseries with correct and incorrect form for various exercises. Richard Yang and Steven Chen from Stanford University have had relative success with [Dynamic Time Warping](https://en.wikipedia.org/wiki/Dynamic_time_warping) (DTW) to solve this type of problem, as described in [this paper](https://www.researchgate.net/publication/324759769_Pose_Trainer_Correcting_Exercise_Posture_using_Pose_Estimation).

![dtw](https://trevphil.com/assets/ta_dtw.png)

Additional research by Keogh et al. in their paper "[Fast Time Series Classification Using Numerosity Reduction](http://alumni.cs.ucr.edu/~xxi/495.pdf)" provides a promising, efficient algorithm to train a kNN model with DTW (with _k_=1 and a dynamic warping window) for a use case similar to the one described here.

The ML frameworks compatible with CoreML on iOS (e.g. [scikit-learn](https://scikit-learn.org/stable/documentation.html)) are currently lacking a suitable model to pre-train a kNN-DTW model and bundle it into an iOS application. Because of this, the best option may be to implement the algorithm manually and ship it with the application. The kNN-DTW algorithm here is written in Swift, but writing the algo in **C** would provide a much faster runtime. For further explanation on kNN-DTW, Mark Regan has implemented a Python version of kNN-DTW similar to the one described by Keogh et al. It can be found [here](https://github.com/markdregan/K-Nearest-Neighbors-with-Dynamic-Time-Warping).

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first. You should use Xcode's **Legacy Build System** to correctly include the videos in Bundle Resources (File → Workspace Settings → Shared Workspace Settings → Build System).

![demo](https://trevphil.com/assets/ta_demo.png)

## Requirements

iOS 11, Swift 4.2

## Installation

TechniqueAnalysis is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'TechniqueAnalysis'
```

## Author

trevphil, trevor.j.phillips@uconn.edu

## License

TechniqueAnalysis is available under the MIT license. See the LICENSE file for more info.
