//
//  main.m
//  ObjCPlaygroud
//
//  Created by Amin Benarieb on 10.09.2021.
//

#import "pose_graph_example.hpp"
#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSInteger, MREmailListEmptyStubViewType) {
    kMREmailListEmptyStubViewType_None = 1 << 0,
    kMREmailListEmptyStubViewType_NoConnection = 1 << 1,
    kMREmailListEmptyStubViewType_NoHeaders = 1 << 2,
    kMREmailListEmptyStubViewType_NoHeadersNoConnection = 1 << 3,
    kMREmailListEmptyStubViewType_NoHeadersCollectorActivation = 1 << 4,

    kMREmailListEmptyStubViewType_NoUnreadHeaders = 1 << 5,
    kMREmailListEmptyStubViewType_NoFlaggedHeaders = 1 << 6,
    kMREmailListEmptyStubViewType_NoHeadersWithAttachments = 1 << 7,

    kMREmailListEmptyStubViewType_NoHeadersInThread = 1 << 8,
    kMREmailListEmptyStubViewType_NoHeadersNoConnectionInThread = 1 << 9,

    kMREmailListEmptyStubViewType_NoSearchResults = 1 << 10,
    kMREmailListEmptyStubViewType_SearchNoConnection = 1 << 11,
    
    kMREmailListEmptyStubViewType_NoConnectionMask = kMREmailListEmptyStubViewType_NoConnection | kMREmailListEmptyStubViewType_NoHeadersNoConnection | kMREmailListEmptyStubViewType_NoHeadersNoConnectionInThread | kMREmailListEmptyStubViewType_SearchNoConnection
};

typedef void (^BLOCK)(void);
typedef void (^BLOCK2)(BLOCK);

void blockCall(BLOCK2 block) {
    block(^{
        NSLog (@"Hello World");
    });
}

int main(int argc, const char *argv[]) {
  @autoreleasepool {
//      blockCall(^(BLOCK block) {
//          // someCall {
//          block();
//          //
//      });
//    MiniSlamWrapper miniSlamWrapper = MiniSlamWrapper();
//    NSLog(@"main2 finished with %d code", miniSlamWrapper.run_example());
      
      for (int i = 0; i < 12; i++) {
          NSLog(@"%d %@", i, (1 << i) & kMREmailListEmptyStubViewType_NoConnectionMask ? @"Y" : @"N");
      }
  }
  return 0;
}
