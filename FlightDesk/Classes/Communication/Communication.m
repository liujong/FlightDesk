//
//  Communication.m
//  ChatAndMapSample
//
//  Created by stepanekdavid on 2/12/16.
//  Copyright © 2016 stepanekdavid. All rights reserved.
//

#import "Communication.h"

#import <AVFoundation/AVFoundation.h>

#ifdef DEVENV
    #define SERVER_URL              @"http://tmp.flightdeskapp.com/flightdesk"
#else
    #define SERVER_URL              @"http://flightdeskapp.com/flightdesk"
#endif

#define WEBAPI_FLIGHTDESKAPI           @"/flight_training_api.php"
#define WEBAPI_FLIGHTDESKAPI_UPLOAD_FIGUREIMAGE           @"/upload_figureimage.php"

@implementation Communication

#pragma mark - Shared Functions
+ (Communication*)sharedManager
{
    __strong static Communication* sharedObject = nil ;
    static dispatch_once_t onceToken ;
    
    dispatch_once( &onceToken, ^{
        sharedObject = [[Communication alloc]init];
    });
    
    return sharedObject ;
}

#pragma mark - SocialCommunication
- (id)init
{
    self = [super init];
    
    if( self )
    {
        
    }
    
    return self ;
}
- (void)sendToService:(NSDictionary*)_params
               action:(NSString*)_action
              success:(void (^)( id _responseObject))_success
              failure:(void (^)( NSError* _error))_failure
{
    NSString *strUrl = [NSString stringWithFormat:@"%@%@",SERVER_URL,_action];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.securityPolicy.allowInvalidCertificates = YES;
    
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    [requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
//    [requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
//    [requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [manager setRequestSerializer:requestSerializer];
    
    [manager.requestSerializer setTimeoutInterval:180];
    
    [manager POST:strUrl parameters:_params progress:nil success:^(NSURLSessionDataTask *operation, id _responseObject){
        
        if( _success )
        {
            _success( _responseObject);
            NSLog(@"success data");
        }
        
    } failure:^(NSURLSessionDataTask *operation, NSError *_error) {
        if( _failure )
        {
            NSLog(@"%@",_error.description);
            _failure( _error);
            
        }
    }];
}
- (void)sendToServiceByPOST:(NSString *)serviceAPIURL
                     params:(NSDictionary *)_params
                      media:(NSData* )_media
                  mediaType:(NSInteger)_mediaType // 0: photo, 1: video
                    success:(void (^)(id _responseObject))_success
                    failure:(void (^)(NSError* _error))_failure{


}
- (void)sendToServiceGet:(NSDictionary*)_params
                  action:(NSString*)_action
                 success:(void (^)( id _responseObject))_success
                 failure:(void (^)( NSError* _error))_failure
{
    NSString *strUrl = [NSString stringWithFormat:@"%@%@",SERVER_URL,_action];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.securityPolicy.allowInvalidCertificates = YES;
    
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    [requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

    
    [manager setRequestSerializer:requestSerializer];
    
    [manager GET:strUrl parameters:_params progress:nil success:^(NSURLSessionDataTask *operation, id _responseObject){
        
        if( _success )
        {
            _success( _responseObject);
        }
        
    } failure:^(NSURLSessionDataTask *operation, NSError *_error) {
        if( _failure )
        {
            NSLog(@"%@",_error.description);
            _failure( _error);
        }
    }];
}
- (void)sendToServicePut:(NSDictionary*)_params
                  action:(NSString*)_action
                 success:(void (^)( id _responseObject))_success
                 failure:(void (^)( NSError* _error))_failure
{
    NSString *strUrl = [NSString stringWithFormat:@"%@%@",SERVER_URL,_action];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.securityPolicy.allowInvalidCertificates = YES;
    
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    [requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [manager setRequestSerializer:requestSerializer];
    
    [manager PUT:strUrl parameters:_params success:^(NSURLSessionDataTask *operation, id _responseObject){
        
        if( _success )
        {
            _success( _responseObject);
        }
        
    } failure:^(NSURLSessionDataTask *operation, NSError *_error) {
        if( _failure )
        {
            NSLog(@"%@",_error.description);
            _failure( _error);
            
        }
    }];
}
- (void)sendToServiceDelete:(NSDictionary*)_params
                  action:(NSString*)_action
                 success:(void (^)( id _responseObject))_success
                 failure:(void (^)( NSError* _error))_failure
{
    NSString *strUrl = [NSString stringWithFormat:@"%@%@",SERVER_URL,_action];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.securityPolicy.allowInvalidCertificates = YES;
    
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    [requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [manager setRequestSerializer:requestSerializer];
    
    [manager DELETE:strUrl parameters:_params success:^(NSURLSessionDataTask *operation, id _responseObject){
        
        if( _success )
        {
            _success( _responseObject);
        }
        
    } failure:^(NSURLSessionDataTask *operation, NSError *_error) {
        if( _failure )
        {
            NSLog(@"%@",_error.description);
            _failure( _error);
            
        }
    }];
}
- (void)sendToServiceByPOST:(NSString *)serviceAPIURL
                     params:(NSDictionary *)_params
                      media:(NSData* )_media
                  mediaType:(NSInteger)_mediaType // 0: photo, 1: video
                       name:(NSString *)name
                    success:(void (^)(id _responseObject))_success
                    failure:(void (^)(NSError* _error))_failure
{
    NSString *strUrl = [NSString stringWithFormat:@"%@%@",SERVER_URL,serviceAPIURL];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    //manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
    manager.securityPolicy.allowInvalidCertificates = YES;
    
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    [requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [manager setRequestSerializer:requestSerializer];
    NSDate *currentime = [NSDate date];
    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"yyyyMMddhhmmss"];
    NSString *imagefileName = [dateformatter stringFromDate:currentime];
    
    NSDictionary *parameters = _params;
    [manager POST:strUrl parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        
        if (_media) {
            if (_mediaType == 0) {
                
                [formData appendPartWithFileData:_media
                                            name:name
                                        fileName:[NSString stringWithFormat:@"Jella-%@.jpg",imagefileName]
                                        mimeType:@"image/jpeg"];
            } else {
                [formData appendPartWithFileData:_media
                                            name:name
                                        fileName:name
                                        mimeType:@"video/quicktime"];
            }
        }
    } progress:nil success:^(NSURLSessionDataTask *operation, id responseObject) {
        
        // Success ;
        if (_success) {
            _success(responseObject);
        }
        
    } failure:^(NSURLSessionDataTask *operation, NSError *error) {
        
        // Failture ;
        if (_failure) {
            _failure(error);
        }
        
    }];
}
- (void)sendToServiceJSON:(NSString *)action
                   params:(NSDictionary *)_params
                  success:(void (^)(id _responseObject))_success
                  failure:(void (^)(NSError *_error))_failure
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.securityPolicy.allowInvalidCertificates = YES;
    
    NSError *error;
    NSData *jsonLoginData =[NSJSONSerialization dataWithJSONObject:_params options:0 error:&error];
    
    AFJSONRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
    [requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [requestSerializer setValue:[NSString stringWithFormat:@"%lu", (unsigned long)jsonLoginData.length] forHTTPHeaderField:@"Content-Length"];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", nil];
    manager.requestSerializer = requestSerializer;
    
    [manager POST:action parameters:_params progress:nil success:^(NSURLSessionDataTask *operation, id responseObject) {
        
        // Success ;
        if (_success)
        {
            _success(responseObject);
        }
        
    } failure:^(NSURLSessionDataTask *operation, NSError *error) {
        NSLog( @"Error:%@", error.description);
        
        // Failture ;
        if (_failure)
        {
            _failure(error);
        }
    }];
}

//FlightDesk API
- (void)ActionFlightDeskLogin:(NSString*)_action
        userName:(NSString*)_username
         password:(NSString*)_password
        successed:(void (^)( id _responseObject))_success
          failure:(void (^)( NSError* _error))_failure
{
    NSMutableDictionary*    params  = [NSMutableDictionary dictionary];
    [params setObject : _action     forKey : @"action"];
    [params setObject : _username          forKey : @"username"];
    [params setObject : _password          forKey : @"password"];
    [params setObject:[AppDelegate sharedDelegate].device_token forKey:@"device_token"];
    [self sendToServiceJSON:[NSString stringWithFormat:@"%@%@", SERVER_URL, WEBAPI_FLIGHTDESKAPI] params:params success:_success failure:_failure ];
}

- (void)ActionFlightDeskRelease:(NSString*)_action
                     userName:(NSString*)_username
                     password:(NSString*)_password
                    successed:(void (^)( id _responseObject))_success
                      failure:(void (^)( NSError* _error))_failure
{
    NSMutableDictionary*    params  = [NSMutableDictionary dictionary];
    [params setObject : _action     forKey : @"action"];
    [params setObject : _username          forKey : @"username"];
    [params setObject : _password          forKey : @"password"];
    [params setObject:[AppDelegate sharedDelegate].device_token forKey:@"device_token"];
    [self sendToServiceJSON:[NSString stringWithFormat:@"%@%@", SERVER_URL, WEBAPI_FLIGHTDESKAPI] params:params success:_success failure:_failure ];
}
- (void)ActionFlightDeskLogout:(NSString*)_action
                        userId:(NSString*)_userId
                     successed:(void (^)( id _responseObject))_success
                       failure:(void (^)( NSError* _error))_failure{
    NSMutableDictionary*    params  = [NSMutableDictionary dictionary];
    [params setObject : _action     forKey : @"action"];
    [params setObject : _userId          forKey : @"user_id"];
    
    [self sendToServiceJSON:[NSString stringWithFormat:@"%@%@", SERVER_URL, WEBAPI_FLIGHTDESKAPI] params:params success:_success failure:_failure ];
}
- (void)ActionFlightDeskDeleteCurrentUser:(NSString*)_action
                        userId:(NSString*)_userId
                     successed:(void (^)( id _responseObject))_success
                       failure:(void (^)( NSError* _error))_failure{
    NSMutableDictionary*    params  = [NSMutableDictionary dictionary];
    [params setObject : _action     forKey : @"action"];
    [params setObject : _userId          forKey : @"user_id"];
    
    [self sendToServiceJSON:[NSString stringWithFormat:@"%@%@", SERVER_URL, WEBAPI_FLIGHTDESKAPI] params:params success:_success failure:_failure ];
}

- (void)ActionFlightDeskSecurityQuestion:(NSString*)_action
                                username:(NSString*)_username
                                question:(NSString*)_question
                                  answer:(NSString*)_answer
                               successed:(void (^)( id _responseObject))_success
                                 failure:(void (^)( NSError* _error))_failure{
    
    NSMutableDictionary*    params  = [NSMutableDictionary dictionary];
    [params setObject : _action     forKey : @"action"];
    [params setObject : _username          forKey : @"username"];
    [params setObject : _question          forKey : @"question"];
    [params setObject : _answer          forKey : @"answer"];
    [params setObject:[AppDelegate sharedDelegate].device_token forKey:@"device_token"];
    
    [self sendToServiceJSON:[NSString stringWithFormat:@"%@%@", SERVER_URL, WEBAPI_FLIGHTDESKAPI] params:params success:_success failure:_failure ];
}

- (void)ActionFlightDeskCheckUsername:(NSString*)_action
                             username:(NSString*)_username
                            successed:(void (^)( id _responseObject))_success
                              failure:(void (^)( NSError* _error))_failure{
    
    NSMutableDictionary*    params  = [NSMutableDictionary dictionary];
    [params setObject : _action     forKey : @"action"];
    [params setObject : _username          forKey : @"username"];
    
    [self sendToServiceJSON:[NSString stringWithFormat:@"%@%@", SERVER_URL, WEBAPI_FLIGHTDESKAPI] params:params success:_success failure:_failure ];
}
- (void)ActionFlightDeskSaveLessonRecords:(NSString*)_action
                userId:(NSNumber *)_userId
                lessonRecrods:(NSArray *)_lessonRecords
               successed:(void (^)( id _responseObject))_success
                 failure:(void (^)( NSError* _error))_failure
{
    NSMutableDictionary*    params  = [NSMutableDictionary dictionary];
    [params setObject : _action     forKey : @"action"];
    [params setObject : _userId          forKey : @"user_id"];
    [params setObject : _lessonRecords          forKey : @"lesson_records"];
    
    [self sendToServiceJSON:[NSString stringWithFormat:@"%@%@", SERVER_URL, WEBAPI_FLIGHTDESKAPI] params:params success:_success failure:_failure ];
}
- (void)ActionFlightDeskLastUpdate:(NSString*)_action
                                   userId:(NSNumber *)_userId
                            lastUpdate:(NSNumber *)_lastUpdate
                                successed:(void (^)( id _responseObject))_success
                                  failure:(void (^)( NSError* _error))_failure
{
    NSMutableDictionary*    params  = [NSMutableDictionary dictionary];
    [params setObject : _action     forKey : @"action"];
    [params setObject : _userId          forKey : @"user_id"];
    [params setObject : _lastUpdate          forKey : @"last_update"];
    
    [self sendToServiceJSON:[NSString stringWithFormat:@"%@%@", SERVER_URL, WEBAPI_FLIGHTDESKAPI] params:params success:_success failure:_failure ];
}

- (void)ActionFlightDeskLogEntries:(NSString*)_action
                            userId:(NSNumber *)_userId
                        logEntries:(NSNumber *)_logEntries
                         successed:(void (^)( id _responseObject))_success
                           failure:(void (^)( NSError* _error))_failure{
    
    NSMutableDictionary*    params  = [NSMutableDictionary dictionary];
    [params setObject : _action     forKey : @"action"];
    [params setObject : _userId          forKey : @"user_id"];
    [params setObject : _logEntries          forKey : @"log_entries"];
    
    [self sendToServiceJSON:[NSString stringWithFormat:@"%@%@", SERVER_URL, WEBAPI_FLIGHTDESKAPI] params:params success:_success failure:_failure ];
}
- (void)ActionFlightDeskUserRegisterUpdate:(NSString*)_action
                                 firstName:(NSString*)_firstName
                                middleName:(NSString*)_middleName
                                  lastName:(NSString*)_lastName
                                     email:(NSString*)_email
                                     phone:(NSString*)_phone
                                      role:(NSString*)_role
                                  username:(NSString*)_username
                                  password:(NSString*)_password
                                    userid:(NSString*)_userid
                                 pilotCert:(NSString*)_pilotCert
                        pilotCertIssueDate:(NSString*)_pilotCertIssueDate
                      medicalCertIssueDate:(NSString *)_medicalCertIssueDate
                        medicalCertExpDate:(NSString*)_medicalCertExpDate
                            cfiCertExpDate:(NSString*)_cfiCertExpDate
                                  question:(NSString*)_question
                                    answer:(NSString*)_answer
                    successed:(void (^)( id _responseObject))_success
                      failure:(void (^)( NSError* _error))_failure
{
    NSMutableDictionary*    params  = [NSMutableDictionary dictionary];
    [params setObject : _action     forKey : @"action"];
    [params setObject : _firstName          forKey : @"firstName"];
    [params setObject : _middleName          forKey : @"middleName"];
    [params setObject : _lastName          forKey : @"lastName"];
    [params setObject : _email          forKey : @"email"];
    [params setObject : _phone          forKey : @"phone"];
    [params setObject : _role          forKey : @"role"];
    [params setObject : _username          forKey : @"username"];
    [params setObject : _password          forKey : @"password"];
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [params setObject : [dateFormatter stringFromDate:[NSDate date]]          forKey : @"created"];
    if (_userid && ![_userid isEqualToString:@""]) {
        [params setObject : _userid          forKey : @"userid"];
    }
    
    [params setObject : _pilotCert          forKey : @"pilotCert"];
    [params setObject : _pilotCertIssueDate          forKey : @"pilotCertIssueDate"];
    [params setObject : _medicalCertIssueDate          forKey : @"medicalCertIssueDate"];
    [params setObject : _medicalCertExpDate          forKey : @"medicalCertExpDate"];
    [params setObject : _cfiCertExpDate          forKey : @"cfiCertExpDate"];
    [params setObject : _question          forKey : @"question"];
    [params setObject : _answer          forKey : @"answer"];
    
    
    
    [self sendToServiceJSON:[NSString stringWithFormat:@"%@%@", SERVER_URL, WEBAPI_FLIGHTDESKAPI] params:params success:_success failure:_failure ];
}

- (void)uploadFigurePhoto:(NSString *)userid
                  imgData:(NSData *)imgData
                successed:(void (^)(id responseObject)) success
                  failure:(void (^)(NSError* error)) failure
{
    //set Parameters
    NSMutableDictionary* params = [NSMutableDictionary dictionary];
    [params setObject:userid     forKey:@"userid"];
    [self sendToServiceByPOST:[NSString stringWithFormat:@"%@?userid=%@",WEBAPI_FLIGHTDESKAPI_UPLOAD_FIGUREIMAGE,userid] params:params media:imgData mediaType:0 name:@"file" success:success failure:failure];
}
- (void)ActionFlightDeskVerifyEmail:(NSString*)_action
                             userId:(NSString *)_userId
                         verifyCode:(NSString*)_verifyCode
                          successed:(void (^)( id _responseObject))_success
                            failure:(void (^)( NSError* _error))_failure{
    NSMutableDictionary*    params  = [NSMutableDictionary dictionary];
    [params setObject : _action     forKey : @"action"];
    [params setObject : _userId          forKey : @"user_id"];
    [params setObject : _verifyCode          forKey : @"verify_code"];
    
    [self sendToServiceJSON:[NSString stringWithFormat:@"%@%@", SERVER_URL, WEBAPI_FLIGHTDESKAPI] params:params success:_success failure:_failure ];
}
- (void)ActionFlightDeskResendVerificationCode:(NSString*)_action
                             userId:(NSString *)_userId
                         userEmail:(NSString*)_userEmail
                          successed:(void (^)( id _responseObject))_success
                            failure:(void (^)( NSError* _error))_failure{
    NSMutableDictionary*    params  = [NSMutableDictionary dictionary];
    [params setObject : _action     forKey : @"action"];
    [params setObject : _userId          forKey : @"user_id"];
    [params setObject : _userEmail          forKey : @"user_email"];
    
    [self sendToServiceJSON:[NSString stringWithFormat:@"%@%@", SERVER_URL, WEBAPI_FLIGHTDESKAPI] params:params success:_success failure:_failure ];
}

- (void)ActionFlightDeskFindInstructor:(NSString*)_action
                                userId:(NSString *)_userId
                          instructorID:(NSString*)_instructorID
                       preInstructorID:(NSString*)_preInstructorID
                             programID:(NSNumber*)_programID
                             successed:(void (^)( id _responseObject))_success
                               failure:(void (^)( NSError* _error))_failure{
    NSMutableDictionary*    params  = [NSMutableDictionary dictionary];
    [params setObject : _action         forKey : @"action"];
    [params setObject : _userId         forKey : @"user_id"];
    [params setObject : _instructorID   forKey : @"instructor_id"];
    [params setObject : _preInstructorID   forKey : @"pre_instructor_id"];
    [params setObject : _programID      forKey : @"program_id"];
    
    [self sendToServiceJSON:[NSString stringWithFormat:@"%@%@", SERVER_URL, WEBAPI_FLIGHTDESKAPI] params:params success:_success failure:_failure ];
}
- (void)ActionFlightDeskFindStudent:(NSString*)_action
                                userId:(NSString *)_userId
                          studentID:(NSString*)_studentID
                             programID:(NSNumber*)_programID
                             successed:(void (^)( id _responseObject))_success
                               failure:(void (^)( NSError* _error))_failure{
    NSMutableDictionary*    params  = [NSMutableDictionary dictionary];
    [params setObject : _action         forKey : @"action"];
    [params setObject : _userId         forKey : @"user_id"];
    [params setObject : _studentID   forKey : @"student_id"];
    [params setObject : _programID      forKey : @"program_id"];
    
    [self sendToServiceJSON:[NSString stringWithFormat:@"%@%@", SERVER_URL, WEBAPI_FLIGHTDESKAPI] params:params success:_success failure:_failure ];
}
- (void)ActionFlightDeskRemoveStudent:(NSString*)_action
                             userId:(NSString *)_userId
                          studentID:(NSNumber*)_studentID
                          programID:(NSNumber*)_programID
                          successed:(void (^)( id _responseObject))_success
                            failure:(void (^)( NSError* _error))_failure{
    NSMutableDictionary*    params  = [NSMutableDictionary dictionary];
    [params setObject : _action         forKey : @"action"];
    [params setObject : _userId         forKey : @"user_id"];
    [params setObject : _studentID   forKey : @"student_id"];
    [params setObject : _programID      forKey : @"program_id"];
    
    [self sendToServiceJSON:[NSString stringWithFormat:@"%@%@", SERVER_URL, WEBAPI_FLIGHTDESKAPI] params:params success:_success failure:_failure ];
}
@end
