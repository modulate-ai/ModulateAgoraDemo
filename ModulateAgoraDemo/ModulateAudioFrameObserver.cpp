#include "ModulateAudioFrameObserver.hpp"
#include <iostream>
#include <cmath>


ModulateAudioFrameObserver::ModulateAudioFrameObserver(void* _initial_voice_skin, size_t _max_frame_size, unsigned int expected_sample_rate) :
max_frame_size(_max_frame_size),
float_buffer(new float[_max_frame_size]),
params(modulate_build_default_parameters_struct()),
voice_skin(_initial_voice_skin) {
    // create a voice skin helper to convert between Modulate's internal sample rate and the provided sample rate
    modulate_voice_skin_helper_create(&voice_skin_helper, (unsigned int)max_frame_size);
    // reset internal buffers before using on an audio stream
    modulate_voice_skin_helper_reset(voice_skin_helper, expected_sample_rate);
}

ModulateAudioFrameObserver::~ModulateAudioFrameObserver() {
    delete[] float_buffer;
}

bool ModulateAudioFrameObserver::checkValidFrame(const AudioFrame& audioFrame) const {
    if(audioFrame.type != FRAME_TYPE_PCM16) {
        std::cerr<<"Frame type not understood"<<std::endl;
        return false;
    }
    if(audioFrame.bytesPerSample != 2) {
        std::cerr<<"Bytes per sampe invalid, expected 2 but got "<<audioFrame.bytesPerSample<<std::endl;
        return false;
    }
    if(audioFrame.channels != 1) {
        std::cerr<<"Modulate expects mono channels but received "<<audioFrame.channels<<std::endl;
        return false;
    }

    if(voice_skin_helper == nullptr) {
        std::cerr<<"Modulate voice skin helper was null"<<std::endl;
        return false;
    }
    if(voice_skin == nullptr) {
        std::cerr<<"Modulate voice skin was null"<<std::endl;
        return false;
    }
    int is_authenticated = 0;
    modulate_voice_skin_check_authenticated(voice_skin, &is_authenticated);
    if(!is_authenticated) {
        std::cerr<<"Modulate voice skin was not authenticated"<<std::endl;
        return false;
    }
    unsigned int num_samples = audioFrame.samples;
    if(num_samples > max_frame_size) {
        std::cerr<<"Modulate number of samples "<<num_samples<<" exceeded max samples "<<max_frame_size<<std::endl;
        return false;
    }
    return true;
}

bool ModulateAudioFrameObserver::onRecordAudioFrame(AudioFrame& audioFrame) {
    if(!checkValidFrame(audioFrame))
        return false;

    unsigned int num_samples = audioFrame.samples;
    unsigned int sample_rate = audioFrame.samplesPerSec;
    short* short_buffer = (short*)audioFrame.buffer;

    // convert the short audio data to float for Modulate to process
    for(size_t i = 0; i < num_samples; i++)
        float_buffer[i] = float(short_buffer[i]) / (1<<15);
    // convert the float audio with a voice skin, returning the new audio to the same audio buffer
    int error_code = 0;
    error_code = modulate_voice_skin_helper_generate(voice_skin, voice_skin_helper, float_buffer, float_buffer, num_samples, sample_rate, &params);
    if(error_code) {
        std::cerr<<"Modulate voice skin helper generate non-zero error code "<<error_code<<std::endl;
        return false;
    }
    // re-cast back from float to short
    for(size_t i = 0; i < num_samples; i++)
        short_buffer[i] = (short)(float_buffer[i] * ((1<<15) - 1));
    return true;
}
