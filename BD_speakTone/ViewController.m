//
//  ViewController.m
//  BD_speakTone
//
//  Created by Safio Wan on 2019/9/5.
//  Copyright © 2019 Safio Wan. All rights reserved.
//

#import "ViewController.h"
/** 语音识别 */
#import "BDSEventManager.h"
#import "BDSASRDefines.h"
#import "BDSASRParameters.h"
const NSString* APP_ID = @"17182064";
const NSString* API_KEY = @"d7rvXkz2OOkqYVIcKX8wARar";
const NSString* SECRET_KEY = @"exOti1HeXppDUlUSewejpwqjaVKq4Ssi";

@interface ViewController ()<BDSClientASRDelegate>
@property (nonatomic,strong)  BDSEventManager *BDspeakEventManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 创建语音识别对象
    self.BDspeakEventManager = [BDSEventManager createEventManagerWithName:BDS_ASR_NAME];
    // 设置语音唤醒代理
    [self.BDspeakEventManager setDelegate:self];
    
    [self.BDspeakEventManager setParameter:@[API_KEY, SECRET_KEY] forKey:BDS_ASR_API_SECRET_KEYS];
    
    //开启提示音 @0 : @"关闭", @(EVRPlayToneAll) : @"开启"}
    [self.BDspeakEventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_LONG_SPEECH];
    //    NSString* toneAsrPath = [[NSBundle mainBundle] pathForResource:@"record_success" ofType:@"caf"];
