//
//  main.m
//  ObjCPlaygroud
//
//  Created by Amin Benarieb on 10.09.2021.
//

#import "pose_graph_example.hpp"
#import <Foundation/Foundation.h>

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    MiniSlamWrapper miniSlamWrapper = MiniSlamWrapper();
    NSLog(@"main2 finished with %d code", miniSlamWrapper.run_example());
  }
  return 0;
}
