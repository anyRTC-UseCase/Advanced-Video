//
//  ARVideoRawData.m
//  AR-Plugin-RawMediaData-iOS
//
//  Created by 余生丶 on 2020/10/22.
//

#import "ARVideoRawData.h"

@implementation ARVideoRawDataFormatter
- (instancetype)init {
    if (self = [super init]) {
        self.mirrorApplied = false;
        self.rotationApplied = false;
        self.type = 0;
    }
    return self;
}
@end

@implementation ARVideoRawData

@end

@implementation ARAudioRawData

@end

@implementation ARPacketRawData

@end
