//
//  AVURLAsset+fileSize.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 27/1/2022.
//

import AVFoundation

extension AVURLAsset {
    var fileSize: Int? {
        let keys: Set<URLResourceKey> = [.totalFileSizeKey, .fileSizeKey]
        let resourceValues = try? url.resourceValues(forKeys: keys)
        
        /// return bytes
        return resourceValues?.fileSize ?? resourceValues?.totalFileSize
    }
}
