/*
 * Copyright (c) 2012-2013 Akihiro Kaneda.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   1.Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *   2.Redistributions in binary form must reproduce the above copyright notice,
 *     this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *   3.Neither the name of the Monochrome Soft nor the names of its contributors
 *     may be used to endorse or promote products derived from this software
 *     without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
/*!
 @file AKBackground.m
 @brief 背景クラス定義
 
 背景の描画を行うクラスを定義する。
 */

#import "AKBackground.h"

/// タイルのサイズ
static const NSInteger kAKTileSize = 64;
/// タイルの横1行の数
static const NSInteger kAKTileCount = 14;
/// 背景画像のファイル名
static NSString *kAKTileFile = @"Back.png";

/*!
 @brief 背景クラス
 
 背景の描画を行う。
 */
@implementation AKBackground

@synthesize batch = batch_;

/*!
 @brief オブジェクト生成処理

 オブジェクトの生成を行う。
 @return 生成したオブジェクト。失敗時はnilを返す。
 */
- (id)init
{
    // スーパークラスの生成処理
    self = [super init];
    if (!self) {
        return nil;
    }
    
    // 背景のバッチノードを作成する
    self.batch = [CCSpriteBatchNode batchNodeWithFile:kAKTileFile capacity:kAKTileCount * kAKTileCount];
    NSAssert(self.batch != nil, @"can not create self.batch");
    
    // タイルサイズを取得する
    NSInteger tileSize = kAKTileSize;
    
    // iPadの場合はサイズを倍にする
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        tileSize *= 2;
    }
    
    // タイルを作成する
    for (int i = 0; i < kAKTileCount; i++) {
        
        for (int j = 0; j < kAKTileCount; j++) {
            
            // タイルを生成する
            CCSprite *tile = [CCSprite spriteWithFile:kAKTileFile];
            NSAssert(tile != nil, @"can not create tile");
            
            // アンカーポイントを中心にして画像を配置する
            tile.position = ccp(tileSize * (i - kAKTileCount / 2),
                                tileSize * (j - kAKTileCount / 2));
            
            // バッチノードに登録する
            [self.batch addChild:tile];
        }
    }
            
    // 位置の設定
    [self moveWithScreenX:0 ScreenY:0];
    
    return self;
}

/*!
 @brief インスタンス解放時処理
 
 インスタンス解放時にオブジェクトを解放する。
 */
- (void)dealloc
{
    // 背景画像の解放
    [self.batch removeFromParentAndCleanup:YES];
    [self.batch removeAllChildrenWithCleanup:YES];
    self.batch = nil;
    
    // スーパークラスの解放処理
    [super dealloc];
}

/*!
 @brief 移動処理
 
 スクリーン座標から背景画像の位置を決める。
 @param scrx スクリーン座標x
 @param scry スクリーン座標y
 */
- (void)moveWithScreenX:(NSInteger)scrx ScreenY:(NSInteger)scry
{
    float posx = 0.0f; /* 背景画像のx座標 */
    float posy = 0.0f; /* 背景画像のy座標 */

    // タイルサイズを取得する
    NSInteger tileSize = kAKTileSize;
    
    // iPadの場合はサイズを倍にする
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        tileSize *= 2;
    }

    // 自機の配置位置を中心とする。
    // そこからタイルサイズ分の範囲でスクロールする。(-32 〜 +32)
    posx = AKPlayerPosX() + tileSize / 2 + (-scrx % tileSize);
    posy = AKPlayerPosY() + tileSize / 2 + (-scry % tileSize);
    AKLog(0, @"basex=%f basey=%f", posx, posy);
    
    // 背景画像の位置を移動する。
    self.batch.position = ccp(posx, posy);
}

@end
