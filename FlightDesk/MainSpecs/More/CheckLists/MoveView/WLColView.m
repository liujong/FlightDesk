//
//  WLColView.m
//  moveSide
//
//  Created by Lenny on 16/4/9.
//  Copyright © 2016年 Lenny. All rights reserved.
//

#import "WLColView.h"
#import "CheckListsMainCell.h"

@interface WLColView ()
{
    CheckListsMainCell *_lastCell;
    CGFloat beginOffSetX;
}
@end

@implementation WLColView

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {

        [self UI];
    }
    return self;
}

#pragma mark - collectionviewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  
    return [self.dataSource colView:self collectionView:collectionView numberOfItemsInSection:section];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CheckListsMainCell *cell = [self.dataSource colView:self collectionView:collectionView cellForItemAtIndexPath:indexPath];
    if (indexPath.row == 0) {
        
        if (_lastCell == nil) {
            
            if ([[NSUserDefaults standardUserDefaults ] boolForKey:@"isSavedChecklistStatus"]==YES) {
                NSInteger positionCell = [[[NSUserDefaults standardUserDefaults] objectForKey:@"selectedCategory"] integerValue];
                if (positionCell == 0) {
                    cell.transform = CGAffineTransformMakeScale(1 + self.sideModel.maxR, 1 + self.sideModel.maxR);
                }
            }
            _lastCell = cell;
        }
    }
    cell.backgroundColor = [UIColor clearColor];
    //cell.indexPath = indexPath;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSIndexPath *lastIndexPath = [self.collectionView indexPathForCell:_lastCell];
    if (indexPath.row != lastIndexPath.row || lastIndexPath == nil) {
        
        [self hitTheCellIndexPath:indexPath];
    }else {
    
//        if ([self.delegate respondsToSelector:@selector(colView:collectionView:didSelectItemAtIndexPath:)]) {
//            
//            [self.delegate colView:self collectionView:collectionView didSelectItemAtIndexPath:indexPath];
//        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (_lastCell == nil) {
        
        return;
    }
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:_lastCell];
    CheckListsMainCell *panView = _lastCell;
    CheckListsMainCell *preView = (CheckListsMainCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row - 1 inSection:0]];
    CheckListsMainCell *lastView = (CheckListsMainCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:0]];
    [self dragScrollview:panView];
    if (preView != nil) {
        
        [self dragScrollview:preView];
    }
    if (lastView != nil) {
        
        [self dragScrollview:lastView];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    beginOffSetX = scrollView.contentOffset.x;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    [self dragScrollviewEnd];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
    [self dragScrollviewEnd];
}


#pragma mark - private motheds
- (void)UI {
    
    [self addSubview:self.collectionView];
}

- (void)dragScrollview:(CheckListsMainCell *)cell {
    
    //中心
    CGPoint cellPoint = [self.collectionView convertPoint:cell.center toView:self];
    CGFloat moveBetween = cellPoint.x - self.center.x;
    //NSLog(@"cellpoint : %f, center : %f", cellPoint.x, self.center.x);
    if (fabs(moveBetween) < 100) {
        
        CGFloat scale = 1 + (self.sideModel.maxR * 10) * (0.1 - fabs(moveBetween) / 1000.0f);
        cell.transform = CGAffineTransformMakeScale(scale, scale);
        _lastCell = cell;
    }else {
        cell.transform = CGAffineTransformMakeScale(1, 1);
    }
}

- (void)dragScrollviewEnd {
    
    NSInteger index = [self.collectionView indexPathForCell:_lastCell].row;
    CGFloat moveBetween = self.sideModel.cellSize.width + self.sideModel.between;
    CGFloat scMove = self.collectionView.contentOffset.x - beginOffSetX;
    if (fabs(scMove) > moveBetween / 2){
        
    }else if (scMove > 0) {
        index ++;
    }else if (scMove < 0) {
        index --;
    }
    [self.collectionView setContentOffset:CGPointMake(-self.sideModel.initOffSetX + index * moveBetween , 0) animated:YES];
    [self.delegate colView:self didScrollToOtherCell:[NSIndexPath indexPathForRow:index inSection:0]];
}

- (void)hitTheCellIndexPath:(NSIndexPath *)indexPath {
    
    NSIndexPath *lastIndexPath = [self.collectionView indexPathForCell:_lastCell];
    CGFloat moveBetween = self.sideModel.cellSize.width + self.sideModel.between;
    
    NSInteger index = lastIndexPath.row;
    
    index = indexPath.row;
    
    [self.delegate colView:self didScrollToOtherCell:indexPath];
    [self.collectionView setContentOffset:CGPointMake(-self.sideModel.initOffSetX + index * moveBetween , 0) animated:YES];

}


#pragma mark - setters and getters

- (UICollectionView *)collectionView {
    
    if (_collectionView == nil) {
        
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc] initWithFrame:self.frame collectionViewLayout:flowLayout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
    }
    return _collectionView;
}

- (void)setSideModel:(SideModel *)sideModel {
    
    _sideModel = sideModel;
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    flowLayout.itemSize = sideModel.cellSize;
    flowLayout.minimumInteritemSpacing = sideModel.between;
    flowLayout.minimumLineSpacing = sideModel.between;
    self.collectionView.collectionViewLayout = flowLayout;
    self.collectionView.contentInset = UIEdgeInsetsMake(0, sideModel.initOffSetX, 0, sideModel.initOffSetX);
}

-(void)selectedItemWithIndexPath:(NSIndexPath *)moveIndexPath{
    [self hitTheCellIndexPath:moveIndexPath];
    CheckListsMainCell *cell = [self.dataSource colView:self collectionView:self.collectionView cellForItemAtIndexPath:moveIndexPath];
    cell.transform = CGAffineTransformMakeScale(1 + self.sideModel.maxR, 1 + self.sideModel.maxR);
    
    _lastCell = cell;
}

@end
