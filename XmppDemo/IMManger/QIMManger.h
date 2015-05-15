//
//  QIMManger.h
//  XmppDemo
//
//  Created by jinlong.yang on 15-5-14.
//  Copyright (c) 2015年 com.qunar.ops.push. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XMPPFramework.h"


@interface QIMManger : UIViewController<XMPPStreamDelegate, XMPPRosterDelegate, XMPPRoomDelegate>
{
    XMPPStream *xmppStream;                         //xmpp流对象
	XMPPReconnect *xmppReconnect;                   //重连对象
    XMPPRoster *xmppRoster;                         //用户对象
    XMPPRoom* xmppRoom;                             //聊天室对象
    
	XMPPRosterCoreDataStorage *xmppRosterStorage;
    XMPPvCardCoreDataStorage *xmppvCardStorage;
	XMPPvCardTempModule *xmppvCardTempModule;
	XMPPvCardAvatarModule *xmppvCardAvatarModule;
	XMPPCapabilities *xmppCapabilities;
	XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
    
    NSString* myPasswd;
}

@property (nonatomic, strong, readonly) XMPPStream* xmppStream;
@property (nonatomic, strong, readonly) XMPPReconnect* xmppReconnect;
@property (nonatomic, strong, readonly) XMPPRoster *xmppRoster;
@property (nonatomic, strong, readonly) XMPPRoom* xmppRoom;

@property (nonatomic, strong, readonly) XMPPRosterCoreDataStorage *xmppRosterStorage;
@property (nonatomic, strong, readonly) XMPPvCardCoreDataStorage* xmppvCardStorage;
@property (nonatomic, strong, readonly) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong, readonly) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong, readonly) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, strong, readonly) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;

- (BOOL)connectWithUserId: (NSString*) userId
                  withPwd: (NSString*) pwd
               withDomain: (NSString*) domain
                 withPort: (short) port
                 withHost: (NSString*) host;

- (void)disconnect;

@end
