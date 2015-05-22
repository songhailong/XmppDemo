//
//  QIMManger.m
//  XmppDemo
//
//  Created by jinlong.yang on 15-5-14.
//  Copyright (c) 2015年 com.qunar.ops.push. All rights reserved.
//

#import "QIMManger.h"
#import "XMPP.h"
#import "XMPPLogging.h"
#import "XMPPReconnect.h"
#import "XMPPCapabilitiesCoreDataStorage.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPvCardAvatarModule.h"
#import "XMPPvCardCoreDataStorage.h"

#import "DDLog.h"
#import "DDTTYLogger.h"

// sysctlbyname需要的库，用于获取设备的资源
#import <sys/sysctl.h>

// Log levels: off, error, warn, info, verbose
#if DEBUG
    static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
    static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

NSString* curUserId = @"shaodw.zhang";
NSString* curUserJid = @"shaodw.zhang@domain";

NSString* testUserJid = @"jinlong.yang@domain";

NSString* testRoomBareJid = @"hermes@domain";
NSString* testRoomNick = @"hermes";


@interface QIMManger ()

- (void)setupStream;        // 初始化xmpp流相关
- (void)teardownStream;     // 释放资源

//- (void)goOnline;           // 上线
//- (void)goOffline;          // 下线

@end

@implementation QIMManger

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 配置日志框架
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLogLevel:XMPP_LOG_FLAG_SEND_RECV];
    
    // 初始化流
    [self xmppTestButton];
    
    [self setupStream];
    
    NSString* userId = curUserId;
    NSString* domain = @"服务名";
    NSString* myPassword = @"密码";
    NSString* host = @"主机名";
    short port = 5223;
    [self connectWithUserId: userId withPwd: myPassword withDomain: domain withPort: port withHost: host];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) dealloc
{
    [self teardownStream];
}


// 测试按钮
-(void) xmppTestButton
{
    // 显示个标题
    CGFloat titleX = 10.f;
    CGFloat titleY = 60.f;
    CGFloat titleW = SCREEN_W-2*titleX;
    CGFloat titleH = 30.f;
    CGRect react = CGRectMake(titleX, titleY, titleW, titleH);
    UILabel* titleLabel = [[UILabel alloc] initWithFrame: react];
    titleLabel.text = @"XMPP Demo";
    titleLabel.textColor = [UIColor grayColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview: titleLabel];
    
    // 测试按钮标题
    NSArray* arrBtnTitle = [NSArray arrayWithObjects: @"发送消息", @"添加好友", @"创建聊天室并进入(临时)", @"设置为永久聊天室",
                                                      @"注册成为聊天室成员", @"获取聊天室人列表", @"邀请人加入聊天室",
                                                      @"获取聊天室列表", @"发送群聊信息", nil];
    NSUInteger nIndex = 0;
    for (NSString* title in arrBtnTitle)
    {
        CGFloat btnW = 140.f;
        CGFloat btnH = 30.f;
        CGFloat btnX;
        CGFloat btnY;
        
        NSUInteger nRet = nIndex % 2;
        if (0 == nRet) {
            // 奇数
            btnY = titleY + titleH + 15.f + btnH*nIndex;
            btnX = 10.f + btnW*nRet;
        }
        else
        {
            // 偶数为上一个索引
            btnY = titleY + titleH + 15.f + btnH*(nIndex-1);
            btnX = 10.f + btnW*nRet + (SCREEN_W-2*btnW-2*10.f);
        }
        
        UIButton* testBtn = [UIButton buttonWithType: UIButtonTypeRoundedRect];
        testBtn.frame = CGRectMake(btnX, btnY, btnW, btnH);
        [testBtn setTitle: title forState: UIControlStateNormal];
        [testBtn setBackgroundColor: [UIColor grayColor]];
        [testBtn setTintColor: [UIColor whiteColor]];
        
        switch (nIndex) {
            case 0:
                [testBtn addTarget: self action: @selector(sendMessageToJid) forControlEvents: UIControlEventTouchUpInside];
                break;
            
            case 1:
                [testBtn addTarget: self action: @selector(addFriend) forControlEvents: UIControlEventTouchUpInside];
                break;
                
            case 2:
                [testBtn addTarget: self action: @selector(initChatRoom) forControlEvents: UIControlEventTouchUpInside];
                break;
            
            case 3:
                [testBtn addTarget: self action: @selector(registerPermentRoom) forControlEvents: UIControlEventTouchUpInside];
                break;
                
            case 4:
                [testBtn addTarget: self action: @selector(registerPermentToMember) forControlEvents: UIControlEventTouchUpInside];
                break;
                
            case 5:
                [testBtn addTarget: self action: @selector(fetchRoomMemberList) forControlEvents: UIControlEventTouchUpInside];
                break;
                
            case 6:
                [testBtn addTarget: self action: @selector(inviteUserJoinRoom) forControlEvents: UIControlEventTouchUpInside];
                break;
                
            case 7:
                [testBtn addTarget: self action: @selector(fetchRoomList) forControlEvents: UIControlEventTouchUpInside];
                break;
                
            case 8:
                [testBtn addTarget: self action: @selector(sendRoomMessage) forControlEvents: UIControlEventTouchUpInside];
                break;
                
            default:
                break;
        }
        [self.view addSubview: testBtn];
        nIndex++;
    }
}


