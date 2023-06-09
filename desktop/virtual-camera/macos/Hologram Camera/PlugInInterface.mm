//
//  PlugInInterface.mm
//  CMIOMinimalSample
//
//  This file implements the CMIO DAL plugin interface
//
//  Created by John Boiles  on 4/9/20.
//
//  CMIOMinimalSample is free software, and use is bound by the terms
//  set out in the LICENSE file distributed with this project.

#import "PlugInInterface.h"

#import <CoreFoundation/CFUUID.h>

#import "PlugIn.h"
#import "Device.h"
#import "Stream.h"
#import "Logging.h"

#pragma mark Plug-In Operations

static UInt32 sRefCount = 0;

ULONG HardwarePlugIn_AddRef(CMIOHardwarePlugInRef self) {
    sRefCount += 1;
    DLogFunc(@"sRefCount now = %d", sRefCount);
    return sRefCount;
}

ULONG HardwarePlugIn_Release(CMIOHardwarePlugInRef self) {
    sRefCount -= 1;
    DLogFunc(@"sRefCount now = %d", sRefCount);
    return sRefCount;
}

HRESULT HardwarePlugIn_QueryInterface(CMIOHardwarePlugInRef self, REFIID uuid, LPVOID* interface) {
    DLogFunc(@"");

    if (!interface) {
        DLogFunc(@"Received an empty interface");
        return E_POINTER;
    }

    // Set the returned interface to NULL in case the UUIDs don't match
    *interface = NULL;

    // Create a CoreFoundation UUIDRef for the requested interface.
    CFUUIDRef cfUuid = CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, uuid);
    CFStringRef uuidString = CFUUIDCreateString(NULL, cfUuid);
    CFStringRef hardwarePluginUuid = CFUUIDCreateString(NULL, kCMIOHardwarePlugInInterfaceID);

    if (CFEqual(uuidString, hardwarePluginUuid)) {
        // Return the interface;
        sRefCount += 1;
        *interface = PlugInRef();
        return kCMIOHardwareNoError;
    } else {
        DLogFunc(@"ERR Queried for some weird UUID %@", uuidString);
    }

    return E_NOINTERFACE;
}

// I think this is deprecated, seems that HardwarePlugIn_InitializeWithObjectID gets called instead
OSStatus HardwarePlugIn_Initialize(CMIOHardwarePlugInRef self) {
    DLogFunc(@"ERR self=%p", self);
    return kCMIOHardwareUnspecifiedError;
}

OSStatus HardwarePlugIn_InitializeWithObjectID(CMIOHardwarePlugInRef self, CMIOObjectID objectID) {
    DLogFunc(@"self=%p", self);

    OSStatus error = kCMIOHardwareNoError;

    PlugIn *plugIn = [PlugIn SharedPlugIn];
    plugIn.objectId = objectID;
    [[ObjectStore SharedObjectStore] setObject:plugIn forObjectId:objectID];

    Device *device = [[Device alloc] init];
    CMIOObjectID deviceId;
    error = CMIOObjectCreate(PlugInRef(), kCMIOObjectSystemObject, kCMIODeviceClassID, &deviceId);
    if (error != noErr) {
        DLog(@"CMIOObjectCreate Error %d", error);
        return error;
    }
    device.objectId = deviceId;
    device.pluginId = objectID;
    [[ObjectStore SharedObjectStore] setObject:device forObjectId:deviceId];

    Stream *stream = [[Stream alloc] init];
    CMIOObjectID streamId;
    error = CMIOObjectCreate(PlugInRef(), deviceId, kCMIOStreamClassID, &streamId);
    if (error != noErr) {
        DLog(@"CMIOObjectCreate Error %d", error);
        return error;
    }
    stream.objectId = streamId;
    [[ObjectStore SharedObjectStore] setObject:stream forObjectId:streamId];
    device.streamId = streamId;

    // Tell the system about the Device
    error = CMIOObjectsPublishedAndDied(PlugInRef(), kCMIOObjectSystemObject, 1, &deviceId, 0, 0);
    if (error != kCMIOHardwareNoError) {
        DLog(@"CMIOObjectsPublishedAndDied plugin/device Error %d", error);
        return error;
    }

    // Tell the system about the Stream
    error = CMIOObjectsPublishedAndDied(PlugInRef(), deviceId, 1, &streamId, 0, 0);
    if (error != kCMIOHardwareNoError) {
        DLog(@"CMIOObjectsPublishedAndDied device/stream Error %d", error);
        return error;
    }

    return error;
}

