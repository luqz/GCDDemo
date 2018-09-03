//
//  ViewController.m
//  GCDDemo
//
//  Created by luqz on 2018/9/2.
//  Copyright © 2018年 jason. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    //1. 队列的创建
    //创建一个串行队列
    //第一个参数为队列标识符
    dispatch_queue_t serialQueue = dispatch_queue_create("com.jianshu.gcdDemo.serialQueue", DISPATCH_QUEUE_SERIAL);
    //创建一个并行队列
    dispatch_queue_t concurrentQueue = dispatch_queue_create("com.jianshu.gcdDemo.serialQueue", DISPATCH_QUEUE_CONCURRENT);
    
    //2. 队列的获取
    //主队列的获取
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    
    //全局并发队列的获取
    //第一个参数为队列优先级
    dispatch_queue_t defaultGlobalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    //在定义DISPATCH_QUEUE_PRIORITY_DEFAULT的地方一共看到四种优先级：
    // DISPATCH_QUEUE_PRIORITY_HIGH
    // DISPATCH_QUEUE_PRIORITY_DEFAULT
    // DISPATCH_QUEUE_PRIORITY_LOW
    // DISPATCH_QUEUE_PRIORITY_BACKGROUND
    //全局队列都是并发队列
    
    //3. 任务的创建
    //同步任务
    //第一个参数为队列
    dispatch_sync(serialQueue, ^{
        
    });
    //异步任务
    dispatch_async(serialQueue, ^{
        
    });
    
    //4.延时加入队列
    //第一个参数为加入队列的时间，第二个参数为加入的队列，block里为要执行的异步任务的内容
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
    });
    
    //5.应用程序生命周期内只执行一次
    //常见于单例的初始化
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
    });
    
    //6.多线程遍历
    //并行队列异步任务，也可以派发到同步队列中，那好像就与for循环没什么区别了
    dispatch_apply(10, defaultGlobalQueue, ^(size_t index) {
        NSLog(@"%@", [NSThread currentThread]);
        [NSThread sleepForTimeInterval:arc4random_uniform(2)];
        NSLog(@"%ld", index);    //多线程中异步输出，输出顺序不确定
    });
    //后续代码会等上面执行完成之后才继续执行
    NSLog(@"after applay");
    
    //7.信号量
    //创建信号量，参数表示可执行任务数量，一般为大于等于0的整数
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    //进入等待状态，若信号量值大于等于1则开始执行任务，信号量值-1，若信号量值等于0，等待信号量值大于等于1时开始执行任务
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    //信号量值+1
    dispatch_semaphore_signal(semaphore);
    
    
    //信号量在1和0之间切换可使不同并行队列中的相关任务按顺序执行，防止不同线程同时访问同一资源，实现线程安全，注意要在不同线程中使用同一个信号量，比如使用静态变量或者将其声明为属性，不要在不同线程中重复创建出不同的信号量
    dispatch_async(defaultGlobalQueue, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);//信号量值-1
        NSLog(@"test dispatch_semaphore 1");
        dispatch_semaphore_signal(semaphore);//信号量值+1
    });
    
    dispatch_async(concurrentQueue, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);//在该任务比上方任务开始执行的晚的情况下，若上方创建的semaphore初始值为1，则等待输出semaphore值+1之后才会开始，若创建的semaphore初始值大于1，则不等待
        NSLog(@"test dispatch_semaphore 2"); //在该任务比上方任务开始执行的晚的情况下，若上方创建的semaphore初始值为1，晚于test dispatch_semaphore 1输出，若创建的semaphore初始值大于1，早于test dispatch_semaphore 1输出
        dispatch_semaphore_signal(semaphore);
    });
    
    //信号量预设为0，使当前线程等待特定操作完成之后再继续执行，达到线程同步的目的
    //比如网络下载结束后的回调中再将信号量+1，可以让当前线程等待下载线程完成后再继续
    
    //8. GCD队列组
    //创建
    dispatch_group_t group = dispatch_group_create();
    
    //加入任务
    //方法1：使用dispatch_group_async
    dispatch_group_async(group, defaultGlobalQueue, ^{
        
    });
    
    dispatch_group_async(group, concurrentQueue, ^{
        
    });
    
    //方法2：
    //向某个队列中加入任务并标记加入到某个队列组中
    dispatch_group_enter(group);//标记未完成数量+1
    dispatch_async(defaultGlobalQueue, ^{
        
        //执行结束后标记完成
        dispatch_group_leave(group);//标记未完成数量-1
    });
    
    
    //等待整组任务执行完成
    //dispatch_group_notify可以指定队列进行后续任务
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        
    });
    
    //dispatch_group_wait使当前线程进入等待状态知道整组任务执行完成
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    
    //9.可取消的定时或延时任务
    //创建timer
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, defaultGlobalQueue);
    //创建开始时间
    //第二个参数为在第一个参数时间上增加的纳秒数，可以通过秒数*NSEC_PER_SEC换算
    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
    //设置timer
    //第二个参数为开始时间类型为dispatch_time_t，第三个参数为定时器间隔，第四个参数为允许误差
    dispatch_source_set_timer(timer, startTime, 0 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    //设置任务
    dispatch_source_set_event_handler(timer, ^{
        
    });
    //开始执行，注意要将timer强引用保存， 否则会丢失
    dispatch_resume(timer);
    //取消
    dispatch_source_cancel(timer);
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
