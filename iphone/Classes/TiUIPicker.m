/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiUIPicker.h"
#import "TiUtils.h"
#import "TiUIPickerRowProxy.h"
#import "TiUIPickerColumnProxy.h"

#define DEFAULT_ROW_HEIGHT 40
#define DEFAULT_COLUMN_PADDING 30

@implementation TiUIPicker

#pragma mark Internal

-(void)dealloc
{
	RELEASE_TO_NIL(picker);
	[super dealloc];
}

USE_PROXY_FOR_VERIFY_AUTORESIZING

-(CGFloat)verifyHeight:(CGFloat)suggestedHeight
{
	// pickers have a forced height so we use it's height
	// instead of letting the user set it
	return picker.frame.size.height;
}

-(UIControl*)picker 
{
	if (picker==nil)
	{
		if (type == -1)
		{
			picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, 2000, 228)];
			((UIPickerView*)picker).delegate = self;
			((UIPickerView*)picker).dataSource = self;
		}
		else 
		{
			picker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, 2000, 228)];
			[(UIDatePicker*)picker setDatePickerMode:type];
			[picker addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
		}
		[self addSubview:picker];
	}
	return picker;
}

-(void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
	if (picker!=nil && !CGRectIsEmpty(bounds))
	{
		// on ipad, the height is sent in invalid but on iphone, it's fixed
		// so we need to compensate for that here so that it will be visible
		if (bounds.size.height<6)
		{
			bounds.size.height = 228;
		}
		[TiUtils setView:picker positionRect:bounds];
	}
}

-(BOOL)isDatePicker
{
	return type != -1;
}

#pragma mark Framework 

-(void)reloadColumn:(id)column
{
	ENSURE_SINGLE_ARG(column,TiUIPickerColumnProxy);
	if ([self isDatePicker]==NO)
	{
		[(UIPickerView*)[self picker] reloadComponent:((TiUIPickerColumnProxy*)column).column];
	}
}

-(NSArray*)columns 
{
	return [self.proxy valueForKey:@"columns"];
}

-(TiProxy*)selectedRowForColumn:(NSInteger)column
{
	if ([self isDatePicker])
	{
		//FIXME
		return nil;
	}
	NSInteger row = [(UIPickerView*)picker selectedRowInComponent:column];
	if (row==-1)
	{
		return nil;
	}
	TiUIPickerColumnProxy *columnProxy = [[self columns] objectAtIndex:column];
	return [columnProxy rowAt:row];
}

-(void)selectRowForColumn:(NSInteger)column row:(NSInteger)row animated:(BOOL)animated
{
	if (![self isDatePicker])
	{
		[(UIPickerView*)picker selectRow:row inComponent:column animated:animated];
		[self pickerView:(UIPickerView*)picker didSelectRow:row inComponent:column];
	}
}

-(void)selectRow:(NSArray*)array
{
	NSInteger column = [TiUtils intValue:[array objectAtIndex:0]];
	NSInteger row = [TiUtils intValue:[array objectAtIndex:1]];
	BOOL animated = [array count] > 2 ? [TiUtils boolValue:[array objectAtIndex:2]] : NO;
	[self selectRowForColumn:column row:row animated:animated];
}


#pragma mark Public APIs 

-(void)setType_:(id)type_
{
	NSInteger curtype = type;
	type = [TiUtils intValue:type_];
	id picker_ = [self picker];
	if (curtype!=type && [self isDatePicker])
	{
		[(UIDatePicker*)picker_ setDatePickerMode:type];
	}
}

-(void)setSelectionIndicator_:(id)value
{
	if ([self isDatePicker]==NO)
	{
		[(UIPickerView*)[self picker] setShowsSelectionIndicator:[TiUtils boolValue:value]];
	}
}

-(void)setMinDate_:(id)date
{
	ENSURE_SINGLE_ARG_OR_NIL(date,NSDate);
	if ([self isDatePicker])
	{
		[(UIDatePicker*)[self picker] setMinimumDate:date];
	}
}

-(void)setMaxDate_:(id)date
{
	ENSURE_SINGLE_ARG_OR_NIL(date,NSDate);
	if ([self isDatePicker])
	{
		[(UIDatePicker*)[self picker] setMaximumDate:date];
	}
}

//TODO: minute interval

-(void)setValue_:(id)date
{
	ENSURE_SINGLE_ARG_OR_NIL(date,NSDate);
	if ([self isDatePicker] && date!=nil)
	{
		[(UIDatePicker*)[self picker] setDate:date];
	}
}

-(void)setLocale_:(id)value
{
	ENSURE_SINGLE_ARG_OR_NIL(value,NSString);
	if ([self isDatePicker])
	{
		if (value==nil)
		{
			[(UIDatePicker*)[self picker] setLocale:[NSLocale currentLocale]];
		}
		else
		{
			NSString *identifier = [NSLocale canonicalLocaleIdentifierFromString:value];
			NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:identifier];
			[(UIDatePicker*)[self picker] setLocale:locale];
			[locale release];
		}
	}
}

