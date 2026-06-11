//  Created by david on 6/10/26.
//  Apache 2 License

#import <Cocoa/Cocoa.h>

#import <AppKit/AppKit.h>

#import "BrowserService.h"

int main(int argc, char *argv[]) {
  @autoreleasepool {
    BrowserService *service = [[BrowserService alloc] init];
    NSRegisterServicesProvider(service, @"BrowserService");
    [[NSRunLoop currentRunLoop] run];
  }
  return 0;
}
