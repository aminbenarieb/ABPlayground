#import "ViewController.h"

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
    
    kMREmailListEmptyStubViewType_NoConnectionMask = kMREmailListEmptyStubViewType_NoConnection | kMREmailListEmptyStubViewType_NoHeadersNoConnection | kMREmailListEmptyStubViewType_NoHeadersNoConnectionInThread
};


@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
    
    
    for (int i = 0; i < 12; i++) {
        NSLog(@"%d %@", i, (1 << i) & kMREmailListEmptyStubViewType_NoConnectionMask ? @"Y" : @"N");
    }
  
    
}

@end
