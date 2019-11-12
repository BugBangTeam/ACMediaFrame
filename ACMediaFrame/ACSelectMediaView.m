//
//  ACSelectMediaView.m
//
//  Created by ArthurCao<https://github.com/honeycao> on 2017/04/12.
//  Version: 2.0.4.
//  Update: 2017/12/28.
//

#import "ACSelectMediaView.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "ACMediaManager.h"
#import "ACMediaImageCell.h"
//Ext
#import "NSString+ACMediaExt.h"
#import "UIImage+ACGif.h"
//git
#import "TZImagePickerController.h"
#import "TZPhotoPreviewController.h"
#import "TZGifPhotoPreviewController.h"
#import "TZVideoPlayerController.h"

@interface ACSelectMediaView ()<UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, TZImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, copy) ACMediaHeightBlock block;

@property (nonatomic, copy) ACSelectMediaBackBlock backBlock;

/** 总的媒体数组 */
@property (nonatomic, strong) NSMutableArray *mediaArray;

@property (nonatomic, strong) NSMutableArray *selectedPhotos;
@property (nonatomic, strong) NSMutableArray *selectedAssets;

@end

@implementation ACSelectMediaView

#pragma mark - Init

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, ACMedia_ScreenWidth/4);
        [self _setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _setup];
    }
    return self;
}

///设置初始值
- (void)_setup
{
    _selectedPhotos = [NSMutableArray array];
    _selectedAssets = [NSMutableArray array];
    
    _mediaArray = [NSMutableArray array];
    _preShowMedias = [NSMutableArray array];
    
    _type = ACMediaTypePhoto;
    _showDelete = YES;
    _shownNavDelete = YES;
    _showAddButton = YES;
    _maxImageSelected = 9;
    _allowTakePicture = YES;
    _videoMaximumDuration = 60;
    _backgroundColor = [UIColor whiteColor];
    _rowImageCount = 4;
    _lineSpacing = 10.0;
    _interitemSpacing = 10.0;
    _sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    [self configureCollectionView];
}

- (void)configureCollectionView
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
    
    _collectionView = [[UICollectionView alloc]initWithFrame:self.bounds collectionViewLayout:layout];
    [_collectionView registerClass:[ACMediaImageCell class] forCellWithReuseIdentifier:NSStringFromClass([ACMediaImageCell class])];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.backgroundColor = _backgroundColor;
    [self addSubview:_collectionView];
}

#pragma mark - setter

- (void)setShowDelete:(BOOL)showDelete {
    _showDelete = showDelete;
}

- (void)setShownNavDelete:(BOOL)shownNavDelete {
    _shownNavDelete = shownNavDelete;
}

- (void)setShowAddButton:(BOOL)showAddButton {
    _showAddButton = showAddButton;
    if (_mediaArray.count > 3 || _mediaArray.count == 0) {
        [self layoutCollection];
    }
}

- (void)setPreShowMedias:(NSArray *)preShowMedias {
    
    _preShowMedias = preShowMedias;
    NSMutableArray *temp = [NSMutableArray array];
    for (id object in preShowMedias) {
        ACMediaModel *model = [ACMediaModel new];
        if ([object isKindOfClass:[UIImage class]]) {
            model.image = object;
        }else if ([object isKindOfClass:[NSString class]]) {
            NSString *obj = (NSString *)object;
            if ([obj isValidUrl]) {
                model.imageUrlString = object;
            }else if ([obj isGifImage]) {
                //名字中有.gif是识别不了的（和自己的拓展名重复了，所以先去掉）
                NSString *name_ = obj.lowercaseString;
                if ([name_ containsString:@"gif"]) {
                    name_ = [name_ stringByReplacingOccurrencesOfString:@".gif" withString:@""];
                }
                model.image = [UIImage ac_setGifWithName:name_];
            }else {
                model.image = [UIImage imageNamed:object];
            }
        }else if ([object isKindOfClass:[ACMediaModel class]]) {
            model = object;
        }
        [temp addObject:model];
    }
    if (temp.count > 0) {
        _mediaArray = temp;
        [self layoutCollection];
    }
}


- (void)setBackgroundColor:(UIColor *)backgroundColor {
    _backgroundColor = backgroundColor;
    [_collectionView setBackgroundColor:backgroundColor];
}

- (void)setRowImageCount:(NSInteger)rowImageCount {
    _rowImageCount = rowImageCount;
}

- (void)setLineSpacing:(CGFloat)lineSpacing {
    _lineSpacing = lineSpacing;
}

- (void)setInteritemSpacing:(CGFloat)interitemSpacing {
    _interitemSpacing = interitemSpacing;
}

- (void)setSectionInset:(UIEdgeInsets)sectionInset {
    _sectionInset = sectionInset;
}

#pragma mark - public method

- (void)observeViewHeight:(ACMediaHeightBlock)value {
    _block = value;
    [self layoutCollection];
}

- (void)observeSelectedMediaArray: (ACSelectMediaBackBlock)backBlock {
    _backBlock = backBlock;
}

