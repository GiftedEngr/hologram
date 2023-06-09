//
//  Device.mm
//  CMIOMinimalSample
//
//  Created by John Boiles  on 4/10/20.
//
//  CMIOMinimalSample is free software, and use is bound by the terms
//  set out in the LICENSE file distributed with this project.

#import "Device.h"

#import <CoreFoundation/CoreFoundation.h>
#include <IOKit/audio/IOAudioTypes.h>

#import "PlugIn.h"
#import "Logging.h"

@interface Device ()
@property BOOL excludeNonDALAccess;
@property pid_t masterPid;
@end


@implementation Device

// Note that the DAL's API calls HasProperty before calling GetPropertyDataSize. This means that it can be assumed that address is valid for the property involved.
- (UInt32)getPropertyDataSizeWithAddress:(CMIOObjectPropertyAddress)address qualifierDataSize:(UInt32)qualifierDataSize qualifierData:(nonnull const void *)qualifierData {

    switch (address.mSelector) {
        case kCMIOObjectPropertyName:
            return sizeof(CFStringRef);
        case kCMIOObjectPropertyManufacturer:
            return sizeof(CFStringRef);
        case kCMIOObjectPropertyElementCategoryName:
            return sizeof(CFStringRef);
        case kCMIOObjectPropertyElementNumberName:
            return sizeof(CFStringRef);
        case kCMIODevicePropertyPlugIn:
            return sizeof(CMIOObjectID);
        case kCMIODevicePropertyDeviceUID:
            return sizeof(CFStringRef);
        case kCMIODevicePropertyModelUID:
            return sizeof(CFStringRef);
        case kCMIODevicePropertyTransportType:
            return sizeof(UInt32);
        case kCMIODevicePropertyDeviceIsAlive:
            return sizeof(UInt32);
        case kCMIODevicePropertyDeviceHasChanged:
            return sizeof(UInt32);
        case kCMIODevicePropertyDeviceIsRunning:
            return sizeof(UInt32);
        case kCMIODevicePropertyDeviceIsRunningSomewhere:
            return sizeof(UInt32);
        case kCMIODevicePropertyDeviceCanBeDefaultDevice:
            return sizeof(UInt32);
        case kCMIODevicePropertyHogMode:
            return sizeof(pid_t);
        case kCMIODevicePropertyLatency:
            return sizeof(UInt32);
        case kCMIODevicePropertyStreams:
            // Only one stream
            return sizeof(CMIOStreamID) * 1;
        case kCMIODevicePropertyStreamConfiguration:
            // Only one stream
            return sizeof(UInt32) + (sizeof(UInt32) * 1);
        case kCMIODevicePropertyExcludeNonDALAccess:
            return sizeof(UInt32);
        case kCMIODevicePropertyCanProcessAVCCommand:
            return sizeof(Boolean);
        case kCMIODevicePropertyCanProcessRS422Command:
            return sizeof(Boolean);
        case kCMIODevicePropertyLinkedCoreAudioDeviceUID:
            return sizeof(CFStringRef);
        case kCMIODevicePropertyDeviceMaster:
            return sizeof(pid_t);
        default:
            DLog(@"Device unhandled getPropertyDataSizeWithAddress for %@", [ObjectStore StringFromPropertySelector:address.mSelector]);
    };

    return 0;
}

