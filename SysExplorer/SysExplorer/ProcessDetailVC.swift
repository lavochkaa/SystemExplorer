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
        sections = [
            (title: "Info", rows: [
                (key: "PID", value: "\(process.pid)"),
                (key: "Name", value: process.name)
            ]),
            (title: "Memory", rows: [
                (key: "RAM", value: "\(mb) MB")
            ])
        ]
    }
}

extension ProcessDetailVC: UITableViewDataSource {

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
        cell.selectionStyle = .none
        return cell
    }
}
