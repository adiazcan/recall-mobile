//
//  ShareViewController.swift
//  ShareExtension
//
//  Recall iOS Share Extension - inline save form.
//  Stays in the host app (Safari, etc.), shows URL + Save button,
//  stores the URL in shared UserDefaults for the main app to sync.
//

import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    // MARK: - UI Elements

    private let navBar = UINavigationBar()
    private let urlLabel = UILabel()
    private let urlValueLabel = UILabel()
    private let statusIcon = UIImageView()
    private let statusLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    private var sharedURL: String?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupUI()
        loadSharedURL()
    }

    // MARK: - Navigation Bar

    private func setupNavigationBar() {
        navBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navBar)

        let navItem = UINavigationItem(title: "Save to Recall")
        navItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        navItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
        navBar.items = [navItem]

        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    // MARK: - Main UI

    private func setupUI() {
        let linkIcon = UIImageView(image: UIImage(systemName: "link"))
        linkIcon.tintColor = .systemBlue
        linkIcon.translatesAutoresizingMaskIntoConstraints = false
        linkIcon.setContentHuggingPriority(.required, for: .horizontal)
        view.addSubview(linkIcon)

        urlLabel.text = "URL"
        urlLabel.font = .systemFont(ofSize: 13, weight: .medium)
        urlLabel.textColor = .secondaryLabel
        urlLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(urlLabel)

        urlValueLabel.text = "Loading\u{2026}"
        urlValueLabel.font = .systemFont(ofSize: 15, weight: .regular)
        urlValueLabel.textColor = .label
        urlValueLabel.numberOfLines = 3
        urlValueLabel.lineBreakMode = .byTruncatingTail
        urlValueLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(urlValueLabel)

        statusIcon.translatesAutoresizingMaskIntoConstraints = false
        statusIcon.isHidden = true
        statusIcon.contentMode = .scaleAspectFit
        view.addSubview(statusIcon)

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.isHidden = true
        statusLabel.font = .systemFont(ofSize: 15, weight: .medium)
        statusLabel.textAlignment = .center
        view.addSubview(statusLabel)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            linkIcon.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 20),
            linkIcon.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            linkIcon.widthAnchor.constraint(equalToConstant: 20),
            linkIcon.heightAnchor.constraint(equalToConstant: 20),

            urlLabel.centerYAnchor.constraint(equalTo: linkIcon.centerYAnchor),
            urlLabel.leadingAnchor.constraint(equalTo: linkIcon.trailingAnchor, constant: 8),
            urlLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            urlValueLabel.topAnchor.constraint(equalTo: urlLabel.bottomAnchor, constant: 6),
            urlValueLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            urlValueLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            activityIndicator.topAnchor.constraint(equalTo: urlValueLabel.bottomAnchor, constant: 24),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            statusIcon.topAnchor.constraint(equalTo: urlValueLabel.bottomAnchor, constant: 20),
            statusIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusIcon.widthAnchor.constraint(equalToConstant: 36),
            statusIcon.heightAnchor.constraint(equalToConstant: 36),

            statusLabel.topAnchor.constraint(equalTo: statusIcon.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }

    // MARK: - Load Shared URL

    private func loadSharedURL() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            urlValueLabel.text = "No content found"
            disableSave()
            return
        }

        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] data, _ in
                    DispatchQueue.main.async {
                        if let url = data as? URL {
                            self?.sharedURL = url.absoluteString
                            self?.urlValueLabel.text = url.absoluteString
                        } else {
                            self?.urlValueLabel.text = "Could not load URL"
                            self?.disableSave()
                        }
                    }
                }
                return
            } else if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] data, _ in
                    DispatchQueue.main.async {
                        if let text = data as? String, self?.isValidURL(text) == true {
                            self?.sharedURL = text
                            self?.urlValueLabel.text = text
                        } else {
                            self?.urlValueLabel.text = "No valid URL found"
                            self?.disableSave()
                        }
                    }
                }
                return
            }
        }

        urlValueLabel.text = "No valid URL found"
        disableSave()
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    @objc private func saveTapped() {
        guard let url = sharedURL else { return }

        disableSave()
        activityIndicator.startAnimating()

        let appGroupId = resolveAppGroupId()
        NSLog("[ShareExtension] App Group ID: %@", appGroupId)
        let defaults = UserDefaults(suiteName: appGroupId)

        // Read auth config synced by the main Flutter app
        let accessToken = defaults?.string(forKey: "shareExtensionAccessToken")
        let apiBaseUrl = defaults?.string(forKey: "shareExtensionApiBaseUrl")

        NSLog("[ShareExtension] Token present: %@, API URL: %@",
              accessToken != nil ? "YES (\(accessToken!.prefix(20))...)" : "NO",
              apiBaseUrl ?? "nil")

        if let token = accessToken, !token.isEmpty,
           let baseUrl = apiBaseUrl, !baseUrl.isEmpty {
            // Make direct API call to create the item
            NSLog("[ShareExtension] Making API call to %@/api/v1/items", baseUrl)
            createItemOnBackend(url: url, token: token, apiBaseUrl: baseUrl)
        } else {
            // No auth available — store as pending for the main app to pick up
            NSLog("[ShareExtension] No auth config - storing as pending URL")
            storePendingUrl(url, defaults: defaults)
            activityIndicator.stopAnimating()
            showSuccess(message: "Saved — will sync when you open Recall")
            dismissAfterDelay()
        }
    }

    // MARK: - API Call

    private func createItemOnBackend(url: String, token: String, apiBaseUrl: String) {
        // Build the API endpoint
        var base = apiBaseUrl
        if base.hasSuffix("/") { base = String(base.dropLast()) }
        guard let endpoint = URL(string: "\(base)/api/v1/items") else {
            activityIndicator.stopAnimating()
            showError(message: "Invalid API URL")
            dismissAfterDelay()
            return
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        let body: [String: Any] = ["url": url]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()

                if let error = error {
                    NSLog("[ShareExtension] API error: \(error.localizedDescription)")
                    // Fallback: store as pending
                    let defaults = UserDefaults(suiteName: self?.resolveAppGroupId() ?? "group.com.recall.mobile")
                    self?.storePendingUrl(url, defaults: defaults)
                    self?.showError(message: "Saved locally — will sync later")
                    self?.dismissAfterDelay()
                    return
                }

                let httpResponse = response as? HTTPURLResponse
                let statusCode = httpResponse?.statusCode ?? 0

                if (200..<300).contains(statusCode) {
                    NSLog("[ShareExtension] Item created successfully (HTTP \(statusCode))")
                    self?.showSuccess(message: "Saved to Recall")
                } else {
                    NSLog("[ShareExtension] API returned HTTP \(statusCode)")
                    if let data = data, let body = String(data: data, encoding: .utf8) {
                        NSLog("[ShareExtension] Response: \(body)")
                    }
                    // Fallback: store as pending
                    let defaults = UserDefaults(suiteName: self?.resolveAppGroupId() ?? "group.com.recall.mobile")
                    self?.storePendingUrl(url, defaults: defaults)
                    self?.showError(message: "Saved locally — will sync later")
                }
                self?.dismissAfterDelay()
            }
        }
        task.resume()
    }

    private func storePendingUrl(_ url: String, defaults: UserDefaults?) {
        var pendingURLs = defaults?.stringArray(forKey: "pendingSharedURLs") ?? []
        pendingURLs.append(url)
        defaults?.set(pendingURLs, forKey: "pendingSharedURLs")
        defaults?.synchronize()
    }

    private func dismissAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    // MARK: - Helpers

    private func disableSave() {
        navBar.items?.first?.rightBarButtonItem?.isEnabled = false
    }

    private func showSuccess(message: String = "Saved to Recall") {
        statusIcon.image = UIImage(systemName: "checkmark.circle.fill")
        statusIcon.tintColor = .systemGreen
        statusIcon.isHidden = false

        statusLabel.text = message
        statusLabel.textColor = .systemGreen
        statusLabel.isHidden = false
    }

    private func showError(message: String) {
        statusIcon.image = UIImage(systemName: "exclamationmark.triangle.fill")
        statusIcon.tintColor = .systemOrange
        statusIcon.isHidden = false

        statusLabel.text = message
        statusLabel.textColor = .systemOrange
        statusLabel.isHidden = false
    }

    private func resolveAppGroupId() -> String {
        if let custom = Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String {
            return custom
        }
        let extensionBundleId = Bundle.main.bundleIdentifier ?? ""
        if let lastDot = extensionBundleId.lastIndex(of: ".") {
            let hostBundleId = String(extensionBundleId[..<lastDot])
            return "group.\(hostBundleId)"
        }
        return "group.com.recall.mobile"
    }

    private func isValidURL(_ string: String) -> Bool {
        if let url = URL(string: string),
           let scheme = url.scheme?.lowercased(),
           scheme == "http" || scheme == "https" {
            return true
        }
        return false
    }
}