#pragma mark --- xmpp 实现部分...........

- (void)setupStream
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
	//NSAssert(xmppStream == nil, @"Method setupStream invoked multiple times");
    
    NSLog(@"xmppStream object instance value = %@", xmppStream);
    if (!xmppStream)
    {
        // Setup xmpp stream
        //
        // The XMPPStream is the base class for all activity.
        // Everything else plugs into the xmppStream, such as modules/extensions and delegates.
        xmppStream = [[XMPPStream alloc] init];
        
#if !TARGET_IPHONE_SIMULATOR
        {
            // Want xmpp to run in the background?
            //
            // P.S. - The simulator doesn't support backgrounding yet.
            //        When you try to set the associated property on the simulator, it simply fails.
            //        And when you background an app on the simulator,
            //        it just queues network traffic til the app is foregrounded again.
            //        We are patiently waiting for a fix from Apple.
            //        If you do enableBackgroundingOnSocket on the simulator,
            //        you will simply see an error message from the xmpp stack when it fails to set the property.
            xmppStream.enableBackgroundingOnSocket = YES;
        }
#endif
        
        // Setup reconnect
        //
        // The XMPPReconnect module monitors for "accidental disconnections" and
        // automatically reconnects the stream for you.
        // There's a bunch more information in the XMPPReconnect header file.
        xmppReconnect = [[XMPPReconnect alloc] init];
        
        // Setup roster
        //
        // The XMPPRoster handles the xmpp protocol stuff related to the roster.
        // The storage for the roster is abstracted.
        // So you can use any storage mechanism you want.
        // You can store it all in memory, or use core data and store it on disk, or use core data with an in-memory store,
        // or setup your own using raw SQLite, or create your own storage mechanism.
        // You can do it however you like! It's your application.
        // But you do need to provide the roster with some storage facility.
        xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
        //	xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithInMemoryStore];
        
        xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:xmppRosterStorage];
        
        xmppRoster.autoFetchRoster = YES;
        xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
        
        // Setup vCard support
        //
        // The vCard Avatar module works in conjuction with the standard vCard Temp module to download user avatars.
        // The XMPPRoster will automatically integrate with XMPPvCardAvatarModule to cache roster photos in the roster.
        
        xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
        xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:xmppvCardStorage];
        
        xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:xmppvCardTempModule];
        
        // Setup capabilities
        //
        // The XMPPCapabilities module handles all the complex hashing of the caps protocol (XEP-0115).
        // Basically, when other clients broadcast their presence on the network
        // they include information about what capabilities their client supports (audio, video, file transfer, etc).
        // But as you can imagine, this list starts to get pretty big.
        // This is where the hashing stuff comes into play.
        // Most people running the same version of the same client are going to have the same list of capabilities.
        // So the protocol defines a standardized way to hash the list of capabilities.
        // Clients then broadcast the tiny hash instead of the big list.
        // The XMPPCapabilities protocol automatically handles figuring out what these hashes mean,
        // and also persistently storing the hashes so lookups aren't needed in the future.
        //
        // Similarly to the roster, the storage of the module is abstracted.
        // You are strongly encouraged to persist caps information across sessions.
        //
        // The XMPPCapabilitiesCoreDataStorage is an ideal solution.
        // It can also be shared amongst multiple streams to further reduce hash lookups.
        xmppCapabilitiesStorage = [XMPPCapabilitiesCoreDataStorage sharedInstance];
        xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:xmppCapabilitiesStorage];
        
        xmppCapabilities.autoFetchHashedCapabilities = YES;
        xmppCapabilities.autoFetchNonHashedCapabilities = NO;
        
        // Activate xmpp modules
        [xmppReconnect         activate:xmppStream];
        [xmppRoster            activate:xmppStream];
        [xmppvCardTempModule   activate:xmppStream];
        [xmppvCardAvatarModule activate:xmppStream];
        [xmppCapabilities      activate:xmppStream];
        
        // 添加代理
        // Add ourself as a delegate to anything we may be interested in
        [xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
}

