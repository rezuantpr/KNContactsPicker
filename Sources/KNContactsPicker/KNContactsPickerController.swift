//
//  KNContactsTableViewController.swift
//  KNContactsPicker
//
//  Created by Dragos-Robert Neagu on 22/10/2019.
//  Copyright © 2019 Dragos-Robert Neagu. All rights reserved.
//

#if canImport(UIKit) && canImport(Contacts)
import UIKit
import Contacts

protocol KNContactsPickerControllerPresentationDelegate: AnyObject {
  func contactPickerDidCancel(_ picker: KNContactsPickerController)
  func contactPickerDidSelect(_ picker: KNContactsPickerController)
}

class KNContactsPickerController: UIViewController {
  lazy var tableView: UITableView = {
    var tableView: UITableView
    if #available(iOS 13.0, *) {
      tableView = UITableView(frame: .zero, style: .insetGrouped)
    } else {
      tableView = UITableView(frame: .zero, style: .grouped)
    }
    tableView.register(KNContactCell.self, forCellReuseIdentifier: CELL_ID)
    tableView.sectionIndexColor = UIColor.lightGray
    tableView.dataSource = self
    tableView.delegate = self
    tableView.translatesAutoresizingMaskIntoConstraints = false
    return tableView
  }()
  
  lazy var doneButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(settings.doneButtonTitle, for: .normal)
    button.setTitleColor(settings.doneButtonTitleColor, for: .normal)
    button.setBackgroundColor(color: settings.tintColor, forState: .normal)
    button.setBackgroundColor(color: settings.tintColor.withAlphaComponent(0.7), forState: .highlighted)
    button.layer.cornerRadius = 10
    if #available(iOS 13.0, *) {
      button.layer.cornerCurve = .continuous
    }
    button.addTarget(self, action: #selector(completeSelection), for: .touchUpInside)
    return button
  }()
  
  let backgroundView = UIView()
  
  public var settings: KNPickerSettings = KNPickerSettings()
  public weak var delegate: KNContactPickingDelegate?
  public weak var presentationDelegate: KNContactsPickerControllerPresentationDelegate?
  
  private let CELL_ID = "KNContactCell"
  private let formatter =  CNContactFormatter()
  
  var searchResultsController: UISearchController?
  var contacts: [CNContact] = []
  var filteredContacts: [CNContact] = []
  var sortedContacts: [String: [CNContact]] = [:]
  var sections: [String] = []
  
  private var selectedContacts: Set<CNContact> = [] {
    didSet {
      showDoneButton()
      self.tableView.reloadData()
    }
  }
  
  func showDoneButton() {
    let alpha: CGFloat = selectedContacts.count == 0 ? 0 : 1
    let inset: CGFloat = selectedContacts.count == 0 ? 0 : settings.doneButtonHeight + 8 + view.safeAreaInsets.bottom
    UIView.animate(withDuration: 0.4, delay: 0, options: [], animations: {
      self.backgroundView.alpha = alpha
      self.doneButton.alpha = alpha
      self.tableView.contentInset.bottom = inset
    }, completion: nil)
  }
  
  
  var shouldDisableSelection: Bool {
    get { return settings.selectionMode == .singleDeselectOthers && selectedContacts.count == 1 }
  }
  
  var isSearchBarEmpty: Bool {
    return searchResultsController?.searchBar.text?.isEmpty ?? true
  }
  
  var isFiltering: Bool {
    return (searchResultsController?.isActive ?? false) && !isSearchBarEmpty
  }
  
  func isSelectedAll() -> Bool {
    isFiltering ? selectedContacts.count == filteredContacts.count : selectedContacts.count == contacts.count
  }
  
  override open func viewDidLoad() {
    super.viewDidLoad()
    
//    view.backgroundColor = .white
    self.navigationItem.largeTitleDisplayMode = .always
    self.navigationItem.title = settings.pickerTitle
    
    self.searchResultsController = KNPickerElements.searchResultsController(settings: settings, controller: self)
    self.navigationItem.searchController = searchResultsController
    self.navigationItem.largeTitleDisplayMode = .always
    self.navigationItem.hidesSearchBarWhenScrolling = false
    
    
    view.addSubview(tableView)
    view.addSubview(backgroundView)
    
    backgroundView.backgroundColor = UIColor(red: 227.0/255.0, green: 227.0/255.0, blue: 231.0/255.0, alpha: 1.0)
    
    backgroundView.addSubview(doneButton)
    
    view.layoutIfNeeded()
    view.setNeedsUpdateConstraints()
    configureButtons()
    showDoneButton()
  }
  
  override func updateViewConstraints() {
    tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
    tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
    tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true

    backgroundView.translatesAutoresizingMaskIntoConstraints = false
    backgroundView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
    backgroundView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
    backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
    backgroundView.heightAnchor.constraint(equalToConstant: settings.doneButtonHeight +  view.safeAreaInsets.bottom + 8 + 16).isActive = true
    
    doneButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
    doneButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
    doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16).isActive = true
    doneButton.heightAnchor.constraint(equalToConstant: settings.doneButtonHeight).isActive = true
    
    super.updateViewConstraints()
  }
  
  func configureButtons() {
    navigationItem.rightBarButtonItem = KNPickerElements.selectAllButton(action: #selector(selectAllSelected), target: self, settings: settings)
    
    navigationItem.leftBarButtonItem = KNPickerElements.closeButton(action: #selector(close), target: self, settings: settings)
  }
  
  public func getSelectedContacts() -> [CNContact] {
    return Array(selectedContacts)
  }
  
  @objc func selectAllSelected() {
    if isSelectedAll() {
      selectedContacts.removeAll()
      self.navigationItem.rightBarButtonItem?.title = "Select All"
    } else {
      let contactsToAdd = isFiltering ? filteredContacts : contacts
      selectedContacts = Set(contactsToAdd)
      self.navigationItem.rightBarButtonItem?.title = "Deselect All"
    }
  }
  
  @objc func close() {
    dismiss(animated: true, completion: nil)
  }
  
  @objc func completeSelection() {
    self.presentationDelegate?.contactPickerDidSelect(self)
  }
  
  @objc func clearSelected() {
    self.selectedContacts.removeAll()
  }
  
  fileprivate func toggleSelected(_ contact: CNContact) {
    if (settings.selectionMode == .singleReselect) {
      self.clearSelected()
      selectedContacts.insert(contact)
    }
    else if selectedContacts.contains(contact) {
      selectedContacts.remove(contact)
    } else {
      selectedContacts.insert(contact)
    }
    
      if isSelectedAll() {
        self.navigationItem.rightBarButtonItem?.title = "Deselect All"
      } else {
        self.navigationItem.rightBarButtonItem?.title = "Select All"
      }
  }
  
  fileprivate func confirmCancel() {
    let firstContactsName = selectedContacts.first?.getFullName(using: formatter) ?? ""
    
    let alert = KNPickerElements.pullToDismissAlert(count: selectedContacts.count,
                                                    contactName: firstContactsName,
                                                    settings: settings,
                                                    controller: self)
    
    alert.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
    
    self.present(alert, animated: true, completion: nil)
  }
  fileprivate func getContact(at indexPath: IndexPath) -> CNContact {
    if isFiltering {
      return self.filteredContacts[indexPath.row]
    }
    else {
      let sectionContact = self.sortedContacts[self.sections[indexPath.section]]
      return sectionContact![indexPath.row]
    }
  }
  
}

extension KNContactsPickerController: UITableViewDelegate, UITableViewDataSource {
  
  // MARK: Table View Sections
  open func numberOfSections(in tableView: UITableView) -> Int {
    return isFiltering ? 1 : self.sections.count
  }
  
  open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return isFiltering ? settings.searchResultSectionTitle : self.sections[section]
  }
  
  // MARK: Table View Rows
  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return isFiltering ? self.filteredContacts.count : self.sortedContacts[self.sections[section]]?.count ?? 0
  }
  
  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID, for: indexPath) as! KNContactCell
    cell.tintColor = settings.tintColor
    let contact = self.getContact(at: indexPath)
    let contactModel = KNContactCellModel(contact: contact, settings: settings, formatter: formatter)
    
    let disabled = ( shouldDisableSelection && !selectedContacts.contains(contact) ) || settings.conditionToDisableContact(contact)
    
    let selected = selectedContacts.contains(contact)
    cell.set(contactModel: contactModel)
    
    cell.setDisabled(disabled: disabled)
    cell.setSelected(selected, animated: false)
    return cell
  }
  
  open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 50
  }
  
  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let contact = self.getContact(at: indexPath)
    self.toggleSelected(contact)
  }
  
  // MARK: Section Index Title
  func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    return self.sections
  }
  
  func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
    return index
  }
  
}

// MARK: SEARCH RESULTS UPDATING
extension KNContactsPickerController: UISearchResultsUpdating {
  
  func filterContentForSearchText(_ searchText: String) {
    let filteredContacts = self.contacts.filter({( currentContact: CNContact) -> Bool in
      return (currentContact.getFullName(using: formatter).lowercased().contains(searchText.lowercased()))
    })
    let outcome = KNContactUtils.sortContactsIntoSections(contacts: filteredContacts, sortingType: .givenName)
    self.filteredContacts = outcome.sortedContacts
    
    
    if isSelectedAll() {
      self.navigationItem.rightBarButtonItem?.title = "Deselect All"
    } else {
      self.navigationItem.rightBarButtonItem?.title = "Select All"
    }
  }
  
  
  public func updateSearchResults(for searchController: UISearchController) {
    self.filterContentForSearchText(searchController.searchBar.text!)
    self.tableView.reloadData()
  }
}

#endif
