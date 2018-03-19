//
//  ViewController.m
//  NFCDemo
//
//  Created by Heaton on 2018/3/19.
//  Copyright © 2018年 WangMingDeveloper. All rights reserved.
//

#import "ViewController.h"
#import <CoreNFC/CoreNFC.h>
#import <MessageUI/MessageUI.h>
//需要开启一个session，与其他session类似，同时只能开启一个
//需要App完全在前台模式
//每个session最多扫描60s，超时需再次开启新session
//配置读取单个或多个Tag，配置为单个时，会在读取到第一个Tag时自动结束session
//隐私描述（后文会写到如何配置）会在扫描页面显示

@interface ViewController ()<NFCNDEFReaderSessionDelegate,MFMailComposeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *readText;
@property(nonatomic,strong) NSString *url;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
}

- (IBAction)scanNFC:(UIButton *)sender {
    // YES：读取一个结束，NO：读取多个
    self.readText.text = nil;
    NFCNDEFReaderSession *session = [[NFCNDEFReaderSession alloc] initWithDelegate:self queue:dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT) invalidateAfterFirstRead:YES];
    [session beginSession];
    
    
}

- (void)readerSessionDidBecomeActive:(NFCReaderSession *)session{
    
}


- (void) readerSession:(nonnull NFCNDEFReaderSession *)session didDetectNDEFs:(nonnull NSArray<NFCNDEFMessage *> *)messages {
    
    for (NFCNDEFMessage *message in messages) {
        for (NFCNDEFPayload *payload in message.records) {
            dispatch_async(dispatch_get_main_queue(), ^{
//                NSString *messeage = [[NSString alloc] initWithData:payload.payload encoding:NSUTF8StringEncoding];
//                NSLog(@"读取到的信息是:%@",messeage);
//                NSString *typeString = [[NSString alloc] initWithData:payload.type encoding:NSUTF8StringEncoding];
//                NSString *identifier = [[NSString alloc] initWithData:payload.identifier encoding:NSUTF8StringEncoding];
//                NSInteger format = payload.typeNameFormat;
//
//                NSString *outputStr = [NSString stringWithFormat:@"NDEF Format:%ld\nNDEF Type:%@\nNDEF ID:%@\nNDEF Messeage:%@\n",format,typeString,identifier,messeage];
//                self.readText.text = outputStr;
                [self parse:payload];
            });
        }
    }
}

-(void)readerSession:(NFCNDEFReaderSession *)session didInvalidateWithError:(NSError *)error{
    NSLog(@"%@",error);
}



