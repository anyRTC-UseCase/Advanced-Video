//
//  ARVideoRawData.h
//  AR-Plugin-RawMediaData-iOS
//
//  Created by 余生丶 on 2020/10/22.
//

#import <Foundation/Foundation.h>

@interface ARVideoRawDataFormatter : NSObject
@property (nonatomic, assign) int type; //YUV 420, YUV 422P, RGBA
@property (nonatomic, assign) BOOL rotationApplied;
@property (nonatomic, assign) BOOL mirrorApplied;
@end

@interface ARVideoRawData : NSObject
@property (nonatomic, assign) int type;
@property (nonatomic, assign) int width;  //width of video frame
@property (nonatomic, assign) int height;  //height of video frame
@property (nonatomic, assign) int yStride;  //stride of Y data buffer
@property (nonatomic, assign) int uStride;  //stride of U data buffer
@property (nonatomic, assign) int vStride;  //stride of V data buffer
@property (nonatomic, assign) int rotation; // rotation of this frame (0, 90, 180, 270)
@property (nonatomic, assign) int64_t renderTimeMs; // timestamp
@property (nonatomic, assign) char* yBuffer;  //Y data buffer
@property (nonatomic, assign) char* uBuffer;  //U data buffer
@property (nonatomic, assign) char* vBuffer;  //V data buffer
@end

@interface ARAudioRawData : NSObject
@property (nonatomic, assign) int samples;  //number of samples in this frame
@property (nonatomic, assign) int bytesPerSample;  //number of bytes per sample: 2 for PCM16
@property (nonatomic, assign) int channels;  //number of channels (data are interleaved if stereo)
@property (nonatomic, assign) int samplesPerSec;  //sampling rate
@property (nonatomic, assign) int bufferSize;
@property (nonatomic, assign) int64_t renderTimeMs;
@property (nonatomic, assign) char* buffer;  //data buffer
@end

@interface ARPacketRawData : NSObject
@property (nonatomic, assign) const unsigned char* buffer;
@property (nonatomic, assign) uint bufferSize;
@end

