/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#import "TiFile.h"

@interface TiFilesystemFileProxy : TiFile {
@private
	NSFileManager *fm;
}

-(id)initWithFile:(NSString*)path;

+(id)makeTemp:(BOOL)isDirectory;

@property(nonatomic,readonly) id name;
@property(nonatomic,readonly) id nativePath;
@property(nonatomic,readonly) id readonly;
@property(nonatomic,readonly) id writable;
@property(nonatomic,readonly) id symbolicLink;
@property(nonatomic,readonly) id executable;
@property(nonatomic,readonly) id hidden;



@end