//名词简介：RTD
//RTD： record typedefinition
//NID：namespace indentifier
//NSS：namespace specific string
//URI：uniform resourceindentifier
//URN：uniform resource name
//MIME: multipurpose internet mailextension
-(void)parse:(nullable NFCNDEFPayload *)payload{
    if(payload == nil)return;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *messeage = [[NSString alloc] initWithData:payload.payload encoding:NSUTF8StringEncoding];
        NSLog(@"读取到的信息是:%@",messeage);
        NSString *typeString = [[NSString alloc] initWithData:payload.type encoding:NSUTF8StringEncoding];
        NSString *identifier = [[NSString alloc] initWithData:payload.identifier encoding:NSUTF8StringEncoding];
        NSInteger format = payload.typeNameFormat;
        NSUInteger payloadBytesLength = [payload.payload length];
        NSString *outputStr = [NSString stringWithFormat:@"NDEF Format:%ld\nNDEF Type:%@\nNDEF ID:%@\nNDEF Messeage:%@\n",format,typeString,identifier,messeage];
        self.readText.text = outputStr;
        unsigned char *payloadBytes = (unsigned char*)[payload.payload bytes];
        NSString *url = nil;
        if(payload.typeNameFormat == NFCTypeNameFormatNFCWellKnown){//参考RTD信息
            if([typeString isEqualToString:@"U"]){
                switch (payloadBytes[0]) {
                        // N/A. No prepending is done
                    case 0x00:break;
                    case 0x01:
                        url = [@"http://www." stringByAppendingString:messeage];break;
                    case 0x02:
                        url = [@"https://www." stringByAppendingString:messeage];break;
                    case 0x03:
                        url = [@"http://" stringByAppendingString:messeage];break;
                    case 0x04:
                        url = [@"https://" stringByAppendingString:messeage];break;
                    case 0x05:
                        url =  [@"tel:" stringByAppendingString:messeage];break;
                    case 0x06: // mailto:
                    {
                        url = [@"mailto:" stringByAppendingString:messeage];
                        self.url = messeage;
                        if([MFMailComposeViewController canSendMail] == YES) {
                            UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"温馨提示" message:[NSString stringWithFormat:@"写邮件给%@,需要吗？",messeage] preferredStyle:UIAlertControllerStyleAlert];
                            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"不需要" style:UIAlertActionStyleCancel handler:nil];
                            UIAlertAction *suere = [UIAlertAction actionWithTitle:@"马上发" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                                //创建可变的地址字符串对象
                                NSMutableString *mailUrl = [[NSMutableString alloc] init];
                                //添加收件人,如有多个收件人，可以使用componentsJoinedByString方法连接，连接符为","
                                [mailUrl appendFormat:@"mailto:%@?", messeage];
                                //添加抄送人
                                NSString *ccRecipients = @"10000000@qq.com";
                                [mailUrl appendFormat:@"&cc=%@", ccRecipients];
                                //添加密送人
                                NSString *bccRecipients = @"256789000@163.com";
                                [mailUrl appendFormat:@"&bcc=%@", bccRecipients];
                                //添加邮件主题
                                [mailUrl appendFormat:@"&subject=%@",@"填写你的邮件主题"];
                                //添加邮件内容
                                [mailUrl appendString:@"&body=<b>Hello</b> World!"];
                                //跳转到系统邮件App发送邮件
                                NSString *emailPath = [mailUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
                                [[UIApplication sharedApplication]openURL:[NSURL URLWithString:emailPath] options:@{} completionHandler:nil];
                                
                
                                //判断用户是否已设置邮件账户
//                                [self sendEmailAction]; // 调用发送邮件的代码
                            }];
                            [alertVC addAction:cancel];
                            [alertVC addAction:suere];
                            [self presentViewController:alertVC animated:YES completion:nil];
                        }else{
                            UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"请先设置邮件账户,谢谢" preferredStyle:UIAlertControllerStyleAlert];
                            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"我知道了" style:UIAlertActionStyleCancel handler:nil];
                            [alertVC addAction:cancel];
                            [self presentViewController:alertVC animated:YES completion:nil];
                        }
                        
                    }
                    break;
                    case 0x07: // ftp://anonymous:anonymous@
                        url = [@"ftp://anonymous:anonymous@" stringByAppendingString:messeage]; break;
                    case 0x08: // ftp://ftp.
                        url = [@"ftp://ftp." stringByAppendingString:messeage]; break;
                    case 0x09: // ftps://
                        url = [@"ftps://" stringByAppendingString:messeage]; break;
                    case 0x0A: // sftp://
                        url = [@"sftp://" stringByAppendingString:messeage]; break;
                    case 0x0B: // smb://
                        url = [@"smb://" stringByAppendingString:messeage]; break;
                    case 0x0C: // nfs://
                        url = [@"nfs://" stringByAppendingString:messeage]; break;
                    case 0x0D: // ftp://
                        url = [@"ftp://" stringByAppendingString:messeage]; break;
                    case 0x0E: // dav://
                        url = [@"dav://" stringByAppendingString:messeage]; break;
                    case 0x0F: // news:
                        url = [@"news:" stringByAppendingString:messeage]; break;
                    case 0x10: // telnet://
                        url = [@"telnet://" stringByAppendingString:messeage]; break;
                    case 0x11: // imap:
                        url = [@"imap:" stringByAppendingString:messeage]; break;
                    case 0x12: // rtsp://
                        url = [@"rtsp://" stringByAppendingString:messeage]; break;
                    case 0x13: // urn:
                        url = [@"urn:" stringByAppendingString:messeage]; break;
                    case 0x14: // pop:
                        url = [@"pop:" stringByAppendingString:messeage]; break;
                    case 0x15: // sip:
                        url = [@"sip:" stringByAppendingString:messeage]; break;
                    case 0x16: // sips:
                        url = [@"sips:" stringByAppendingString:messeage]; break;
                    case 0x17: // tftp:
                        url = [@"tftp:" stringByAppendingString:messeage]; break;
                    case 0x18: // btspp://
                        url = [@"btspp://" stringByAppendingString:messeage]; break;
                    case 0x19: // btl2cap://
                        url = [@"btl2cap://" stringByAppendingString:messeage]; break;
                    case 0x1A: // btgoep://
                        url = [@"btgoep://" stringByAppendingString:messeage]; break;
                    case 0x1B: // tcpobex://
                        url = [@"tcpobex://" stringByAppendingString:messeage]; break;
                    case 0x1C: // irdaobex://
                        url = [@"irdaobex://" stringByAppendingString:messeage]; break;
                    case 0x1D: // file://
                        url = [@"file://" stringByAppendingString:messeage]; break;
                    case 0x1E: // urn:epc:id:
                        url = [@"urn:epc:id:" stringByAppendingString:messeage]; break;
                    case 0x1F: // urn:epc:tag:
                        url = [@"urn:epc:tag:" stringByAppendingString:messeage]; break;
                    case 0x20: // urn:epc:pat:
                        url = [@"urn:epc:pat:" stringByAppendingString:messeage]; break;
                    case 0x21: // urn:epc:raw:
                        url = [@"urn:epc:raw:" stringByAppendingString:messeage]; break;
                    case 0x22: // urn:epc:
                        url = [@"urn:epc:" stringByAppendingString:messeage]; break;
                    case 0x23: // urn:nfc:
                        url = [@"urn:nfc:" stringByAppendingString:messeage]; break;
                    default:
                        break;
                }
            }
        }
    });
    
}



- (void)parseTextPayload:(unsigned char* )payloadBytes length:(NSUInteger)length {

    // Parse first byte Text Record Status Byte.
    BOOL isUTF16 = payloadBytes[0] & 0x80;
    uint8_t codeLength = payloadBytes[0] & 0x7F;
    
    if (length < 1 + codeLength) {
//        return nil;
    }
    
    // Get lang code and text.
    NSString *langCode = [[NSString alloc] initWithBytes:payloadBytes + 1 length:codeLength encoding:NSUTF8StringEncoding];
    NSString *text = [[NSString alloc] initWithBytes:payloadBytes + 1 + codeLength
                                              length:length - 1 - codeLength
                                            encoding: (!isUTF16)?NSUTF8StringEncoding:NSUTF16StringEncoding];
    if (!langCode || !text) {
//        return nil;
    }
    
    NSLog(@"%@%@",langCode,text);
   
//    NSLog(@"")
}

#pragma mark - MFMailComposeViewControllerDelegate的代理方法：
-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    switch (result) {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail send canceled: 用户取消编辑");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved: 用户保存邮件");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent: 用户点击发送");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail send errored: %@ : 用户尝试保存或发送邮件失败", [error localizedDescription]);
            break;
    }
    // 关闭邮件发送视图
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