OSStatus HardwarePlugIn_Teardown(CMIOHardwarePlugInRef self) {
    DLogFunc(@"self=%p", self);

    OSStatus error = kCMIOHardwareNoError;

    PlugIn *plugIn = [PlugIn SharedPlugIn];
    [plugIn teardown];

    return error;
}

#pragma mark CMIOObject Operations

void HardwarePlugIn_ObjectShow(CMIOHardwarePlugInRef self, CMIOObjectID objectID) {
    DLogFunc(@"self=%p", self);
}

Boolean  HardwarePlugIn_ObjectHasProperty(CMIOHardwarePlugInRef self, CMIOObjectID objectID, const CMIOObjectPropertyAddress* address) {

    NSObject<CMIOObject> *object = [ObjectStore GetObjectWithId:objectID];

    if (object == nil) {
        DLogFunc(@"ERR nil object");
        return false;
    }

    Boolean answer = [object hasPropertyWithAddress:*address];

    // DLogFunc(@"%@(%d) %@ self=%p hasProperty=%d", NSStringFromClass([object class]), objectID, [ObjectStore StringFromPropertySelector:address->mSelector], self, answer);

    return answer;
}

OSStatus HardwarePlugIn_ObjectIsPropertySettable(CMIOHardwarePlugInRef self, CMIOObjectID objectID, const CMIOObjectPropertyAddress* address, Boolean* isSettable) {

    NSObject<CMIOObject> *object = [ObjectStore GetObjectWithId:objectID];

    if (object == nil) {
        DLogFunc(@"ERR nil object");
        return kCMIOHardwareBadObjectError;
    }

    *isSettable = [object isPropertySettableWithAddress:*address];

    // DLogFunc(@"%@(%d) %@ self=%p settable=%d", NSStringFromClass([object class]), objectID, [ObjectStore StringFromPropertySelector:address->mSelector], self, *isSettable);

    return kCMIOHardwareNoError;
}

OSStatus HardwarePlugIn_ObjectGetPropertyDataSize(CMIOHardwarePlugInRef self, CMIOObjectID objectID, const CMIOObjectPropertyAddress* address, UInt32 qualifierDataSize, const void* qualifierData, UInt32* dataSize) {

    NSObject<CMIOObject> *object = [ObjectStore GetObjectWithId:objectID];
    
    if (object == nil) {
        DLogFunc(@"ERR nil object");
        return kCMIOHardwareBadObjectError;
    }

    *dataSize = [object getPropertyDataSizeWithAddress:*address qualifierDataSize:qualifierDataSize qualifierData:qualifierData];

    // DLogFunc(@"%@(%d) %@ self=%p size=%d", NSStringFromClass([object class]), objectID, [ObjectStore StringFromPropertySelector:address->mSelector], self, *dataSize);

    return kCMIOHardwareNoError;
}

