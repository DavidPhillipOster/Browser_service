//  BrowserService.m
//  BrowserService
//
//  Created by David Phillip Oster on 6/10/26.
//

#import "BrowserService.h"
#import <AppKit/AppKit.h>

@interface NSPasteboard (BrowserService)
- (nullable NSAttributedString *)attributedStringForType:(NSPasteboardType)pType;
@end
@implementation  NSPasteboard (BrowserService)
- (nullable NSAttributedString *)attributedStringForType:(NSPasteboardType)pType {
  NSAttributedString *result = nil;
  NSData *data = [self dataForType:pType];
  if (0 < data.length) {
    NSError *error = nil;
    result = [[NSAttributedString alloc] initWithData:data options:@{NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType} documentAttributes:nil error:&error];
  }
  return result;
}
@end

@interface BrowserService ()
@property NSString *bundleID;
@end

@implementation BrowserService

- (void)openURL:(NSURL *)url {
  NSWorkspace *ws = NSWorkspace.sharedWorkspace;
  NSURL *appURL = [ws URLForApplicationWithBundleIdentifier:self.bundleID];
  [ws openURLs:@[url] withApplicationAtURL:appURL
                              configuration:NSWorkspaceOpenConfiguration.configuration
                          completionHandler:^(NSRunningApplication * _Nullable app, NSError * _Nullable error) {
    if (error) {
      NSLog(@"%@", error);
    }
  }];
}

- (void)doBrowserService:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error {
  self.bundleID = userData;
  // simple case: pboard is an NSString with exactly one URL.
  NSURL *url = [NSURL URLFromPasteboard:pboard];
  if (url) {
    [self openURL:url];
    return;
  }

  __block BOOL didFindURL = NO;

  if (@available(macOS 15.4, *)) {
    // pboard is an NSString with a URL and other characters before or after.
    [pboard detectValuesForPatterns:[NSSet setWithObject:NSPasteboardDetectionPatternProbableWebURL] completionHandler:^(NSDictionary<NSPasteboardDetectionPattern,id> * _Nullable detectedValues, NSError * _Nullable error) {
      NSString *link = detectedValues[NSPasteboardDetectionPatternProbableWebURL];
      if ([link isKindOfClass:[NSString class]] && link.length) {
        NSURL *url = [NSURL URLWithString:link];
        [self openURL:url];
        didFindURL = YES;
      } else if ([link isKindOfClass:[NSURL class]]) {
        [self openURL:url];
        didFindURL = YES;
      }
    }];
  }
  if (didFindURL) {
    return;
  }

  // pboard is attributed text with a clickable link and other characters before or after.
  NSAttributedString *aString = [pboard attributedStringForType:NSPasteboardTypeRTF];
  if (aString.length) {
    [aString enumerateAttributesInRange:NSMakeRange(0, aString.length) options:0 usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
      NSURL *value = (NSURL *)attrs[NSLinkAttributeName];
      if ([value isKindOfClass:[NSURL class]]) {
        [self openURL:value];
        didFindURL = YES;
        *stop = YES;
      }
    }];
  }
  if (didFindURL) {
    return;
  }
  NSBeep();
}

@end
