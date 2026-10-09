import SwiftUI
import UIKit
import ImageIO

/// CVee's dog mascot. Each mood ships as a still image (`Mascot/cvee-<mood>`) and an
/// animated WebP data asset (`Mascot/cvee-<mood>-animated`) in the asset catalog.
enum MascotMood: String, CaseIterable {
    case curious, wink, joyful

    var stillImageName: String { "Mascot/cvee-\(rawValue)" }
    var animationAssetName: String { "Mascot/cvee-\(rawValue)-animated" }
}

struct MascotView: View {
    let mood: MascotMood
    var size: CGFloat = 84
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityPlayAnimatedImages) private var playAnimatedImages
    @State private var animation: UIImage?

    private var animates: Bool { !reduceMotion && playAnimatedImages }

    var body: some View {
        Group {
            if animates, let animation {
                AnimatedMascotImage(animation: animation, restingImage: UIImage(named: mood.stillImageName))
            } else {
                Image(mood.stillImageName).resizable().scaledToFit()
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
        .task(id: "\(mood.rawValue)-\(animates)") {
            // The still shows until frames are decoded off the main thread.
            let key = mood.rawValue
            let assetName = mood.animationAssetName
            animation = MascotAnimationCache.cached(key)
            guard animation == nil, animates else { return }
            let decoded = await Task.detached(priority: .utility) {
                MascotAnimationCache.decode(assetName: assetName, key: key)
            }.value
            if !Task.isCancelled { animation = decoded }
        }
    }
}

/// Decodes each animated mood once. NSCache is thread-safe, and the cost limit keeps roughly
/// two moods' frames resident.
enum MascotAnimationCache {
    nonisolated(unsafe) private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 32 * 1024 * 1024
        return cache
    }()

    nonisolated static func cached(_ key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    nonisolated static func decode(assetName: String, key: String) -> UIImage? {
        if let cached = cached(key) { return cached }
        guard let data = NSDataAsset(name: assetName)?.data,
              let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        guard count > 1 else { return nil }

        let options = [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
        var frames: [UIImage] = []
        var duration: TimeInterval = 0
        var cost = 0
        for index in 0..<count {
            guard let frame = CGImageSourceCreateImageAtIndex(source, index, options) else { continue }
            frames.append(UIImage(cgImage: frame))
            duration += frameDelay(in: source, at: index)
            cost += frame.bytesPerRow * frame.height
        }
        guard !frames.isEmpty, let animated = UIImage.animatedImage(with: frames, duration: duration) else { return nil }
        cache.setObject(animated, forKey: key as NSString, cost: cost)
        return animated
    }

    nonisolated private static func frameDelay(in source: CGImageSource, at index: Int) -> TimeInterval {
        let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
        let webP = properties?[kCGImagePropertyWebPDictionary] as? [CFString: Any]
        let gif = properties?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        let delay = (webP?[kCGImagePropertyWebPUnclampedDelayTime] as? Double)
            ?? (webP?[kCGImagePropertyWebPDelayTime] as? Double)
            ?? (gif?[kCGImagePropertyGIFUnclampedDelayTime] as? Double)
            ?? (gif?[kCGImagePropertyGIFDelayTime] as? Double)
            ?? 0.045
        return delay > 0.01 ? delay : 0.045
    }
}

/// Plays the mood twice, then rests on the still image, so the dog greets without looping
/// beside the capture field. A new mood replays it.
private struct AnimatedMascotImage: UIViewRepresentable {
    let animation: UIImage
    let restingImage: UIImage?

    final class Coordinator {
        var current: UIImage?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        view.isAccessibilityElement = false
        return view
    }

    func updateUIView(_ view: UIImageView, context: Context) {
        guard context.coordinator.current !== animation else { return }
        context.coordinator.current = animation
        view.stopAnimating()
        view.animationImages = animation.images
        view.animationDuration = animation.duration
        view.animationRepeatCount = 2
        view.image = restingImage ?? animation.images?.last
        view.startAnimating()
    }
}

/// The mascot with a speech bubble beside it. At accessibility text sizes the dog sits above
/// the bubble so the message keeps the full row width.
struct MascotSpeechBubble: View {
    let mood: MascotMood
    let title: String
    let message: String
    var accessibilityID = "tasks.mascot"
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .trailing, spacing: 2) {
                MascotView(mood: mood, size: 72)
                    .padding(.trailing, 12)
                bubble(tail: .top)
            }
        } else {
            HStack(alignment: .center, spacing: 0) {
                bubble(tail: .trailing)
                MascotView(mood: mood, size: 84)
            }
        }
    }

    private func bubble(tail: SpeechBubbleShape.TailEdge) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(CVeeColors.ink)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(CVeeColors.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.leading, 14)
        .padding(.trailing, tail == .trailing ? 14 + SpeechBubbleShape.tailLength : 14)
        .padding(.top, tail == .top ? SpeechBubbleShape.tailLength : 0)
        .background {
            SpeechBubbleShape(tail: tail).fill(CVeeColors.card)
            SpeechBubbleShape(tail: tail).stroke(CVeeColors.divider, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(accessibilityID)
    }
}

/// Rounded bubble with a small tail pointing at the mascot.
struct SpeechBubbleShape: Shape {
    enum TailEdge { case trailing, top }
    static let tailLength: CGFloat = 10
    var tail: TailEdge
    var cornerRadius: CGFloat = 14

    // One continuous outline, so the fill and the hairline stroke both include the tail.
    func path(in rect: CGRect) -> Path {
        let tailLength = Self.tailLength
        let tailHalfWidth: CGFloat = 8
        var body = rect
        switch tail {
        case .trailing: body.size.width -= tailLength
        case .top: body.origin.y += tailLength; body.size.height -= tailLength
        }
        let radius = min(cornerRadius, body.width / 2, body.height / 2)
        let topLeft = CGPoint(x: body.minX, y: body.minY)
        let topRight = CGPoint(x: body.maxX, y: body.minY)
        let bottomRight = CGPoint(x: body.maxX, y: body.maxY)
        let bottomLeft = CGPoint(x: body.minX, y: body.maxY)

        var path = Path()
        path.move(to: CGPoint(x: body.minX + radius, y: body.minY))
        if tail == .top {
            // Tip sits over the mascot, which is inset from the trailing edge.
            let tipX = max(body.minX + radius + tailHalfWidth, body.maxX - 48)
            path.addLine(to: CGPoint(x: tipX - tailHalfWidth, y: body.minY))
            path.addLine(to: CGPoint(x: tipX, y: rect.minY))
            path.addLine(to: CGPoint(x: tipX + tailHalfWidth, y: body.minY))
        }
        path.addArc(tangent1End: topRight, tangent2End: bottomRight, radius: radius)
        if tail == .trailing {
            let tailHalf = min(tailHalfWidth, max(0, body.height / 2 - radius))
            path.addLine(to: CGPoint(x: body.maxX, y: body.midY - tailHalf))
            path.addLine(to: CGPoint(x: rect.maxX, y: body.midY))
            path.addLine(to: CGPoint(x: body.maxX, y: body.midY + tailHalf))
        }
        path.addArc(tangent1End: bottomRight, tangent2End: bottomLeft, radius: radius)
        path.addArc(tangent1End: bottomLeft, tangent2End: topLeft, radius: radius)
        path.addArc(tangent1End: topLeft, tangent2End: topRight, radius: radius)
        path.closeSubpath()
        return path
    }
}