- (void)teardownStream
{
	[xmppStream removeDelegate:self];
	[xmppRoster removeDelegate:self];
	
	[xmppReconnect         deactivate];
	[xmppRoster            deactivate];
	[xmppvCardTempModule   deactivate];
	[xmppvCardAvatarModule deactivate];
	[xmppCapabilities      deactivate];
	
	[xmppStream disconnect];
	
	xmppStream = nil;
	xmppReconnect = nil;
    xmppRoster = nil;
	xmppRosterStorage = nil;
	xmppvCardStorage = nil;
    xmppvCardTempModule = nil;
	xmppvCardAvatarModule = nil;
	xmppCapabilities = nil;
	xmppCapabilitiesStorage = nil;
}

// 用于jid的resource部分
NSString* getMachine() {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *name = malloc(size);
    sysctlbyname("hw.machine", name, &size, NULL, 0);
    
    NSString *machine = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
    
    free(name);
    
    if( [machine isEqualToString:@"i386"] || [machine isEqualToString:@"x86_64"] ) machine = @"mac(ios_sim)";
    else if( [machine isEqualToString:@"iPhone1,1"] ) machine = @"iPhone_1G";
    else if( [machine isEqualToString:@"iPhone1,2"] ) machine = @"iPhone_3G";
    else if( [machine isEqualToString:@"iPhone2,1"] ) machine = @"iPhone_3GS";
    else if( [machine isEqualToString:@"iPhone3,1"] ) machine = @"iPhone_4";
    else if( [machine isEqualToString:@"iPod1,1"] ) machine = @"iPod_Touch_1G";
    else if( [machine isEqualToString:@"iPod2,1"] ) machine = @"iPod_Touch_2G";
    else if( [machine isEqualToString:@"iPod3,1"] ) machine = @"iPod_Touch_3G";
    else if( [machine isEqualToString:@"iPod4,1"] ) machine = @"iPod_Touch_4G";
    else if( [machine isEqualToString:@"iPad1,1"] ) machine = @"iPad_1";
    else if( [machine isEqualToString:@"iPad2,1"] ) machine = @"iPad_2";
    return machine;
}

