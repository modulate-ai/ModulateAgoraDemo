#ifndef ModulateAudioFrameObserver_hpp
#define ModulateAudioFrameObserver_hpp

// Ignore all warnings in agora headers
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
#include <AgoraRtcKit/IAgoraMediaEngine.h>
#pragma clang diagnostic pop

#include <stdio.h>
#include <chrono>

#include "modulate/modulate.h"

class ModulateAudioFrameObserver : public agora::media::IAudioFrameObserver
{
protected:
    const size_t max_frame_size;
    float* float_buffer;
    void* voice_skin_helper;

    bool checkValidFrame(const AudioFrame& audioFrame) const;

public:
    modulate_parameters params;
    void* voice_skin;

    ModulateAudioFrameObserver(void* _initial_voice_skin, size_t max_frame_size, unsigned int expected_sample_rate);
    ~ModulateAudioFrameObserver();

    // Occurs when the recorded audio frame is received.
    virtual bool onRecordAudioFrame(AudioFrame& audioFrame) override;

    // Occurs when the audio playback frame is received.
    virtual bool onPlaybackAudioFrame(AudioFrame& audioFrame) override
    {
        return true;
    };
    // Occurs when the audio playback frame of a specified user is received.
    virtual bool onPlaybackAudioFrameBeforeMixing(unsigned int uid, AudioFrame& audioFrame) override
    {
        return true;
    };
    // Occurs when the mixed recorded and playback audio frame is received.
    virtual bool onMixedAudioFrame(AudioFrame& audioFrame) override
    {
        return true;
    };
};

#endif /* ModulateAudioFrameObserver_hpp */
