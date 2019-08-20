//
//  Communication.h
//  ChatAndMapSample
//
//  Created by stepanekdavid on 2/12/16.
//  Copyright © 2016 stepanekdavid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPSessionManager.h"

@interface Communication : AFHTTPSessionManager<NSURLConnectionDelegate>
{
    NSMutableData *_responseData;
}
+ (Communication*)sharedManager ;
- (void)sendToService:(NSDictionary*)_params
               action:(NSString*)_action
              success:(void (^)(id _responseObject))_success
              failure:(void (^)(NSError* _error))_failure ;
- (void)sendToServiceByPOST:(NSString *)serviceAPIURL
                     params:(NSDictionary *)_params
                      media:(NSData* )_media
                  mediaType:(NSInteger)_mediaType // 0: photo, 1: video
                    success:(void (^)(id _responseObject))_success
                    failure:(void (^)(NSError* _error))_failure;

//FlightDesk apis
- (void)ActionFlightDeskLogin:(NSString*)_action
                userName:(NSString*)_username
                password:(NSString*)_password
               successed:(void (^)( id _responseObject))_success
                      failure:(void (^)( NSError* _error))_failure;
- (void)ActionFlightDeskRelease:(NSString*)_action
                     userName:(NSString*)_username
                     password:(NSString*)_password
                    successed:(void (^)( id _responseObject))_success
                      failure:(void (^)( NSError* _error))_failure;
- (void)ActionFlightDeskLogout:(NSString*)_action
                     userId:(NSString*)_userId
                    successed:(void (^)( id _responseObject))_success
                      failure:(void (^)( NSError* _error))_failure;
- (void)ActionFlightDeskDeleteCurrentUser:(NSString*)_action
                                   userId:(NSString*)_userId
                                successed:(void (^)( id _responseObject))_success
                                  failure:(void (^)( NSError* _error))_failure;
- (void)ActionFlightDeskSecurityQuestion:(NSString*)_action
                                username:(NSString*)_username
                                question:(NSString*)_question
                                  answer:(NSString*)_answer
                               successed:(void (^)( id _responseObject))_success
                                 failure:(void (^)( NSError* _error))_failure;

- (void)ActionFlightDeskCheckUsername:(NSString*)_action
                            username:(NSString*)_username
                            successed:(void (^)( id _responseObject))_success
                              failure:(void (^)( NSError* _error))_failure;

- (void)ActionFlightDeskSaveLessonRecords:(NSString*)_action
                                   userId:(NSNumber *)_userId
                            lessonRecrods:(NSArray *)_lessonRecords
                                successed:(void (^)( id _responseObject))_success
                                  failure:(void (^)( NSError* _error))_failure;
- (void)ActionFlightDeskLastUpdate:(NSString*)_action
                            userId:(NSNumber *)_userId
                        lastUpdate:(NSNumber *)_lastUpdate
                         successed:(void (^)( id _responseObject))_success
                           failure:(void (^)( NSError* _error))_failure;
- (void)ActionFlightDeskLogEntries:(NSString*)_action
                            userId:(NSNumber *)_userId
                        logEntries:(NSNumber *)_logEntries
                         successed:(void (^)( id _responseObject))_success
                           failure:(void (^)( NSError* _error))_failure;
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
                      medicalCertIssueDate:(NSString*)_medicalCertIssueDate
                        medicalCertExpDate:(NSString*)_medicalCertExpDate
                            cfiCertExpDate:(NSString*)_cfiCertExpDate
                                  question:(NSString*)_question
                                    answer:(NSString*)_answer
                                 successed:(void (^)( id _responseObject))_success
                                   failure:(void (^)( NSError* _error))_failure;

- (void)uploadFigurePhoto:(NSString *)userid
                   imgData:(NSData *)imgData
                 successed:(void (^)(id responseObject)) success
                   failure:(void (^)(NSError* error)) failure;

- (void)ActionFlightDeskVerifyEmail:(NSString*)_action
                             userId:(NSString *)_userId
                         verifyCode:(NSString*)_verifyCode
                          successed:(void (^)( id _responseObject))_success
                            failure:(void (^)( NSError* _error))_failure;
- (void)ActionFlightDeskResendVerificationCode:(NSString*)_action
                                        userId:(NSString *)_userId
                                     userEmail:(NSString*)_userEmail
                                     successed:(void (^)( id _responseObject))_success
                                       failure:(void (^)( NSError* _error))_failure;
- (void)ActionFlightDeskFindInstructor:(NSString*)_action
                                userId:(NSString *)_userId
                          instructorID:(NSString*)_instructorID
                       preInstructorID:(NSString*)_preInstructorID
                          programID:(NSNumber*)_programID
                             successed:(void (^)( id _responseObject))_success
                               failure:(void (^)( NSError* _error))_failure;
- (void)ActionFlightDeskFindStudent:(NSString*)_action
                             userId:(NSString *)_userId
                          studentID:(NSString*)_studentID
                          programID:(NSNumber*)_programID
                          successed:(void (^)( id _responseObject))_success
                            failure:(void (^)( NSError* _error))_failure;
- (void)ActionFlightDeskRemoveStudent:(NSString*)_action
                               userId:(NSString *)_userId
                            studentID:(NSNumber *)_studentID
                            programID:(NSNumber *)_programID
                            successed:(void (^)( id _responseObject))_success
                              failure:(void (^)( NSError* _error))_failure;
@end