+ (CGFloat)defaultViewHeight {
    return 1;
}

- (void)reload {
    [self layoutCollection];
}

#pragma mark -  Collection View DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger num = self.mediaArray.count < _maxImageSelected ? self.mediaArray.count : _maxImageSelected;
    //图片最大数不显示添加按钮
    if (num == _maxImageSelected) {
        return _maxImageSelected;
    }
    return _showAddButton ? num + 1 : num;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ACMediaImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([ACMediaImageCell class]) forIndexPath:indexPath];
    if (indexPath.row == _mediaArray.count) {
        [cell showAddWithImage:self.addImage];
    }else{
        ACMediaModel *model = [[ACMediaModel alloc] init];
        model = _mediaArray[indexPath.row];
        
        if (model.imageUrlString) {
            [cell showIconWithUrlString:model.imageUrlString image:nil];
        }else {
            //这个地方可能会存在一个问题
            [cell showIconWithUrlString:nil image:model.image];
        }
        [cell videoImage:self.videoTagImage show:model.isVideo];
        [cell deleteButtonWithImage:self.deleteImage show:_showDelete];
        
        __weak typeof(self) weakself = self;
        cell.ACMediaClickDeleteButton = ^{
            if (indexPath.row < _mediaArray.count) {
                [_mediaArray removeObjectAtIndex:indexPath.row];
            }
            
            if (indexPath.row < weakself.selectedAssets.count) {
                [weakself.selectedAssets removeObjectAtIndex:indexPath.row];
            }
            if (indexPath.row < weakself.selectedPhotos.count) {
                [weakself.selectedPhotos removeObjectAtIndex:indexPath.row];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself layoutCollection];
            });
        };
    }
    return cell;
}

#pragma mark - collection view delegate

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return self.lineSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return self.interitemSpacing;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat itemW = (self.frame.size.width - self.sectionInset.left - (self.rowImageCount - 1) * self.interitemSpacing - self.sectionInset.right) / self.rowImageCount;
    return CGSizeMake(itemW, itemW);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return self.sectionInset;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == _selectedPhotos.count) {
        TZImagePickerController *imagePickController = [[TZImagePickerController alloc] initWithMaxImagesCount:_maxImageSelected delegate:self];
        imagePickController.selectedAssets = _selectedAssets;
        [self configureTZNaviBar:imagePickController];
        imagePickController.modalPresentationStyle = UIModalPresentationFullScreen;
        [[self currentViewController] presentViewController:imagePickController animated:YES completion:nil];
    } else { // preview photos or video / 预览照片或者视频
        PHAsset *asset = _selectedAssets[indexPath.item];
        BOOL isVideo = NO;
        isVideo = asset.mediaType == PHAssetMediaTypeVideo;
        if ([[asset valueForKey:@"filename"] containsString:@"GIF"]) {
            TZGifPhotoPreviewController *vc = [[TZGifPhotoPreviewController alloc] init];
            TZAssetModel *model = [TZAssetModel modelWithAsset:asset type:TZAssetModelMediaTypePhotoGif timeLength:@""];
            vc.model = model;
            vc.modalPresentationStyle = UIModalPresentationFullScreen;
            [[self currentViewController] presentViewController:vc animated:YES completion:nil];
        } else if (isVideo) { // perview video / 预览视频
            TZVideoPlayerController *vc = [[TZVideoPlayerController alloc] init];
            TZAssetModel *model = [TZAssetModel modelWithAsset:asset type:TZAssetModelMediaTypeVideo timeLength:@""];
            vc.model = model;
            vc.modalPresentationStyle = UIModalPresentationFullScreen;
            [[self currentViewController] presentViewController:vc animated:YES completion:nil];
        } else { // preview photos / 预览照片
            TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithSelectedAssets:_selectedAssets selectedPhotos:_selectedPhotos index:indexPath.item];
            imagePickerVc.maxImagesCount = _maxImageSelected;
            [self configureTZNaviBar:imagePickerVc];
            imagePickerVc.modalPresentationStyle = UIModalPresentationFullScreen;
            [imagePickerVc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
                [self handleAssetsFromAlbum:assets photos:photos];
            }];
            [[self currentViewController] presentViewController:imagePickerVc animated:YES completion:nil];
        }
    }
}

#pragma mark - 布局

///计算高度，刷新collectionview，并返回相应的高度和数据
- (void)layoutCollection {
    NSInteger itemCount = _showAddButton ? _mediaArray.count + 1 : _mediaArray.count;
    //图片最大数也不显示添加按钮
    if (_mediaArray.count == _maxImageSelected && _showAddButton) {
        itemCount -= 1;
    }
    CGRect frame = _collectionView.frame;
    frame.size.height = [self collectionHeightWithCount:itemCount];
    _collectionView.frame = frame;
    
    CGRect selfframe = self.frame;
    selfframe.size.height = _collectionView.frame.size.height;
    self.frame = selfframe;

    !_block ?  : _block(_collectionView.frame.size.height);
    !_backBlock ?  : _backBlock(_mediaArray);
    
    [_collectionView reloadData];
}

