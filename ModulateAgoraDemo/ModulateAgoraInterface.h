#ifndef ModulateAgoraInterface_h
#define ModulateAgoraInterface_h

#import <Foundation/Foundation.h>

// Ignore all warnings in agora headers
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
#import <AgoraRtcKit/AgoraRtcEngineKit.h>
#pragma clang diagnostic pop

@interface ModulateAgoraInterface : NSObject
- (id _Nonnull)initWithMaxFrameSize:(unsigned int)max_frame_size andExpectedSampleRate:(unsigned int)expected_sample_rate;
- (void)attachModulateToRtcEngineKit:(AgoraRtcEngineKit* _Nonnull) kit;
- (void)setRadioStrength:(float) radio_strength;
- (void)setPresenceStrength:(float) radio_strength;
- (void)selectVoiceSkin:(NSString* _Nonnull) voice_skin_name;
- (NSArray* _Nonnull)getVoiceSkinNames;
@end

#endif /* ModulateAgoraInterface_h */
