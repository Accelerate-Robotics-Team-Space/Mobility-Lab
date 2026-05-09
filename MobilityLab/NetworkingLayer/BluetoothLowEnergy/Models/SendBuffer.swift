//
//  SendBuffer.swift
//  MobilityLab
//
//  Created by Anton on 6/6/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import Foundation

/**
* Copyright (c) 2015 jmnavarro. All rights reserved.
*
* This library is free software; you can redistribute it and/or modify it under
* the terms of the GNU Lesser General Public License as published by the Free
* Software Foundation; either version 2.1 of the License, or (at your option)
* any later version.
*
* This library is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
* details.
*/

open class SendBuffer<Element> {
    open var onAdded: ((Element) -> Void)?
    open var onLocked: ((Element) -> Void)?
    open var onRemoved: ((Element) -> Void)?

    open var onFlush: ((
            _ items: [Element],
            _ commit: @escaping () -> Void,
            _ rollback: @escaping () -> Void,
            _ queue: OperationQueue) -> Void)?

    open var currentElements: [Element] {
        return buffer
    }

    open var lockedElements: [Element] {
        return locked
    }

    open var isFull: Bool {
        return self.buffer.count >= bufferSize
    }

    open var isFlushing: Bool {
        return !self.locked.isEmpty
    }

    open var size: Int {
        return bufferSize
    }

    open var autoFlush = true

    fileprivate let bufferSize: Int
    fileprivate let bufferQueue: OperationQueue
    fileprivate var doFlushWhenCompleted = false

    fileprivate var buffer: [Element]
    fileprivate var locked: [Element]

    fileprivate let queueKey = DispatchSpecificKey<Void>()

    public init(bufferSize: Int) {
        self.bufferSize = bufferSize

        let queueName = "sendbuffer-serial"
        let queue = DispatchQueue(label: queueName, attributes: [])
        queue.setSpecific(key: queueKey, value: ())

        bufferQueue = OperationQueue()
        bufferQueue.name = queueName
        bufferQueue.maxConcurrentOperationCount = 1
        bufferQueue.underlyingQueue = queue

        buffer = [Element]()
        buffer.reserveCapacity(bufferSize)

        locked = [Element]()
        locked.reserveCapacity(bufferSize)
    }

    open func add(_ element: Element) {
        bufferQueue.addOperation {
            self.buffer.append(element)
            self.onAdded?(element)

            if self.autoFlush {
                self.flushIfNeeded()
            }
        }
    }

    open func flush() {
        bufferQueue.addOperation {
            if self.isFlushing {
                // if several flush calls happened from different threads
                // then a new flush will be done when the current one is completed
                self.doFlushWhenCompleted = true
                return
            }

            let itemCount = min(self.bufferSize, self.buffer.count)

            let range = 0..<itemCount
            self.locked += Array(self.buffer[range])
            self.buffer.removeSubrange(range)

            if let onLocked = self.onLocked {
                self.locked.forEach(onLocked)
            }

            self.onFlush?(
                self.locked,
                self.commitFlush,
                self.rollbackFlush,
                self.bufferQueue)
        }
    }

    fileprivate func commitFlush() {
        bufferQueue.schedule(options: .none) {
            self.assertOnBufferQueue()
        
            if let onRemoved = self.onRemoved {
                self.locked.forEach(onRemoved)
            }

            self.locked.removeAll(keepingCapacity: true)

            if self.autoFlush || self.doFlushWhenCompleted {
                self.flushIfNeeded()
                self.doFlushWhenCompleted = false
            }
        }
    }

    fileprivate func rollbackFlush() {
        bufferQueue.schedule(options: .none) {
            self.assertOnBufferQueue()

            // insert them back in the head. Keep same order
            self.locked.reversed().forEach {
                self.buffer.insert($0, at: 0)
                self.onAdded?($0)
            }

            self.locked.removeAll(keepingCapacity: true)
            self.doFlushWhenCompleted = false
        }
    }

    fileprivate func flushIfNeeded() {
        if isFull {
            if isFlushing {
                // Flush is needed but the queue is flushing right now.
                // When the current flush is completed, it will start over again
                doFlushWhenCompleted = true
            } else {
                flush()
            }
        }
    }

    fileprivate func assertOnBufferQueue() {
//        let value: Void? = DispatchQueue.getSpecific(key: queueKey)
//        assert(value != nil)
    }
}
