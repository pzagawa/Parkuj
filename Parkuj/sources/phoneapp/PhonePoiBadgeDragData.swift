//
//  PhonePoiBadgeDragData.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 20/02/2021.
//

import SwiftUI

class PhonePoiBadgeDragData: ObservableObject
{
    static let SCREEN_MARGIN: CGFloat = 40
    static let PADDING_SIZE: CGFloat = 16
    static let ANIM_DURATION: Double = 0.2 //100ms

    enum State: String
    {
        case none; case dragging; case cancel; case commit;
    }
    
    enum MoveDir: Int
    {
        case stop = 0; case left = -1; case right = 1;
    }

    @Published var state: State = .none
    @Published var offset: CGSize = .zero
    @Published var moveDir: MoveDir = .stop
    
    private var screenWidth: CGFloat = 0
    private var moveDirPrev: PhonePoiBadgeDragData.MoveDir = .stop
    private var indexOffset: Int = 0
    
    var minIndexOffset: Int = 0
    var maxIndexOffset: Int = Int.max

    init()
    {
        self.screenWidth = UIScreen.main.bounds.width
    }
 
    //propagate local changes to shared data
    func setExtDragData(extDragData: PhonePoiBadgeDragData)
    {
        extDragData.state = state
        extDragData.offset = offset
        extDragData.moveDir = moveDir
        extDragData.moveDirPrev = moveDirPrev
    }
    
    func reset()
    {
        self.state = .cancel
        self.offset = .zero
    }
    
    func indexOffsetInc()
    {
        indexOffset += 1
    }

    func indexOffsetDec()
    {
        indexOffset -= 1
    }
    
    var indexOffsetValue: Int
    {
        get
        {
            return indexOffset
        }
        set
        {
            indexOffset = newValue
        }
    }

    private var badgeWidth: CGFloat
    {
        return self.screenWidth - (PhonePoiBadgeDragData.SCREEN_MARGIN * 2)
    }

    private var commitOffset: CGFloat
    {
        return self.badgeWidth / 2
    }

    var snapGridSize: CGFloat
    {
        return self.badgeWidth + PhonePoiBadgeDragData.PADDING_SIZE
    }
    
    var isMoveCommited: Bool
    {
        return (moveDir == .stop && state == .commit)
    }
    
    var moveFinishedLeft: Bool
    {
        return moveDirPrev == .left
    }
    
    var moveFinishedRight: Bool
    {
        return moveDirPrev == .right
    }
    
    func positionOffset(positionIndex: Int) -> CGFloat
    {
        return self.offset.width + (CGFloat(positionIndex) * snapGridSize)
    }

    var animationState: Animation?
    {
        return (self.state == .none) ? .none : .easeOut(duration: PhonePoiBadgeDragData.ANIM_DURATION)
    }

    private func resetMove()
    {
        state = .cancel
        offset = .zero
        onDragCommit()
    }

    private func setMove(value: CGFloat)
    {
        state = .commit
        offset = .init(width: value, height: 0)
        onDragCommit()
    }

    var dragGesture: some Gesture
    {
        DragGesture()
        .onChanged
        {
            [weak self] action in
            
            guard let this = self else
            {
                return
            }

            if this.state != .dragging
            {
                this.state = .dragging
            }

            this.offset = action.translation
            
            if action.translation.width < 0
            {
                if this.moveDir != .left
                {
                    this.moveDirPrev = .left
                    this.moveDir = .left
                }
            }

            if action.translation.width > 0
            {
                if this.moveDir != .right
                {
                    this.moveDirPrev = .right
                    this.moveDir = .right
                }
            }
        }
        .onEnded
        {
            [weak self] action in
            
            guard let this = self else
            {
                return
            }
            
            if action.translation.width > (+this.commitOffset)
            {
                //check if item index change before first item
                if this.indexOffsetValue <= this.minIndexOffset
                {
                    this.resetMove()

                    this.fireHapticFeedback(type: .error)
                }
                else
                {
                    this.setMove(value: +this.snapGridSize)
                    
                    this.fireHapticFeedback(type: .success)
                }
                return
            }

            if action.translation.width < (-this.commitOffset)
            {
                //check if item index change after last item
                if this.indexOffsetValue >= (this.maxIndexOffset - 1)
                {
                    this.resetMove()
                    
                    this.fireHapticFeedback(type: .error)
                }
                else
                {
                    this.setMove(value: -this.snapGridSize)

                    this.fireHapticFeedback(type: .success)
                }
                return
            }

            this.resetMove()
        }
    }
    
    private func onDragCommit()
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + PhonePoiBadgeDragData.ANIM_DURATION)
        {
            [weak self] in
            
            guard let this = self else
            {
                return
            }

            this.moveDirPrev = this.moveDir
            this.moveDir = .stop
        }
    }
    
    private func fireHapticFeedback(type: UINotificationFeedbackGenerator.FeedbackType)
    {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}
