//
//  AddingQuizViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 6/5/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "AddingQuizViewController.h"
#import "AddQuestionViewController.h"
#import "QuestionCell.h"
#import "PersistentCoreDataStack.h"
#import "Quiz+CoreDataClass.h"
#import "Question+CoreDataClass.h"
#import "CountDownViewController.h"

@interface AddingQuizViewController ()<AddQuestionViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, MKDropdownMenuDelegate, MKDropdownMenuDataSource, CountDownViewControllerDelegate, SWTableViewCellDelegate>
{
    NSMutableArray *questionsArray;
    NSInteger currentIndex;
    
    NSNumber *courseGroupID;
    LessonGroup *currentCourse;
    
    BOOL isShownCoundDownDialog;
    
    NSManagedObjectContext *contextRecords;
    NSMutableArray *arrayLessonGroup;
}

@end

@implementation AddingQuizViewController

@synthesize currentQuiz, currentStudent;
@synthesize isEditOldQuiz;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
//    self.title = @"Adding New Quiz";
    
    [self.navigationItem setHidesBackButton:YES animated:YES];
    
    contextRecords = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    questionsArray = [[NSMutableArray alloc] init];
    currentIndex = 1;
    isShownCoundDownDialog = NO;
    corseDropmenu.dataSource = self;
    corseDropmenu.delegate = self;
    arrayLessonGroup = [[NSMutableArray alloc] init];
    [QuestionTableView registerNib:[UINib nibWithNibName:@"QuestionCell" bundle:nil] forCellReuseIdentifier:@"QuestionItem"];
    
    if (currentQuiz && isEditOldQuiz) {
        txtQuizname.text = currentQuiz.name;
        txtQuizNumber.text = [NSString stringWithFormat:@"%ld", [currentQuiz.quizNumber integerValue]];
        courseGroupID = currentQuiz.courseGroupID;

        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:contextRecords];
        NSError *error;
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"groupID == %@", currentQuiz.courseGroupID];
        [request setPredicate:predicate];
        NSArray *objects = [contextRecords executeFetchRequest:request error:&error];
        if (objects == nil) {
            FDLogError(@"Unable to retrieve students!");
        } else if (objects.count == 0) {
            FDLogDebug(@"No valid students found!");
        } else {
            LessonGroup *lsGroup = objects[0];
            currentCourse = lsGroup;
        }
        
        [corseDropmenu reloadAllComponents];
        txtTimeLimit.text = currentQuiz.timeLimit;
        txtPassingScore.text = [NSString stringWithFormat:@"%ld", [currentQuiz.passingScore integerValue]];
        [QuestionTableView reloadData];
    }
    
    [self reloadAllComponentsFrames];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"AddingQuizViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    
    CGRect sizeRect = [UIScreen mainScreen].bounds;
    [navView setFrame:CGRectMake(0, 0, sizeRect.size.width, navView.frame.size.height)];
    [self.navigationController.navigationBar addSubview:navView];
    
    [self getLessonGroup];
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)deviceOrientationDidChange{
    [navView setFrame:CGRectMake(0, 0, self.view.frame.size.width, navView.frame.size.height)];
    [self setNavigationColorWithGradiant];
}
- (void)setNavigationColorWithGradiant{
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = [UIScreen mainScreen] .bounds;
    gradientLayer.colors = @[ (__bridge id)[UIColor colorWithRed:233.0f/255.0f green:244.0f/255.0f blue:0.0f alpha:1.0f].CGColor,
                              (__bridge id)[UIColor colorWithRed:24.0f/255.0f green:140.0f/255.0f blue:0 alpha:1.0f].CGColor ];
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    UIGraphicsBeginImageContext(gradientLayer.bounds.size);
    [gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.navigationController.navigationBar setBackgroundImage:gradientImage forBarMetrics:UIBarMetricsDefault];
}
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [navView removeFromSuperview];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)getLessonGroup{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:contextRecords];
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parentGroup == NULL AND student == NULL"];
    [request setPredicate:predicate];
    NSArray *objects = [contextRecords executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve students!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid students found!");
    } else {
        for (LessonGroup *lessonGroup in objects) {
            [arrayLessonGroup addObject:lessonGroup];
        }
        
        [corseDropmenu reloadAllComponents];
    }
    
}
- (void)reloadAllComponentsFrames{
    CGRect rectTableview = QuestionTableView.frame;
    if (currentQuiz && isEditOldQuiz) {
        rectTableview.size.height = [currentQuiz.questions count] * 44.0f;
    }else{
        rectTableview.size.height = [questionsArray count] * 44.0f;
    }
    
    QuestionTableView.frame = rectTableview;
    
    [addQuestionBtn setFrame:CGRectMake(addQuestionBtn.frame.origin.x, QuestionTableView.frame.origin.y + QuestionTableView.frame.size.height, addQuestionBtn.frame.size.width, addQuestionBtn.frame.size.height)];
    
    [scrView setContentSize:CGSizeMake(self.view.bounds.size.width, addQuestionBtn.frame.origin.y + addQuestionBtn.frame.size.height + 70.0f)];
//    if (scrView.frame.size.height > self.view.bounds.size.height) {
//        scrView.scrollEnabled = YES;
//    }else{
//        scrView.scrollEnabled = NO;
//    }
}

