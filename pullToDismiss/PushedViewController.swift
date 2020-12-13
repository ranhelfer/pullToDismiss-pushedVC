//
//  PushedViewController.swift
//  pullToDismiss
//
//  Created by rhalfer on 16/01/2020.
//  Copyright © 2020 rhalfer. All rights reserved.
//

import UIKit

class PushedViewController: UIViewController, UICollectionViewDataSource {

    var interactor: DismissInteractor? = nil
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(UINib(nibName: CellCollectionViewCell.NibName, bundle: nil), forCellWithReuseIdentifier: CellCollectionViewCell.Identifier)
        collectionView.dataSource = self
        
        interactor?.setUp(scrollView: collectionView, viewController: self)
    }
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellCollectionViewCell.Identifier, for: indexPath) as? CellCollectionViewCell {
            return cell
        }
        assertionFailure("Failed to dequeue cell of type CellCollectionViewCell")
        return collectionView.dequeueReusableCell(withReuseIdentifier: CellCollectionViewCell.Identifier, for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 200
    }
    
}
