//
//  ViewController.m
//  Rokuon_R001
//
//  Created by 寺内 信夫 on 2015/11/11.
//  Copyright © 2015年 寺内 信夫. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	// 近接センサオン
	[UIDevice currentDevice].proximityMonitoringEnabled = YES;
	
	// 近接センサ監視
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(proximitySensorStateDidChange:)
												 name:UIDeviceProximityStateDidChangeNotification
											   object:nil];

	tableView.dataSource = self;
	tableView.delegate = self;
	
	playSounds = [[NSMutableDictionary alloc] init];

	[self resetPlaySounds];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	// 近接センサオフ
	[UIDevice currentDevice].proximityMonitoringEnabled = NO;
	
	// 近接センサ監視解除
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIDeviceProximityStateDidChangeNotification
												  object:nil];
}

- (void)proximitySensorStateDidChange:(NSNotification *)notification
{
	int on_off = [UIDevice currentDevice].proximityState;
	
	switch (on_off) {
			// off
		case 0:
			// Wave Off
			[self stopRecord];
			
			[self resetPlaySounds];

			[tableView reloadData];
			
			[self playRecord];
			
			break;
			
			// on
		case 1:
			// Wave On
			[self recordFile];
			
			break;
	}
}

- (void)resetPlaySounds
{
	NSString *dir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
	
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"]]; // Localeの指定
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	NSError *error;
	NSArray *list = [fileManager contentsOfDirectoryAtPath:dir
													 error:&error];
	
	// ファイルやディレクトリの一覧を表示する
	for (NSString *name in list) {
		NSString *path = [NSString stringWithFormat:@"%@/%@", dir, name];

		url = [NSURL fileURLWithPath:path];

		NSDictionary *attribute = [fileManager attributesOfItemAtPath:path error:nil];
		
		NSDate *creationDate = [attribute objectForKey:NSFileCreationDate];
		NSDate *modificationDate = [attribute objectForKey:NSFileModificationDate];
		NSNumber *fileSize = [attribute objectForKey:NSFileSize];
		
		NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
							  name				, @"name"		,
							  url				, @"url"		,
							  creationDate		, @"cre date"	,
							  modificationDate	, @"mod date"	,
							  fileSize			, @"size"		,
							  nil];
		
		[playSounds setObject:data
					   forKey:name];
	}
	
	playTitles = [playSounds.allKeys sortedArrayUsingComparator:^(id obj1, id obj2) {
		return [obj2 compare:obj1];
	}];
}

- (NSURL*)getURL
{
	// File Path
	NSString *dir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
	
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"]]; // Localeの指定
	[df setDateFormat:@"yyyyMMdd_HHmmss_"];
	
	// 日付(NSDate) => 文字列(NSString)に変換
	NSDate *now = [NSDate date];
	int intMillSec = (int) floor(([now timeIntervalSince1970] - floor([now timeIntervalSince1970]))*1000);
	
	// 日付(NSDate) => 文字列(NSString)に変換
	NSString* strNow = [NSString stringWithFormat: @"%@%03d", [df stringFromDate: now], intMillSec];
	
	NSString *filePath = [dir stringByAppendingFormat: @"/%@.caf", strNow];
	url = [NSURL fileURLWithPath: filePath];
	
	return url;
}

- (NSMutableDictionary *)setAudioRecorder
{
	NSMutableDictionary *settings = [[NSMutableDictionary alloc] init];
	[settings setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
	[settings setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
	[settings setValue:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
	[settings setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
	[settings setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
	[settings setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
	
	return settings;
}

//
// recordFile
//
- (void)recordFile
{
	NSLog(@"Record");
	
	// Prepare recording(Audio session)
	NSError *error = nil;
	
	session = [AVAudioSession sharedInstance];
	
	if ( session.inputAvailable )   // for iOS6 [session inputIsAvailable]  iOS5
	{
		[session setCategory:AVAudioSessionCategoryPlayAndRecord
					   error:&error];
	}
	
	if ( error != nil )
	{
		NSLog(@"Error when preparing audio session :%@", [error localizedDescription]);
		return;
	}
	
	[session setActive:YES
				 error:&error];
	if ( error != nil )
	{
		NSLog(@"Error when enabling audio session :%@", [error localizedDescription]);
		return;
	}
	
	recorder = [[AVAudioRecorder alloc] initWithURL:[self getURL]
										   settings:[self setAudioRecorder]
											  error:&error];
	
	//recorder.meteringEnabled = YES;
	if ( error != nil )
	{
		NSLog(@"Error when preparing audio recorder :%@", [error localizedDescription]);
		return;
	}
	
	[recorder record];
}

//
// stopRecord
//
- (void)stopRecord
{
	NSLog(@"Stop");
	
	if ( recorder != nil && recorder.isRecording )
	{
		[recorder stop];
		
		recorder = nil;
	}
}

//
// playRecord
//
- (void)playRecord
{
	NSLog(@"Play");
	
	NSError *error = nil;
	
	NSLog(@"plat = %@", url);
	
	if ( [[NSFileManager defaultManager] fileExistsAtPath:[url path]] )
	{
		player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
		
		if ( error != nil )
		{
			NSLog(@"Error %@", [error localizedDescription]);
		}
		
		[player prepareToPlay];
		[player play];
	}
}

//
//
//
- (void)toCommand:(NSString *)command toTitle:(NSString *)title
{
	if ([command isEqualToString:@"toPlay"]) {
	
		imageView.image = [UIImage imageNamed:@"Play.png"];
		
		[self playRecord];
		
	} else if ([command isEqualToString:@"toRec"]) {
		
		imageView.image = [UIImage imageNamed:@"Rec.png"];
		
		[self recordFile];
		
	} else if ([command isEqualToString:@"toPause"]) {
		
		imageView.image = [UIImage imageNamed:@"Pause.png"];
		
		[self stopRecord];
		
	}
	
	label_SoundTitle_Front.text	 = title;
	label_SoundTitle_Back.text	 = title;
}


//
//
//
- (void)drawTitle:(NSString *)title
{
	if ([title isEqualToString:@""]) {

	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return playSounds.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;// = [tableView dequeueReusableCellWithIdentifier:@"cell"];
	// cellデータが無い場合、UITableViewCellを生成して、"cell"というkeyでキャッシュする
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
	}
	
	cell.textLabel.text = [playTitles objectAtIndex:indexPath.row];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *title_org = [playTitles objectAtIndex:indexPath.row];
	
	for (NSString *title in playSounds.keyEnumerator)
	{
		if ([title isEqualToString:title_org])
		{
			//url = playSounds[title];
			NSDictionary *dic = playSounds[title];
			NSLog(@"dic = key   : %@ ", [dic allKeys]);
			NSLog(@"      value : %@ ", [dic allValues]);
			
			url = dic[@"url"];
		}
	}
	
	[self toCommand:@"toPlay" toTitle:[playTitles objectAtIndex:indexPath.row]];
}

@end