#error 请正确设置提示音
    [self.BDspeakEventManager setParameter:@(EVRPlayToneTypeStart) forKey:BDS_ASR_PLAY_TONE];
    
    //离线引擎身份验证 设置 APPID 离线授权所需APPCODE（APPID）， 如使用该方式进行正式授权，请移除临时授权文件
    [self.BDspeakEventManager setParameter:APP_ID forKey:BDS_ASR_OFFLINE_APP_CODE];
    //离线正式授权文件路径
    NSString* offline_license = [[NSBundle mainBundle] pathForResource:@"bds_license" ofType:@"dat"];
    [self.BDspeakEventManager setParameter:offline_license forKey:BDS_ASR_OFFLINE_LICENSE_FILE_PATH];
    //识别语言 @0 : @"普通话", @1 : @"粤语", @2 : @"英文", @3 : @"四川话"
    [self.BDspeakEventManager setParameter:@(EVoiceRecognitionLanguageChinese) forKey:BDS_ASR_LANGUAGE];
    //采样率 @"自适应", @"8K", @"16K"
    [self.BDspeakEventManager setParameter:@(EVoiceRecognitionRecordSampleRateAuto) forKey:BDS_ASR_SAMPLE_RATE];
    //设置DEBUG_LOG的级别
    [self.BDspeakEventManager setParameter:@(EVRDebugLogLevelTrace) forKey:BDS_ASR_DEBUG_LOG_LEVEL];
    //唤醒后立刻进行识别需开启该参数，其他情况请忽略该参数
    //    [self.BDspeakEventManager setParameter:@(YES) forKey:BDS_ASR_NEED_CACHE_AUDIO];
    
    [self.BDspeakEventManager setParameter:@"" forKey:BDS_ASR_OFFLINE_ENGINE_TRIGGERED_WAKEUP_WORD];
    
    //开启端点检测 {@NO : @"关闭", @YES : @"开启"} 使用长语音必须开启本地VAD
    //端点检测，即自动检测音频输入的起始点和结束点。SDK默认开启VAD，检测到静音后自动停止识别。
    //如果需要自行控制识别结束需关闭VAD，请同时关闭服务端VAD与端上VAD
    [self.BDspeakEventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_LOCAL_VAD];
    // 关闭服务端VAD
    //      [self.BDspeakEventManager setParameter:@(NO) forKey:BDS_ASR_ENABLE_EARLY_RETURN];
    // 关闭本地VAD
    //      [self.BDspeakEventManager setParameter:@(NO) forKey:BDS_ASR_ENABLE_LOCAL_VAD];
    //打开的话配置端点检测（二选一）
    [self configModelVAD];//ModelVAD
    //[self configDNNMFE];//DNNMFE
    // ModelVAD端点检测方式  检测更加精准，抗噪能力强，响应速度较慢
    
    //离在线并行识别
    // 参数设置：识别策略为离在线并行
    [self.BDspeakEventManager setParameter:@(EVR_STRATEGY_BOTH) forKey:BDS_ASR_STRATEGY];
    // 参数设置：离线识别引擎类型 EVR_OFFLINE_ENGINE_INPUT 输入法模式  EVR_OFFLINE_ENGINE_GRAMMER 离线引    擎语法模式
    //离线语音识别仅支持命令词识别（语法模式）。
    //[self.BDspeakEventManager setParameter:@(EVR_OFFLINE_ENGINE_INPUT) forKey:BDS_ASR_OFFLINE_ENGINE_TYPE];
    [self.BDspeakEventManager setParameter:@(EVR_OFFLINE_ENGINE_GRAMMER) forKey:BDS_ASR_OFFLINE_ENGINE_TYPE];
    //并生成bsg文件。下载语法文件后，设置BDS_ASR_OFFLINE_ENGINE_GRAMMER_FILE_PATH参数
    NSString* gramm_filepath = [[NSBundle mainBundle] pathForResource:@"baidu_speech_grammar" ofType:@"bsg"];
    // 请在 (官网)[http://speech.baidu.com/asr] 参考模板定义语法，下载语法文件后，替换BDS_ASR_OFFLINE_ENGINE_GRAMMER_FILE_PATH参数
    [self.BDspeakEventManager setParameter:gramm_filepath forKey:BDS_ASR_OFFLINE_ENGINE_GRAMMER_FILE_PATH];
    //离线识别资源文件路径
    NSString* lm_filepath = [[NSBundle mainBundle] pathForResource:@"bds_easr_basic_model" ofType:@"dat"];
    [self.BDspeakEventManager setParameter:lm_filepath forKey:BDS_ASR_OFFLINE_ENGINE_DAT_FILE_PATH];
    //加载离线引擎
    [self.BDspeakEventManager sendCommand:BDS_ASR_CMD_LOAD_ENGINE];
    [self.BDspeakEventManager sendCommand:BDS_ASR_CMD_START];
    // Do any additional setup after loading the view, typically from a nib.
}
- (void)configModelVAD {
    NSString *modelVAD_filepath = [[NSBundle mainBundle] pathForResource:@"bds_easr_basic_model" ofType:@"dat"];
    //ModelVAD所需资源文件路径
    [self.BDspeakEventManager setParameter:modelVAD_filepath forKey:BDS_ASR_MODEL_VAD_DAT_FILE];
    
    [self.BDspeakEventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_MODEL_VAD];
    
    //开启语义理解
    [self.BDspeakEventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_NLU];
    
    [self.BDspeakEventManager setParameter:@"15363" forKey:BDS_ASR_PRODUCT_ID];
    
    
}
#pragma mark - MVoiceRecognitionClientDelegate
-(void)VoiceRecognitionClientWorkStatus:(int)workStatus obj:(id)aObj{
    switch (workStatus) {
        case EVoiceRecognitionClientWorkStatusNewRecordData: {
            break;
        }
            
        case EVoiceRecognitionClientWorkStatusStartWorkIng: {
            break;
        }
        case EVoiceRecognitionClientWorkStatusStart: {
            NSLog(@" Start Tone shoud rising");
            break;
        }
        case EVoiceRecognitionClientWorkStatusEnd: {
            break;
        }
        case EVoiceRecognitionClientWorkStatusFlushData: {
            break;
        }
        case EVoiceRecognitionClientWorkStatusFinish: {
            break;
        }
        case EVoiceRecognitionClientWorkStatusMeterLevel: {
            break;
        }
        case EVoiceRecognitionClientWorkStatusCancel: {
            break;
        }
        case EVoiceRecognitionClientWorkStatusError: {
            break;
        }
        case EVoiceRecognitionClientWorkStatusLoaded: {
            break;
        }
        case EVoiceRecognitionClientWorkStatusUnLoaded: {
            break;
        }
        case EVoiceRecognitionClientWorkStatusChunkThirdData: {
            break;
        }
        case EVoiceRecognitionClientWorkStatusChunkNlu: {
            NSString *nlu = [[NSString alloc] initWithData:(NSData *)aObj encoding:NSUTF8StringEncoding];
            NSLog(@"%@", nlu);
            break;
        }
        case EVoiceRecognitionClientWorkStatusChunkEnd: {
            break;
        }
        case EVoiceRecognitionClientWorkStatusFeedback: {
            break;
        }
        case EVoiceRecognitionClientWorkStatusRecorderEnd: {
            break;
        }
        case EVoiceRecognitionClientWorkStatusLongSpeechEnd: {
            break;
        }
        default:
            break;
    }

}
@end
