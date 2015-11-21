//
//  ViewController.h
//  Rokuon_R001
//
//  Created by 寺内 信夫 on 2015/11/11.
//  Copyright © 2015年 寺内 信夫. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate, UITableViewDataSource, UITableViewDelegate>
{
	AVAudioSession *session;
	AVAudioRecorder *recorder;
	AVAudioPlayer *player;
	
	NSURL *url;
	
	__weak IBOutlet UITableView *tableView;
	
	__weak IBOutlet UILabel *label_SoundTitle_Front;
	__weak IBOutlet UILabel *label_SoundTitle_Back;
	
	NSMutableDictionary *playSounds;
	NSArray *playTitles;
}

@end

