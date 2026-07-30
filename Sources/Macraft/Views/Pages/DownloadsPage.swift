import SwiftUI

// MARK: - Downloads Page
struct DownloadsPage: View {
    var body: some View {
        PageContainer(title: "下载中心", subtitle: "正在下载与已完成的资源会显示在这里") {
            Card {
                EmptyState(
                    icon: "tray",
                    title: "暂无下载任务",
                    message: "当你安装新版本或下载资源包时，进度会实时显示在这里。"
                )
            }
        }
    }
}