-(void)setMinuteInterval_:(id)value
{
	ENSURE_SINGLE_ARG(value,NSObject);
	if ([self isDatePicker])
	{
		NSInteger interval = [TiUtils intValue:value];
		[(UIDatePicker*)[self picker] setMinuteInterval:interval];
	}
}

-(void)setCountDownDuration_:(id)value
{
	ENSURE_SINGLE_ARG(value,NSObject);
	if ([self isDatePicker])
	{
		double duration = [TiUtils doubleValue:value] / 1000;
		[(UIDatePicker*)[self picker] setDatePickerMode:UIDatePickerModeCountDownTimer];
		[(UIDatePicker*)[self picker] setCountDownDuration:duration];
	}
}

#pragma mark Datasources

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return [[self columns] count];
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	TiUIPickerColumnProxy *proxy = [[self columns] objectAtIndex:component];
	return [proxy rowCount];
}
			 
			 
#pragma mark Delegates (only for UIPickerView) 


// returns width of column and height of row for each component. 
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
	//TODO: add blain's super duper width algorithm
	
	// first check to determine if this column has a width
	TiUIPickerColumnProxy *proxy = [[self columns] objectAtIndex:component];
	id width = [proxy valueForKey:@"width"];
	if (width != nil)
	{
		return [TiUtils floatValue:width];
	}
	return (self.frame.size.width - DEFAULT_COLUMN_PADDING) / [[self columns] count];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
	TiUIPickerColumnProxy *proxy = [[self columns] objectAtIndex:component];
	id height = [proxy valueForKey:@"height"];
	if (height != nil)
	{
		return [TiUtils floatValue:height];
	}
	return DEFAULT_ROW_HEIGHT;
}

// these methods return either a plain UIString, or a view (e.g UILabel) to display the row for the component.
// for the view versions, we cache any hidden and thus unused views and pass them back for reuse. 
// If you return back a different object, the old one will be released. the view will be centered in the row rect  
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	TiUIPickerColumnProxy *proxy = [[self columns] objectAtIndex:component];
	TiUIPickerRowProxy *rowproxy = [proxy rowAt:row];
	return [rowproxy valueForKey:@"title"];
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
	TiUIPickerColumnProxy *proxy = [[self columns] objectAtIndex:component];
	TiUIPickerRowProxy *rowproxy = [proxy rowAt:row];
	NSString *title = [rowproxy valueForKey:@"title"];
	if (title!=nil)
	{
		UILabel *pickerLabel = (UILabel *)view;
		
		if (pickerLabel == nil) 
		{
			CGRect frame = CGRectMake(0.0, 0.0, [self pickerView:pickerView widthForComponent:component]-20, [self pickerView:pickerView rowHeightForComponent:component]);
			pickerLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
			[pickerLabel setTextAlignment:UITextAlignmentLeft];
			[pickerLabel setBackgroundColor:[UIColor clearColor]];
			
			float fontSize = [TiUtils floatValue:[rowproxy valueForUndefinedKey:@"fontSize"] def:[TiUtils floatValue:[self.proxy valueForUndefinedKey:@"fontSize"] def:18.0]];	
			[pickerLabel setFont:[UIFont boldSystemFontOfSize:fontSize]];
		}
		
		[pickerLabel setText:title];
		return pickerLabel;
	}
	else 
	{
		return [rowproxy view];
	}
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	if ([self.proxy _hasListeners:@"change"])
	{
		TiUIPickerColumnProxy *proxy = [[self columns] objectAtIndex:component];
		TiUIPickerRowProxy *rowproxy = [proxy rowAt:row];
		NSMutableArray *selected = [NSMutableArray array];
		NSInteger colIndex = 0;
		for (TiUIPickerColumnProxy *col in [self columns])
		{
			int rowIndex = row;
			if (component!=colIndex)
			{
				rowIndex = [pickerView selectedRowInComponent:colIndex];
			}
			TiUIPickerRowProxy *rowSelected = [col rowAt:rowIndex];
			NSString *title = [rowSelected valueForUndefinedKey:@"title"];
			// if they have a title, make that the value otherwise use the row proxy
			if (title!=nil)
			{
				[selected addObject:title];
			}
			else 
			{
				[selected addObject:rowSelected];
			}
			colIndex++;
		}
		NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
							   selected,@"selectedValue",
							   NUMINT(row),@"rowIndex",
							   NUMINT(component),@"columnIndex",
							   proxy,@"column",
							   rowproxy,@"row",
							   nil];
		[self.proxy fireEvent:@"change" withObject:event];
	}
}

-(void)valueChanged:(id)sender
{
	if ([self.proxy _hasListeners:@"change"])
	{
		NSDate *date = [(UIDatePicker*)sender date];
		NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:date,@"value",nil];
		[self.proxy replaceValue:date forKey:@"value" notification:NO];
		[self.proxy fireEvent:@"change" withObject:event];
	}
}


@end