//
//  BottlesListViewController.swift
//  Vinishko
//
//  Created by Денис on 01.10.2022.
//

import UIKit
import RealmSwift

class BottlesListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UpdateTableView {
    
    let alertView = UIView()
    var bottles: Results<Bottle>!
    var filteredBottles: Results<Bottle>!
    
    private let shared = FilterManager.shared
    private let searchController = UISearchController(searchResultsController: nil)
    
    @IBOutlet weak var tableView: UITableView!
    
    private var searchBarIsEmpty: Bool {
        guard let text = searchController.searchBar.text else { return false }
        return text.isEmpty
    }
    private var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bottles = realm.objects(Bottle.self)
        tableView.delegate = self
        tableView.dataSource = self
        registerCell()
        setupSearchBar()
        tableView.reloadData()
    }
            
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        alertView.removeFromSuperview()
    }
    
    private func addBannerWith(alertText: String) {
        if bottles.count == 0 {
            alertView.frame = CGRect(x: CGFloat(0), y: tableView.bounds.height / 2 - 80, width: tableView.bounds.width, height: CGFloat(80))
            alertView.backgroundColor = .redWineColor
            
            let alertTextLabel = UILabel()
            alertTextLabel.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: alertView.bounds.width, height: CGFloat(80))
            
            alertTextLabel.textAlignment = .center
            alertTextLabel.font = .systemFont(ofSize: 18, weight: .semibold)
            alertTextLabel.textColor = .white
            alertTextLabel.text = alertText
            
            alertView.addSubview(alertTextLabel)
            tableView.addSubview(alertView)
        }
    }
    
    private func registerCell() {
        let cell = UINib(nibName: "BottleCell", bundle: nil)
        tableView.register(cell, forCellReuseIdentifier: "bottleCell")
    }
    
    private func setupSearchBar() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Найти винишко по названию"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return filteredBottles.count
        }
        return bottles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bottleCell", for: indexPath) as! BottleCell
        if isFiltering {
            cell.setup(model: filteredBottles.reversed()[indexPath.row])
        } else {
            cell.setup(model: bottles.reversed()[indexPath.row])
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        tableView.separatorStyle = .none
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let bottle = bottles.reversed()[indexPath.row]
        let deleteAction = UIContextualAction(style: .destructive, title: "Удалить") {  (contextualAction, view, boolValue) in
            StorageManager.deleteObject(bottle)
            tableView.deleteRows(at: [indexPath], with: .left)
        }
        let swipeActions = UISwipeActionsConfiguration(actions: [deleteAction])
        return swipeActions
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let editVC = storyboard?.instantiateViewController(withIdentifier: "editBottle") as? NewBottleViewController else { return }
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        let bottle = isFiltering ? filteredBottles.reversed()[indexPath.row] : bottles.reversed()[indexPath.row]
        editVC.currentBottle = bottle
        editVC.isEdited = true
        editVC.delegate = self
        editVC.modalPresentationStyle = .pageSheet
        present(editVC, animated: true)
    }
    
    // Delegate method
    func update() {
        tableView.reloadData()
    }
    
    @IBAction func filterButtonAction(_ sender: Any) {
        performSegue(withIdentifier: "filter", sender: nil)
    }
    
    @IBAction func unwindSegue(_ segue: UIStoryboardSegue) {
        bottles = realm.objects(Bottle.self)
        
        if shared.colorIdOptionInfo != nil && shared.colorIdOptionInfo != 9 {
            let filtered = bottles.where { $0.wineColor == shared.colorIdOptionInfo }
            bottles = filtered
        }
           
        if shared.placeOfPurchaseOptionInfo != nil {
            let filtered = bottles.where { $0.placeOfPurchase == shared.placeOfPurchaseOptionInfo }
            bottles = filtered
        }
        
        if shared.countryOptionInfo != nil {
            let filtered = bottles.where { $0.wineCountry == shared.countryOptionInfo }
            bottles = filtered
        }
        addBannerWith(alertText: "Упс, ничего не нашлось..(")
        tableView.reloadData()
    }
        
}

// MARK: Searching
extension BottlesListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        filteredBottles = bottles.filter("name CONTAINS[cd] %@", searchText)
        tableView.reloadData()
    }
}