-(BOOL) connectWithUserId:(NSString *)userId withPwd:(NSString *)pwd withDomain:(NSString *)domain withPort:(short)port withHost:(NSString *)host
{
    // isDisconnected：如果连接关闭会返回YES
    BOOL isXmppDisconnect = [xmppStream isDisconnected];
    NSLog(@"xmpp is disconnect : %d", isXmppDisconnect);
    if (!isXmppDisconnect) {
        return YES;
    }
    
    if (userId == nil || pwd == nil) {
        return NO;
    }
    
    myPasswd = pwd;
    
    NSString* resource = [NSString stringWithFormat:@"%@_%@", getMachine(), [XMPPStream generateUUID]];
    NSLog(@"[xmpp] 获得本机resource为: %@", resource);
    
    NSString* myUrl = [NSString stringWithFormat:@"%@@%@/%@", userId, domain, resource];
    [xmppStream setMyJID:[XMPPJID jidWithString: myUrl]];
    [xmppStream setHostName: host];
    [xmppStream setHostPort: port];
    
    BOOL isConn = [xmppStream isConnected];
    NSLog(@"[xmpp] 是否连接到xmpp----： %d", isConn);
    if (!isConn)
    {
        NSError* error = nil;
        if (![xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error])
        {
            NSLog(@"[xmpp] 连接失败, err: %@", error);
            return NO;
        }
    }
    
    NSLog(@"[xmpp] connect to xmpp server is success");
    return YES;
}

-(void) disconnect
{
    XMPPPresence* presence = [XMPPPresence presenceWithType: @"unavailable"];
    [xmppStream sendElement: presence];
}


#pragma mark ---- XMPPStreamDelegate -----

#pragma mark - 身份认证
-(void) xmppStreamDidConnect:(XMPPStream *)sender
{
    NSLog(@"[xmpp] 身份认证开始 - %@: %@", THIS_FILE, THIS_METHOD);
    
    NSError *error = nil;
    if (![xmppStream authenticateWithPassword:myPasswd error:&error])
    {
        NSLog(@"[xmpp] 认证失败，Error authenticating: %@", error);
    }
    NSLog(@"[xmpp] 认证通过。");
}

#pragma mark - 验证通过，使其为在线状态
-(void) xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    NSLog(@"[xmpp] 认证成功开始上线");
    
    XMPPPresence *presence = [XMPPPresence presence];
    NSXMLElement *query = [NSXMLElement elementWithName:@"c" xmlns:@"http://jabber.org/protocol/caps"];
    NSXMLElement* priority = [NSXMLElement elementWithName: @"priority" stringValue: @"0"];
    [presence addChild:query];
    [presence addChild:priority];
    [xmppStream sendElement:presence];
    
    NSLog(@"[xmpp] 出席结束....");
}

#pragma mark - 当接收到 <iq /> 标签的内容时，XMPPFramework 框架回调该方法
-(BOOL) xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    NSLog(@"[xmpp] 收到iq节的内容....");
    
    //通过iq对象来获取对应元素，之后再拿到对应熟悉的值
    //[iq elementForName: @"" xmlns: @""];
    
    /*
     *  获取已注册聊天室列表
     *  注：服务端自己实现的
     */
    NSMutableArray* existRoomList = [NSMutableArray array];
    NSXMLElement* queryRoomListElement = [iq elementForName: @"query" xmlns: @"http://jabber.org/protocol/muc#user_mucs"];
    //NSLog(@"获取已注册聊天室列表xml对象： %@", queryRoomListElement);
    if (queryRoomListElement)
    {
        NSArray* roomList = [queryRoomListElement elementsForName: @"muc_rooms"];
        NSLog(@"已注册的room的list为： %@", roomList);
        for (NSString* attr in roomList)
        {
            NSXMLElement* muc_rooms = (NSXMLElement*)attr;
            NSString* name = [[muc_rooms attributeForName: @"name"] stringValue];
            NSString* host = [[muc_rooms attributeForName: @"host"] stringValue];
            NSString* roomJID = [NSString stringWithFormat: @"%@@%@", name, host];
            
            NSMutableDictionary* dict = [NSMutableDictionary dictionary];
            dict[@"name"] = name;
            dict[@"jid"] = roomJID;
            [existRoomList addObject: dict];
        }
        NSLog(@"fetch existd room list : %@", existRoomList);
    }
    
    /*
     *  获取已注册聊天室成员列表
     *  注：服务端自己实现的
     */
    NSMutableArray* arrRoomMemList = [NSMutableArray array];
    NSXMLElement* roomMemListElement = [iq elementForName: @"query" xmlns: @"http://jabber.org/protocol/muc#register"];
    NSXMLElement* registerElement = [roomMemListElement elementForName: @"set_register"]; // 获取已注册成员列表和注册成为群成员的命名空间相同，大爷的
    NSLog(@"registerSetElemet ---> %@", registerElement);
    //NSLog(@"获取已注册聊天室成员列表 element: %@", roomMemListElement);
    if (roomMemListElement && !registerElement)
    {
        NSArray* memList =[roomMemListElement elementsForName: @"m_user"];
        
        for (NSString* user in memList)
        {
            NSXMLElement* userElement = (NSXMLElement*)user;
            NSString* userJid = [[userElement attributeForName: @"jid"] stringValue];
            [arrRoomMemList addObject: userJid];
        }
        NSLog(@"获取的群成员jid列表： %@", arrRoomMemList);
    }
    
    return YES;
}

