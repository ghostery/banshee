banshee
=======

An iOS browser built on top of UIWebView - [screenshot](https://d1k68i4h6ifyxa.cloudfront.net/screens/banshee_screen1.png)

This projects implements tabs, bookmarks, address bar, search bar, loading indicators, and much more for UIWebView. Currently it only supports iOS 7.0 and greater with ARC-only. See branches for older versions.

## Installation

* Copy "Browser" and "Browser Resources" folder into your xcode project.

* This project is cocoapods compatible if you prefer installing it via cocoapods.

## Dependencies

* CoreData.framework
* SystemConfiguration.framework
* libxml2.2.dylib

To include these dependencies you need to add them to your linked libraries. To do this click on project name in Project Navigator then click on your project target. Then under the "Build Phases" section you will see a "Link Binary With Libraries" item, expand it and click the "+" button.

Since libxml is not a framework but rather a dylib you will also have to add it to the head search paths. To do this go to "Build Settings" section of xcode.Set the "Head Search Paths": `$(SDKROOT)/usr/include/libxml2`


## Integration

The recommended way to integrate the browser code is to make your view controller a subclass of the browser controller. Which should look something like this:

    #import <banshee/BrowserViewController.h> // only necessary if using banshee cocoapod

    @interface ViewController : BrowserViewController


### AppDelegate

In the app delegate you should place this code in your `didFinishLaunchingWithOptions`:

    self.window = [[BrowserMainWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setRootViewController:[[ViewController alloc] init]];

Note: These instructions only work if you create an empty project file. If you create a different type of project like a "single page" app, you will have to use a different approach since story board files are pulled in via plist file.

## License

Copyright (c) 2014 Evidon unless otherwise specified

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
