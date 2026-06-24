//
//  ViewController.swift
//  SysExplorer
//
//  Created by name space on 6/24/26.
//

import UIKit

class ViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let spinner = UIActivityIndicatorView(style: .large)
    private let refreshControl = UIRefreshControl()
    private let searchController = UISearchController(searchResultsController: nil)
    private var processes: [SysProcessInfo] = []
    private var filteredProcesses: [SysProcessInfo] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Processes"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        tableView.contentInsetAdjustmentBehavior = .automatic
        navigationController?.navigationBar.tintColor = .label
        view.backgroundColor = .systemBackground

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController

        refreshControl.addTarget(self, action: #selector(refreshProcesses), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        view.addSubview(spinner)
        spinner.center = view.center
        spinner.startAnimating()

        DispatchQueue.global().async {
            let loaded = Array((ProcessManager.getAllProcesses() as! [SysProcessInfo]).prefix(10)).filter { $0.name != "unknown"}
            DispatchQueue.main.async {
                self.processes = loaded
                self.filteredProcesses = loaded
                self.tableView.reloadData()
                self.spinner.stopAnimating()
            }
        }
    }

    @objc private func refreshProcesses() {
    DispatchQueue.global().async {
        let loaded = Array((ProcessManager.getAllProcesses() as! [SysProcessInfo]).prefix(10)).filter { $0.name != "unknown"}
        DispatchQueue.main.async {
            self.processes = loaded
            self.filteredProcesses = loaded
            self.tableView.reloadData()
            self.refreshControl.endRefreshing()
        }
    }
}
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredProcesses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let process = filteredProcesses[indexPath.row]
        cell.textLabel?.text = process.name
        cell.detailTextLabel?.text = "PID: \(process.pid) | RAM: \(process.memoryBytes / 1024 / 1024) MB"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let process = filteredProcesses[indexPath.row]
        let detailVC = ProcessDetailVC(process: process)
        navigationController?.pushViewController(detailVC, animated: true)
    }

}

extension ViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text ?? ""
        if query.isEmpty {
            filteredProcesses = processes
        } else {
            filteredProcesses = processes.filter { $0.name.localizedStandardContains(query)}
        }
        tableView.reloadData()
    }
}