#pragma mark - 接收消息
-(void) xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    NSLog(@"正在接受消息。。。。。");
    // if 1 == isChatMessageWithBody : 单人聊天
    // if 0 == isChatMessageWithBody : 群聊
    BOOL isChatMessageWithBody = [message isChatMessageWithBody];
    NSLog(@"是单人聊天吗：---- %d", isChatMessageWithBody);
    
    NSString* body = [[message elementForName: @"body"] stringValue];
    NSLog(@"内容为： ---- %@", body);
    
    NSString* from = [[message attributeForName: @"from"] stringValue];
    NSLog(@"from---> %@", from);
    
    // 判断是否是好友邀请
    NSXMLElement* x = [message elementForName: @"x" xmlns: @"http://jabber.org/protocol/muc#user"];
    if (x)
    {
        x = [message elementForName: @"x" xmlns: @"jabber:x:conference"];
        if (x)
        {
            NSLog(@"这里是收到加入群的邀请了。。。。。。。。");
            NSLog(@"1）先注册群。。。。");
            // 先进行注册
            NSString *key = [XMPPStream generateUUID];
            NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
            [iq addAttributeWithName:@"to" stringValue:[NSString stringWithFormat:@"%@", from]];
            [iq addAttributeWithName:@"id" stringValue:key];
            [iq addAttributeWithName:@"type" stringValue:@"set"];
            NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"http://jabber.org/protocol/muc#register"];
            [iq addChild:query];
            [xmppStream sendElement: iq];
            
            NSLog(@"2）再加入聊天室。。。。。");
            // 加入到聊天室
            NSString* curUser = [[xmppStream myJID] user];
            NSXMLElement *presence = [NSXMLElement elementWithName:@"presence"];
            [presence addAttributeWithName:@"to" stringValue:[NSString stringWithFormat:@"%@/%@", from, curUser]];
            NSXMLElement *priority = [NSXMLElement elementWithName:@"priority" numberValue:@(5)];
            NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:@"http://jabber.org/protocol/muc"];
            [presence addChild:priority];
            [presence addChild:x];
            [xmppStream sendElement: presence];
        }
    }
}

#pragma mark - 收到错误信息调用
-(void) xmppStream:(XMPPStream *)sender didReceiveError:(DDXMLElement *)error
{
    NSLog(@"Error: %@", error);
}

#pragma mark - 获取好友状态
-(void) xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    NSLog(@"获取好友状态，%@: %@ - %@", THIS_FILE, THIS_METHOD, [presence fromStr]);
    
    NSString* curUser = [[sender myJID] user];
    NSLog(@"当前用户为： %@", curUser);
    
    // 取得好友状态
    NSString* presenceType = [presence type];
    NSLog(@"好友状态： %@", presenceType);
    
    // 在线用户
    NSString* presenceFromUser = [[presence from] user];
    NSLog(@"在线用户： %@", presenceFromUser);
    
    // 这里再次加好友
    if ([presenceType isEqualToString: @"subscribed"])
    {
        // 有好友发来订阅，默认添加
        NSLog(@"[xmpp] 有好友请求发来，默认将其添加....");
        XMPPJID* onLineJId = [XMPPJID jidWithString: presenceFromUser];
        [xmppRoster acceptPresenceSubscriptionRequestFrom: onLineJId andAddToRoster: YES];
    }
    
    if (![presenceFromUser isEqualToString: curUser])
    {
        if ([presenceType isEqualToString: @"available"])
        {
            // 在线
            NSLog(@"好友： %@ ----在线", presenceFromUser);
        }
        else if ([presenceType isEqualToString: @"unavailable"])
        {
            // 不在线
            NSLog(@"好友：%@ ----不在线", presenceFromUser);
        }
    }
}


