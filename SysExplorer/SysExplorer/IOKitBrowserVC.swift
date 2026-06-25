import UIKit

class IOKitBrowserVC: UIViewController {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var services: [(name: String, className: String)] = []

    private func loadServices() {
        DispatchQueue.global().async {
            let entries = IOKitExplorer.getRootEntries() as! [IOKitEntry]
            let loaded = entries.map { (name: $0.name ?? "", className: $0.className ?? "") }
            DispatchQueue.main.async {
                self.services = loaded
                self.tableView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "IOKit"
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

extension IOKitBrowserVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let service = services[indexPath.row]
        cell.textLabel?.text = service.name
        cell.detailTextLabel?.text = service.className
        return cell
    }
}