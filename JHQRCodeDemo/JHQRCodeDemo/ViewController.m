//
//  ViewController.m
//  JHQRCodeDemo
//
//  Created by jalaSmart on 17/6/20.
//  Copyright © 2017年 MrChen. All rights reserved.
//

#import "JHQRCode.h"
#import "ViewController.h"
#define kHeight [[UIScreen mainScreen] bounds].size.height
#define kWidth [[UIScreen mainScreen] bounds].size.width

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *textField;

@property (weak, nonatomic) IBOutlet UIImageView *QRCodeImageView;
@property (weak, nonatomic) IBOutlet UILabel *resultLab;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)createQRCodeBtnClick:(UIButton *)sender {
    if (_textField.text.length <= 0)
    {
        NSLog(@"未输入信息");
        return;
    }
    
    self.QRCodeImageView.image = [JHQRCode buildQRCodeWithMessage:_textField.text withCodeType: JHCodeTypeQRCode withSize:CGSizeMake(150, 80)];

}


- (IBAction)scanBtnClick:(UIButton *)sender {
    
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake((kWidth - 240) / 2.0, (kHeight - 240) / 2.0, 240, 240)];
    view.backgroundColor = [UIColor clearColor];
    view.layer.borderColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:0.8].CGColor;
    view.layer.borderWidth = 2.5;
    
    UIView *lineView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 240, 5)];
    lineView.backgroundColor = [UIColor colorWithRed:0.1 green:0.9 blue:0.1 alpha:0.8];
    
    [JHQRCode scanWithView:self withscanView:view withLineView:lineView withCompleteBlock:^(NSString *result) {
        
        self.resultLab.text = [NSString stringWithFormat:@"扫描结果：%@", result];
    }];
}

- (UIImage *)handleCIImage:(CIImage *)image withSize:(CGSize)size
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

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.textField resignFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
