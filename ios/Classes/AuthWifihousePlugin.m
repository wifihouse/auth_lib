#import "AuthWifihousePlugin.h"
#if __has_include(<auth_wifihouse/auth_wifihouse-Swift.h>)
#import <auth_wifihouse/auth_wifihouse-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "auth_wifihouse-Swift.h"
#endif

@implementation AuthWifihousePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAuthWifihousePlugin registerWithRegistrar:registrar];
}
@end
