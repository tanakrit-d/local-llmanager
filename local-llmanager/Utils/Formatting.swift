//
//  Formatting.swift
//  local-llmanager
//
//  Created by Dominic McRae on 23/04/2025.
//

import Foundation

func formatBytes(_ bytes: Int) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useGB, .useMB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: Int64(bytes))
}

func formatRelativeDate(_ dateString: String) -> String {
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    if let date = isoFormatter.date(from: dateString) {
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .full
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    } else {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        if let date = dateFormatter.date(from: dateString) {
             return dateFormatter.string(from: date)
        }
    }
    return dateString
}
