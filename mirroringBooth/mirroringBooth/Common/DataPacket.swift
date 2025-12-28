//
//  DataPacket.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-27.
//

import Foundation

/// 비디오 스트리밍에서 전송되는 패킷 타입
enum DataPacketType: UInt8 {
    case sps = 0x01        // Sequence Parameter Set
    case pps = 0x02        // Picture Parameter Set
    case idrFrame = 0x03   // KeyFrame (IDR Frame)
    case pFrame = 0x04     // P-Frame (Predicted Frame)
    case photo = 0x05      // High Quality Photo (JPEG)
    case captureRequest = 0x06  // Capture Photo Request (iPad → iPhone)
}

/// 비디오 패킷 구조
/// [1 byte: type] + [4 bytes: data length] + [N bytes: data]
struct DataPacket {
    let type: DataPacketType
    let data: Data

    /// 패킷을 전송 가능한 Data로 직렬화
    func serialize() -> Data {
        var packet = Data()
        packet.append(type.rawValue)

        // 데이터 길이를 4바이트로 추가 (Big Endian)
        var length = UInt32(data.count).bigEndian
        packet.append(Data(bytes: &length, count: 4))

        // 실제 데이터 추가
        packet.append(data)

        return packet
    }

    /// 수신된 Data에서 패킷 파싱
    static func deserialize(_ data: Data) -> DataPacket? {
        guard data.count >= 5 else { return nil }

        // 타입 추출
        guard let type = DataPacketType(rawValue: data[0]) else { return nil }

        // 길이 추출 (Big Endian)
        let lengthData = data.subdata(in: 1..<5)
        let length = lengthData.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }

        // 데이터 추출
        guard data.count >= 5 + Int(length) else { return nil }
        let payload = data.subdata(in: 5..<(5 + Int(length)))

        return DataPacket(type: type, data: payload)
    }
}
