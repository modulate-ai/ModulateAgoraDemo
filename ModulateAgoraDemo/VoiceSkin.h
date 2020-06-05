#ifndef VoiceSkin_h
#define VoiceSkin_h

#import <Foundation/Foundation.h>

#define MODULATE_INTERNAL_SAMPLE_RATE 24000

@interface VoiceSkin : NSObject

- (id)init:(NSString *)filename withAPIKeyFilename:(NSString *)keyFilename andMaxFrameSize:(unsigned int)max_frame_size;
- (void)reset;

@property (readonly) void* raw_voice_skin;
@property (readonly) NSString* skin_name;

@end

#endif /* VoiceSkin_h */
