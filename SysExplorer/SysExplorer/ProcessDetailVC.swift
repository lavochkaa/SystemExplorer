import UIKit

class ProcessDetailVC: UIViewController {

    private let process: SysProcessInfo
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private var sections: [(title: String, rows:[(key: String, value: String)])] = []


    init(process: SysProcessInfo) {
        self.process = process
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = process.name
        view.backgroundColor = .systemBackground

        buildSections()

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func buildSections() {
        let mb = process.memoryBytes / 1024 / 1024
        let files = (ProcessManager.getOpenFiles(forPid: process.pid) as? [String]) ?? []
        let xmlString = ProcessManager.getEntitlementsForPID(process.pid) ?? ""
        let entitnlemetsKeys = parseEntitlementKeys(from: xmlString)

        sections = [
            (title: "Info", rows: [
                (key: "PID", value: "\(process.pid)"),
                (key: "Name", value: process.name),
                (key: "Threads", value: "\(process.threadCount)"),
                (key: "Path", value: process.path ?? "unknown"),
                (key: "Inspect Binary", value: "→")
            ]),
            (title: "Memory", rows: [
                (key: "RAM", value: "\(mb) MB")
            ]),
            (title: "Open Files", rows: files.map { (key: $0, value: "") }),
            (title: "Entitlements", rows: entitnlemetsKeys.map { (key: $0, value: "")})
        ]
    }
}

extension ProcessDetailVC: UITableViewDataSource, UITableViewDelegate{

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "detail")
        let row = sections[indexPath.section].rows[indexPath.row]
        cell.textLabel?.text = row.key
        cell.detailTextLabel?.text = row.value
        cell.selectionStyle = row.key == "Inspect Binary" ? .default : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = sections[indexPath.section].rows[indexPath.row]
        if row.key == "Inspect Binary", let path = process.path {
            navigationController?.pushViewController(MachOInspectorVC(path: path), animated: true)
        }
    }
}

extension ProcessDetailVC {
    private func parseEntitlementKeys(from xml: String) -> [String] {
        guard !xml.isEmpty else { return ["No entitlemets"]}

        var keys: [String] = []
        let lines = xml.components(separatedBy: "\n")
        for line in lines {
            let trimed = line.trimmingCharacters(in: .whitespaces)
            if trimed.hasPrefix("<key>") && trimed.hasSuffix("</key") {
                let key = trimed.replacingOccurrences(of: "<key>", with: "").replacingOccurrences(of: "</key>", with: "")
                keys.append(key)
            }
        }
        return keys.isEmpty ? ["No entitlements"] : keys
    }
}
