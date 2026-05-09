//
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import CoreBluetooth
import Foundation

protocol BlePacketDelegate: AnyObject {
    func managerIsReady(completion: @escaping () -> Void)
}

class BlePacket {
    static let headerCapacity = 2
    static let chunkSize = 230
    
    weak var delegate: BlePacketDelegate?
    
    private var chunks: [Data] = []
    private var maxChunks = 0
    
    enum PacketResult {
        case success(data: Data)
        case needMoreData
        case failure(err: Error)
    }

    // MARK: - Init
    init(data: Data = Data()) {
        chunks = data.asDataChunks(chunkSize: Self.chunkSize)
    }
    
    // MARK: - Util Methods
    func receiveData(_ receivedData: Data, result: @escaping (PacketResult) -> Void) {
        var iter = receivedData.makeIterator()
        
        guard
            let headerNextIter = iter.next(),
            let headerSequence = BLESequence(rawValue: UInt8(bigEndian: headerNextIter)) else {
            return result(.failure(err: NetworkingError.BLE.noPacketHeader))
        }
        
        switch headerSequence {
        case .header:
            guard let chunkCountNextIter = iter.next() else { break }
            maxChunks = Int(UInt8(bigEndian: chunkCountNextIter))
            
            let nextChunk = getDataFromChunk(receivedData, at: &iter)
            return receiveData(nextChunk, result: result)
        case .packet:
            let chunkData = getDataFromChunk(receivedData, at: &iter)
            chunks.append(chunkData)
            
            if chunks.count == maxChunks {
                let assembledChunks = assembleChunks(chunks)
                return result(.success(data: assembledChunks))
            } else {
                return result(.needMoreData)
            }
        default: break
        }
    }
    
    func transmit(to peripheral: CBPeripheral, char: CBCharacteristic, completion: @escaping (BLESequence) -> Void) {
        transmit(updater: PacketUpdater(centralPeripehral: peripheral,
                                        characteristic: char),
                 completion: completion)
    }
    
    func transmit(using manager: CBPeripheralManager, char: CBMutableCharacteristic, completion: @escaping (BLESequence) -> Void) {
        transmit(updater: PacketUpdater(peripheralManager: manager,
                                        characteristic: char),
                 completion: completion)
    }
}

// MARK: - Private
private extension BlePacket {
    struct PacketUpdater {
        let peripheralUpdater: (CBPeripheralManager, CBMutableCharacteristic)?
        let centralUpdater: (CBPeripheral, CBCharacteristic)?
        
        init(peripheralManager: CBPeripheralManager, characteristic: CBMutableCharacteristic) {
            self.peripheralUpdater = (peripheralManager, characteristic)
            self.centralUpdater = nil
        }
        
        init(centralPeripehral: CBPeripheral, characteristic: CBCharacteristic) {
            self.peripheralUpdater = nil
            self.centralUpdater = (centralPeripehral, characteristic)
        }
        
        func updateValue(_ value: Data) -> Bool? {
            if let peripheralUpdater = peripheralUpdater {
                let (manager, char) = peripheralUpdater
                return manager.updateValue(value, for: char, onSubscribedCentrals: nil)
            } else if let centralUpdater = centralUpdater {
                let (peripheral, char) = centralUpdater
                peripheral.writeValue(value, for: char, type: .withoutResponse)
                return true
            } else {
                return nil
            }
        }
    }
    
    // MARK: - Transmitter
    func transmit(updater: PacketUpdater,
                  currentSequence: BLESequence = .initialize,
                  currentChunk: Int = 0, remainingRetries: Int = 3,
                  completion: @escaping (BLESequence) -> Void) {
        switch currentSequence {
        case .initialize:
            transmit(updater: updater,
                     currentSequence: .header,
                     currentChunk: currentChunk,
                     remainingRetries: remainingRetries,
                     completion: completion)
        case .header:
            guard let chunksCount = UInt8(exactly: chunks.count) else { return completion(.error) }
            
            var header = Data(capacity: Self.headerCapacity)
            header.append(currentSequence.rawValue.bigEndian)
            header.append(chunksCount.bigEndian)  // we can guard the UInt8 and then just return error if we fail
            
            addNewHeader(header, atChunkIndex: 0)
            transmit(updater: updater,
                     currentSequence: .packet,
                     currentChunk: currentChunk,
                     remainingRetries: remainingRetries,
                     completion: completion)
        case .packet:
            guard
                !chunks.isEmpty,
                let valueWasUpdated = updater.updateValue(chunks[currentChunk]) else { return completion(.error) }
            
            if valueWasUpdated {
                transmit(updater: updater,
                         currentSequence: currentChunk == (chunks.count - 1) ? .end : .packet,
                         currentChunk: currentChunk + 1,
                         remainingRetries: 3,
                         completion: completion)
            } else if remainingRetries > 0 {
                guard delegate != nil else { return completion(.error) }
                
                delegate?.managerIsReady {
                    self.transmit(updater: updater,
                                  currentSequence: .packet,
                                  currentChunk: currentChunk,
                                  remainingRetries: remainingRetries - 1,
                                  completion: completion)
                }
            } else {
                return completion(.error)
            }
        default:
            return completion(currentSequence)
        }
    }
    
    // MARK: - Healper Methods
    func addNewHeader(_ header: Data, atChunkIndex: Int) {
        guard !chunks.isEmpty else { return }
        
        var tmpData = Data(capacity: chunks[atChunkIndex].count + BlePacket.headerCapacity)
        tmpData.append(contentsOf: header)
        tmpData.append(contentsOf: chunks[atChunkIndex])
        
        chunks[atChunkIndex] = tmpData
    }
    
    func assembleChunks(_ chunks: [Data]) -> Data {
        var tmpData = Data()
        for chunk in chunks {
            tmpData.append(chunk)
        }
        
        return tmpData
    }
    
    func getDataFromChunk(_ chunkData: Data, at iter: inout Data.Iterator) -> Data {
        var tmpData = Data(capacity: Self.chunkSize)
        for _ in 0...Self.chunkSize {
            guard let tmpNextIter = iter.next() else { break }
            
            tmpData.append(tmpNextIter)
        }
        
        return tmpData
    }
}