// 发送消息
-(void) sendMessageToJid
{
    NSLog(@"发送聊天信息............");
    NSString* chatMsg = @"haohaoxuexi,tiantianxiangshang.";
    [self sendMessageToJid: testUserJid withMsg: chatMsg];
}

#pragma mark - 发送消息
-(void) sendMessageToJid: (NSString*) jid withMsg: (NSString*) chatMsg
{
    //XMPPFramework主要是通过KissXML来生成XML文件
    //生成<body>文档
    NSXMLElement* body = [NSXMLElement elementWithName: @"body"];
    [body setStringValue: chatMsg];
    
    //生成XML消息文档
    NSXMLElement* message = [NSXMLElement elementWithName: @"message"];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    [message addAttributeWithName:@"to" stringValue: jid];
    [message addAttributeWithName:@"from" stringValue:[[xmppStream myJID] description]];
    [message addChild: body];
    
    [xmppStream sendElement: message];
}

/*
 *  添加好友，这好像有点问题 对方收到的竟然是user而不是jid
 */
-(void) addFriend
{
    NSLog(@"添加好友................");
    XMPPJID* friendJid = [XMPPJID jidWithString: testUserJid];
    [xmppRoster subscribePresenceToUser: friendJid];
}


#pragma mark ---- XMPPRosterDelegate ----

#pragma mark --- 收到添加好友的请求(处理添加好友的回调)
-(void) xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
    NSLog(@"收到添加好友的请求.......");
    
    //请求的用户
    NSString* presenceFromUser = [[presence from] user];
    NSLog(@"请求添加好友的用户： %@", presenceFromUser);
    
    // 得到好友状态
    NSString* presenceType = [presence type];
    NSLog(@"好友：%@ ---> 状态：%@", presenceFromUser, presenceType);
    
    // 添加好友
    XMPPJID* jid = [XMPPJID jidWithString: presenceFromUser];
    [xmppRoster acceptPresenceSubscriptionRequestFrom: jid andAddToRoster: YES];
}

#pragma mark - 获取到一个好友节点
-(void) xmppRoster:(XMPPRoster *)sender didReceiveRosterItem:(DDXMLElement *)item
{
    NSLog(@"获取到一个好友节点.......");
    NSLog(@"item: ---> %@", item);
    NSString* friendJID = [[item attributeForName: @"jid"] stringValue];
    NSLog(@"好友列表： %@", friendJID);
}

#pragma mark - 获取完好友列表
-(void) xmppRosterDidEndPopulating:(XMPPRoster *)sender
{
    NSLog(@"获取完好友列表...........");
}


// 创建聊天室
-(void) initChatRoom
{
    NSLog(@"1、初始化聊天室............");
    XMPPJID* roomJid = [XMPPJID jidWithString: testRoomBareJid];
    XMPPRoomCoreDataStorage* xmppRoomStorage = [XMPPRoomCoreDataStorage sharedInstance];
    
    xmppRoom = [[XMPPRoom alloc] initWithRoomStorage: xmppRoomStorage jid: roomJid];
    [xmppRoom activate: xmppStream];
    [xmppRoom addDelegate: self delegateQueue: dispatch_get_main_queue()];
    
    NSLog(@"2、加入聊天室..............");
    [xmppRoom joinRoomUsingNickname: testRoomNick history: nil];
}

