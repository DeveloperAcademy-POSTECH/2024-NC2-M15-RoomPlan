//
//  MarkdownView.swift
//  MyRaum
//
//  Created by Yune Cho on 10/17/26.
//

import SwiftUI

//마크다운 문서를 보여주는 뷰 (개인정보처리방침, 이용약관)
//제목(#, ##, ###), 목록(-, 1.), 구분선(---), 문단을 지원하고 굵게, 링크 같은 문장 안의 서식은 AttributedString으로 처리
struct MarkdownView: View {
    let markdown: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(MarkdownBlock.parse(markdown).enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        //링크가 본문과 구분되도록 파란색으로 표시
        .tint(Color.blue)
    }
}

private extension MarkdownView {
    @ViewBuilder
    func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            switch level {
            case 1:
                inlineText(text)
                    .font(.title2)
                    .bold()
                    .padding(.bottom, 6)
            case 2:
                inlineText(text)
                    .font(.headline)
                    .padding(.top, 14)
            default:
                inlineText(text)
                    .font(.subheadline)
                    .bold()
                    .padding(.top, 6)
            }

        case .paragraph(let text):
            inlineText(text)
                .font(.callout)

        case .listItem(let marker, let text):
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(verbatim: marker)
                inlineText(text)
            }
            .font(.callout)
            .padding(.leading, 4)

        case .divider:
            Divider()
                .padding(.vertical, 8)
        }
    }

    func inlineText(_ text: String) -> Text {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        if let attributed = try? AttributedString(markdown: text, options: options) {
            return Text(attributed)
        }
        return Text(verbatim: text)
    }
}

private enum MarkdownBlock {
    case heading(level: Int, text: String)
    case paragraph(String)
    case listItem(marker: String, text: String)
    case divider

    static func parse(_ markdown: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var paragraph: [String] = []

        //줄바꿈으로 나뉜 문장들은 하나의 문단으로 합침
        func flushParagraph() {
            if !paragraph.isEmpty {
                blocks.append(.paragraph(paragraph.joined(separator: " ")))
                paragraph.removeAll()
            }
        }

        for rawLine in markdown.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.isEmpty {
                flushParagraph()
            } else if line == "---" {
                flushParagraph()
                blocks.append(.divider)
            } else if let heading = heading(in: line) {
                flushParagraph()
                blocks.append(heading)
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                flushParagraph()
                blocks.append(.listItem(marker: "•", text: String(line.dropFirst(2))))
            } else if let item = numberedItem(in: line) {
                flushParagraph()
                blocks.append(item)
            } else {
                paragraph.append(line)
            }
        }
        flushParagraph()

        return blocks
    }

    private static func heading(in line: String) -> MarkdownBlock? {
        let level = line.prefix { $0 == "#" }.count
        guard (1...3).contains(level), line.dropFirst(level).first == " " else { return nil }
        return .heading(level: level, text: String(line.dropFirst(level + 1)))
    }

    //"1. 내용" 형식의 번호 목록
    private static func numberedItem(in line: String) -> MarkdownBlock? {
        let number = line.prefix { $0.isNumber }
        guard !number.isEmpty, line.dropFirst(number.count).hasPrefix(". ") else { return nil }
        return .listItem(marker: "\(number).", text: String(line.dropFirst(number.count + 2)))
    }
}

#Preview {
    ScrollView {
        MarkdownView(markdown: """
        # 제목
        **굵은 글씨**가 있는 문단입니다.

        ## 1. 항목
        - 목록 하나
        - [링크](mailto:raumdaum.app@gmail.com)

        1. 번호 목록
        2. 두 번째

        ---

        시행일: 2026년 10월 17일
        """)
        .padding()
    }
}