- (void) displayContentController: (UIViewController*) content;
{
    [self.view addSubview:content.view];
    [self addChildViewController:content];
    [content didMoveToParentViewController:self];
}

- (void)removeCurrentViewFromSuper:(UIViewController *)viewController{
    [viewController willMoveToParentViewController:nil];  // 1
    [viewController.view removeFromSuperview];            // 2
    [viewController removeFromParentViewController];
}
- (IBAction)onAddQuestion:(id)sender {
    AddQuestionViewController *questionView = [[AddQuestionViewController alloc] initWithNibName:@"AddQuestionViewController" bundle:nil];
    [questionView.view setFrame:self.view.bounds];
    questionView.delegate = self;
    questionView.currentIndex = currentIndex;
    [self displayContentController:questionView];
    [questionView animateShow];
}

- (IBAction)onSetTimeLimit:(id)sender {
    if (isShownCoundDownDialog) {
        return;
    }
    isShownCoundDownDialog = YES;
    CountDownViewController *countDownView = [[CountDownViewController alloc] initWithNibName:@"CountDownViewController" bundle:nil];
    [countDownView.view setFrame:self.view.bounds];
    countDownView.delegate = self;
    [self displayContentController:countDownView];
    [countDownView animateShow];
}
#pragma mark CountDownViewControllerDelegate
- (void)didCancelCoundDownView:(CountDownViewController *)countDownView{
    isShownCoundDownDialog = NO;
    [self removeCurrentViewFromSuper:countDownView];
}
- (void)returnValueFromCoundDownView:(CountDownViewController *)countDownView strDate:(NSString *)_strDate{
    isShownCoundDownDialog = NO;
    [self removeCurrentViewFromSuper:countDownView];
    txtTimeLimit.text = _strDate;
}
#pragma  mark AddQuestionViewControllerDelegate
- (void)didCancelAddQuestionView:(AddQuestionViewController *)questionView{
    [self removeCurrentViewFromSuper:questionView];
}
- (void)didDoneAddQuestionView:(AddQuestionViewController *)questionView questionInfo:(NSMutableDictionary *)_questionInfo{
    if (currentQuiz && isEditOldQuiz) {
        NSError *error = nil;
        Question *question = [NSEntityDescription insertNewObjectForEntityForName:@"Question" inManagedObjectContext:contextRecords];
        question.question = [_questionInfo objectForKey:@"question"];
        question.answerA = [_questionInfo objectForKey:@"answerA"];
        question.answerB = [_questionInfo objectForKey:@"answerB"];
        question.answerC = [_questionInfo objectForKey:@"answerC"];
        question.explanationReference = [_questionInfo objectForKey:@"explanationReference"];
        question.explanationcode = [_questionInfo objectForKey:@"explanationCode"];
        question.explanationofcorrectAnswer = [_questionInfo objectForKey:@"explanationOfCorrectAnswer"];
        question.lastSync =[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        question.lastUpdate = @(0);
        question.marked = @(0);
        question.gaveAnswer = @"";
        question.questionId = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        question.quizId = currentQuiz.recordId;
        question.correctAnswer = [_questionInfo objectForKey:@"markcorrectAnswer"];
        question.recodeId = @(0);
        question.figureurl = [_questionInfo  objectForKey:@"figure_url"];
        NSInteger maxOrdering = 1;
        for (Question *questionToMaxOrdering in currentQuiz.questions) {
            if (maxOrdering < [questionToMaxOrdering.ordering integerValue]) {
                maxOrdering = [questionToMaxOrdering.ordering integerValue];
            }
        }
        question.ordering = [NSNumber numberWithInteger:maxOrdering +1];
        [currentQuiz addQuestionsObject:question];
        [contextRecords save:&error];
        if (error) {
            NSLog(@"Error when saving managed object context : %@", error);
        }
    }else{
        BOOL isExist = NO;
        for (int i =0 ; i < [questionsArray count]; i ++) {
            NSDictionary *oneDic = [questionsArray objectAtIndex:i];
            if ([[oneDic objectForKey:@"id"] integerValue] == [[_questionInfo objectForKey:@"id"] integerValue]) {
                isExist = YES;
                [questionsArray replaceObjectAtIndex:i withObject:_questionInfo];
                break;
            }
        }
        if (!isExist) {
            [questionsArray addObject:_questionInfo];
            currentIndex = [questionsArray count] + 1;
        }
    }
    
    [self reloadAllComponentsFrames];
    [QuestionTableView reloadData];
    [self removeCurrentViewFromSuper:questionView];
    
//    if (![[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
//        [self savingAuto];
//    }
}

- (void)didDoneAddQuestionView:(AddQuestionViewController *)questionView question:(Question *)_question{
    for (int i = 0 ; i < currentQuiz.questions.count; i ++) {
        Question *questionToCheck = [currentQuiz.questions objectAtIndex:i];
        if ([questionToCheck.questionId integerValue] == [_question.questionId integerValue] && [questionToCheck.ordering integerValue] == [_question.ordering integerValue]) {
            [currentQuiz replaceObjectInQuestionsAtIndex:i withObject:_question];
        }
    }
    [self reloadAllComponentsFrames];
    [self removeCurrentViewFromSuper:questionView];
    [QuestionTableView reloadData];
    
//    if (![[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
//        [self savingAuto];
//    }
}

#pragma mark TableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (currentQuiz && isEditOldQuiz) {
        return currentQuiz.questions.count;
    }
    return [questionsArray count];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"QuestionItem";
    QuestionCell *cell = (QuestionCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier
                                                                                           forIndexPath:indexPath];
