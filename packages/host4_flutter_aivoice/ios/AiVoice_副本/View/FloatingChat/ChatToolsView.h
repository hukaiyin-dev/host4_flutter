//
//  ChatToolsView.h
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ChatToolsView : UIView

@property (strong, nonatomic) IBOutlet UIView *contentView;

@property (nonatomic, assign) AiVoiceChatState chatState;

-(void)playAnimal;

-(void)stopAnimal;

@end

NS_ASSUME_NONNULL_END
