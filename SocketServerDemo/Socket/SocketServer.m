//
//  SocketServer.m
//  SocketServerDemo
//
//  Created by ENUUI on 2017/8/1.
//  Copyright © 2017年 FUHUI. All rights reserved.
//

#import "SocketServer.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>


@interface SocClient : NSObject

@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (nonatomic, strong) NSDate *checkTime;
@end

@implementation SocClient
@end

@interface SocketServer () <GCDAsyncSocketDelegate>
@property (nonatomic, strong) GCDAsyncSocket *socServer;
@property (nonatomic, strong) NSMutableArray *mClientArr;
@property (nonatomic, strong) NSThread *check;
@end

@implementation SocketServer

- (instancetype)init {
    if (self = [super init]) {
        _socServer = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
        _mClientArr = [NSMutableArray array];
        _check = [[NSThread alloc] initWithTarget:self selector:@selector(checkClient) object:nil];
    }
    return self;
}

- (void)start {
    
    NSError *error = nil;
    BOOL suc = [_socServer acceptOnPort:1234 error:&error];
    if (suc) {
        NSLog(@"success");
        [_check start];
    } else {
        NSLog(@"fail: %@", error);
    }
}
#pragma mark - delegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    SocClient *c = [SocClient new];
    c.socket = newSocket;
    c.checkTime = [NSDate date];
    [_mClientArr addObject:c];
    
    [newSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)clientSocket didReadData:(NSData *)data withTag:(long)tag  {
    NSString *clientStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@", clientStr);
    NSString *log = [NSString stringWithFormat:@"IP:%@ %zd data: %@",clientSocket.connectedHost,clientSocket.connectedPort,clientStr];
    
    for (SocClient *c in _mClientArr) {
        if (![clientSocket isEqual:c.socket]) {
            //群聊 发送给其他客户端
            [self writeDataWithSocket:c.socket str:log];
        }else{
            ///更新最新时间
            c.checkTime = [NSDate date];
        }
    }
    [clientSocket readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    NSLog(@"又下线");
    NSMutableArray *arrayNew = [NSMutableArray array];
    for (SocClient *c in _mClientArr) {
        if ([c.socket isEqual:sock]) {
            continue;
        }
        [arrayNew addObject:c];
    }
    _mClientArr = arrayNew;
}

- (void)exitWithSocket:(GCDAsyncSocket *)clientSocket{
    //    [self writeDataWithSocket:clientSocket str:@"成功退出\n"];
    //    [self.arrayClient removeObject:clientSocket];
    //
    //    NSLog(@"当前在线用户个数:%ld",self.arrayClient.count);
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    NSLog(@"数据发送成功..");
}

- (void)writeDataWithSocket:(GCDAsyncSocket*)clientSocket str:(NSString*)str{
    [clientSocket writeData:[str dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
}

#pragma mark - check heartbeat
- (void)checkClient {
    
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, nil);
    dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), 20 * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(timer, ^{
        [self doCheckClient];
    });
}

- (void)doCheckClient {
    if (_mClientArr.count == 0) return;
    
    NSDate *date = [NSDate date];
    
    NSMutableArray *mArrNew = [NSMutableArray array];
    
    for (SocClient *c in _mClientArr) {
        if ([date timeIntervalSinceDate:c.checkTime] > 15.0) {
            continue;
        }
        [mArrNew addObject:c];
    }
    _mClientArr = mArrNew;
}
@end
