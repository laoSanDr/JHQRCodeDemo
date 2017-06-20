//
//  JHQRCode.m
//  JHQRCodeDemo
//
//  Created by jalaSmart on 17/6/20.
//  Copyright © 2017年 MrChen. All rights reserved.
//

#import "JHQRCode.h"

@interface JHQRCode ()<AVCaptureMetadataOutputObjectsDelegate>

@property(nonatomic,strong)CIFilter *QRfilter;

@property(nonatomic,copy)void(^completeBlock)(NSString *code);

@property(nonatomic,strong)AVCaptureSession *session;

@property(nonatomic,strong)AVCaptureVideoPreviewLayer *previewLayer;
///扫描的框框
@property(nonatomic,strong)UIView  *preView;

@property(nonatomic,strong)UIView  *lineView;

///是否正在扫描
@property(nonatomic,assign)BOOL   isScaning;

@end

@implementation JHQRCode

///构建方法
+ (instancetype)shareInstance
{
    static JHQRCode *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[JHQRCode alloc]init];
    });
    return instance;
}


///创建二维码
+ (UIImage *)buildQRCodeWithMessage:(NSString *)message
                       withCodeType:(JHCodeType)type
                           withSize:(CGSize)size
{
    JHQRCode *instance = [JHQRCode shareInstance];
    instance.QRfilter = [CIFilter filterWithName:type == JHCodeTypeQRCode ? @"CIQRCodeGenerator" : @"CICode128BarcodeGenerator"];
    ///恢复默认
    [instance.QRfilter setDefaults];
    
    NSData *data;
    if (type == JHCodeTypeQRCode) {
        //纠错水平  L M Q H
        [instance.QRfilter setValue:@"H" forKey:@"inputCorrectionLevel"];
        data = [message dataUsingEncoding:NSUTF8StringEncoding];
    }
    else
    {
        data = [message dataUsingEncoding:NSISOLatin2StringEncoding];
    }
    //添加数据
    [instance.QRfilter setValue:data forKey:@"inputMessage"];
    
    CIImage *outputImage = [instance.QRfilter outputImage];
    
    return [self handleCIImage:outputImage withSize:size];
}

+ (UIImage *)handleCIImage:(CIImage *)image withSize:(CGSize)size
{
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size.width/CGRectGetWidth(extent), size.width/CGRectGetHeight(extent));
    
    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    // 2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}
// 扫描二维码
+ (void)scanWithView:(UIViewController *)vc
        withscanView:(UIView *)view
        withLineView:(UIView *)lineView
   withCompleteBlock:(void (^)(NSString *))completeBlock
{
    JHQRCode *instance = [JHQRCode shareInstance];
    instance.completeBlock = completeBlock;
    instance.isScaning = YES;
    instance.preView = view;
    instance.lineView = lineView;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError *error = nil;
    
    AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc]initWithDevice:device error:&error];
    if (error) {
        completeBlock(@"error");
        return;
    }
    
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc]init];
    [output setMetadataObjectsDelegate:instance queue:dispatch_get_main_queue()];
    
    AVCaptureSession *session = [[AVCaptureSession alloc]init];
    if ([session canAddInput:input]){
        [session addInput:input];
    }
    if ([session canAddOutput:output]) {
        [session addOutput:output];
    }
    
    [output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code]];
    
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:session];
    previewLayer.frame = vc.view.frame;
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [vc.view.layer addSublayer:previewLayer];
    [vc.view.layer addSublayer:view.layer];
    [vc.view.layer addSublayer:lineView.layer];
    //    start
    [session startRunning];
    instance.session = session;
    instance.previewLayer = previewLayer;
    
    //    开始动画
    ///先这是lineView的初始位置
    lineView.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, 1);
    [instance scanAnimation];
    
}
///动画
- (void)scanAnimation
{
    static BOOL flag;
    __weak __typeof(&*self)weakSelf = self;
    if (self.isScaning)
    {
        [UIView animateWithDuration:1.6
                         animations:^{
                             weakSelf.lineView.frame = CGRectMake(weakSelf.preView.frame.origin.x, flag ? weakSelf.preView.frame.origin.y + 1.5: weakSelf.preView.frame.origin.y + weakSelf.preView.frame.size.height - 1.5, weakSelf.preView.frame.size.width, 1.5);
                         }
                         completion:^(BOOL finished) {
                             flag = !flag;
                             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.02 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                 [self scanAnimation];
                             });
                         }];
    }
}

+ (void)endScan
{
    JHQRCode *instance = [JHQRCode shareInstance];
    [instance.previewLayer removeFromSuperlayer];
    [instance.preView.layer removeFromSuperlayer];
    [instance.lineView.layer removeFromSuperlayer];
    [instance.session stopRunning];
    instance.isScaning = NO;
}

#pragma mark - delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    [self.session stopRunning];
    self.isScaning = NO;
    if (metadataObjects.count > 0 && self.completeBlock)
    {
        AVMetadataMachineReadableCodeObject *qrObj = [metadataObjects lastObject];
        self.completeBlock(qrObj.stringValue);
    }
    [self.previewLayer removeFromSuperlayer];
    [self.preView.layer removeFromSuperlayer];
    [self.lineView.layer removeFromSuperlayer];
    
}




@end
