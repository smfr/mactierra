//
//  MTSoupSettingsPanelController.m
//  MacTierra
//
//  Created by Simon Fraser on 8/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTSoupSettingsPanelController.h"

#import "MT_Settings.h"
#import "MT_World.h"

#import "MTWorldSettings.h"
#import "MTWorldController.h"

@implementation MTSoupSettingsPanelController

@synthesize worldSettings;

- (IBAction)showSettings:(id)sender
{
    // fetch settings from the world
    self.worldSettings = [[[MTWorldSettings alloc] initWithSettings:mWorldController.world->settings()] autorelease];
    self.worldSettings.soupSize = mWorldController.world->soupSize();
    
    [NSApp beginSheet:mSettingsPanel
       modalForWindow:[mWorldController.document windowForSheet]
        modalDelegate:self
       didEndSelector:@selector(soupSettingsPanelDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

- (void)soupSettingsPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSOKButton)
    {
        const MacTierra::Settings* theSettings = worldSettings.settings;
        BOOST_ASSERT(theSettings);
        mWorldController.world->setSettings(*theSettings);
    
    
    }
    [sheet orderOut:nil];
    self.worldSettings = nil;
}

- (IBAction)okSettingsPanel:(id)sender
{
    [NSApp endSheet:mSettingsPanel returnCode:NSOKButton];
}

- (IBAction)cancelSettingsPanel:(id)sender
{
    [NSApp endSheet:mSettingsPanel returnCode:NSCancelButton];
}

@end
