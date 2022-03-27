//
//  KNContactPickerButtons.swift
//  KNContactsPicker
//
//  Created by Dragos-Robert Neagu on 13/11/2019.
//  Copyright © 2019 Dragos-Robert Neagu. All rights reserved.
//

#if canImport(UIKit)
import UIKit

struct KNPickerElements {
    
    private static let PICK_CONTACT_ICON            = "person.crop.circle.badge.checkmark"
    private static let PICK_CONTACT_FILLED_ICON     = "person.crop.circle.fill.badge.checkmark"
    private static let CLEAR_SELECTION_ICON         = "trash.circle"
    private static let CLEAR_SELECTION_FILLED_ICON  = "trash.circle.fill"
    
    static func selectAllButton(action: Selector, target: UIViewController, settings: KNPickerSettings) -> UIBarButtonItem {
      let rightButton = UIBarButtonItem(title: "SelectAll", style: .done, target: target, action: action)
      return rightButton
    }
    
    static func selectAllButton(_ count: Int, action: Selector, target: UIViewController, settings: KNPickerSettings) -> UIBarButtonItem {
        let leftButton: UIButton = UIButton(type: .system)
        leftButton.setTitle(settings.selectAllContactsButtonTitle, for: .normal)
        leftButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        leftButton.addTarget(target, action: action, for: .touchUpInside)
        
        if #available(iOS 13.0, *) {
            leftButton.tintColor = .systemBlue
        }
        
        leftButton.sizeToFit()
        return UIBarButtonItem(customView: leftButton)
    }
    
    static func closeButton(action: Selector, target: UIViewController,  settings: KNPickerSettings) -> UIBarButtonItem {
      let leftButton = UIBarButtonItem(title: settings.closeButtonTitle, style: .done, target: target, action: action)
      return leftButton
    }
    
    static func pullToDismissAlert(count: Int, contactName: String, settings: KNPickerSettings, controller: KNContactsPickerController) -> UIAlertController {
        let message = (count > 1 && !contactName.isEmpty) ?
            String(format: settings.pullToDismissMessageMultipleContacts, contactName, count.advanced(by: -1)) :
            String(format: settings.pullToDismissMessageSingleContact, contactName)
        
        let alert = UIAlertController(title: settings.pullToDismissAlertTitle, message: message, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: settings.pullToDismissCompleteSelectionButtonTitle,
                                      style: .default) { _ in
                                        controller.presentationDelegate?.contactPickerDidSelect(controller)
        })
        
        alert.addAction(UIAlertAction(title: settings.pullToDismissDiscardSelectionButtonTitle,
                                      style: .destructive) { _ in
                                        controller.presentationDelegate?.contactPickerDidCancel(controller)
        })
        
        alert.addAction(UIAlertAction(title: settings.pullToDismissCancelButtonTitle,
                                      style: .cancel, handler: nil))
        
        return alert
    }
    
    static func searchResultsController(settings: KNPickerSettings, controller: KNContactsPickerController) -> UISearchController {
        
        let searchResultsController = UISearchController(searchResultsController: nil)
        searchResultsController.searchResultsUpdater = controller
        
        searchResultsController.hidesNavigationBarDuringPresentation = false
        searchResultsController.obscuresBackgroundDuringPresentation = false
        searchResultsController.navigationItem.largeTitleDisplayMode = .always
        searchResultsController.searchBar.placeholder = settings.searchBarPlaceholder
        
        controller.definesPresentationContext = true
        
        if #available(iOS 13.0, *) {
            
            let transparentAppearance = UINavigationBarAppearance().copy()
            transparentAppearance.configureWithTransparentBackground()
            
            searchResultsController.navigationItem.standardAppearance = transparentAppearance
            searchResultsController.navigationItem.compactAppearance = transparentAppearance
            searchResultsController.navigationItem.scrollEdgeAppearance = transparentAppearance
        }
        
        return searchResultsController
    }
}
#endif