- (CGFloat)collectionHeightWithCount: (NSInteger)count
{
    NSInteger maxRow = count == 0 ? 0 : (count - 1) / self.rowImageCount + 1;
    CGFloat itemH = (self.frame.size.width - self.sectionInset.left - (self.rowImageCount - 1) * self.interitemSpacing - self.sectionInset.right) / self.rowImageCount;
    CGFloat h = maxRow == 0 ? 0 : (maxRow * itemH + (maxRow - 1) * self.lineSpacing + self.sectionInset.top + self.sectionInset.bottom);
    return h;
}


#pragma mark - TZImagePickerController Delegate

//相册选取图片
- (void)imagePickerController:(TZImagePickerController *)picker
       didFinishPickingPhotos:(NSArray<UIImage *> *)photos
                 sourceAssets:(NSArray *)assets
        isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto
{
    [self handleAssetsFromAlbum:assets photos:photos];
}

///选取视频后的回调
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingVideo:(UIImage *)coverImage sourceAssets:(id)asset {
    _selectedAssets = [NSMutableArray arrayWithObject:asset];
    _selectedPhotos = [NSMutableArray arrayWithObject:coverImage];
    
    [[ACMediaManager manager] getMediaInfoFromAsset:asset completion:^(NSString *name, id pathData) {
        ACMediaModel *model = [[ACMediaModel alloc] init];
        model.name = name;
        model.uploadType = pathData;
        model.image = coverImage;
        model.isVideo = YES;
        model.asset = asset;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.mediaArray addObject:model];
            [self layoutCollection];
        });
    }];
}

#pragma mark - private methods

/** 从相册中选择图片之后的数据处理 */
- (void)handleAssetsFromAlbum: (NSArray *)assets photos: (NSArray *)photos
{
    
    NSMutableArray *selectedAssets = [assets mutableCopy];
    
    if ([selectedAssets isEqualToArray: _selectedAssets]) {
        return;
    }
    _selectedAssets = [NSMutableArray arrayWithArray:assets];
    _selectedPhotos = [NSMutableArray arrayWithArray:photos];
    
    [self.mediaArray removeAllObjects];
    [self layoutCollection];
    for (PHAsset *new in assets) {
        NSInteger index = [assets indexOfObject:new];
        __weak typeof(self) weakSelf = self;
        [[ACMediaManager manager] getMediaInfoFromAsset:new completion:^(NSString *name, id pathData) {
            
            ACMediaModel *model = [[ACMediaModel alloc] init];
            model.name = name;
            model.asset = new;
            model.uploadType = pathData;
            model.image = photos[index];
            
            if ([NSString isGifWithImageData:pathData]) {
                model.image = [UIImage ac_setGifWithData:pathData];
            }
            [weakSelf.mediaArray addObject:model];
            
            //最后一个处理完就在主线程中进行布局
            if ([new isEqual:[assets lastObject]]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf layoutCollection];
                });
            }
        }];
    }
}

///配置 TZImagePickerController属性、导航栏属性
- (void)configureTZNaviBar: (TZImagePickerController *)pick
{
    pick.allowTakePicture = self.allowTakePicture;
    pick.allowPickingOriginalPhoto = self.allowPickingOriginalPhoto;
    
    if (_type == ACMediaTypeVideo) {
        pick.allowPickingVideo = YES;
        pick.allowPickingImage = NO;
    }else if (_type == ACMediaTypePhoto) {
        pick.allowPickingVideo = NO;
        pick.allowPickingImage = YES;
    }else {
        pick.allowPickingVideo = YES;
        pick.allowPickingImage = YES;
    }
    
    if (self.naviBarBgColor) {
        pick.naviBgColor = self.naviBarBgColor;
    }
    if (self.naviBarTitleColor) {
        pick.naviTitleColor = self.naviBarTitleColor;
    }
    if (self.naviBarTitleFont) {
        pick.naviTitleFont = self.naviBarTitleFont;
    }
    if (self.barItemTextColor) {
        pick.barItemTextColor = self.barItemTextColor;
    }
    if (self.barItemTextFont) {
        pick.barItemTextFont = self.barItemTextFont;
    }
    if (self.barBackButton) {
        pick.navLeftBarButtonSettingBlock = ^(UIButton *leftButton) {
            leftButton = _barBackButton;
        };
    }
    pick.isStatusBarDefault = self.isStatusBarDefault;
}

///获取当前的控制器，优先使用外界的赋值
- (UIViewController *)currentViewController
{
    //if set rootViewController
    if (self.rootViewController) {
        return self.rootViewController;
    }
    
    UIViewController *result = nil;
    
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows)
        {
            if (tmpWin.windowLevel == UIWindowLevelNormal)
            {
                window = tmpWin;
                break;
            }
        }
    }
    
    UIView *frontView = [[window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];
    
    if ([nextResponder isKindOfClass:[UIViewController class]])
        result = nextResponder;
    else
        result = window.rootViewController;
    
    NSAssert(result, @"\n*******\n rootViewController must not be nil. \n******");
    
    return result;
}

@end
