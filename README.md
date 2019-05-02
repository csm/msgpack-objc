# msgpack-objc

[![Build Status](https://travis-ci.org/csm/msgpack-objc.svg?branch=master)](https://travis-ci.org/csm/msgpack-objc)

An Objective-C wrapper for [msgpack-c](https://github.com/msgpack/msgpack-c). Focuses on ease of use and speed. 
If you need configurability, there are other, more advanced libraries, for example [MPMessagePack](https://github.com/gabriel/MPMessagePack).

This library will always try to use sane defaults. <del>If any nil value is encountered in the MessagePack-data, the object will
be omitted instead of returning an `[NSNull null]`. This means that there can be no nil objects in dictionaries, and object-less
keys will be lost in translation.</del>

Unlike the upstream version, this version handles nil values via `NSNull`. `nil` itself is not allowed and is not returned by
this library when it encounters a msgpack null.

### Example usage:
```objc
#import <msgpack-objc/MessagePack.h>

NSDictionary *dictionary = @{@"name": @"msgpack-objc"};

NSData *messagePackData = [MessagePack packObject:dictionary];
NSDictionary *unpackedDictionary = [MessagePack unpackData:messagePackData];
```

### Supported native types:
- `NSArray`
- `NSData`
- `NSDate` (using [MessagePack timestamps](https://github.com/msgpack/msgpack/blob/master/spec.md#timestamp-extension-type))
- `NSDictionary`
- `NSNumber` (`boolean`, `u64`, `i64`, `float32/64`)
- `NSString`
- `NSNull`

## Extension support

The library supports [MessagePack timestamps](https://github.com/msgpack/msgpack/blob/master/spec.md#timestamp-extension-type),
and will return an `NSDate`-object whenever one is encountered. When serializing, any `NSDate`-objects will also be
serialized as native MessagePack timestamps.

You can add native serialization for your own classes by conforming to protocol `MessagePackSerializable` and register it like this:
```c
[MessagePack registerClass:Person.class forExtensionType:14];
```
