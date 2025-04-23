//
//  OllamaModels.swift
//  local-llmanager
//
//  Created by Dominic McRae on 22/04/2025.
//

import Foundation

//struct LocalModelItem: Identifiable {
//    let id: String
//    var name: String
//    var identifier: String
//    var size: String
//    var modified: String
//}
//
//struct RunningModelItem: Identifiable {
//    let id: String
//    var name: String
//    var identifier: String
//    var size: String
//    var processor: String
//    var until: String
//}

struct DisplayModelItem: Identifiable {
    let id: String
    var name: String
    var identifier: String
    var sizePacked: String
    var sizeUnpacked: String
    var processor: String
    var until: String
    var modified: String
    var isRunning: Bool
}
