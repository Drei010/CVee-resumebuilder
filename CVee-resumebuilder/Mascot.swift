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

/// Shared mascot geometry, so Tasks and Saved Jobs show the dog at the same prominence.
enum MascotMetrics {
    /// The dog at standard text sizes.
    static let prominentSize: CGFloat = 112
    /// The dog at accessibility text sizes, where it stacks above the bubble.
    static let stackedSize: CGFloat = 72
    /// How far the dog's lower part reaches over the top edge of the card it leans on.
    static let leaningOverlap: CGFloat = 22
    /// How far the bubble's bottom sits above the dog's bottom when the dog leans on a card,
    /// leaving a small gap above the card.
    static let leaningBubbleLift: CGFloat = leaningOverlap + 10
    /// The bubble's trailing tail sits this far above the bubble's bottom, level with the dog's
    /// head, so a bubble that grows taller with its text still points at the dog.
    static let leaningTailInset: CGFloat = prominentSize * 0.7 - leaningBubbleLift

    /// The dog leans on the card at standard text sizes; accessibility sizes stack instead,
    /// so no text is ever covered.
    static func leansOnCard(at size: DynamicTypeSize) -> Bool { !size.isAccessibilitySize }

    /// Top padding for the card the dog leans on, keeping the card's own content clear of it.
    static func cardTopPadding(at size: DynamicTypeSize, standard: CGFloat = 16) -> CGFloat {
        leansOnCard(at: size) ? leaningOverlap + 6 : standard
    }
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
/// on the capture card. A new mood replays it.
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
    var mascotSize: CGFloat = 84
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .trailing, spacing: 2) {
                MascotView(mood: mood, size: MascotMetrics.stackedSize)
                    .padding(.trailing, 12)
                MascotBubble(title: title, message: message, tail: .top, accessibilityID: accessibilityID)
            }
        } else {
            HStack(alignment: .center, spacing: 0) {
                MascotBubble(title: title, message: message, tail: .trailing, accessibilityID: accessibilityID)
                MascotView(mood: mood, size: mascotSize)
            }
        }
    }
}

/// The mascot leaning on a card: the dog sits on the card's top edge at its trailing side with
/// its lower part over the card, and the speech bubble sits to its leading side above the card.
/// The dog draws above the card but never takes taps, so the card's controls stay tappable; the
/// card keeps its own content clear of the dog with `MascotMetrics.cardTopPadding(at:)`. At
/// accessibility text sizes the dog, bubble and card stack without overlapping.
struct MascotLeaningCard<Card: View>: View {
    let mood: MascotMood
    let title: String
    let message: String
    let accessibilityID: String
    let card: Card
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(mood: MascotMood, title: String, message: String, accessibilityID: String = "tasks.mascot",
         @ViewBuilder card: () -> Card) {
        self.mood = mood
        self.title = title
        self.message = message
        self.accessibilityID = accessibilityID
        self.card = card()
    }

    var body: some View {
        if MascotMetrics.leansOnCard(at: dynamicTypeSize) {
            // Negative spacing pulls the card up under the dog, so the row's height still covers
            // everything and nothing is clipped by the list row.
            VStack(spacing: -MascotMetrics.leaningOverlap) {
                HStack(alignment: .bottom, spacing: 4) {
                    MascotBubble(title: title, message: message, tail: .trailing, accessibilityID: accessibilityID,
                                 trailingTailInsetFromBottom: MascotMetrics.leaningTailInset)
                        .padding(.bottom, MascotMetrics.leaningBubbleLift)
                    MascotView(mood: mood, size: MascotMetrics.prominentSize)
                        .allowsHitTesting(false)
                }
                .padding(.trailing, 8)
                .zIndex(1)
                card
            }
        } else {
            VStack(alignment: .trailing, spacing: 12) {
                VStack(alignment: .trailing, spacing: 2) {
                    MascotView(mood: mood, size: MascotMetrics.stackedSize)
                        .padding(.trailing, 12)
                    MascotBubble(title: title, message: message, tail: .top, accessibilityID: accessibilityID)
                }
                card
            }
        }
    }
}

/// The bubble's title and message on the card surface, read as one element.
private struct MascotBubble: View {
    let title: String
    let message: String
    let tail: SpeechBubbleShape.TailEdge
    let accessibilityID: String
    var trailingTailInsetFromBottom: CGFloat?

    var body: some View {
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
            let shape = SpeechBubbleShape(tail: tail, trailingTailInsetFromBottom: trailingTailInsetFromBottom)
            shape.fill(CVeeColors.card)
            shape.stroke(CVeeColors.divider, lineWidth: 1)
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
    /// Holds a trailing tail this far above the bubble's bottom instead of at its middle, for a
    /// mascot aligned to the bubble's bottom rather than its center.
    var trailingTailInsetFromBottom: CGFloat?

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
            // Keep the tail on the straight edge, clear of both corners.
            var tipY = body.midY
            if let inset = trailingTailInsetFromBottom {
                tipY = min(max(body.maxY - inset, body.minY + radius + tailHalf), body.maxY - radius - tailHalf)
            }
            path.addLine(to: CGPoint(x: body.maxX, y: tipY - tailHalf))
            path.addLine(to: CGPoint(x: rect.maxX, y: tipY))
            path.addLine(to: CGPoint(x: body.maxX, y: tipY + tailHalf))
        }
        path.addArc(tangent1End: bottomRight, tangent2End: bottomLeft, radius: radius)
        path.addArc(tangent1End: bottomLeft, tangent2End: topLeft, radius: radius)
        path.addArc(tangent1End: topLeft, tangent2End: topRight, radius: radius)
        path.closeSubpath()
        return path
    }
}
