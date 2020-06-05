#import <Foundation/Foundation.h>
#import <AgoraAudioKit/IAgoraRtcEngine.h>

#import "VoiceSkin.h"
#include "ModulateAgoraInterface.h"
#include "ModulateAudioFrameObserver.hpp"


@interface ModulateAgoraInterface() {
    NSArray* skin_names;
    NSMutableDictionary* voice_skin_map;
    ModulateAudioFrameObserver* modulate_observer;
}

@end


@implementation ModulateAgoraInterface

- (id)initWithMaxFrameSize:(unsigned int)max_frame_size andExpectedSampleRate:(unsigned int)expected_sample_rate {
    self = [super init];

    // Calculate the max frame size in samples for the voice skins, at the internal modulate sample rate
    double frame_size_in_ms = (double)max_frame_size / ((double)expected_sample_rate / 1000.0);
    unsigned int modulate_max_frame_size = (unsigned int)ceil((MODULATE_INTERNAL_SAMPLE_RATE/1000.0) * frame_size_in_ms);

    // Create all of the voice skin objects, loading them from the .mod voice skin files and authenticating them
    // via the API key with Modulate's authentication server
    skin_names = [[NSArray alloc]
                  initWithObjects:@"sarena_2020_03_25",
                  @"daniel_2020_03_25",
                  nil];
    voice_skin_map = [[NSMutableDictionary alloc] initWithCapacity:[skin_names count]];
    for (NSString* name in skin_names) {
        [voice_skin_map setValue:[[VoiceSkin alloc] init:name withAPIKeyFilename:@"api_key" andMaxFrameSize:modulate_max_frame_size] forKey:name];
    }

    // Create a Modulate frame observer, which will conduct the realtime voice conversionn via Agora's callback
    // Select the first voice skin as a default to begin using, though this can be changed later via
    // [self selectVoiceSkin];
    VoiceSkin* voice_skin = [voice_skin_map valueForKey:skin_names[0]];
    [voice_skin reset];  // reset the skin's internal state before use on an audio stream
    modulate_observer = new ModulateAudioFrameObserver([voice_skin raw_voice_skin],
                                                       max_frame_size, expected_sample_rate);
    return self;
}

- (void)dealloc {
    delete modulate_observer;
}

// Agora interface based on https://docs.agora.io/en/Video/rawdata_ios?platform=iOS
// as of August 04, 2019
- (void)attachModulateToRtcEngineKit:(AgoraRtcEngineKit* _Nonnull) kit {
    NSLog(@"Attaching Modulate to RTC Engine");
    void* handle = [kit getNativeHandle];
    agora::rtc::IRtcEngine* engine = (agora::rtc::IRtcEngine*)handle;

    agora::util::AutoPtr<agora::media::IMediaEngine> mediaEngine;
    mediaEngine.queryInterface(engine, agora::AGORA_IID_MEDIA_ENGINE);
    if (mediaEngine)
    {
        mediaEngine->registerAudioFrameObserver(modulate_observer);
    }
}

- (void)setRadioStrength:(float) radio_strength {
    modulate_observer->params.radio_strength = radio_strength;
}

- (void)setPresenceStrength:(float) presence_strength {
    modulate_observer->params.presence_strength = presence_strength;
}

- (void)selectVoiceSkin:(NSString* _Nonnull) voice_skin_name {
    VoiceSkin* voice_skin = [voice_skin_map valueForKey:voice_skin_name];
    NSLog(@"Selected skin %@", [voice_skin skin_name]);
    [voice_skin reset];  // reset the skin's internal state before use on an audio stream
    modulate_observer->voice_skin = [voice_skin raw_voice_skin];
}

- (NSArray* _Nonnull)getVoiceSkinNames {
    return skin_names;
}

@end
