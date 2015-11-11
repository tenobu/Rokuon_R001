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

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	// 近接センサオン
	[UIDevice currentDevice].proximityMonitoringEnabled = YES;
	
	// 近接センサ監視
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(proximitySensorStateDidChange:)
												 name:UIDeviceProximityStateDidChangeNotification
											   object:nil];
}

- (void)didReceiveMemoryWarning {
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
			
			[self playRecord];
			
			break;
			
			// on
		case 1:
			// Wave On
			[self recordFile];
			
			break;
	}
	
}

-(NSMutableDictionary *)setAudioRecorder
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

-(void)recordFile
{
	// Prepare recording(Audio session)
	NSError *error = nil;
	
	session = [AVAudioSession sharedInstance];
	
	if ( session.inputAvailable )   // for iOS6 [session inputIsAvailable]  iOS5
	{
		[session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
	}
	
	if ( error != nil )
	{
		NSLog(@"Error when preparing audio session :%@", [error localizedDescription]);
		return;
	}
	
	[session setActive:YES error:&error];
	if ( error != nil )
	{
		NSLog(@"Error when enabling audio session :%@", [error localizedDescription]);
		return;
	}
	
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
	
	// recorder = [[AVAudioRecorder alloc] initWithURL:url settings:nil error:&error];
	recorder = [[AVAudioRecorder alloc] initWithURL:url settings:[self setAudioRecorder] error:&error];
	
	//recorder.meteringEnabled = YES;
	if ( error != nil )
	{
		NSLog(@"Error when preparing audio recorder :%@", [error localizedDescription]);
		return;
	}
	[recorder record];
}

-(void)stopRecord
{
	if ( recorder != nil && recorder.isRecording )
	{
		[recorder stop];
		
		recorder = nil;
	}
}

-(void)playRecord
{
	NSError *error = nil;
	
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

@end
