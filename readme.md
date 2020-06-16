# SeeSoSample

### Index
- [App Introduction](#App-Introduction)
- [Requirements](#Requirements)
- [How to run](#How-to-run)
- [Function description of the app](#Function-description-of-the-app)

## App Introduction

 This app is designed to help you understand how GazeTracker works. This is because the functions available for each state are activated.

## Requirements

- XCode 11.5
- SeeSo.framework : 2.2.0
- Swift: 5.2
- It must be run on a **real iOS device. (iOS 13.0 +, iPhone 6s +)**
- It must be an **internet environment.**

## How to run

1. Clone or download this project.
2. Add SeeSo.framework to the project as shown below. (At this time, "copy items if needed" should be checked.)

    ![images/_2020-06-11__3.32.25.png](images/1.png)

    2-1 

    ![images/_2020-06-11__3.32.39.png](images/2.png)

    2-2

    ![images/_2020-06-11__3.33.44.png](images/3.png)

    2-3

3. Now change the SeeSo.framework to sign & embed as shown below.

    ![images/_2020-06-11__3.33.21.png](images/4.png)

    3-1

4. Sign in with your developer ID in the Signing & Capabilities tab.
5. Insert your own development key in the licenseKey into the "ViewController.swift".

    ![images/_2020-06-15__5.40.07.png](images/5.png)

    5-1

6. Allow camera access.

    ![images/IMG_0239.png](images/6.png)

## Function description of the app

1. Click on the switch to activate it. SeeSo.framework's GazeTracker
To create. Deactivation again destroys the object.

    ![images/IMG_0241.png](images/7.png)

    1-1. GazeTracker init.

    ![images/IMG_0240.png](images/8.png)

    1-2. GazeTracker deinit

2. Clicking the switch to activate activates eye tracking. If it is deactivated again, the eye tracking is stopped.

    ![images/SeeSoSample1.png](images/9.png)

    2-1. Tracking

    ![images/IMG_0241%201.png](images/10.png)

    2-2. Stop Tracking

3. Click the switch to activate it, and GazePointView uses the onFilteredGaze's coordinates. If disabled again, the OnGaze's coordinates are used.

    ![images/SeeSoSample3.png](images/11.png)

    3-1. Filtered Gaze

    ![images/SeeSoSample2.png](images/12.png)

    3-2 Raw Gaze

4. The One Five button can only select one of the two. When selected, the color changes to green, meaning one-point calibration and five-point calibration, respectively. Click the start button next to start calibration.

    ![images/SeeSoSample3%201.png](images/13.png)

    4-1. Five point calibration mode.

    ![images/SeeSoSample4.png](images/14.png)

    4-2 One point calibration mode.

5. The top label tells you the status of each. If an error occurs, see the api documentation and deal with it.
6. The camera preview is visible when it is in eye tracking.
