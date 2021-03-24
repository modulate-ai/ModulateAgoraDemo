#import "VoiceSkin.h"

#include "modulate/modulate.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface VoiceSkin()

- (void)pingWithAPIKeyFilename:(NSString *)filename;
- (NSString*)loadApiKeyFromFilename:(NSString*)filename;
- (void)showAlert:(NSString*)message;

@end

@implementation VoiceSkin

- (id)init:(NSString *)filename withAPIKeyFilename:(NSString *)keyFilename andMaxFrameSize:(unsigned int)max_frame_size{
    self = [super init];

    // Get the resouce path for the .mod voice skin file
    NSBundle* main = [NSBundle mainBundle];
    NSString* skinfile_path = [main pathForResource:filename ofType:@"mod"];

    // Create the voice skin from the voice skin file
    NSDate *load_start = [NSDate date];
    if(modulate_voice_skin_create(max_frame_size, [skinfile_path UTF8String], &_raw_voice_skin))
        [NSException raise:@"ModulateError" format:@"Voice skin creation failed"];
    NSDate *load_end = [NSDate date];
    NSLog(@"Load Time: %f", [load_end timeIntervalSinceDate:load_start]);

    // Retrieve the voice skin's name
    char voice_skin_name[MODULATE_SKIN_NAME_MAX_LENGTH];
    modulate_voice_skin_get_skin_name(_raw_voice_skin, voice_skin_name);
    _skin_name = [NSString stringWithUTF8String:voice_skin_name];

    // Authenticate the voice skin with Modulate's auth server
    [self pingWithAPIKeyFilename:keyFilename];
    return self;
}

- (void)reset {
    NSDate *reset_start = [NSDate date];
    if(modulate_voice_skin_reset(_raw_voice_skin))
        [NSException raise:@"ModulateError" format:@"Voice skin reset failed"];
    NSDate *reset_end = [NSDate date];
    NSLog(@"Reset Time: %f", [reset_end timeIntervalSinceDate:reset_start]);
}

- (NSString*)loadApiKeyFromFilename:(NSString*)filename {
    char* buffer = 0;
    long length = 0;
    FILE * f = fopen([filename UTF8String], "rb");
    if (f) {
        fseek(f, 0, SEEK_END);
        length = ftell (f);
        fseek(f, 0, SEEK_SET);
        buffer = (char*)malloc((length+1)*sizeof(char));
        if (buffer) {
            fread(buffer, sizeof(char), length, f);
        }
        fclose(f);
    }
    if(!buffer)
        return nil;
    buffer[length] = '\0';
    NSString* ret = [NSString stringWithUTF8String:buffer];
    free(buffer);
    ret = [ret stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    ret = [ret stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    return ret;
}

- (void)pingWithAPIKeyFilename:(NSString *)filename {
    NSLog(@"Loading API Key from %@", filename);
    NSBundle* main = [NSBundle mainBundle];
    NSString* api_key_path = [main pathForResource:filename ofType:@"txt"];
    NSString* api_key = [self loadApiKeyFromFilename:api_key_path];
    NSLog(@"Loaded API key %@", api_key);

    NSLog(@"Building ping to modulate...");
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"https://ping.modulate.ai/v1/ping"]];
    [request setHTTPMethod:@"POST"];

    char msg[MODULATE_AUTHENTICATION_MESSAGE_LENGTH];
    int error_code = modulate_voice_skin_create_authentication_message(_raw_voice_skin, [api_key UTF8String], msg, sizeof(msg));
    if(error_code) {
        NSLog(@"Authentication message creation failed");
        [self showAlert:@"Failed to create authentication message"];
        return;
    }

    NSString* authentication_message = [[NSString alloc] initWithUTF8String:msg];

    NSError *error;
    NSDictionary *post = @{@"request_string" : authentication_message};
    NSData *postData = [NSJSONSerialization dataWithJSONObject:post options:0 error:&error];
    if(!postData) {
        NSLog(@"Failed to create JSON %@", error);
        [self showAlert:@"Failed to create authentication message JSON"];
        return;
    }

    [request setHTTPBody:postData];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (!data) {
            NSLog(@"sendAsynchronousRequest failed: %@", connectionError);
            [self showAlert:@"Failed to send authentication message - please ensure that you are connected to the internet."];
            return;
        }

        @try {
            NSError *error;
            NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            NSString* signed_respose = responseData[@"signed_response"];
            bool success = ([responseData[@"success"] boolValue] == YES);
            NSLog(@"Authentication succeeded? %s", success ? "true" : "false");
            if(!success) {
                NSLog(@"Response Data: %@", responseData);
                [self showAlert:@"Failed to authenticate with Modulate server - please ensure that you are connected to the internet."];
                return;
            }
            const char* auth_check = [signed_respose UTF8String];

            if(auth_check) {
                int error_code2 = modulate_voice_skin_check_authentication_message(self->_raw_voice_skin, auth_check);
                if(error_code2) {
                    [self showAlert:@"Failed to authenticate with Modulate server"];
                    return;
                }
            } else {
                NSLog(@"Authentication Failed - check message was nullptr");
                [self showAlert:@"Failed to authenticate with null message"];
                return;
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Authentication Failed - exception %@", exception);
            [self showAlert:@"Authentication Failed with Exception"];
        }
    }];
    NSLog(@"Ping sent!");
}

- (void)showAlert:(NSString*)message {
    NSString* error_name = [NSString stringWithFormat:@"Error creating %@", _skin_name];
    UIAlertView *alert_view = [[UIAlertView alloc] initWithTitle:error_name message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert_view show];
}

@end
