//
//  ViewController.m
//  SocketServerDemo
//
//  Created by ENUUI on 2017/8/1.
//  Copyright © 2017年 FUHUI. All rights reserved.
//

#import "ViewController.h"
#import "SocketServer.h"

@interface ViewController ()
@property (nonatomic, strong) SocketServer *socServer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _socServer = [[SocketServer alloc] init];
    [_socServer start];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
