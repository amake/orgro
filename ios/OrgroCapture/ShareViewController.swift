import UIKit
import UniformTypeIdentifiers
import os

// Logging level must be `critical` to be able to see logging in Console.app
fileprivate let logger = Logger(.disabled)

fileprivate let orgProtocolScheme = Bundle.main.infoDictionary!["AMKOrgProtocolScheme"] as! String

class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        logger.critical("View did load")
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
            let providers = extensionItem.attachments else {
            logger.critical("Did not have extensionItem or providers")
            close()
            return
        }

        Task {
            do {
                try await processProviders(providers)
            } catch {
                logger.critical("Error: \(error)")
            }
            close()
        }
    }

    private func processProviders(_ providers: [NSItemProvider]) async throws {
        let plistDataType = UTType.propertyList.identifier
        if let p = providers.first(where: { $0.hasItemConformingToTypeIdentifier(plistDataType) })  {
            logger.critical("Had plist; loading")
            let item = try await p.loadItem(forTypeIdentifier: plistDataType)
            await sharePlist(item)
            return
        }

        var url: NSSecureCoding?, text: NSSecureCoding?

        let urlDataType = UTType.url.identifier
        if let p = providers.first(where: { $0.hasItemConformingToTypeIdentifier(urlDataType) }) {
            logger.critical("Had URL; loading")
            url = try await p.loadItem(forTypeIdentifier: urlDataType)
        }

        let textDataType = UTType.plainText.identifier
        if let p = providers.first(where: { $0.hasItemConformingToTypeIdentifier(textDataType) }) {
            logger.critical("Had plain text; loading")
            text = try await p.loadItem(forTypeIdentifier: textDataType)
        }

        guard url != nil || text != nil else {
            throw NSError()
        }

        if url == nil {
            await shareParts(urlItem: nil, titleItem: nil, bodyItem: text)
        } else {
            await shareParts(urlItem: url, titleItem: text, bodyItem: nil)
        }
    }

    private func sharePlist(_ item: NSSecureCoding?) async {
        let outerDict = item as! NSDictionary
        let dict = outerDict[NSExtensionJavaScriptPreprocessingResultsKey] as! NSDictionary
        logger.critical("Got dict: \(dict.debugDescription)")

        let url = dict["baseURI"]
        let title = dict["title"]
        let body = dict["selection"]
        await shareParts(urlItem: url, titleItem: title, bodyItem: body)
    }

    private func shareParts(urlItem: Any?, titleItem: Any?, bodyItem: Any?) async {
        logger.critical("Got url: \(urlItem.debugDescription), title: \(titleItem.debugDescription), body: \(bodyItem.debugDescription)")

        var comp = URLComponents()
        comp.scheme = orgProtocolScheme
        comp.host = "capture"
        var queryItems: [URLQueryItem] = []
        if let url = urlItem as? NSURL {
            queryItems.append(URLQueryItem(name: "url", value: url.absoluteString))
        } else if let url = urlItem as? String {
            queryItems.append(URLQueryItem(name: "url", value: url))
        }
        if let title = titleItem as? String, !title.isEmpty {
            queryItems.append(URLQueryItem(name: "title", value: title))
        }
        if let body = bodyItem as? String, !body.isEmpty {
            queryItems.append(URLQueryItem(name: "body", value: body))
        }
        comp.queryItems = queryItems
        let orgUrl = comp.url!
        logger.critical("Going to open url: \(orgUrl)")
        let success = await openURL(orgUrl)
        logger.critical("Open url succeeded: \(success)")
    }

    @discardableResult
    private func openURL(_ url: URL, completion: ((Bool) -> Void)? = nil) async -> Bool {
        let responder = sequence(first: self, next: \.next)
            .first(where: { $0 is UIApplication })
        guard let application = responder as? UIApplication else {
            return false
        }
        return await application.open(url, options: [:])
    }

    func close() {
        logger.critical("Going to close")
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
