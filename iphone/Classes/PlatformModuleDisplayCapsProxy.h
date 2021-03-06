/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiProxy.h"


@interface PlatformModuleDisplayCapsProxy : TiProxy {

}

@property(nonatomic,readonly) NSNumber* platformHeight;
@property(nonatomic,readonly) NSNumber* platformWidth;
@property(nonatomic,readonly) NSNumber* density;
@property(nonatomic,readonly) NSString* dpi;

@end
