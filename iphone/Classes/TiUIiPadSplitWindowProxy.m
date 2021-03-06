/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiUIiPadSplitWindowProxy.h"
#import "TiUIiPadSplitWindowView.h"
#import "TiUtils.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_2


@implementation TiUIiPadSplitWindowProxy

-(TiUIView*)newView
{
	return [[TiUIiPadSplitWindowView alloc] init];
}

-(UIViewController *)controller
{
	if ([controller isKindOfClass:[UISplitViewController class]])
	{
		return controller;
	}
	TiUIiPadSplitWindowView *view = (TiUIiPadSplitWindowView*)[self view];
	UIViewController *c = [view controller];
	self.controller = c;
	return c;
}

-(void)windowDidClose
{
	//TODO: reattach the root controller?
	[super windowDidClose];
}

-(void)setToolbar:(id)items withObject:(id)properties
{
	ENSURE_UI_THREAD_WITH_OBJ(setToolbar,items,properties);
	[(TiUIiPadSplitWindowView*)[self view] setToolbar:items withObject:properties];
}

@end

#endif