//    
//    static NSString *simpleTableIdentifier = @"QuestionItem";
//    QuestionCell *cell = (QuestionCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
//    if (cell == nil) {
//        cell = [QuestionCell sharedCell];
//    }
//    
    cell.delegate = self;
    cell.leftUtilityButtons = [self leftButtons];
    cell.rightUtilityButtons = [self rightButtons];
    
    if (currentQuiz && isEditOldQuiz) {
        Question *oneQuestion = [currentQuiz.questions objectAtIndex:indexPath.row];
        cell.questionDes.text =[NSString stringWithFormat:@"%ld. %@ - %@ (%@)", [oneQuestion.ordering integerValue], oneQuestion.question, oneQuestion.explanationReference, oneQuestion.explanationcode];
    }else{
        NSDictionary *oneQuestion = [questionsArray objectAtIndex:indexPath.row];
        cell.questionDes.text =[NSString stringWithFormat:@"%@. %@ - %@ (%@)", [oneQuestion objectForKey:@"id"], [oneQuestion objectForKey:@"question"], [oneQuestion objectForKey:@"explanationReference"], [oneQuestion objectForKey:@"explanationCode"]];
    }   
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}
- (NSArray *)rightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:@"Delete"];
    
    return rightUtilityButtons;
}

- (NSArray *)leftButtons
{
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor greenColor] title:@"Edit"];
    
    return leftUtilityButtons;
}
#pragma mark - SWTableViewDelegate
//Edit
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index {
    switch (index) {
        case 0:
        {
            NSIndexPath *indexPath = [QuestionTableView indexPathForCell:cell];
            if (currentQuiz && isEditOldQuiz) {
                Question *oneQuestion = [currentQuiz.questions objectAtIndex:indexPath.row];
                
                AddQuestionViewController *questionView = [[AddQuestionViewController alloc] initWithNibName:@"AddQuestionViewController" bundle:nil];
                [questionView.view setFrame:self.view.bounds];
                questionView.delegate = self;
                questionView.selectedQuestion = oneQuestion;
                [self displayContentController:questionView];
                [questionView animateShow];
            }else{
                NSMutableDictionary *selectedInfo = [[questionsArray objectAtIndex:indexPath.row] mutableCopy];
                
                AddQuestionViewController *questionView = [[AddQuestionViewController alloc] initWithNibName:@"AddQuestionViewController" bundle:nil];
                [questionView.view setFrame:self.view.bounds];
                questionView.delegate = self;
                questionView.currentIndex = [[selectedInfo objectForKey:@"id"] integerValue];
                questionView.selectedQuestionInfo = selectedInfo;
                [self displayContentController:questionView];
                [questionView animateShow];
            }
        }
            break;
        default:
            break;
    }
}
//Delete
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    switch (index) {
        case 0:
        {
            NSIndexPath *indexPath = [QuestionTableView indexPathForCell:cell];
            NSString *msg = [NSString stringWithFormat:@"Do you want to delete current Question"];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:msg preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
                
                if (currentQuiz && isEditOldQuiz) {
                    Question *questionToDelete = [currentQuiz.questions objectAtIndex:indexPath.row];
                    NSInteger currentOrdering = [questionToDelete.ordering integerValue];
                    for (Question *quesToUpDateOrdering in currentQuiz.questions) {
                        if ([quesToUpDateOrdering.ordering integerValue] > currentOrdering) {
                            NSInteger tmpOrdering = [quesToUpDateOrdering.ordering integerValue];
                            quesToUpDateOrdering.ordering = [NSNumber numberWithInteger:tmpOrdering-1];
                        }
                    }
                    NSError *error = nil;
                    if ([questionToDelete.recodeId integerValue] != 0) {
                        DeleteQuery *deleteQueryForQuestion = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:contextRecords];
                        deleteQueryForQuestion.type = @"question";
                        deleteQueryForQuestion.idToDelete = questionToDelete.recodeId;
                        
                        [contextRecords save:&error];
                        if (error) {
                            NSLog(@"Error when saving managed object context : %@", error);
                        }
                    }
                    if (![[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
                        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Quiz" inManagedObjectContext:contextRecords];
                        NSFetchRequest *request = [[NSFetchRequest alloc] init];
                        [request setEntity:entityDesc];
                        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"quizGroupId == %@", currentQuiz.quizGroupId];
                        [request setPredicate:predicate];
                        NSArray *objects = [contextRecords executeFetchRequest:request error:&error];
                        if (objects == nil) {
                            FDLogError(@"Unable to retrieve Quiz!");
                        } else if (objects.count == 0) {
                            FDLogDebug(@"No valid Quiz found!");
                        } else{
                            for (Quiz *quizToPraseDeleteQuestions in objects) {
                                if ([quizToPraseDeleteQuestions.recordId integerValue] != [currentQuiz.recordId integerValue]) {
                                    for (Question *qToDelete in quizToPraseDeleteQuestions.questions) {
                                        BOOL isDeleted = NO;
                                        
                                        if ([qToDelete.ordering integerValue] == [questionToDelete.ordering integerValue]) {
                                            if ([qToDelete.recodeId integerValue] != 0) {
                                                DeleteQuery *deleteQuery = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:contextRecords];
                                                deleteQuery.type = @"question";
                                                deleteQuery.idToDelete = qToDelete.recodeId;
                                                [contextRecords save:&error];
                                                if (error) {
                                                    NSLog(@"Error when saving managed object context : %@", error);
                                                }
                                                [quizToPraseDeleteQuestions removeQuestionsObject:qToDelete];
                                                [contextRecords deleteObject:qToDelete];
                                                isDeleted = YES;
                                            }
                                        }
                                        
                                        if (isDeleted) {
                                            NSInteger orderingToUpdate = [qToDelete.ordering integerValue];
                                            qToDelete.ordering =[NSNumber numberWithInteger:orderingToUpdate-1];
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    
                    [currentQuiz removeObjectFromQuestionsAtIndex:indexPath.row];
                    [contextRecords deleteObject:questionToDelete];
                    [contextRecords save:&error];
                    if (error) {
                        NSLog(@"Error when saving managed object context : %@", error);
                    }
                }else{
                    [questionsArray removeObjectAtIndex:indexPath.row];
                    for (int i = 0; i < questionsArray.count; i ++) {
                        NSMutableDictionary *currentQuestion = [questionsArray objectAtIndex:i];
                        if ([[currentQuestion objectForKey:@"id"] integerValue] > indexPath.row + 1) {
                            NSInteger currentQuestionIDToUpdate = [[currentQuestion objectForKey:@"id"] integerValue];
                            [currentQuestion setObject:@(currentQuestionIDToUpdate-1) forKey:@"id"];
                            [questionsArray replaceObjectAtIndex:i withObject:currentQuestion];
                        }
                    }
                    currentIndex = currentIndex - 1;
                }
                [QuestionTableView deleteRowsAtIndexPaths:@[indexPath]  withRowAnimation:UITableViewRowAnimationAutomatic];
                [QuestionTableView reloadData];
                [self reloadAllComponentsFrames];
            }];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
                
            }];
            [alert addAction:cancel];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];

        }
            break;
        default:
            break;
    }
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    return  YES;
}

