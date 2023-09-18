//
//  ListViewController.swift
//  TravelBook
//
//  Created by Jimmy Ghelani on 2023-09-18.
//

import UIKit

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var names = [String]()
    var comments = [String]()
    var ids = [UUID]()
    var chosenTitle = ""
    var chosenTitleID: UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addItem))
        
        getData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newPlace"), object: nil)
    }
    
    @objc func addItem() {
        chosenTitle = ""
        performSegue(withIdentifier: "toMapView", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapView" {
            let destination = segue.destination as! ViewController
            destination.hasData = !chosenTitle.isEmpty
            destination.selectedTitle = chosenTitle
            destination.selectedTitleID = chosenTitleID
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return names.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        var configuration = cell.defaultContentConfiguration()
        configuration.text = names[indexPath.row]
        cell.contentConfiguration = configuration
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenTitle = names[indexPath.row]
        chosenTitleID = ids[indexPath.row]
        performSegue(withIdentifier: "toMapView", sender: nil)
    }
    
    @objc func getData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = Places.fetchRequest()
        request.returnsObjectsAsFaults = false
        
        do {
            self.names.removeAll(keepingCapacity: false)
            self.comments.removeAll(keepingCapacity: false)
            self.ids.removeAll(keepingCapacity: false)
            
            let results = try context.fetch(request)
            if results.count > 0 {
                for result in results {
                    names.append(result.title!)
                    comments.append(result.subtitle!)
                    ids.append(result.id!)
                }
                self.tableView.reloadData()
            }
        } catch {
            print("Couldn't retrieve data: \(error)")
        }
    }

}

#Preview {
    let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
    let controller = storyboard.instantiateViewController(withIdentifier: "mainVC")
    
    return UINavigationController(rootViewController: controller)
}
