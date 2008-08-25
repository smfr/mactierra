//
//  MTSoupSettingsPanelController.h
//  MacTierra
//
//  Created by Simon Fraser on 8/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MTWorldSettings;
@class MTWorldController;

@interface MTSoupSettingsPanelController : NSObject
{
    IBOutlet NSPanel*           mSettingsPanel;

    IBOutlet MTWorldController* mWorldController;
    
    MTWorldSettings*            worldSettings;

}

@property (retain) MTWorldSettings* worldSettings;

- (IBAction)showSettings:(id)sender;


// for settings panel
- (IBAction)okSettingsPanel:(id)sender;
- (IBAction)cancelSettingsPanel:(id)sender;

@end
