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
 @file AKRadar.m
 @brief レーダークラス定義
 
 敵のいる方向を示すレーダーを管理するクラスを定義する。
 */

#import "AKRadar.h"
#import "AKCharacter.h"
#import "AKScreenSize.h"
#import "AKGameScene.h"

/// レーダーのサイズ
static const NSInteger kAKRadarSize = 128;
/// レーダーの配置位置
static const CGPoint kAKRadarPos = {400, 190};
/// レーダーの配置位置、右からの位置
static const float kAKRadarPosRightPoint = 80.0f;
/// レーダーの配置位置、上からの位置
static const float kAKRadarPosTopPoint = 130.0f;

/*!
 @brief レーダークラス

 敵のいる方向を示すレーダーを管理するクラス。
 */
@implementation AKRadar

@synthesize radarImage = radarImage_;
@synthesize markerImage = markerImage_;

/*!
 @brief オブジェクト生成処理

 オブジェクトの生成を行う。
 @return 生成したオブジェクト。失敗時はnilを返す。
 */
- (id)init
{
    int i = 0;              // ループ変数
    CCSprite *marker = nil; // マーカーの画像
    
    // スーパークラスの生成処理を実行する
    self = [super init];
    if (!self) {
        return nil;
    }
    
    // レーダーの画像を読み込む
    self.radarImage = [CCSprite spriteWithFile:@"Radar.png"];
    assert(self.radarImage != nil);
    
    // レーダーの画像をノードに配置する
    [self addChild:self.radarImage z:0];
    
    // レーダーの位置を設定する
    self.radarImage.position = ccp([AKScreenSize positionFromRightPoint:kAKRadarPosRightPoint],
                                   [AKScreenSize positionFromTopPoint:kAKRadarPosTopPoint]);
    
    // 自機用のマーカーの画像を読み込む
    marker = [CCSprite spriteWithFile:@"Marker.png"];
    
    // レーダーのサイズを決める
    NSInteger radarSize = kAKRadarSize;
    
    // iPadの場合はサイズを倍にする
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        radarSize *= 2;
    }
    
    // 自機のマーカーはレーダーの中心とする
    marker.position = ccp(radarSize / 2, radarSize / 2);
    
    // レーダーの上に配置する
    [self.radarImage addChild:marker];

    // マーカーを保存する配列を生成する
    self.markerImage = [NSMutableArray arrayWithCapacity:kAKMaxEnemyCount];
    
    // マーカーを生成する
    for (i = 0; i < kAKMaxEnemyCount; i++) {
        
        // マーカーの画像を読み込む
        marker = [CCSprite spriteWithFile:@"Marker.png"];
        
        // 初期状態は非表示とする
        marker.visible = NO;
        
        // レーダーの上に配置する
        [self.radarImage addChild:marker];
        
        // 配列に登録する
        [self.markerImage addObject:marker];
    }
    
    return self;
}

/*!
 @brief インスタンス解放時処理

 インスタンス解放時にオブジェクトを解放する。
 */
- (void)dealloc
{
    // マーカーを解放する
    self.markerImage = nil;
    [self.radarImage removeAllChildrenWithCleanup:YES];
    
    // レーダーの画像を解放する
    [self removeChild:self.radarImage cleanup:YES];
    
    // スーパークラスの解放処理を実行する
    [super dealloc];
}

/*!
 @brief マーカーの配置位置更新処理

 マーカーの配置位置を敵の座標情報から更新する。
 @param enemys 敵情報配列
 @param screenAngle 画面の傾き
 */
- (void)updateMarker:(const NSArray *)enemys ScreenAngle:(float)screenAngle
{
    // レーダーのサイズを決める
    NSInteger radarSize = kAKRadarSize;
    
    // iPadの場合はサイズを倍にする
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        radarSize *= 2;
    }

    // 各敵の位置をマーカーに反映させる
    for (int i = 0; i < kAKMaxEnemyCount; i++) {
        
        // 配列サイズのチェックを行う
        assert(i < enemys.count);
        assert(i < self.markerImage.count);
        
        // 配列から要素を取得する
        AKCharacter *enemy = [enemys objectAtIndex:i];
        CCNode *marker = [self.markerImage objectAtIndex:i];
        
        // 敵が画面に配置されていない場合はマーカーの表示を消す
        if (!enemy.isStaged) {
            AKLog(0 && marker.visible, @"visible=NO i=%d", i);
            marker.visible = NO;
            continue;
        }
        
        // 自機から見て敵の方向を調べる。
        // 絶対座標ではステージループの問題が発生するため
        // スクリーン座標を使用する。
        float angle = AKCalcDestAngle(AKPlayerPosX(), AKPlayerPosY(),
                                      enemy.image.position.x, enemy.image.position.y);
        
        // 自機の向いている方向を上向きとする。
        // 上向き(π/2)を0とするので、自機の角度 - π / 2をマイナスする。
        angle -= screenAngle - M_PI / 2;
        
        AKLog(0, @"angle=%f", angle);
        
        // マーカーの向きを計算する
        // 敵の向いている向きから自機の向いている向きをマイナスして画面の向きに補正する
        float makerAngle =  enemy.angle - [AKGameScene getInstance].player.angle + M_PI / 2.0f;
                
        // 座標を計算する
        // レーダーの中心を原点とするため、xyそれぞれレーダーの幅の半分を加算する。
        float posx = ((radarSize / 2) * cos(angle)) + (radarSize / 2);
        float posy = ((radarSize / 2) * sin(angle)) + (radarSize / 2);
        AKLog(0, @"enemy=(%f,%f) angle=%f marker=(%f,%f)",
               enemy.image.position.x, enemy.image.position.y,
               AKCnvAngleRad2Deg(angle), posx, posy);
        
        // マーカーの配置位置と角度を設定し、表示状態にする。
        marker.position = ccp(posx, posy);
        marker.rotation = AKCnvAngleRad2Scr(makerAngle);
        marker.visible = YES;
    }
}
@end
