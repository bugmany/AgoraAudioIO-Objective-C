//
//  Define.h
//  OpenVodieCall
//
//  Created by CavanSu on 2017/9/5.
//  Copyright © 2017 Agora. All rights reserved.
//

#ifndef Define_h
#define Define_h

#define ThemeColor [UIColor Red:122 Green:203 Blue:253]

typedef NS_ENUM(int, AudioMode) {
    
    AudioMode_SelfCapture_SDKRender = 1,
    AudioMode_SDKCapture_SelfRender = 2,
    AudioMode_SDKCapture_SDKRender = 3,
    AudioMode_SelfCapture_SelfRender = 4
    
};


#endif /* Define_h */
