//
//  UIImage+ACGif.m
//
//  Version: 2.0.4.
//  Created by ArthurCao<https://github.com/honeycao> on 2017/4/26.
//  Update: 2017/12/27.
//

#import "UIImage+ACGif.h"
#import "UIImage+GIF.h"

@implementation UIImage (ACGif)

+ (UIImage *)ac_setGifWithName: (NSString *)name {
    return [self acadsoc_animatedGIFNamed:name];
}

+ (UIImage *)ac_setGifWithData: (NSData *)data {
    return [self sd_animatedGIFWithData:data];
}

+ (UIImage *)imageForResourcePath:(NSString *)path ofType:(NSString *)type inBundle:(NSBundle *)bundle {
    return [UIImage imageWithContentsOfFile:[bundle pathForResource:path ofType:type]];
}

+ (UIImage *)acadsoc_animatedGIFNamed:(NSString *)name {
    CGFloat scale = [UIScreen mainScreen].scale;
    
    if (scale > 1.0f) {
        NSString *retinaPath = [[NSBundle mainBundle] pathForResource:[name stringByAppendingString:@"@2x"] ofType:@"gif"];
        
        NSData *data = [NSData dataWithContentsOfFile:retinaPath];
        
        if (data) {
            return [UIImage sd_animatedGIFWithData:data];
        }
        
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"gif"];
        
        data = [NSData dataWithContentsOfFile:path];
        
        if (data) {
            return [UIImage sd_animatedGIFWithData:data];
        }
        
        return [UIImage imageNamed:name];
    }
    else {
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"gif"];
        
        NSData *data = [NSData dataWithContentsOfFile:path];
        
        if (data) {
            return [UIImage sd_animatedGIFWithData:data];
        }
        
        return [UIImage imageNamed:name];
    }
}

@end
