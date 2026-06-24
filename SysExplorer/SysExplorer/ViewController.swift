//
//  ViewController.swift
//  SysExplorer
//
//  Created by name space on 6/24/26.
//

import UIKit

class ViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var processes: [SysProcessInfo] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Processes"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.tintColor = .label
        view.backgroundColor = .systemBackground

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        processes = ProcessManager.getAllProcesses() as! [SysProcessInfo]
        tableView.reloadData()
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return processes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let process = processes[indexPath.row]
        cell.textLabel?.text = process.name
        cell.detailTextLabel?.text = "PID: \(process.pid) | RAM: \(process.memoryBytes / 1024 / 1024) MB"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let process = processes[indexPath.row]
        let detailVC = ProcessDetailVC(process: process)
        navigationController?.pushViewController(detailVC, animated: true)
    }

}
