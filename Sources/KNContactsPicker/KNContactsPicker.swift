//
//  KNContactsPicker.swift
//  KNContactsPicker
//
//  Created by Dragos-Robert Neagu on 24/10/2019.
//  Copyright © 2019 Dragos-Robert Neagu. All rights reserved.
//

#if canImport(UIKit) && canImport(Contacts)
import UIKit
import Contacts

open class KNContactsPicker: UINavigationController {
  
  var settings: KNPickerSettings = KNPickerSettings()
  weak var contactPickingDelegate: KNContactPickingDelegate!
  private var contacts: [CNContact] = []
  
  private var sortingOutcome: KNSortingOutcome?
  
  lazy var contactPickerController = self.getContactsPicker()
  override open func viewDidLoad() {
    super.viewDidLoad()
    self.fetchContacts()
    
    self.navigationBar.prefersLargeTitles = true
    self.navigationItem.largeTitleDisplayMode = .always
    
    self.viewControllers.append(contactPickerController)
  }
  
  public init(delegate: KNContactPickingDelegate?, settings: KNPickerSettings) {
    self.contactPickingDelegate = delegate
    self.settings = settings
    super.init(nibName: nil, bundle: nil)
  }
  
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public func deselectAll() {
    contactPickerController.deselectAll()
  }
  
  func getContactsPicker() -> KNContactsPickerController {
    let controller = KNContactsPickerController()
    
    controller.settings = settings
    controller.delegate = contactPickingDelegate
    controller.presentationDelegate = self
    controller.contacts = sortingOutcome?.sortedContacts ?? []
    controller.sortedContacts = sortingOutcome?.contactsSortedInSections ?? [:]
    controller.sections = sortingOutcome?.sections ?? []
    
    return controller
  }
  
  func fetchContacts() {
    
    switch settings.pickerContactsSource {
    case .userProvided:
      self.sortingOutcome = KNContactUtils.sortContactsIntoSections(contacts: settings.pickerContactsList, sortingType: settings.displayContactsSortedBy)
    case .default:
      requestAndSortContacts()
    }
    
  }
  
  private func requestAndSortContacts() {
    switch KNContactsAuthorisation.requestAccess(conditionToEnableContact: settings.conditionToDisplayContact) {
    case .success(let resultContacts):
      self.sortingOutcome = KNContactUtils.sortContactsIntoSections(contacts: resultContacts, sortingType: settings.displayContactsSortedBy)
      
    case .failure(let failureReason):
      if failureReason != .pendingAuthorisation {
        self.dismiss(animated: true, completion: {
          self.contactPickingDelegate?.contactPicker(didFailPicking: failureReason)
        })
      }
    }
  }
  
}
#endif
