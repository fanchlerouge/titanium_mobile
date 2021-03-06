/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#import "TiUIView.h"
#import "TiWindowProxy.h"

@interface TiUIiPhoneNavigationGroup : TiUIView<UINavigationControllerDelegate> {
@private
	UINavigationController *controller;
	TiWindowProxy *root;
	TiWindowProxy *current;
	BOOL opening;
}

@end
