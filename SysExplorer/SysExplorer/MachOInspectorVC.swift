import UIKit

class MachOInspectorVC: UIViewController {

    private let path: String
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var sections: [(title: String, rows: [String])] = []

    init(path: String) {
        self.path = path
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("inti(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Mach-O Inspector"
        view.backgroundColor = .systemBackground

        if let info = MachOParser.parseFile(path) {
            sections = [
                ("Info", [
                    "Arch: \(info.arch ?? "unknown")",
                    "Type: \(info.fileType ?? "unknown")",
                    "64-bit: \(info.is64bit ? "Yes" : "No")"
                ]),
                ("Segments", info.segments ?? []),
                ("Linked Libraries", info.linkedLibraries ?? [])
            ]
        } else {
            sections = [("Error", ["Failed to parse binary at path: \(path)"])]
        }

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

extension MachOInspectorVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = sections[indexPath.section].rows[indexPath.row]
        cell.textLabel?.numberOfLines = 0
        return cell
    }
}