// Note that the DAL's API calls HasProperty before calling GetPropertyData. This means that it can be assumed that address is valid for the property involved.
- (void)getPropertyDataWithAddress:(CMIOObjectPropertyAddress)address qualifierDataSize:(UInt32)qualifierDataSize qualifierData:(nonnull const void *)qualifierData dataSize:(UInt32)dataSize dataUsed:(nonnull UInt32 *)dataUsed data:(nonnull void *)data {

    switch (address.mSelector) {
        case kCMIOObjectPropertyName:
            *static_cast<CFStringRef*>(data) = CFSTR("Hologram Camera");
            *dataUsed = sizeof(CFStringRef);
            break;
        case kCMIOObjectPropertyManufacturer:
            *static_cast<CFStringRef*>(data) = CFSTR("Hologram Labs");
            *dataUsed = sizeof(CFStringRef);
            break;
        case kCMIOObjectPropertyElementCategoryName:
            *static_cast<CFStringRef*>(data) = CFSTR("catname");
            *dataUsed = sizeof(CFStringRef);
            break;
        case kCMIOObjectPropertyElementNumberName:
            *static_cast<CFStringRef*>(data) = CFSTR("element number name");
            *dataUsed = sizeof(CFStringRef);
            break;
        case kCMIODevicePropertyPlugIn:
            *static_cast<CMIOObjectID*>(data) = self.pluginId;
            *dataUsed = sizeof(CMIOObjectID);
            break;
        case kCMIODevicePropertyDeviceUID:
            *static_cast<CFStringRef*>(data) = CFSTR("CMIO Simple Device");
            *dataUsed = sizeof(CFStringRef);
            break;
        case kCMIODevicePropertyModelUID:
            *static_cast<CFStringRef*>(data) = CFSTR("CMIO Simple Model");
            *dataUsed = sizeof(CFStringRef);
            break;
        case kCMIODevicePropertyTransportType:
            *static_cast<UInt32*>(data) = kIOAudioDeviceTransportTypeBuiltIn;
            *dataUsed = sizeof(UInt32);
            break;
        case kCMIODevicePropertyDeviceIsAlive:
            *static_cast<UInt32*>(data) = 1;
            *dataUsed = sizeof(UInt32);
            break;
        case kCMIODevicePropertyDeviceHasChanged:
            *static_cast<UInt32*>(data) = 0;
            *dataUsed = sizeof(UInt32);
            break;
        case kCMIODevicePropertyDeviceIsRunning:
            *static_cast<UInt32*>(data) = 1;
            *dataUsed = sizeof(UInt32);
            break;
        case kCMIODevicePropertyDeviceIsRunningSomewhere:
            *static_cast<UInt32*>(data) = 1;
            *dataUsed = sizeof(UInt32);
            break;
        case kCMIODevicePropertyDeviceCanBeDefaultDevice:
            *static_cast<UInt32*>(data) = 1;
            *dataUsed = sizeof(UInt32);
            break;
        case kCMIODevicePropertyHogMode:
            *static_cast<pid_t*>(data) = -1;
            *dataUsed = sizeof(pid_t);
            break;
        case kCMIODevicePropertyLatency:
            *static_cast<UInt32*>(data) = 0;
            *dataUsed = sizeof(UInt32);
            break;
        case kCMIODevicePropertyStreams:
            *static_cast<CMIOObjectID*>(data) = self.streamId;
            *dataUsed = sizeof(CMIOObjectID);
            break;
        case kCMIODevicePropertyStreamConfiguration:
            DLog(@"TODO kCMIODevicePropertyStreamConfiguration");
            break;
        case kCMIODevicePropertyExcludeNonDALAccess:
            *static_cast<UInt32*>(data) = self.excludeNonDALAccess ? 1 : 0;
            *dataUsed = sizeof(UInt32);
            break;
        case kCMIODevicePropertyCanProcessAVCCommand:
            *static_cast<Boolean*>(data) = false;
            *dataUsed = sizeof(Boolean);
            break;
        case kCMIODevicePropertyCanProcessRS422Command:
            *static_cast<Boolean*>(data) = false;
            *dataUsed = sizeof(Boolean);
            break;
        case kCMIODevicePropertyDeviceMaster:
            *static_cast<pid_t*>(data) = self.masterPid;
            *dataUsed = sizeof(pid_t);
            break;
        default:
            DLog(@"Device unhandled getPropertyDataWithAddress for %@", [ObjectStore StringFromPropertySelector:address.mSelector]);
            *dataUsed = 0;
            break;
    };
}