-(void) registerPermentRoom
{
    NSLog(@"[xmppRoomDidJoin] 配置聊天室为永久聊天室...........");
    // 先提交配置表单
    [xmppRoom fetchConfigurationForm]; // 提交配置表单
    
    // 向服务器提交配置表单
    NSXMLElement* field = [NSXMLElement elementWithName:@"field"];
    [field addAttributeWithName:@"type"stringValue:@"boolean"];
    [field addAttributeWithName:@"var"stringValue:@"muc#roomconfig_persistentroom"];
    [field addChild:[NSXMLElement elementWithName:@"value"objectValue:@"1"]];  // 将持久属性置为YES。
    
    NSXMLElement* x = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
    [x addAttributeWithName:@"type"stringValue:@"form"];
    [x addChild: field];
    [xmppRoom configureRoomUsingOptions:x];
}

/*
 *  聊天室创建完了，注册成为这个聊天室的成员
 *  注：这个是服务端自己定义的
 */
-(void) registerPermentToMember
{
    NSLog(@"聊天室创建成功后，开始注册成为这个聊天室的成员。。。。");
    
    //先进行注册
    NSString *key = [XMPPStream generateUUID];
    NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
    [iq addAttributeWithName:@"to" stringValue: testRoomBareJid];
    [iq addAttributeWithName:@"id" stringValue: key];
    [iq addAttributeWithName:@"type" stringValue:@"set"];
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"http://jabber.org/protocol/muc#register"];
    [iq addChild:query];
    [xmppStream sendElement: iq];
}


#pragma mark ---- XMPPRoomDelegate ----

#pragma mark - 群聊
-(void) xmppRoom:(XMPPRoom *)sender didReceiveMessage:(XMPPMessage *)message fromOccupant:(XMPPJID *)occupantJID
{
    NSLog(@"群聊开始了。。。。。。。。。");
    NSLog(@"群聊的消息： %@", message);
    NSString* chatType = [[message attributeForName: @"type"] stringValue];
    NSString* fromUser = [[xmppStream myJID] bare];
    NSString* body = [[message elementForName: @"body"] stringValue];
    
    NSLog(@"用户：%@ 正在发消息, 消息内容： %@, 群聊类型：%@", fromUser, body, chatType);
}

#pragma mark - 获取聊天室信息
-(void) xmppRoomDidJoin:(XMPPRoom *)sender
{
    NSLog(@"获取聊天室信息^^^^^^^^^^^^^^^");
    /*
     [xmppRoom fetchConfigurationForm];
     [xmppRoom fetchBanList];
     [xmppRoom fetchMembersList];
     [xmppRoom fetchModeratorsList];
     */
}

#pragma mark - 收到好友名单列表
-(void) xmppRoom:(XMPPRoom *)sender didFetchMembersList:(NSArray *)items
{
    NSLog(@"收到好友名单列表................");
    NSLog(@"好友列表： %@", items);
}

#pragma mark - 收到主持人名单列表
-(void) xmppRoom:(XMPPRoom *)sender didFetchModeratorsList:(NSArray *)items
{
    NSLog(@"收到主持人名单列表................");
    NSLog(@"主持人列表： %@", items);
}

#pragma mark - 收到禁止名单列表
-(void) xmppRoom:(XMPPRoom *)sender didFetchBanList:(NSArray *)items
{
    NSLog(@"收到禁止名单列表................");
    NSLog(@"禁止名单列表： %@", items);
}