OSStatus HardwarePlugIn_ObjectGetPropertyData(CMIOHardwarePlugInRef self, CMIOObjectID objectID, const CMIOObjectPropertyAddress* address, UInt32 qualifierDataSize, const void* qualifierData, UInt32 dataSize, UInt32* dataUsed, void* data) {

    NSObject<CMIOObject> *object = [ObjectStore GetObjectWithId:objectID];

    if (object == nil) {
        DLogFunc(@"ERR nil object");
        return kCMIOHardwareBadObjectError;
    }

    [object getPropertyDataWithAddress:*address qualifierDataSize:qualifierDataSize qualifierData:qualifierData dataSize:dataSize dataUsed:dataUsed data:data];

//    if ([ObjectStore IsBridgedTypeForSelector:address->mSelector]) {
//        id dataObj = (__bridge NSObject *)*static_cast<CFTypeRef*>(data);
//        // DLogFunc(@"%@(%d) %@ self=%p data(id)=%@", NSStringFromClass([object class]), objectID, [ObjectStore StringFromPropertySelector:address->mSelector], self, dataObj);
//    } else {
//        UInt32 *dataInt = (UInt32 *)data;
//        // DLogFunc(@"%@(%d) %@ self=%p data(int)=%d", NSStringFromClass([object class]), objectID, [ObjectStore StringFromPropertySelector:address->mSelector], self, *dataInt);
//    }

    return kCMIOHardwareNoError;
}

OSStatus HardwarePlugIn_ObjectSetPropertyData(CMIOHardwarePlugInRef self, CMIOObjectID objectID, const CMIOObjectPropertyAddress* address, UInt32 qualifierDataSize, const void* qualifierData, UInt32 dataSize, const void* data) {

    NSObject<CMIOObject> *object = [ObjectStore GetObjectWithId:objectID];

    if (object == nil) {
        DLogFunc(@"ERR nil object");
        return kCMIOHardwareBadObjectError;
    }

    UInt32 *dataInt = (UInt32 *)data;
    DLogFunc(@"%@(%d) %@ self=%p data(int)=%d", NSStringFromClass([object class]), objectID, [ObjectStore StringFromPropertySelector:address->mSelector], self, *dataInt);

    [object setPropertyDataWithAddress:*address qualifierDataSize:qualifierDataSize qualifierData:qualifierData dataSize:dataSize data:data];

    return kCMIOHardwareNoError;
}

#pragma mark CMIOStream Operations
OSStatus HardwarePlugIn_StreamCopyBufferQueue(CMIOHardwarePlugInRef self, CMIOStreamID streamID, CMIODeviceStreamQueueAlteredProc queueAlteredProc, void* queueAlteredRefCon, CMSimpleQueueRef* queue) {

    Stream *stream = (Stream *)[ObjectStore GetObjectWithId:streamID];

    if (stream == nil) {
        DLogFunc(@"ERR nil object");
        return kCMIOHardwareBadObjectError;
    }

    *queue = [stream copyBufferQueueWithAlteredProc:queueAlteredProc alteredRefCon:queueAlteredRefCon];

    DLogFunc(@"%@ (id=%d) self=%p queue=%@", stream, streamID, self, (__bridge NSObject *)*queue);

    return kCMIOHardwareNoError;
}

#pragma mark CMIODevice Operations
OSStatus HardwarePlugIn_DeviceStartStream(CMIOHardwarePlugInRef self, CMIODeviceID deviceID, CMIOStreamID streamID) {
    DLogFunc(@"self=%p device=%d stream=%d", self, deviceID, streamID);

    Stream *stream = (Stream *)[ObjectStore GetObjectWithId:streamID];

    if (stream == nil) {
        DLogFunc(@"ERR nil object");
        return kCMIOHardwareBadObjectError;
    }

    [stream startServingFrames];

    return kCMIOHardwareNoError;
}

OSStatus HardwarePlugIn_DeviceSuspend(CMIOHardwarePlugInRef self, CMIODeviceID deviceID) {
    DLogFunc(@"self=%p", self);
    return kCMIOHardwareNoError;
}

OSStatus HardwarePlugIn_DeviceResume(CMIOHardwarePlugInRef self, CMIODeviceID deviceID) {
    DLogFunc(@"self=%p", self);
    return kCMIOHardwareNoError;
}

