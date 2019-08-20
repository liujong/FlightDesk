//
//  WLColView.h
//  moveSide
//
//  Created by Lenny on 16/4/9.
//  Copyright © 2016年 Lenny. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SideModel.h"

@class WLColView,CheckListsMainCell;

@protocol WLColViewDataSource <NSObject>

- (NSInteger)colView:(WLColView *)colView collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;
- (CheckListsMainCell *)colView:(WLColView *)colView collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@protocol WLColViewDelegate <NSObject>

- (void)colView:(WLColView *)colView collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)colView:(WLColView *)colView didScrollToOtherCell:(NSIndexPath *)indexPath;

@end

@interface WLColView : UIView<UICollectionViewDataSource,UICollectionViewDelegate>

@property(nonatomic,strong)UICollectionView *collectionView;
@property(nonatomic,strong)SideModel *sideModel;

@property(nonatomic,assign)id<WLColViewDataSource> dataSource;
@property(nonatomic,assign)id<WLColViewDelegate> delegate;

-(void)selectedItemWithIndexPath:(NSIndexPath *)moveIndexPath;

@end
