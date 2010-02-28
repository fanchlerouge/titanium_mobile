/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "NetworkModule.h"
#import "Reachability.h"
#import "TitaniumApp.h"
#import "SBJSON.h"

@implementation NetworkModule

-(void)startReachability
{
	NSAssert([NSThread currentThread],@"not on the main thread for startReachability");
	// reachability runs on the current run loop so we need to make sure we're
	// on the main UI thread
	reachability = [[Reachability reachabilityForInternetConnection] retain];
	[reachability startNotifer];
	[self updateReachabilityStatus];
}

-(void)stopReachability
{
	NSAssert([NSThread currentThread],@"not on the main thread for stopReachability");
	[reachability stopNotifer];
	RELEASE_TO_NIL(reachability);
}

-(void)_configure
{
	[super _configure];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
	[self performSelectorOnMainThread:@selector(startReachability) withObject:nil waitUntilDone:NO];
}

-(void)_destroy
{
	[self performSelectorOnMainThread:@selector(stopReachability) withObject:nil waitUntilDone:NO];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
	RELEASE_TO_NIL(pushNotificationCallback);
	RELEASE_TO_NIL(pushNotificationError);
	RELEASE_TO_NIL(pushNotificationSuccess);
	[super _destroy];
}

-(void)updateReachabilityStatus
{
	NetworkStatus status = [reachability currentReachabilityStatus];
	switch(status)
	{
		case NotReachable:
		{
			state = TiNetworkConnectionStateNone;
			break;
		}
		case ReachableViaWiFi:
		{
			state = TiNetworkConnectionStateWifi;
			break;
		}
		case ReachableViaWWAN:
		{
			state = TiNetworkConnectionStateMobile;
			break;
		}
		default:
		{
			state = TiNetworkConnectionStateUnknown;
			break;
		}
	}
	if ([self _hasListeners:@"change"])
	{
		NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
							   [self networkType], @"networkType",
							   [self online], @"online",
							   [self networkTypeName], @"networkTypeName",
							   nil];
		[self fireEvent:@"change" withObject:event];
	}
}

-(void)reachabilityChanged:(NSNotification*)note
{
	[self updateReachabilityStatus];
}

-(id)encodeURIComponent:(id)args
{
	id arg = [args objectAtIndex:0];
	NSString *unencodedString = [TiUtils stringValue:arg];
	return [(NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
								(CFStringRef)unencodedString,
								NULL,
								(CFStringRef)@"!*'();:@+$,/?%#[]=", 
								kCFStringEncodingUTF8) autorelease];
}

-(id)decodeURIComponent:(id)args
{
	id arg = [args objectAtIndex:0];
	NSString *encodedString = [TiUtils stringValue:arg];
	return [(NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (CFStringRef)encodedString, CFSTR(""), kCFStringEncodingUTF8) autorelease];
}

-(void)addConnectivityListener:(id)args
{
	id arg = [args objectAtIndex:0];
	ENSURE_TYPE(arg,KrollCallback);
	NSArray *newargs = [NSArray arrayWithObjects:@"change",arg,nil];
	[self addEventListener:newargs];
}

-(void)removeConnectivityListener:(id)args
{
	id arg = [args objectAtIndex:0];
	ENSURE_TYPE(arg,KrollCallback);
	NSArray *newargs = [NSArray arrayWithObjects:@"change",arg,nil];
	[self removeEventListener:newargs];
}

- (NSString*) remoteDeviceUUID
{
	return [[TitaniumApp app] remoteDeviceUUID];
}

- (NSNumber*)online
{
	if (state!=TiNetworkConnectionStateNone && state!=TiNetworkConnectionStateUnknown)
	{
		return NUMBOOL(YES);
	}
	return NUMBOOL(NO);
}

- (NSString*)networkTypeName
{
	switch(state)
	{
		case TiNetworkConnectionStateNone:
			return @"NONE";
		case TiNetworkConnectionStateWifi:
			return @"WIFI";
		case TiNetworkConnectionStateLan:
			return @"LAN";
		case TiNetworkConnectionStateMobile:
			return @"MOBILE";
	}
	return @"UNKNOWN";
}