OSStatus HardwarePlugIn_DeviceStopStream(CMIOHardwarePlugInRef self, CMIODeviceID deviceID, CMIOStreamID streamID) {
    DLogFunc(@"self=%p device=%d stream=%d", self, deviceID, streamID);

    Stream *stream = (Stream *)[ObjectStore GetObjectWithId:streamID];

    if (stream == nil) {
        DLogFunc(@"ERR nil object");
        return kCMIOHardwareBadObjectError;
    }

    [stream stopServingFrames];

    return kCMIOHardwareNoError;
}

OSStatus HardwarePlugIn_DeviceProcessAVCCommand(CMIOHardwarePlugInRef self, CMIODeviceID deviceID, CMIODeviceAVCCommand* ioAVCCommand) {
    DLogFunc(@"self=%p", self);
    return kCMIOHardwareNoError;
}

OSStatus HardwarePlugIn_DeviceProcessRS422Command(CMIOHardwarePlugInRef self, CMIODeviceID deviceID, CMIODeviceRS422Command* ioRS422Command) {
    DLogFunc(@"self=%p", self);
    return kCMIOHardwareNoError;
}

OSStatus HardwarePlugIn_StreamDeckPlay(CMIOHardwarePlugInRef self, CMIOStreamID streamID) {
    DLogFunc(@"self=%p", self);
    return kCMIOHardwareIllegalOperationError;
}

OSStatus HardwarePlugIn_StreamDeckStop(CMIOHardwarePlugInRef self,CMIOStreamID streamID) {
    DLogFunc(@"self=%p", self);
    return kCMIOHardwareIllegalOperationError;
}

OSStatus HardwarePlugIn_StreamDeckJog(CMIOHardwarePlugInRef self, CMIOStreamID streamID, SInt32 speed) {
    DLogFunc(@"self=%p", self);
    return kCMIOHardwareIllegalOperationError;
}

OSStatus HardwarePlugIn_StreamDeckCueTo(CMIOHardwarePlugInRef self, CMIOStreamID streamID, Float64 requestedTimecode, Boolean playOnCue) {
    DLogFunc(@"self=%p", self);
    return kCMIOHardwareIllegalOperationError;
}

static CMIOHardwarePlugInInterface sInterface = {
    // Padding for COM
    NULL,
    
    // IUnknown Routines
    (HRESULT (*)(void*, CFUUIDBytes, void**))HardwarePlugIn_QueryInterface,
    (ULONG (*)(void*))HardwarePlugIn_AddRef,
    (ULONG (*)(void*))HardwarePlugIn_Release,

    // DAL Plug-In Routines
    HardwarePlugIn_Initialize,
    HardwarePlugIn_InitializeWithObjectID,
    HardwarePlugIn_Teardown,
    HardwarePlugIn_ObjectShow,
    HardwarePlugIn_ObjectHasProperty,
    HardwarePlugIn_ObjectIsPropertySettable,
    HardwarePlugIn_ObjectGetPropertyDataSize,
    HardwarePlugIn_ObjectGetPropertyData,
    HardwarePlugIn_ObjectSetPropertyData,
    HardwarePlugIn_DeviceSuspend,
    HardwarePlugIn_DeviceResume,
    HardwarePlugIn_DeviceStartStream,
    HardwarePlugIn_DeviceStopStream,
    HardwarePlugIn_DeviceProcessAVCCommand,
    HardwarePlugIn_DeviceProcessRS422Command,
    HardwarePlugIn_StreamCopyBufferQueue,
    HardwarePlugIn_StreamDeckPlay,
    HardwarePlugIn_StreamDeckStop,
    HardwarePlugIn_StreamDeckJog,
    HardwarePlugIn_StreamDeckCueTo
};

static CMIOHardwarePlugInInterface* sInterfacePtr = &sInterface;
static CMIOHardwarePlugInRef sPlugInRef = &sInterfacePtr;

CMIOHardwarePlugInRef PlugInRef() {
    return sPlugInRef;
}
