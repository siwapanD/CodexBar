import AppKit
import Testing
@testable import CodexBar

@MainActor
struct MergedBrandPercentIconTests {
    private func solidImage(_ side: CGFloat = 16) -> NSImage {
        let image = NSImage(size: NSSize(width: side, height: side))
        image.lockFocus()
        NSColor.black.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: side, height: side)).fill()
        image.unlockFocus()
        return image
    }

    @Test
    func `empty entries produce no image`() {
        #expect(MergedBrandPercentIcon.image(entries: []) == nil)
    }

    @Test
    func `single entry renders a template image`() {
        let image = MergedBrandPercentIcon.image(
            entries: [.init(brand: self.solidImage(), text: "45%")])
        #expect(image != nil)
        #expect(image?.isTemplate == true)
        #expect((image?.size.width ?? 0) > 0)
        #expect((image?.size.height ?? 0) >= 18)
    }

    @Test
    func `more providers yield a wider strip`() {
        let single = MergedBrandPercentIcon.image(
            entries: [.init(brand: self.solidImage(), text: "45%")])
        let triple = MergedBrandPercentIcon.image(
            entries: [
                .init(brand: self.solidImage(), text: "45%"),
                .init(brand: self.solidImage(), text: "80%"),
                .init(brand: self.solidImage(), text: "12%"),
            ])
        #expect((triple?.size.width ?? 0) > (single?.size.width ?? 0))
    }

    @Test
    func `percent text widens a provider group`() {
        let withText = MergedBrandPercentIcon.image(
            entries: [.init(brand: self.solidImage(), text: "100%")])
        let withoutText = MergedBrandPercentIcon.image(
            entries: [.init(brand: self.solidImage(), text: nil)])
        #expect((withText?.size.width ?? 0) > (withoutText?.size.width ?? 0))
    }
}