// 邀请好友加入聊天室
-(void) inviteUserJoinRoom
{
    NSLog(@"%@邀请好友加入到聊天室", [[xmppStream myJID] user]);
    /*
        // 这种得是wengao.han主动进入聊天室，是他自己的行为，否则[xmppStream sendElement: presence]; 这样发送的话是自己邀请自己，会报错。
        <presence
            from="hag66@shakespeare.lit/pda"
            to='darkcave@macbeth.shakespeare.lit/thirdwitch'>
            <x xmlns='http://jabber.org/protocol/muc'/>
        </presence>
     */
    
    /* *** 邀请他人进入聊天室
        <message
            from='crone1@shakespeare.lit/desktop'
            to='ygroup@conference.l-tqserver2.cc.beta.cn6/用户名'>
            <x xmlns='http://jabber.org/protocol/muc#user'>
                <invite to='hecate@shakespeare.lit'>
                    <reason>
                        Hey Hecate, this is the place for all good witches!
                    </reason>
                </invite>
            </x>
        </message>
     */
    
    XMPPJID* inviteUser = [XMPPJID jidWithString: testUserJid];
    [xmppRoom inviteUser: inviteUser withMessage: @"jinlong.yang invite you join ygroup room"];
}

#pragma mark - 新人加入群聊（实现代理方法）
-(void) xmppRoom:(XMPPRoom *)sender occupantDidJoin:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
    NSLog(@"有人加入群聊了。。。。。。。。。");
    NSLog(@"xmppjid： %@", occupantJID);
    NSString* newAddJid = [[occupantJID bareJID] description];
    NSLog(@"新加入的jabberid 为： %@", newAddJid);
    NSLog(@"presence: %@", presence);
    NSString* fromUser = [[presence from] resource];
    NSLog(@"新加入的用户为： %@", fromUser);
    NSString* presenceType = [presence type];
    NSLog(@"新加入用户的出席类型： %@", presenceType);
}

#pragma mark - 有人退出群聊
-(void) xmppRoom:(XMPPRoom *)sender occupantDidLeave:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
    
}

/*
 *  获取已注册聊天室成员列表
 *  注：这不是官方的，服务端需要实现一个
 */
-(void) fetchRoomMemberList
{
    NSLog(@"获取已聊天室成员列表。。。。");
    
    NSXMLElement* iq = [NSXMLElement elementWithName: @"iq"];
    [iq addAttributeWithName: @"to" stringValue: testRoomBareJid];
    [iq addAttributeWithName: @"id" stringValue: [xmppStream generateUUID]];
    [iq addAttributeWithName: @"type" stringValue: @"get"];
    
    // 注：这将原有的jabber:iq:roster命名空间修改了成如下这个命名空间
    NSXMLElement* query = [NSXMLElement elementWithName: @"query" xmlns: @"http://jabber.org/protocol/muc#register"];
    [iq addChild: query];
    
    [xmppStream sendElement: iq];
}


/*
 *  获取已注册聊天室列表
 *  注：这不是官方的，服务端需要实现一个
 */
-(void) fetchRoomList
{
    NSLog(@"获取已注册聊天室列表...........");
    
    NSString* domain = [[xmppStream myJID] domain];
    NSString* to = [NSString stringWithFormat: @"conference.%@", domain];
    
    NSXMLElement* iq = [NSXMLElement elementWithName: @"iq"];
    [iq addAttributeWithName: @"to" stringValue: to];
    [iq addAttributeWithName: @"id" stringValue: [xmppStream generateUUID]];
    [iq addAttributeWithName: @"type" stringValue: @"get"];
    
    NSXMLElement* query = [NSXMLElement elementWithName: @"query" xmlns: @"http://jabber.org/protocol/muc#user_mucs"];
    [iq addChild: query];
    [xmppStream sendElement: iq];
}

// 发送群聊信息
-(void) sendRoomMessage
{
    NSString* chatMsg = @"this is jinlong.yang send a chat group message，please see";
    NSString* sendUserJid = [[xmppStream myJID] bare];
    NSLog(@"当前用户jid为： %@", sendUserJid);
    
    NSXMLElement* message = [NSXMLElement elementWithName: @"message"];
    [message addAttributeWithName: @"type" stringValue: @"groupchat"];
    [message addAttributeWithName: @"from" stringValue: sendUserJid];
    [message addAttributeWithName: @"to" stringValue: testRoomBareJid];
    
    NSXMLElement* body = [NSXMLElement elementWithName: @"body"];
    [body setStringValue: chatMsg];
    
    [message addChild: body];
    [xmppStream sendElement: message];
}


@end
