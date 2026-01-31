//
//  ItemListHeader.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import SwiftUI

struct ItemListHeader: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = self.appState

        VStack(spacing: 8) {
            // Row 1: Breadcrumb + Filter buttons
            HStack {
                self.breadcrumb
                Spacer()
                self.filterButtons
            }

            // Row 2: Local search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(
                    String(localized: "Search locally...", comment: "Local search placeholder"),
                    text: $appState.filter.searchQuery
                )
                .textFieldStyle(.plain)

                if !self.appState.filter.searchQuery.isEmpty {
                    Button {
                        self.appState.filter.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // Row 3: Column headers
            self.columnHeaders
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }

    @ViewBuilder
    private var breadcrumb: some View {
        if let project = self.appState.selectedProject {
            HStack(spacing: 4) {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Text(project.path.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    private var columnHeaders: some View {
        @Bindable var appState = self.appState

        // Minimum space reserved for title column
        let minTitleWidth: CGFloat = 100
        // Spacing between columns (resize handle width)
        let columnSpacing: CGFloat = 13

        return GeometryReader { geometry in
            let availableWidth = geometry.size.width - 16 // Account for horizontal padding
            let maxCategoryWidth = availableWidth - appState.labelsColumnWidth - minTitleWidth - (columnSpacing * 2)
            let maxLabelsWidth = availableWidth - appState.categoryColumnWidth - minTitleWidth - (columnSpacing * 2)

            HStack(spacing: 0) {
                Text(String(localized: "Category", comment: "Column header for category"))
                    .frame(width: appState.categoryColumnWidth, alignment: .leading)

                ColumnResizeHandle(
                    width: $appState.categoryColumnWidth,
                    minWidth: 60,
                    maxWidth: max(60, maxCategoryWidth)
                )

                Text(String(localized: "Title", comment: "Column header for title"))
                    .frame(maxWidth: .infinity, alignment: .leading)

                ColumnResizeHandle(
                    width: $appState.labelsColumnWidth,
                    minWidth: 60,
                    maxWidth: max(60, maxLabelsWidth),
                    inverted: true
                )

                Text(String(localized: "Labels", comment: "Column header for labels"))
                    .frame(width: appState.labelsColumnWidth, alignment: .leading)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
        }
        .frame(height: 20)
    }

    private var filterButtons: some View {
        HStack(spacing: 4) {
            FilterToggle(
                title: String(localized: "Open", comment: "Open filter button"),
                isSelected: self.appState.filter.mode == .open
            ) {
                self.appState.filter.mode = .open
            }

            FilterToggle(
                title: String(localized: "Closed", comment: "Closed filter button"),
                isSelected: self.appState.filter.mode == .closed
            ) {
                self.appState.filter.mode = .closed
            }

            FilterToggle(
                title: String(localized: "Templates", comment: "Templates filter button"),
                isSelected: self.appState.filter.mode == .templates
            ) {
                self.appState.filter.mode = .templates
            }
        }
    }
}

private struct ColumnResizeHandle: View {
    @Binding var width: CGFloat
    let minWidth: CGFloat
    let maxWidth: CGFloat
    var inverted: Bool = false

    @State private var isDragging = false
    @State private var isHovering = false

    var body: some View {
        Rectangle()
            .fill(Color.secondary.opacity(self.isDragging || self.isHovering ? 0.5 : 0.3))
            .frame(width: 1, height: 12)
            .padding(.horizontal, 6)
            .contentShape(Rectangle().size(width: 13, height: 20))
            .onHover { hovering in
                self.isHovering = hovering
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        self.isDragging = true
                        let delta = self.inverted ? -value.translation.width : value.translation.width
                        let newWidth = self.width + delta
                        self.width = min(max(newWidth, self.minWidth), self.maxWidth)
                    }
                    .onEnded { _ in
                        self.isDragging = false
                    }
            )
    }
}

private struct FilterToggle: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            Text(self.title)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .background(self.isSelected ? Color.accentColor : Color.clear)
        .foregroundStyle(self.isSelected ? .white : .primary)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

#Preview {
    ItemListHeader()
        .environment(AppState())
}