#pragma mark - MKDropdownMenuDataSource

- (NSInteger)numberOfComponentsInDropdownMenu:(MKDropdownMenu *)dropdownMenu {
    return 1;
}

- (NSInteger)dropdownMenu:(MKDropdownMenu *)dropdownMenu numberOfRowsInComponent:(NSInteger)component {
    return arrayLessonGroup.count;
}

#pragma mark - MKDropdownMenuDelegate

- (NSString *)dropdownMenu:(MKDropdownMenu *)dropdownMenu titleForComponent:(NSInteger)component {
    return currentCourse.name;
}

- (NSString *)dropdownMenu:(MKDropdownMenu *)dropdownMenu titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    LessonGroup *currentLG = [arrayLessonGroup objectAtIndex:row];
    return currentLG.name;
}

- (BOOL)dropdownMenu:(MKDropdownMenu *)dropdownMenu shouldUseFullRowWidthForComponent:(NSInteger)component {
    return NO;
}
- (void)dropdownMenu:(MKDropdownMenu *)dropdownMenu didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    currentCourse = [arrayLessonGroup objectAtIndex:row];
    [dropdownMenu closeAllComponentsAnimated:YES];
    [corseDropmenu reloadAllComponents];
}
- (IBAction)onBackQuizPrograms:(id)sender {
    if (!currentQuiz && [txtQuizname.text isEqualToString:@""] && [txtQuizNumber.text isEqualToString:@""] && [txtTimeLimit.text isEqualToString:@""] && [txtPassingScore.text isEqualToString:@""] && questionsArray.count == 0) {
        
        /////////
        [corseDropmenu closeAllComponentsAnimated:YES];
        [corseDropmenu reloadAllComponents];
        
        /////////////
        
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"Do you want to save your changes before exiting?" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
                         {
                             [self onSave:nil];
                         }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action)
                         {
                              [self.navigationController popViewControllerAnimated:YES];
                         }];
    [alert addAction:ok];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)showAlert:(NSString *)msg title:(NSString *)title{
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        NSLog(@"you pressed Yes, please button");
    }];
    [alert addAction:yesButton];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)updateCurrentQuizAsAdmin{
}

