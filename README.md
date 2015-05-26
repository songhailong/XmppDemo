# my ios xmpp demo
这个主要是xmpp ios客户端的简单实现demo, 界面上又对应的各种触发按钮，具体收到的信息只能在控制台来查看，具体的xml流都会打印出来

# **xmpp ios client** #

*注：依赖于XMPPFrameWork这个ios开源框架*

下面简单的解析下这个demo：

**1、头文件实现三个协议：XMPPStreamDelegate、XMPPRosterDelegate、XMPPRoomDelegate<br/>
**2、初始化：配置日志调试框架用于输出具体的xml流、初始化流、连接到xmpp<br/>
**3、实现协议：XMPPStreamDelegate<br/>
**4、实现协议：XMPPRosterDelegate<br/>
**5、实现协议：XMPPRoomDelegate<br/>

## XMPPStreamDelegate协议具体实现方法有：

    #pragma mark - 身份认证
    -(void) xmppStreamDidConnect:(XMPPStream *)sender

    #pragma mark - 验证通过，使其为在线状态
    -(void) xmppStreamDidAuthenticate:(XMPPStream *)sender

    #pragma mark - 当接收到 <iq /> 标签的内容时，XMPPFramework 框架回调该方法
    -(BOOL) xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq

    #pragma mark - 接收消息
    -(void) xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
    #注：其中接收消息这分：（1）接收单人聊天信息 (2) 接收到入群的邀请

    #pragma mark - 收到错误信息调用
    -(void) xmppStream:(XMPPStream *)sender didReceiveError:(DDXMLElement *)error

    #pragma mark - 获取好友状态
    -(void) xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence

## XMPPRosterDelegate具体实现方法有：

    #pragma mark --- 收到添加好友的请求(处理添加好友的回调)
    -(void) xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence

    #pragma mark - 获取到一个好友节点
    -(void) xmppRoster:(XMPPRoster *)sender didReceiveRosterItem:(DDXMLElement *)item

    #pragma mark - 获取完好友列表
    -(void) xmppRosterDidEndPopulating:(XMPPRoster *)sender

## XMPPRoomDelegate协议具体实现方法：

    #pragma mark - 有人在群里发言
    -(void) xmppRoom:(XMPPRoom *)sender didReceiveMessage:(XMPPMessage *)message fromOccupant:(XMPPJID *)occupantJID

    #pragma mark - 获取聊天室信息
    -(void) xmppRoomDidJoin:(XMPPRoom *)sender

    #pragma mark - 收到好友名单列表
    -(void) xmppRoom:(XMPPRoom *)sender didFetchMembersList:(NSArray *)items

    #pragma mark - 收到主持人名单列表
    -(void) xmppRoom:(XMPPRoom *)sender didFetchModeratorsList:(NSArray *)items

    #pragma mark - 收到禁止名单列表
    -(void) xmppRoom:(XMPPRoom *)sender didFetchBanList:(NSArray *)items

    #pragma mark - 新人加入群聊（实现代理方法）
    -(void) xmppRoom:(XMPPRoom *)sender occupantDidJoin:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence

    #pragma mark - 有人退出群聊
    -(void) xmppRoom:(XMPPRoom *)sender occupantDidLeave:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence

## TLS Verify


