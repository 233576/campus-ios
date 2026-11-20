import Foundation
import CommonCrypto
import CryptoKit

/// 两个模块共用的编解码工具。
///
/// - 胖乖生活：SHA-256 签名 + form 编码
/// - GiWiFi：MD5 签名、AES-128-ECB/PKCS7（App Portal API）、AES-128-CBC/ZeroPadding（网页登录）
enum Crypto {

    // MARK: - 摘要

    /// SHA-256 十六进制小写（胖乖生活所有接口的 sign）。
    static func sha256Hex(_ raw: String) -> String {
        let digest = SHA256.hash(data: Data(raw.utf8))
        var out = ""
        out.reserveCapacity(64)
        for byte in digest {
            let hex = String(byte, radix: 16)
            if hex.count == 1 { out += "0" }
            out += hex
        }
        return out
    }

    /// MD5 十六进制小写（GiWiFi App Portal 的 sign）。
    static func md5Hex(_ value: String) -> String {
        Insecure.MD5.hash(data: Data(value.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    // MARK: - 表单编码

    /// 胖乖生活用的宽松编码：保留字母数字与 `-._*`。
    static func formEncode(_ value: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._*")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    /// `application/x-www-form-urlencoded` 请求体。
    static func formBody(_ fields: [(String, String)]) -> Data {
        let body = fields
            .map { "\(formEncode($0.0))=\(formEncode($0.1))" }
            .joined(separator: "&")
        return Data(body.utf8)
    }

    /// jQuery `$.serialize()` 的等价实现：`k=v&k=v`，空格转 `+`，其余按 UTF-8 字节 `%XX` 大写。
    static func formSerialize(_ pairs: [(String, String)]) -> String {
        pairs
            .filter { !$0.0.isEmpty }
            .map { javaFormURLEncode($0.0) + "=" + javaFormURLEncode($0.1) }
            .joined(separator: "&")
    }

    /// 等价于 `java.net.URLEncoder.encode(value, "UTF-8")`：
    /// 保留 `[0-9A-Za-z]` 与 `-_.*`，空格转 `+`，其余按 UTF-8 字节输出 `%XX` 大写。
    static func javaFormURLEncode(_ value: String) -> String {
        var output = String()
        output.reserveCapacity(value.count * 3)
        for byte in value.utf8 {
            switch byte {
            case 0x30...0x39, 0x41...0x5A, 0x61...0x7A, 0x2D, 0x5F, 0x2E, 0x2A:
                output.append(Character(UnicodeScalar(byte)))
            case 0x20:
                output.append("+")
            default:
                output.append(String(format: "%%%02X", byte))
            }
        }
        return output
    }

    // MARK: - AES-128-ECB + PKCS7（GiWiFi App Portal）

    static func aes128ECBEncryptBase64(plaintext: String, key: String) -> String? {
        let keyData = Data(key.utf8)
        guard keyData.count == kCCKeySizeAES128 else { return nil }
        let inputData = Data(plaintext.utf8)
        guard !inputData.isEmpty else { return nil }

        let bufferSize = inputData.count + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        var encryptedLength = 0

        let status = buffer.withUnsafeMutableBytes { outBytes -> CCCryptorStatus in
            guard let outBase = outBytes.baseAddress else { return CCCryptorStatus(kCCMemoryFailure) }
            return inputData.withUnsafeBytes { inBytes -> CCCryptorStatus in
                guard let inBase = inBytes.baseAddress else { return CCCryptorStatus(kCCMemoryFailure) }
                return keyData.withUnsafeBytes { keyBytes -> CCCryptorStatus in
                    CCCrypt(
                        CCOperation(kCCEncrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionECBMode | kCCOptionPKCS7Padding),
                        keyBytes.baseAddress, keyData.count,
                        nil,
                        inBase, inputData.count,
                        outBase, bufferSize,
                        &encryptedLength
                    )
                }
            }
        }

        guard status == CCCryptorStatus(kCCSuccess) else { return nil }
        return buffer.prefix(encryptedLength).base64EncodedString()
    }

    static func aes128ECBDecryptBase64(_ base64: String, key: String) -> String? {
        guard let encrypted = Data(base64Encoded: base64) else { return nil }
        let keyData = Data(key.utf8)
        guard keyData.count == kCCKeySizeAES128, encrypted.count % kCCBlockSizeAES128 == 0 else { return nil }

        let bufferSize = encrypted.count + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        var plainLength = 0

        let status = buffer.withUnsafeMutableBytes { outBytes -> CCCryptorStatus in
            guard let outBase = outBytes.baseAddress else { return CCCryptorStatus(kCCMemoryFailure) }
            return encrypted.withUnsafeBytes { inBytes -> CCCryptorStatus in
                guard let inBase = inBytes.baseAddress else { return CCCryptorStatus(kCCMemoryFailure) }
                return keyData.withUnsafeBytes { keyBytes -> CCCryptorStatus in
                    CCCrypt(
                        CCOperation(kCCDecrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionECBMode | kCCOptionPKCS7Padding),
                        keyBytes.baseAddress, keyData.count,
                        nil,
                        inBase, encrypted.count,
                        outBase, bufferSize,
                        &plainLength
                    )
                }
            }
        }

        guard status == CCCryptorStatus(kCCSuccess) else { return nil }
        return String(data: buffer.prefix(plainLength), encoding: .utf8)
    }

    // MARK: - AES-128-CBC + ZeroPadding（GiWiFi 网页登录）

    /// 复刻官方 Portal 页面的 `cryptoEncode()`：AES-128-CBC，**ZeroPadding**（补 0x00），
    /// 正好对齐时不再补整块。
    static func aes128CBCZeroPadBase64(plaintext: String, key: String, iv: String) -> String? {
        let keyData = Data(key.utf8)
        let ivData = Data(iv.utf8)
        guard keyData.count == kCCKeySizeAES128, ivData.count == kCCBlockSizeAES128 else { return nil }

        var inputData = Data(plaintext.utf8)
        let remainder = inputData.count % kCCBlockSizeAES128
        if remainder != 0 {
            inputData.append(Data(repeating: 0, count: kCCBlockSizeAES128 - remainder))
        }

        let bufferSize = inputData.count + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        var encryptedLength = 0

        let status = buffer.withUnsafeMutableBytes { outBytes -> CCCryptorStatus in
            guard let outBase = outBytes.baseAddress else { return CCCryptorStatus(kCCMemoryFailure) }
            return inputData.withUnsafeBytes { inBytes -> CCCryptorStatus in
                guard let inBase = inBytes.baseAddress else { return CCCryptorStatus(kCCMemoryFailure) }
                return keyData.withUnsafeBytes { keyBytes -> CCCryptorStatus in
                    ivData.withUnsafeBytes { ivBytes -> CCCryptorStatus in
                        CCCrypt(
                            CCOperation(kCCEncrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            0,                       // 无 ECB、无 PKCS7 → 纯 CBC
                            keyBytes.baseAddress, keyData.count,
                            ivBytes.baseAddress,
                            inBase, inputData.count,
                            outBase, bufferSize,
                            &encryptedLength
                        )
                    }
                }
            }
        }

        guard status == CCCryptorStatus(kCCSuccess) else { return nil }
        return buffer.prefix(encryptedLength).base64EncodedString()
    }
}