-(NSNumber*)networkType
{
	return NUMINT(state);
}

MAKE_SYSTEM_PROP(NETWORK_NONE,TiNetworkConnectionStateNone);
MAKE_SYSTEM_PROP(NETWORK_WIFI,TiNetworkConnectionStateWifi);
MAKE_SYSTEM_PROP(NETWORK_MOBILE,TiNetworkConnectionStateMobile);
MAKE_SYSTEM_PROP(NETWORK_LAN,TiNetworkConnectionStateLan);
MAKE_SYSTEM_PROP(NETWORK_UNKNOWN,TiNetworkConnectionStateUnknown);

MAKE_SYSTEM_PROP(NOTIFICATION_TYPE_BADGE,1);
MAKE_SYSTEM_PROP(NOTIFICATION_TYPE_ALERT,2);
MAKE_SYSTEM_PROP(NOTIFICATION_TYPE_SOUND,3);

#pragma mark Push Notifications 

-(void)registerForPushNotifications:(id)args
{
	ENSURE_SINGLE_ARG(args,NSDictionary);
	
	//TODO: remoteNotification
	//TODO: handle if already registered
	
	UIApplication * app = [UIApplication sharedApplication];
	UIRemoteNotificationType ourNotifications = [app enabledRemoteNotificationTypes];
	
	NSArray *typesRequested = [args objectForKey:@"types"];
	
	RELEASE_TO_NIL(pushNotificationCallback);
	RELEASE_TO_NIL(pushNotificationError);
	RELEASE_TO_NIL(pushNotificationSuccess);
	
	pushNotificationSuccess = [[args objectForKey:@"success"] retain];
	pushNotificationError = [[args objectForKey:@"error"] retain];
	pushNotificationCallback = [[args objectForKey:@"callback"] retain];
	
	if (typesRequested!=nil)
	{
		for (id thisTypeRequested in typesRequested) 
		{
			NSInteger value = [TiUtils intValue:thisTypeRequested];
			switch(value)
			{
				case 1: //NOTIFICATION_TYPE_BADGE
				{
					ourNotifications |= UIRemoteNotificationTypeBadge;
					break;
				}
				case 2: //NOTIFICATION_TYPE_ALERT
				{
					ourNotifications |= UIRemoteNotificationTypeAlert;
					break;
				}
				case 3: //NOTIFICATION_TYPE_SOUND
				{
					ourNotifications |= UIRemoteNotificationTypeSound;
					break;
				}
			}
		}
	}
	
	[[TitaniumApp app] setRemoteNotificationDelegate:self];
	[app registerForRemoteNotificationTypes:ourNotifications];
}

-(void)unregisterForPushNotifications:(id)args
{
	UIApplication * app = [UIApplication sharedApplication];
	[app unregisterForRemoteNotifications];
}

#pragma mark Push Notification Delegates

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
	// called by TitaniumApp
	if (pushNotificationSuccess!=nil)
	{
		NSString *token = [[TitaniumApp app] remoteDeviceUUID];
		NSDictionary *event = [NSDictionary dictionaryWithObject:token forKey:@"deviceToken"];
		[self _fireEventToListener:@"remote" withObject:event listener:pushNotificationSuccess thisObject:nil];
	}
	
	//TODO: fire register
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
	// called by TitaniumApp
	if (pushNotificationCallback!=nil)
	{
		id event = [NSDictionary dictionaryWithObject:[SBJSON stringify:userInfo] forKey:@"data"];
		[self _fireEventToListener:@"remote" withObject:event listener:pushNotificationCallback thisObject:nil];
	}
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
	// called by TitaniumApp
	if (pushNotificationError!=nil)
	{
		NSDictionary *event = [NSDictionary dictionaryWithObject:[error description] forKey:@"error"];
		[self _fireEventToListener:@"remote" withObject:event listener:pushNotificationError thisObject:nil];
	}
}

@end
