# Modulate + Agora Integration Demo

This project builds an example application which lets users voice chat with voice skins, via Agora's voice chat service!  Users can select different voice skins, apply customization filters, and join different chat channels.

## To Build

1) Locate your libmodulate.a, api_key.txt, and various .mod files that you received from Modulate, and copy them to the ModulateAgoraDemo/modulate/ directory
2) Change the skin_names array allocation in ModulateAgoraDemo/ModulateAgoraInterface.mm to contain the .mod files that you have put into ModulateAgoraDemo/modulate/
3) In ModulateAgoraDemo, rename AppID.swift.template to AppID.swift, and enter your Agora app ID
4) Add the Agora libraries in the libs/ directory
5) Change your code signing team in the ModulateAgoraDemo.xcodeproj project to be your own team

## To Use as a Reference

The Modulate-specific logic in this codebase is concentrated in the VoiceSkin, ModulateAgoraFrameObserver, and ModulateAgoraInterface classes.  Copying those classes into your project, along with the ModulateAgoraDemo-Bridging-Header.h file and the contents of the modulate/ directory should let you hook up Modulate's voice skins to Agora's voice chat by simply following the ModulateAgoraInterface creation and attachment lines in ViewController.swift.

The VoiceSkin class is an Objective-C class for containing voice skin data and logic.  It wraps the underlying voice skin void*, alongside helpers for doing authentication network calls on iOS devices.  It does not provide a helper function for converting audio frames using the voice skins, as that is handled via access to the raw void* in ModulateAgoraFrameObserver to avoid blocking operations.

The ModulateAgoraFrameObserver class performs the real-time voice conversion computation, holding a reference to the currently selected voice skin, a voice skin helper for sample rate conversion, and a filter parameters structure for customization.  It is designed to be lightweight and real-time friendly, written in C++ and doing only the minimum necessary work in the realtime audio thread.

The ModulateAgoraInterface class manages a collection of the voice skins in the app, and handles registering the ModulateAgoraFrameObserver with Agora's SDK.  It is the primary point of contact between the Modulate logic and the rest of the app, and communication between the rest of the app logic and Modulate's voice skins (e.g. setting a new filter customization parameter) should be done through this class.
