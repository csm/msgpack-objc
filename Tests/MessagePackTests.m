//
//  Tests.m
//  Tests
//
//  Created by Joel Ekström on 2017-11-06.
//  Copyright © 2017 FootballAddicts AB. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MessagePack.h"

#pragma mark - MessagePackSerializable object

@interface Person : NSObject <NSSecureCoding, MessagePackSerializable>

@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *secondName;

@end

@implementation Person

- (instancetype)initWithMessagePackData:(NSData *)data extensionType:(int8_t)type
{
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

- (NSData *)messagePackData
{
    return [NSKeyedArchiver archivedDataWithRootObject:self];
}

- (instancetype)initWithFirstName:(NSString *)firstName andSecondName:(NSString *)secondName
{
    self = [super init];
    if (self) {
        self.firstName = firstName;
        self.secondName = secondName;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.firstName = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(firstName))];
        self.secondName = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(secondName))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.firstName forKey:NSStringFromSelector(@selector(firstName))];
    [aCoder encodeObject:self.secondName forKey:NSStringFromSelector(@selector(secondName))];
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (BOOL)isEqual:(id)object
{
    if (object == self) {
        return YES;
    }
    
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    Person *person = (Person *)object;
    return [self.firstName isEqual:person.firstName]
    && [self.secondName isEqual:person.secondName];
}

- (NSUInteger)hash
{
    return [self.firstName hash] ^ [self.secondName hash];
}

@end

#pragma mark - Unit tests

@interface MessagePackTests : XCTestCase

@end

@implementation MessagePackTests

- (void)testJSONUnpackPerformance {
    NSString *path = [[NSBundle bundleForClass:self.class] pathForResource:@"testdata" ofType:@"json" inDirectory:nil];
    NSData *JSONData = [NSData dataWithContentsOfFile:path];
    [self measureBlock:^{
        [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:nil];
    }];
}

- (void)testMessagePackUnpackPerformance {
    NSString *path = [[NSBundle bundleForClass:self.class] pathForResource:@"testdata" ofType:@"msgpack" inDirectory:nil];
    NSData *messagePackData = [NSData dataWithContentsOfFile:path];
    [self measureBlock:^{
        [MessagePack unpackData:messagePackData];
    }];
}

- (void)testStringPacking {
    NSString *testString = @"A string with ovänliga karaktärer 🙈";
    NSData *packed = [MessagePack packObject:testString];
    NSString *unpacked = [MessagePack unpackData:packed];
    XCTAssertEqualObjects(testString, unpacked);
}

- (void)testNumberPacking {
    NSNumber *anInt = [NSNumber numberWithInt:64];
    NSNumber *aFloat = [NSNumber numberWithFloat:10.5];
    NSNumber *aDouble = [NSNumber numberWithDouble:100.1];
    NSNumber *aChar = [NSNumber numberWithChar:8];
    NSNumber *aBool = @YES;
    NSArray *numbers = @[anInt, aFloat, aDouble, aChar, aBool];
    NSData *packed = [MessagePack packObject:numbers];
    NSArray *unpacked = [MessagePack unpackData:packed];
    XCTAssertEqualObjects(numbers, unpacked);
    XCTAssertEqual(unpacked[4], @YES);
}

- (void)testDictionaryPacking {
    NSDictionary *dictionary = @{@"an array": @[@1, @2, @YES, @"hello"],
                                 @"a number": @41241,
                                 @"another dictionary": @{@"a": @1, @"b": @"yes, hello"},
                                 @"a string": @"yes, yes"};
    NSData *packed = [MessagePack packObject:dictionary];
    NSDictionary *unpacked = [MessagePack unpackData:packed];
    XCTAssertEqualObjects(dictionary, unpacked);
}

- (void)testExtension {
    Person *person = [[Person alloc] initWithFirstName:@"John" andSecondName:@"Doe"];
    [MessagePack registerClass:Person.class forExtensionType:14];
    NSData *packedData = [MessagePack packObject:person];
    id unpackedObject = [MessagePack unpackData:packedData];
    XCTAssertEqualObjects(person, unpackedObject);
}

- (void)testDatePacking {
    NSArray *testDates = @[[NSDate dateWithTimeIntervalSince1970:1000000],             // 32-bit
                           [NSDate dateWithTimeIntervalSince1970:1500000.12345],       // 64-bit
                           [NSDate dateWithTimeIntervalSince1970:2147483647.1234578],  // 96-bit
                           [NSDate dateWithTimeIntervalSince1970:-1.5],                // Negative dates are always 96-bit in MessagePack
                           [NSDate dateWithTimeIntervalSince1970:-1.001],
                           [NSDate dateWithTimeIntervalSince1970:-10000.999],
                           [NSDate dateWithTimeIntervalSince1970:-0.0001],
                           [NSDate dateWithTimeIntervalSince1970:-0.9999],
                           [NSDate dateWithTimeIntervalSince1970:0.00001],
                           [NSDate distantFuture],
                           [NSDate distantFuture],
                           [NSDate new]];


    NSData *messagePackDates = [MessagePack packObject:testDates];
    NSArray *unpackedDates = [MessagePack unpackData:messagePackDates];

    for (int i = 0; i < testDates.count; ++i) {
        XCTAssertEqual([testDates[i] timeIntervalSince1970], [unpackedDates[i] timeIntervalSince1970]);
    }
}

- (void)testNull {
    // minimal example, array with a single null
    NSData *data = [[NSData alloc] initWithBase64EncodedString: @"kcA=" options: 0];
    NSObject *unpacked = [MessagePack unpackData: data];
    XCTAssertNotNil(unpacked);
    XCTAssertTrue([unpacked isKindOfClass: [NSArray class]]);
    XCTAssertEqual(1, [((NSArray *) unpacked) count]);
    XCTAssertTrue([[((NSArray *) unpacked) objectAtIndex: 0] isKindOfClass: [NSNull class]]);
}

@end