- (void)savingAuto{
    if (!txtQuizname.text.length)
    {
        return;
    }
    if (!txtQuizNumber.text.length)
    {
        return;
    }
    NSError *error = nil;
    if (currentQuiz) {
        currentQuiz.name = txtQuizname.text;
        currentQuiz.passingScore = [NSNumber numberWithInteger:[txtPassingScore.text integerValue]];
        currentQuiz.quizNumber = [NSNumber numberWithInteger:[txtQuizNumber.text integerValue]];
        currentQuiz.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        currentQuiz.lastUpdate = @(0);
        currentQuiz.timeLimit = txtTimeLimit.text;
        
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Quiz" inManagedObjectContext:contextRecords];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"quizGroupId == %@", currentQuiz.quizGroupId];
        [request setPredicate:predicate];
        NSArray *objects = [contextRecords executeFetchRequest:request error:&error];
        if (objects == nil) {
            FDLogError(@"Unable to retrieve Quiz!");
        } else if (objects.count == 0) {
            FDLogDebug(@"No valid Quiz found!");
            
        } else if (objects.count == 1) {
            NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:contextRecords];
            NSError *error;
            // load the remaining lesson groups
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            [request setEntity:entityDesc];
            NSArray *objectsForStudent = [contextRecords executeFetchRequest:request error:&error];
            
            if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
                [self updateCurrentQuizAsAdmin];
                [contextRecords save:&error];
                if (error) {
                    NSLog(@"Error when saving managed object context : %@", error);
                }
                return;
            }
            if (objectsForStudent == nil) {
                FDLogError(@"Unable to retrieve students!");
            } else if (objectsForStudent.count == 0) {
                FDLogDebug(@"No valid students found!");
            } else {
                FDLogDebug(@"%lu students found", (unsigned long)[objectsForStudent count]);
                NSInteger index = 0;
                for (Student *student in objectsForStudent) {
                    if ([currentStudent.userID integerValue] != [student.userID integerValue]) {
                        for (LessonGroup *lessonGroup in student.subGroups) {
                            if ([lessonGroup.name isEqualToString:currentCourse.name]) {
                                index = index + 1;
                                Quiz *quiz = [NSEntityDescription insertNewObjectForEntityForName:@"Quiz" inManagedObjectContext:contextRecords];
                                quiz.quizId = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000 + index];
                                quiz.name = txtQuizname.text;
                                quiz.courseGroupID = lessonGroup.groupID;
                                quiz.passingScore = [NSNumber numberWithInteger:[txtPassingScore.text integerValue]];
                                quiz.quizNumber = [NSNumber numberWithInteger:[txtQuizNumber.text integerValue]];
                                quiz.studentUserID = student.userID;
                                quiz.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                                quiz.lastUpdate =@(0);
                                quiz.timeLimit = txtTimeLimit.text;
                                quiz.gotScore = @(0);
                                quiz.quizTaken = @(0);
                                quiz.recordId = @(0);
                                quiz.quizGroupId = currentQuiz.quizGroupId;
                                int i = 0;
                                for (Question *questionToAdd in currentQuiz.questions) {
                                    
                                    Question *question = [NSEntityDescription insertNewObjectForEntityForName:@"Question" inManagedObjectContext:contextRecords];
                                    question.question = questionToAdd.question;
                                    question.answerA = questionToAdd.answerA;
                                    question.answerB = questionToAdd.answerB;
                                    question.answerC = questionToAdd.answerC;
                                    question.explanationReference = questionToAdd.explanationReference;
                                    question.explanationcode = questionToAdd.explanationcode;
                                    question.explanationofcorrectAnswer = questionToAdd.explanationofcorrectAnswer;
                                    question.lastSync =[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                                    question.lastUpdate =@(0);
                                    question.marked = @(0);
                                    question.gaveAnswer = @"";
                                    question.questionId = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000 +i];
                                    question.quizId = quiz.recordId;
                                    question.correctAnswer = questionToAdd.correctAnswer;
                                    question.recodeId = @(0);
                                    question.figureurl = questionToAdd.figureurl;
                                    question.ordering = questionToAdd.ordering;
                                    [quiz addQuestionsObject:question];
                                    i ++;
                                }
                                
                                [lessonGroup addQuizesObject:quiz];
                            }
                        }
                    }
                    
                }
            }
        }
        else{
            for (Quiz *quizToUpdate in objects) {
                if ([quizToUpdate.recordId integerValue] != [currentQuiz.recordId integerValue]) {
                    quizToUpdate.name = txtQuizname.text;
                    quizToUpdate.passingScore = [NSNumber numberWithInteger:[txtPassingScore.text integerValue]];
                    quizToUpdate.quizNumber = [NSNumber numberWithInteger:[txtQuizNumber.text integerValue]];
                    quizToUpdate.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                    quizToUpdate.lastUpdate =@(0);
                    quizToUpdate.timeLimit = txtTimeLimit.text;
                    for (Question *questionToUpdateOrAdd in currentQuiz.questions) {
                        Question *oldQuestion = nil;
                        for (Question *ques in quizToUpdate.questions) {
                            if ([ques.question isEqualToString:questionToUpdateOrAdd.question]) {
                                oldQuestion = ques;
                                break;
                            }
                        }
                        if (oldQuestion != nil) {
                            oldQuestion.question = questionToUpdateOrAdd.question;
                            oldQuestion.answerA = questionToUpdateOrAdd.answerA;
                            oldQuestion.answerB = questionToUpdateOrAdd.answerB;
                            oldQuestion.answerC = questionToUpdateOrAdd.answerC;
                            oldQuestion.explanationReference = questionToUpdateOrAdd.explanationReference;
                            oldQuestion.explanationcode = questionToUpdateOrAdd.explanationcode;
                            oldQuestion.explanationofcorrectAnswer = questionToUpdateOrAdd.explanationofcorrectAnswer;
                            oldQuestion.correctAnswer = questionToUpdateOrAdd.correctAnswer;
                            oldQuestion.figureurl = questionToUpdateOrAdd.figureurl;
                            
                        }else{
                            Question *question = [NSEntityDescription insertNewObjectForEntityForName:@"Question" inManagedObjectContext:contextRecords];
                            question.question = questionToUpdateOrAdd.question;
                            question.answerA = questionToUpdateOrAdd.answerA;
                            question.answerB = questionToUpdateOrAdd.answerB;
                            question.answerC = questionToUpdateOrAdd.answerC;
                            question.explanationReference = questionToUpdateOrAdd.explanationReference;
                            question.explanationcode = questionToUpdateOrAdd.explanationcode;
                            question.explanationofcorrectAnswer = questionToUpdateOrAdd.explanationofcorrectAnswer;
                            question.lastSync =[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                            question.lastUpdate = @(0);
                            question.marked = @(0);
                            question.gaveAnswer = @"";
                            question.questionId = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                            question.quizId = quizToUpdate.recordId;
                            question.correctAnswer = questionToUpdateOrAdd.correctAnswer;
                            question.recodeId = @(0);
                            question.figureurl = questionToUpdateOrAdd.figureurl;
                            question.ordering = questionToUpdateOrAdd.ordering;
                            [quizToUpdate addQuestionsObject:question];
                        }
                    }
                }
            }
        }
        [contextRecords save:&error];
        if (error) {
            NSLog(@"Error when saving managed object context : %@", error);
        }
    }else{
        NSEntityDescription *entityDescToCheckOfQuizNumber = [NSEntityDescription entityForName:@"Quiz" inManagedObjectContext:contextRecords];
        NSFetchRequest *requestToCheckOfLessonNumber = [[NSFetchRequest alloc] init];
        [requestToCheckOfLessonNumber setEntity:entityDescToCheckOfQuizNumber];
        NSPredicate *predicateToCheckLessonNumber = [NSPredicate predicateWithFormat:@"quizNumber == %@ AND studentUserID = %@", [NSNumber numberWithInteger:[txtQuizNumber.text integerValue]], currentStudent.userID];
        [requestToCheckOfLessonNumber setPredicate:predicateToCheckLessonNumber];
        NSArray *objectsQuizes = [contextRecords executeFetchRequest:requestToCheckOfLessonNumber error:&error];
        if (objectsQuizes.count>0) {
            BOOL isExist  = NO;
            for (Quiz *quizToCheckGroup in objectsQuizes) {
                NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:contextRecords];
                NSError *error;
                NSFetchRequest *request = [[NSFetchRequest alloc] init];
                [request setEntity:entityDesc];
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"groupID == %@", quizToCheckGroup.courseGroupID];
                [request setPredicate:predicate];
                NSArray *objects = [contextRecords executeFetchRequest:request error:&error];
                if (objects == nil) {
                    FDLogError(@"Unable to retrieve students!");
                } else if (objects.count == 0) {
                    FDLogDebug(@"No valid students found!");
                } else {
                    LessonGroup *lsGroup = objects[0];
                    if ([currentCourse.name.lowercaseString isEqualToString:lsGroup.name.lowercaseString]) {
                        isExist = YES;
                    }
                }
            }
            
            if (isExist) {
                [self showAlert:[NSString stringWithFormat:@"Quiz %@ already exists, please check number and try again.", txtQuizNumber.text] title:@"Input Error"];
                return;
            }
        }
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            [self saveQuizesWithAdminAccount];
            [contextRecords save:&error];
            if (error) {
                NSLog(@"Error when saving managed object context : %@", error);
            }
            return;
        }
        
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:contextRecords];
        NSError *error;
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        NSArray *objects = [contextRecords executeFetchRequest:request error:&error];
        
        NSNumber *quizGroupIdWithInstructor = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        
        if (objects == nil) {
            FDLogError(@"Unable to retrieve students!");
        } else if (objects.count == 0) {
            FDLogDebug(@"No valid students found!");
        } else {
            FDLogDebug(@"%lu students found", (unsigned long)[objects count]);
            NSInteger index = 0;
            for (Student *student in objects) {
                for (LessonGroup *lessonGroup in student.subGroups) {
                    if ([lessonGroup.name isEqualToString:currentCourse.name]) {
                        index = index + 1;
                        Quiz *quiz = [NSEntityDescription insertNewObjectForEntityForName:@"Quiz" inManagedObjectContext:contextRecords];
                        quiz.quizId = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000 + index];
                        quiz.name = txtQuizname.text;
                        quiz.courseGroupID = lessonGroup.groupID;
                        quiz.passingScore = [NSNumber numberWithInteger:[txtPassingScore.text integerValue]];
                        quiz.quizNumber = [NSNumber numberWithInteger:[txtQuizNumber.text integerValue]];
                        quiz.studentUserID = student.userID;
                        quiz.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                        quiz.lastUpdate =@(0);
                        quiz.timeLimit = txtTimeLimit.text;
                        quiz.gotScore = @(0);
                        quiz.quizTaken = @(0);
                        quiz.recordId = @(0);
                        quiz.quizGroupId = quizGroupIdWithInstructor;
                        int i = 0;
                        for (NSDictionary *dict in questionsArray) {
                            
                            Question *question = [NSEntityDescription insertNewObjectForEntityForName:@"Question" inManagedObjectContext:contextRecords];
                            question.question = [dict objectForKey:@"question"];
                            question.answerA = [dict objectForKey:@"answerA"];
                            question.answerB = [dict objectForKey:@"answerB"];
                            question.answerC = [dict objectForKey:@"answerC"];
                            question.explanationReference = [dict objectForKey:@"explanationReference"];
                            question.explanationcode = [dict objectForKey:@"explanationCode"];
                            question.explanationofcorrectAnswer = [dict objectForKey:@"explanationOfCorrectAnswer"];
                            question.lastSync =[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                            question.lastUpdate =@(0);
                            question.marked = @(0);
                            question.gaveAnswer = @"";
                            question.questionId = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000 +i];
                            question.quizId = quiz.recordId;
                            question.correctAnswer = [dict objectForKey:@"markcorrectAnswer"];
                            question.recodeId = @(0);
                            question.figureurl = [dict  objectForKey:@"figure_url"];
                            question.ordering = [NSNumber numberWithInteger:[[dict objectForKey:@"id"] integerValue]];
                            [quiz addQuestionsObject:question];
                            i ++;
                        }
                        
                        [lessonGroup addQuizesObject:quiz];
                        
                        
                        if ([lessonGroup.groupID integerValue] == [courseGroupID integerValue]) {
                            currentStudent = student;
                            currentQuiz = quiz;
                            isEditOldQuiz = YES;
                        }
                    }
                }
            }
        }
        [contextRecords save:&error];
        if (error) {
            NSLog(@"Error when saving managed object context : %@", error);
        }
    }
}
- (void)saveQuizesWithAdminAccount{
    Quiz *quiz = [NSEntityDescription insertNewObjectForEntityForName:@"Quiz" inManagedObjectContext:contextRecords];
    quiz.quizId = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    quiz.name = txtQuizname.text;
    quiz.courseGroupID = currentCourse.groupID;
    quiz.passingScore = [NSNumber numberWithInteger:[txtPassingScore.text integerValue]];
    quiz.quizNumber = [NSNumber numberWithInteger:[txtQuizNumber.text integerValue]];
    quiz.studentUserID = @(0);
    quiz.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    quiz.lastUpdate =@(0);
    quiz.timeLimit = txtTimeLimit.text;
    quiz.gotScore = @(0);
    quiz.quizTaken = @(0);
    quiz.recordId = @(0);
    quiz.quizGroupId = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    int i = 0;
    for (NSDictionary *dict in questionsArray) {
        
        Question *question = [NSEntityDescription insertNewObjectForEntityForName:@"Question" inManagedObjectContext:contextRecords];
        question.question = [dict objectForKey:@"question"];
        question.answerA = [dict objectForKey:@"answerA"];
        question.answerB = [dict objectForKey:@"answerB"];
        question.answerC = [dict objectForKey:@"answerC"];
        question.explanationReference = [dict objectForKey:@"explanationReference"];
        question.explanationcode = [dict objectForKey:@"explanationCode"];
        question.explanationofcorrectAnswer = [dict objectForKey:@"explanationOfCorrectAnswer"];
        question.lastSync =[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        question.lastUpdate =@(0);
        question.marked = @(0);
        question.gaveAnswer = @"";
        question.questionId = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000 +i];
        question.quizId = quiz.recordId;
        question.correctAnswer = [dict objectForKey:@"markcorrectAnswer"];
        question.recodeId = @(0);
        question.figureurl = [dict  objectForKey:@"figure_url"];
        question.ordering = [NSNumber numberWithInteger:[[dict objectForKey:@"id"] integerValue]];
        [quiz addQuestionsObject:question];
        i ++;
    }
    
    [currentCourse addQuizesObject:quiz];
}

- (IBAction)onSave:(id)sender {
    if (!txtQuizname.text.length)
    {
        [self showAlert:@"Please input Quiz Name" title:@"Input Error"];
        return;
    }
    if (!txtQuizNumber.text.length)
    {
        [self showAlert:@"Please input Quiz Number" title:@"Input Error"];
        return;
    }
    if (!txtTimeLimit.text.length)
    {
        [self showAlert:@"Please set Time Limit" title:@"Input Error"];
        return;
    }
    if (!txtPassingScore.text.length)
    {
        [self showAlert:@"Please input Passing Score" title:@"Input Error"];
        return;
    }
    if (currentQuiz) {
        if (currentQuiz.questions.count == 0)
        {
            [self showAlert:@"Please add Questions" title:@"Input Error"];
            return;
        }
    }else{
        if (questionsArray.count == 0)
        {
            [self showAlert:@"Please add Questions" title:@"Input Error"];
            return;
        }
    }
    
    [self savingAuto];
    
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"Quiz Saved." preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
                         {
                             [self.navigationController popViewControllerAnimated:YES];
                         }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
    
}
@end