- (BOOL)hasPropertyWithAddress:(CMIOObjectPropertyAddress)address {
    switch (address.mSelector) {
        case kCMIOObjectPropertyName:
        case kCMIOObjectPropertyManufacturer:
        case kCMIOObjectPropertyElementCategoryName:
        case kCMIOObjectPropertyElementNumberName:
        case kCMIODevicePropertyPlugIn:
        case kCMIODevicePropertyDeviceUID:
        case kCMIODevicePropertyModelUID:
        case kCMIODevicePropertyTransportType:
        case kCMIODevicePropertyDeviceIsAlive:
        case kCMIODevicePropertyDeviceHasChanged:
        case kCMIODevicePropertyDeviceIsRunning:
        case kCMIODevicePropertyDeviceIsRunningSomewhere:
        case kCMIODevicePropertyDeviceCanBeDefaultDevice:
        case kCMIODevicePropertyHogMode:
        case kCMIODevicePropertyLatency:
        case kCMIODevicePropertyStreams:
        case kCMIODevicePropertyExcludeNonDALAccess:
        case kCMIODevicePropertyCanProcessAVCCommand:
        case kCMIODevicePropertyCanProcessRS422Command:
        case kCMIODevicePropertyDeviceMaster:
            return true;
        case kCMIODevicePropertyStreamConfiguration:
        case kCMIODevicePropertyLinkedCoreAudioDeviceUID:
            return false;
        default:
            DLog(@"Device unhandled hasPropertyWithAddress for %@", [ObjectStore StringFromPropertySelector:address.mSelector]);
            return false;
    };
}

- (BOOL)isPropertySettableWithAddress:(CMIOObjectPropertyAddress)address {
    switch (address.mSelector) {
        case kCMIOObjectPropertyName:
        case kCMIOObjectPropertyManufacturer:
        case kCMIOObjectPropertyElementCategoryName:
        case kCMIOObjectPropertyElementNumberName:
        case kCMIODevicePropertyPlugIn:
        case kCMIODevicePropertyDeviceUID:
        case kCMIODevicePropertyModelUID:
        case kCMIODevicePropertyTransportType:
        case kCMIODevicePropertyDeviceIsAlive:
        case kCMIODevicePropertyDeviceHasChanged:
        case kCMIODevicePropertyDeviceIsRunning:
        case kCMIODevicePropertyDeviceIsRunningSomewhere:
        case kCMIODevicePropertyDeviceCanBeDefaultDevice:
        case kCMIODevicePropertyHogMode:
        case kCMIODevicePropertyLatency:
        case kCMIODevicePropertyStreams:
        case kCMIODevicePropertyStreamConfiguration:
        case kCMIODevicePropertyCanProcessAVCCommand:
        case kCMIODevicePropertyCanProcessRS422Command:
        case kCMIODevicePropertyLinkedCoreAudioDeviceUID:
            return false;
        case kCMIODevicePropertyExcludeNonDALAccess:
        case kCMIODevicePropertyDeviceMaster:
            return true;
        default:
            DLog(@"Device unhandled isPropertySettableWithAddress for %@", [ObjectStore StringFromPropertySelector:address.mSelector]);
            return false;
    };
}

- (void)setPropertyDataWithAddress:(CMIOObjectPropertyAddress)address qualifierDataSize:(UInt32)qualifierDataSize qualifierData:(nonnull const void *)qualifierData dataSize:(UInt32)dataSize data:(nonnull const void *)data {

    switch (address.mSelector) {
        case kCMIODevicePropertyExcludeNonDALAccess:
            self.excludeNonDALAccess = (*static_cast<const UInt32*>(data) != 0);
            break;
        case kCMIODevicePropertyDeviceMaster:
            self.masterPid = *static_cast<const pid_t*>(data);
            break;
        default:
            DLog(@"Device unhandled setPropertyDataWithAddress for %@", [ObjectStore StringFromPropertySelector:address.mSelector]);
            break;
    };
}

@end
