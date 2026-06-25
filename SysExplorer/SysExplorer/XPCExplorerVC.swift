import UIKit

class XPCExplorerVC: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var services: [(name: String, label: String)] = []

    private func loadServices() {
        DispatchQueue.global().async {
            let path = "/System/Library/LaunchDaemons"
            guard let files = try? FileManager.default.contentsOfDirectory(atPath: path) else { return }

            var loaded: [(name: String, label: String)] = []
            for file in files where file.hasSuffix(".plist") {
                let fullPath = "\(path)/\(file)"
                guard let dict = NSDictionary(contentsOfFile: fullPath) else { continue }

                let label = dict["Label"] as? String ?? file
                if let machServices = dict["MachServices"] as? [String: Any] {
                    for service in machServices.keys {
                        loaded.append((name: service, label: label))
                    }
                }
            }

            DispatchQueue.main.async {
                self.services = loaded
                self.tableView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "XPC Services"
        view.backgroundColor = .systemBackground
        loadServices()

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

}

extension XPCExplorerVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let service = services[indexPath.row]
        cell.textLabel?.text = service.name
        cell.detailTextLabel?.text = service.label
        return cell
    }
}